# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from graphviz import Digraph
import json
import numpy as np
import os
from .parser import HWHComposable
from pynq import DefaultIP, DefaultHierarchy
from pynq.utils import ReprDict
from .repr_dict import ReprDictComposable
from .virtual import DFXRegion, StreamingIP, UnloadedIP
from typing import Type, Union

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


_mem_items = ['axis_register_slice', 'axis_data_fifo',
              'fifo_generator', 'axis_dwidth_converter',
              'axis_subset_converter']


def _nest_level(pl: list) -> int:
    """Compute nested levels of a list iteratively"""

    if not isinstance(pl, list):
        return 0
    level = 0
    for item in pl:
        level = max(level, _nest_level(item))

    return level + 1


def _count_slots(pl: list) -> int:
    """Returns the number of elements in a list"""

    total = 0
    for l0 in pl:
        if isinstance(l0, list):
            for l1 in l0:
                if isinstance(l1, list):
                    for l2 in l1:
                        total += 1
                else:
                    total += 1
        else:
            total += 1

    return total


def _find_index_in_list(pipeline: list, element: Type[DefaultIP]) \
        -> Union[int, tuple]:
    """Return the index of the element in the pipeline"""

    for i, v in enumerate(pipeline):
        if isinstance(v, list):
            for ii, vv in enumerate(v):
                for iii, vvv in enumerate(vv):
                    if vvv == element:
                        return i, ii, iii
        elif v == element:
            return i

    return None


def _edge_label(si: int, mi: int, debug: bool) -> str:
    """Generate edge label given"""

    return '<<font color=\"' + ('green' if debug else 'white') + '\">' + \
           'si=' + str(si) + ' mi=' + str(mi) + '</font>>'


def _get_ip_name_by_vlnv(description: dict, vlnv: str) -> str:
    """Search IP by its VLNV and return its name"""

    for k, v in description['ip'].items():
        ip_vlnv = v.get('type')
        if ip_vlnv == vlnv:
            return k
    return None


class Composable(DefaultHierarchy):
    """This class keeps track of a composable overlay

    The Composable class holds the state of the logic available for run-time
    composition through and AXI4-Stream switch

    Our definition of composable overlay is: "post-bitstream configurable
    dataflow pipeline". Hence, this class must expose configurability through
    content discovery, dataflow configuration and runtime protection.

    This class stores two dictionaries: c_dict and dfx_dict

    Each entry of the Composable dictionary (c_dict) is a mapping:
    'name' -> {si, mi, modtype, dfx, loaded, bitstream}, where
    name (str) is the key of the entry.
    si (list) list of physical port in the switch the IP is connected to
    mi (list) list of physical port in the switch the IP is connected from
    modtype(str) IP type
    dfx (bool) IP is located in a DFX region
    loaded (bool) IP is loaded
    bitstream (str) location of the corresponding partial bitstream

    Each entry of the PR dictionary (pr_dict) dictionary is a mapping:
    'name' -> {decoupler, gpio, ip}, where
    name (str) is the name of the partial region
    decoupler (str) fullpath of the DFX decoupler that controls the pr region
    gpio (dict) index of PS GPIO that control the DFX decoupler
    ip (dict) dictionary of partial bitstream and IP associated to the region

    Attributes
    ----------
    graph : Digraph
        Graphviz Digraph representation of the current dataflow pipeline
    """

    @staticmethod
    def checkhierarchy(description):
        if _get_ip_name_by_vlnv(description, 'xilinx.com:ip:axis_switch:1.1'):
            return True

        return False

    def __init__(self, description):
        """Return a new Composable object.

        Performs a hardware discovery where the different IP cores connected
        to the switch are added to the c_dict and the DFX regions are added
        to the dfx_dict

        Parameters
        ----------
        description : dict
            Description of the hierarchy

        Note
        ----
        This class requires that partial bitstreams and corresponding HWH files
        to be next to bitstream file that was used to create the Overlay object
        The name convention for partial bitstreams and HWH file is

        <bitstream_name>_<hierarchy>_<pr_region>_<pr_module_name>.{bit|hwh}

        For instance if the main bitstream is `base.bit` and there are two DFX
        regions with the names `pr_0` and `pr_1` each of them with the same
        two reconfigurable module, `function_1` and `function_2` the names
        should be as follow

            base_composable_pr_0_function_1.bit
            base_composable_pr_0_function_1.hwh
            base_composable_pr_0_function_2.bit
            base_composable_pr_0_function_2.hwh
            base_composable_pr_1_function_1.bit
            base_composable_pr_1_function_1.hwh
            base_composable_pr_1_function_2.bit
            base_composable_pr_1_function_2.hwh

        """

        super().__init__(description)
        self._hier = description['fullpath'] + '/'
        self._dfx_dict = None
        self._bitfile = description['device'].bitfile_name
        self._hwh_name = os.path.splitext(self._bitfile)[0] + '.hwh'
        self._ol = description['overlay']

        switch_name = \
            _get_ip_name_by_vlnv(description, 'xilinx.com:ip:axis_switch:1.1')
        self._switch = getattr(self._ol, self._hier + switch_name)
        self._max_slots = self._switch.max_slots
        pipelinecrt = \
            _get_ip_name_by_vlnv(description, 'xilinx.com:ip:axi_gpio:2.0')
        if pipelinecrt:
            self._pipecrtl = getattr(self._ol, self._hier + pipelinecrt)
            self._soft_reset = self._pipecrtl.channel1
            self._dfx_control = self._pipecrtl.channel2
        else:
            self._soft_reset = None
            self._dfx_control = None

        parser = HWHComposable(self._hwh_name, self.axis_switch._fullpath)
        self._c_dict = parser.c_dict
        self._dfx_dict = parser.dfx_dict

        self._paths = dict()
        self._default_paths()
        self._switch.mi = self._sw_default

        self.graph = Digraph()
        self.graph.graph_attr['rankdir'] = 'LR'
        self._graph_debug = False
        self._current_pipeline = None
        self._current_flat_pipeline = None

    @property
    def dfx_dict(self) -> dict:
        """Returns the dfx_dict dictionary

        All the DFX regions in the hierarchy. Key is the name of the dfx region
        value is a dictionary with DFX decoupler, PS GPIO that controls the DFX
        decoupler and partial bitstreams associated to the region
        {str: {'decoupler' : str, 'gpio' : {'decouple' : int, 'status' : int},
        ip': dict}}.
        """

        return ReprDict(self._dfx_dict, rootname='dfx_dict')

    @property
    def c_dict(self) -> dict:
        """Returns the c_dict dictionary

        All the IP cores connected to the AXI4-Stream Switch. Key is the name
        of the IP; value is a dictionary mapping the producer and consumer to
        the switch port, whether the IP is in a dfx region and loaded
        {str: {'si' : list, 'mi' : list, 'modtype': str,
        'dfx': bool, 'loaded': bool, 'bitstream: str'}}.
        """

        return ReprDictComposable(self._c_dict,
                                  rootname=self._hier.replace('/', ''))

    @property
    def current_pipeline(self) -> list:
        """List of IP objects in the current dataflow pipeline"""

        return self._current_pipeline

    def _default_paths(self):
        """Get default paths from user file

        Generate default AXI4-Stream Switch default configuration based on the
        user provided dictionary as well as _paths dictionary
        """

        self._default_ip = dict()
        self._sw_default = np.ones(self._max_slots, dtype=np.int64) * -1
        filename = os.path.splitext(self._hwh_name)[0] + '_paths.json'
        if not os.path.isfile(filename):
            return

        with open(filename, "r") as file:
            jsondict = json.load(file)
        sw_default = jsondict[self._hier.replace('/', '')]

        for k, v in sw_default.items():
            self._sw_default[v['mi']['port']] = v['si']['port']

        paths = dict()
        for k, v in sw_default.items():
            for kk, vv in v.items():
                key = k + ('_in' if kk == 'si' else '_out')
                paths[key] = {
                    kk: vv['port'],
                    'Description': vv['Description'],
                    'fullpath': None
                }

        c_dict = self._c_dict.copy()
        for k, v in paths.items():
            for kk, vv in self._c_dict.items():
                si = v.get('si')
                mi = v.get('mi')
                cii = vv.get('si')
                pii = vv.get('mi')
                if (si is not None and cii is not None and si in cii) or \
                   (mi is not None and pii is not None and mi in pii):
                    if kk in c_dict.keys():
                        c_dict.pop(kk)
                    v['fullpath'] = kk
                    c_dict[k] = vv.copy()
                    c_dict[k]['default'] = True
                    c_dict[k]['fullpath'] = kk
                    if kk not in self._default_ip.keys():
                        self._default_ip[kk] = c_dict[k].copy()
                    if 'cpath' not in self._default_ip[kk].keys():
                        self._default_ip[kk]['cpath'] = dict()
                    key, delkey = ('si', 'mi') if mi is None else ('mi', 'si')
                    if c_dict[k].get(delkey):
                        c_dict[k].pop(delkey)
                    self._default_ip[kk]['cpath'][key] = k
                    break

        self._c_dict = c_dict
        self._paths = paths

    def _pr_download(self, partial_region: str, partial_bit: str) -> None:
        """The method to download a partial bitstream onto PL.

        The composable dictionary is updated with the new hardware loaded onto
        the reconfigurable region
        In this method, the corresponding parser will only be
        added once the `download()` method of the hierarchical block is called.
        Note
        ----
        There is no check on whether the partial region specified by users
        is really partial-reconfigurable. So users have to make sure the
        `partial_region` provided is correct.
        Parameters
        ----------
        partial_region : str
            The name of the hierarchical block corresponding to the PR region.
        partial_bit : str
            The name of the partial bitstream.
        """

        self._ol.pr_download(self._hier + partial_region, partial_bit)
        self._unload_region_from_ip_dict(partial_region)
        dfx_dict = \
            self._dfx_dict[partial_region]['rm'][os.path.basename(partial_bit)]
        self._set_loaded(dfx_dict)

    def _unload_region_from_ip_dict(self, partial_region: str) -> None:
        """Unset loaded attribute for all the IP of provided region"""

        for k in self._c_dict.keys():
            if partial_region in k:
                self._c_dict[k]['loaded'] = False

    def _set_loaded(self, dfx_dict: dict) -> None:
        """Set loaded attribute in the c_dict for IP on dfx_dict"""

        for ip in dfx_dict:
            self._c_dict[ip]['loaded'] = True

    def _relative_path(self, fullpath: str, port: str = 'si') -> str:
        """Return relative path of an IP within the hierarchy

        If the IP is in the default paths, return proper name
        """

        fullpath = fullpath.replace(self._hier, '')
        if fullpath not in self._default_ip.keys():
            return fullpath

        for k, v in self._default_ip.items():
            if v['fullpath'] == fullpath:
                return v['cpath'][port]

    def compose(self, cle_list: list) -> None:
        """Configure design to implement required dataflow pipeline

        Parameters
        ----------
        cle_list : list
            list of the composable IP objects
            Examples:
            [a, b, c, d] yields

            .. code-block:: none

                    -> a -> b -> c -> d ->

            [a, b, [[c,d],[e]], f, g] yields

            .. code-block:: none

                                -> c -> d -
                              /            \\
                    -> a -> b               f -> g ->
                              \\            /
                                ---> e ----
        """

        if not isinstance(cle_list, list):
            raise TypeError("The composable pipeline must be a list")

        levels = _nest_level(cle_list)

        if levels > 3:
            raise SystemError("Data flow pipeline with a nest levels bigger "
                              "than 3 is not supported. {}".format(levels))
        elif levels % 2 == 0:
            raise SystemError("Data flow pipeline with an even nest"
                              " levels is not supported. {}".format(levels))

        slots = _count_slots(cle_list)
        if slots > self._max_slots:
            raise SystemError("Number of slots in the list is bigger than {} "
                              "which are the max slots that hardware allows"
                              .format(self._max_slots))

        switch_conf = np.ones(self._max_slots, dtype=np.int64) * -1

        flat_list = list()
        graph = Digraph(
            node_attr={'shape': 'box'},
            edge_attr={'color': 'green'},
            graph_attr={'rankdir': self.graph.graph_attr['rankdir']}
            )
        gdebug = self._graph_debug
        for i, l0 in enumerate(cle_list):
            if isinstance(l0, list):
                key = self._relative_path(cle_list[i+1]._fullpath)
                next_node = self._c_dict[key]
                if len(l0) != len(next_node['mi']):
                    raise SystemError("Node {} has {} input(s) and cannot meet"
                                      "pipeline requirement of {} input(s)"
                                      .format(key, len(next_node['mi']),
                                              len(l0)))
                for ii, l1 in enumerate(l0):
                    if not isinstance(l1, list):
                        raise SystemError("Branches must be represented as "
                                          "list of list")
                    for iii, l2 in enumerate(l1):
                        ip = cle_list[i][ii][iii]
                        if ip == 1:
                            continue
                        flat_list.append(ip)
                        si = self._c_dict[
                            self._relative_path(ip._fullpath)]['si'][0]
                        if iii == len(l1) - 1:
                            consumer = key
                            mi = self._c_dict[consumer]['mi'][ii]
                        else:
                            consumer = self._relative_path(
                                cle_list[i][ii][iii+1]._fullpath)
                            mi = self._c_dict[consumer]['mi'][0]

                        if not np.where(switch_conf == si)[0].size:
                            switch_conf[mi] = si
                            graph.edge(self._relative_path(ip._fullpath),
                                       consumer,
                                       label=_edge_label(si, mi, gdebug))
                        else:
                            raise SystemError("IP: {} is already being used in"
                                              " the provided pipeline. An IP "
                                              "instance can only be used once"
                                              .format(ip._fullpath))
            else:
                ip = cle_list[i]
                flat_list.append(ip)
                if i == len(cle_list) - 1:
                    break
                si = self._c_dict[(path := self._relative_path(ip._fullpath,
                                                               'si'))]['si']
                if not isinstance(cle_list[i+1], list):
                    mi = self._c_dict[(key :=
                                      self._relative_path(
                                        cle_list[i+1]._fullpath, 'mi'))]['mi']

                    if not np.where(switch_conf == si[0])[0].size:
                        switch_conf[mi[0]] = si[0]
                        graph.edge(path, key,
                                   label=_edge_label(si[0], mi[0], gdebug))
                    else:
                        raise SystemError("IP: {} is already being used in the"
                                          " provided pipeline. An IP instance "
                                          "can only be used once"
                                          .format(ip._fullpath))

                elif len(cle_list[i+1]) != len(si):
                    raise SystemError("Node {} has {} output(s) and cannot "
                                      "meet pipeline requirement of {} "
                                      "output(s)".format(l0._fullpath, len(si),
                                                         len(cle_list[i+1])))
                else:
                    for j in range(len(si)):
                        nextip = cle_list[i+1][j][0]
                        if nextip != 1:
                            nextkey = self._relative_path(nextip._fullpath)
                            mi = self._c_dict[nextkey]['mi'][0]
                        else:
                            nextip = cle_list[i+2]
                            nextkey = self._relative_path(nextip._fullpath)
                            mi = self._c_dict[nextkey]['mi'][j]

                        if not np.where(switch_conf == si[j])[0].size:
                            switch_conf[mi] = si[j]
                            graph.edge(self._relative_path(ip._fullpath),
                                       self._relative_path(nextip._fullpath),
                                       label=_edge_label(si[j], mi, gdebug))
                        else:
                            raise SystemError("IP: {} is already being used "
                                              "in the provided pipeline. An IP"
                                              " instance can only be used once"
                                              .format(ip._fullpath))

        if self._soft_reset:
            self._soft_reset[0].write(1)
            self._soft_reset[0].write(0)

        self._configure_switch(switch_conf)

        for idx, ip in enumerate(flat_list):
            port = 'mi' if idx == len(flat_list)-1 else 'si'
            key = self._relative_path(ip._fullpath, port)
            if self._c_dict[key]["dfx"]:
                graph.node(key,
                           _attributes={"color": "blue", "fillcolor": "cyan",
                                        "style": "filled"})
            if not isinstance(ip, UnloadedIP):
                if hasattr(ip, "start"):
                    ip.start()
            else:
                raise AttributeError("IP {} is not loaded, load IP before "
                                     "composing a pipeline"
                                     .format(ip._fullpath))

        self._current_pipeline = cle_list
        self._current_flat_pipeline = flat_list
        self.graph = graph

    def loadIP(self, dfx_list: list) -> None:
        """Download dfx IP onto the corresponding partial regions

        Parameters
        ----------
        dfx_list: list
            List of IP to be downloaded onto the dfx regions. The list can
            contain either a string with the fullname or the IP object

            Examples:
                [cpipe.pr_0.fast_accel, cpipe.pr_1.dilate_accel]
                ['pr_0/fast_accel', 'pr_1/dilate_accel']
        """

        bit_dict = dict()

        for ip in dfx_list:
            if isinstance(ip, str):
                fullpath = ip
            else:
                fullpath = self._relative_path(ip._fullpath)

            bitname = os.path.basename(self._c_dict[fullpath]['bitstream'])
            for pr in self._dfx_dict:
                if pr in bitname:
                    if pr not in bit_dict.keys():
                        bit_dict[pr] = dict()
                        bit_dict[pr]['bitstream'] = bitname
                        bit_dict[pr]['loaded'] = \
                            self._c_dict[fullpath]['loaded']
                    elif bit_dict[pr]['bitstream'] != bitname:
                        raise SystemError("\'{}\' and \'{}\' bitstreams cannot"
                                          " be loaded into the same DFX "
                                          " region \'{}\' at the same time"
                                          .format(bit_dict[pr]['bitstream'],
                                                  bitname, pr))

        path = os.path.dirname(self._bitfile) + '/'
        for pr in bit_dict:
            if not bit_dict[pr]['loaded']:
                decoupler = self._dfx_control[self._dfx_dict[pr]['decouple']]
                if self._dfx_control and decoupler:
                    decoupler.write(1)
                for i in range(5):
                    try:
                        self._pr_download(pr, path + bit_dict[pr]['bitstream'])
                        break
                    except TimeoutError:
                        if i != 4:
                            continue
                        raise TimeoutError("{} partial bitstream could not be "
                                           "downloaded"
                                           .format(bit_dict[pr]['bitstream']))

                if self._dfx_control and decoupler:
                    decoupler.write(0)

    def remove(self, iplist: list = None) -> None:
        """Remove IP object from the current pipeline

        Parameters
        ----------
        iplist: list
            List of IP to be removed from the current pipeline

            Examples:
                [cpipe.pr_0.erode]
                [cpipe.pr_1.filter2d, cpipe.pr_fork.duplicate]
        """

        if self._current_pipeline is None:
            raise SystemError("A pipeline has not been composed yet")

        pipeline = self._current_pipeline

        if iplist is None:
            raise ValueError("remove requires a list of IP object")

        for ip in iplist:
            if ip not in pipeline:
                raise ValueError("IP object {} does not exit in current "
                                 "pipeline {}".format(ip, iplist))

            pipeline.remove(ip)

        self.compose(pipeline)

    def insert(self, iptuple: tuple) -> None:
        """Insert a new IP or list of IP into current pipeline

        Parameters
        ----------
        iptuple: tuple
            Tuple of two items.
            First: list of IP to be inserted
            Second: index

            Examples:
                ([cpipe.pr_0.erode], 3)
                ([cpipe.pr_1.filter2d, cpipe.pr_fork.duplicate], 2)
        """

        if not isinstance(iptuple, tuple):
            raise ValueError("insert expects a tuple as an argument")
        elif len(iptuple) != 2:
            raise ValueError("insert expects a tuple with two elements")
        elif not isinstance(iptuple[1], int):
            raise ValueError("insert expects an integer as index")
        elif iptuple[1] > len(self._current_pipeline):
            raise ValueError("index cannot be bigger than current pipeline"
                             "length")

        if not isinstance(iptuple[0], list):
            newlist = [iptuple[0]]
        else:
            newlist = iptuple[0]

        pipeline = self._current_pipeline[:iptuple[1]] + newlist + \
            self._current_pipeline[iptuple[1]:]

        self.compose(pipeline)

    def replace(self, replaceip: tuple) -> None:
        """Replace an IP object in the current pipeline

        Parameters
        ----------
        replaceip: tuple
            Tuple of two items.
            First: IP object to be replaced
            Second: new IP object

            Examples:
                (cpipe.pr_0.erode, cpipe.pr_1.dilate)
        """

        if not isinstance(replaceip, tuple):
            raise ValueError("replace expects a tuple as an argument")
        elif len(replaceip) != 2:
            raise ValueError("replace expects a tuple with two IP objects")

        pipeline = self._current_pipeline
        idx = _find_index_in_list(pipeline, replaceip[0])

        if isinstance(idx, int):
            pipeline[idx] = replaceip[1]
        elif isinstance(idx, tuple):
            pipeline[idx[0]][idx[1]][idx[2]] = replaceip[1]
        else:
            raise ValueError("IP {} is not in the current pipeline"
                             .format(replaceip[0]._fullpath))

        self.compose(pipeline)

    def tap(self, ip: Union[Type[DefaultIP], int] = None) -> None:
        """Observe the output of an IP object in the current pipeline

        Tap into the output of the IP cores in the current pipeline
        Note that tap is not supported in a branch

        You can tap by passing the IP name or the index of the IP in the list.

        Note that tap does not modify the attribute current_pipeline

        Parameters
        ----------
        ip:
            Either an IP object in the current pipeline to be tapped or
            index of IP object in the current pipeline to be tapped

            Examples:
                tap(cpipe.pr_1.dilate)
                tap(6)
        """

        if self._current_pipeline is None:
            raise SystemError("A pipeline has not been composed yet")

        if isinstance(ip, int):
            if ip >= len(self._current_pipeline):
                raise ValueError("list index ({}) is out of range, supported "
                                 "indexes are integers from 0 to {}"
                                 .format(ip, len(self._current_pipeline)-1))
            else:
                index = ip
        else:
            try:
                index = self._current_pipeline.index(ip)
            except ValueError:
                raise ValueError("{} {} does not exist in the list or IP is in"
                                 " a branch "
                                 .format(ip, ip._fullpath
                                         if hasattr(ip, '_fullpath') else ''))

        ip = self._current_pipeline[index]
        new_list = self._current_pipeline[0:index+1]

        if index < len(self._current_pipeline)-1:
            key = self._relative_path(ip._fullpath)
            if len(self._c_dict[key]['si']) != 1:
                raise SystemError("tap into an IP with multiple outputs is "
                                  "not supported")
            new_list.append(self._current_pipeline[-1])

        pipeline = self._current_pipeline.copy()
        self.compose(new_list)
        self._current_pipeline = pipeline.copy()

    def untap(self) -> None:
        """Restores current pipeline after tap happened"""

        if self._current_pipeline is None:
            raise SystemError("There is nothing to untap")

        self.compose(self._current_pipeline)

    def __getattr__(self, name):
        if self._dfx_dict is None:
            return super().__getattr__(name)
        elif name in self._dfx_dict:
            return DFXRegion(self, name)
        elif name in self._paths:
            try:
                attr = getattr(self._ol, self._paths[name]['fullpath'])
            except AttributeError:
                attr = super().__getattr__(self._paths[name]['fullpath'])
            return attr
        elif (key := self._hier + name) not in self._ol.ip_dict.keys() and \
                name in self._c_dict.keys():
            return StreamingIP(key)
        elif name in self._c_dict:
            try:
                attr = super().__getattr__(name)
            except AttributeError:
                attr = getattr(self._ol, name)
            return attr
        else:
            raise AttributeError("\'{}\' object has no attribute \'{}\'"
                                 .format(type(self).__name__, name))

    def __dir__(self):
        return sorted(set(super().__dir__() +
                          list(self.__dict__.keys()) +
                          list(self._c_dict.keys()) +
                          list(self._default_ip.keys())))

    def _configure_switch(self, new_sw_config: dict) -> None:
        """Verify that default values are set and configure the switch"""

        switch_conf = np.copy(new_sw_config)

        for idx, val in enumerate(switch_conf):
            if val < 0 and self._sw_default[idx] > 0 and \
                    self._sw_default[idx] not in switch_conf:
                switch_conf[idx] = self._sw_default[idx]

        self._switch.mi = switch_conf
