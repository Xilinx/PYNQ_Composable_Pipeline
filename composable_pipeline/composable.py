# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq import DefaultIP, DefaultHierarchy
from pynq.lib import AxiGPIO
from pynq.utils import ReprDict
from graphviz import Digraph
from typing import Type, Union
import numpy as np
import os
import json
from .switch import StreamSwitch
from .parser import HWHComposable

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


def _count_slots(pl: str) -> int:
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


class Composable(DefaultHierarchy):
    """This class keeps track of a composable overlay

    The Composable class holds the state of the logic available for run-time
    composition through and AXI4-Stream switch

    Our definition of composable overlay is: "post-bitstream configurable
    dataflow pipeline". Hence, this class must expose configurability through
    content discovery, dataflow configuration and runtime protection.

    This class stores two dictionaries: c_dict and dfx_dict

    Each entry of the Composable dictionary (c_dict) is a mapping:
    'name' -> {ci, pi, modtype, dfx, loaded, bitstream}, where
    name (str) is the key of the entry.
    ci (list) list of physical port in the switch the IP is connected to
    pi (list) list of physical port in the switch the IP is connected from
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
    c_dict : dict
        All the IP cores connected to the AXI4-Stream Switch. Key is the name
        of the IP; value is a dictionary mapping the producer and consumer to
        the switch port, whether the IP is in a dfx region and loaded
        {str: {'ci' : list, 'pi' : list, 'modtype': str,
               'dfx': bool, 'loaded': bool, 'bitstream: str'}}.
    dfx_dict : dict
        All the DFX regions in the hierarchy. Key is the name of the dfx region
        value is a dictionary with DFX decoupler, PS GPIO that controls the DFX
        decoupler and partial bitstreams associated to the region
        {str: {'decoupler' : str, 'gpio' : {'decouple' : int, 'status' : int},
               'ip': dict}}.
    graph : Digraph
        Graphviz Digraph representation of the current dataflow pipeline
    current_pipeline : list
        list of the IP objects in the current dataflow pipeline
    """

    @staticmethod
    def checkhierarchy(description):
        return (
            'axis_switch' in description['ip'] and
            'pipeline_control' in description['ip'])

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

        <bitstream_name>_<pr_region>_<pr_module_name>.{bit|hwh}

        For instance if the main bitstream is `base.bit` and there are two DFX
        regions with the names `pr_0` and `pr_1` each of them with the same
        two reconfigurable module, `function_1` and `function_2` the names
        should be as follow

            base_pr_0_function_1.bit
            base_pr_0_function_1.hwh
            base_pr_0_function_2.bit
            base_pr_0_function_2.hwh
            base_pr_1_function_1.bit
            base_pr_1_function_1.hwh
            base_pr_1_function_2.bit
            base_pr_1_function_2.hwh
        """

        super().__init__(description)
        self._hier = description['fullpath'] + '/'
        self._dfx_dict = None
        self._bitfile = description['device'].bitfile_name
        self._hwh_name = os.path.splitext(self._bitfile)[0] + '.hwh'
        self._pipecrtl = self.pipeline_control
        self._switch = self.axis_switch
        self._max_slots = self._switch.max_slots
        self._ol = description['overlay']

        parser = HWHComposable(self._hwh_name, self.axis_switch._fullpath)
        self._c_dict = parser.c_dict
        self._dfx_dict = parser.dfx_dict

        self._paths = dict()
        self._default_paths()
        self._switch.pi = self._sw_default

        self._soft_reset = self._pipecrtl.channel1
        self._dfx_control = self._pipecrtl.channel2
        self.graph = Digraph()
        self.graph.graph_attr['size'] = '14'
        self.graph.graph_attr['rankdir'] = 'LR'
        self._graph_debug = False
        self._current_pipeline = None
        self._current_flat_pipeline = None

    @property
    def dfx_dict(self):
        """Returns the dfx_dict dictionary"""

        return ReprDict(self._dfx_dict, rootname='dfx_dict')

    @property
    def c_dict(self):
        """Returns the c_dict dictionary"""

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
            self._sw_default[v['pi']['port']] = v['ci']['port']

        paths = dict()
        for k, v in sw_default.items():
            for kk, vv in v.items():
                key = k + ('_in' if kk == 'ci' else '_out')
                paths[key] = {
                    kk: vv['port'],
                    'Description': vv['Description'],
                    'fullpath': None
                }

        c_dict = self._c_dict.copy()
        for k, v in paths.items():
            for kk, vv in self._c_dict.items():
                ci = v.get('ci')
                pi = v.get('pi')
                cii = vv.get('ci')
                pii = vv.get('pi')
                if (ci is not None and cii is not None and ci in cii) or \
                   (pi is not None and pii is not None and pi in pii):
                    c_dict.pop(kk)
                    v['fullpath'] = kk
                    c_dict[k] = vv
                    c_dict[k]['default'] = True
                    c_dict[k]['fullpath'] = kk
                    self._default_ip[kk] = c_dict[k]
                    self._default_ip[kk]['cpath'] = k
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
        """Unset loaded attribute for all of the IP of provided region"""

        for k in self._c_dict.keys():
            if partial_region in k:
                self._c_dict[k]['loaded'] = False

    def _set_loaded(self, dfx_dict: dict) -> None:
        """Set loaded attribute in the c_dict for IP on dfx_dict"""

        for ip in dfx_dict:
            self._c_dict[ip]['loaded'] = True

    def _relative_path(self, fullpath: str) -> str:
        """For IP within the hierarchy return relative path

        If the IP is in the default paths, return proper name
        """

        fullpath = fullpath.replace(self._hier, '')
        if fullpath not in self._default_ip.keys():
            return fullpath

        for k, v in self._default_ip.items():
            if v['fullpath'] == fullpath:
                return v['cpath']

    def compose(self, cle_list: list) -> None:
        """Configure design to implement required dataflow pipeline

        Parameters
        ----------
        cle_list : list
            list of the composable IP objects
            Examples:
            [a, b, c, d] yields
                -> a -> b -> c -> d ->

            [a, b, [[c,d],[e]], f, g] yields

                            -> c -> d -
                          /            \\
                -> a -> b               f -> g ->
                          \\            /
                            -> e ------
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
            edge_attr={'color': 'green'}
            )

        graph.graph_attr['size'] = self.graph.graph_attr['size']
        graph.graph_attr['rankdir'] = self.graph.graph_attr['rankdir']

        labelcolor = '<<font color=\"' + ('green' if self._graph_debug else
                                          'white') + '\">'

        for i, l0 in enumerate(cle_list):
            if isinstance(l0, list):
                key = self._relative_path(cle_list[i+1]._fullpath)
                next_node = self._c_dict[key]
                if len(l0) != len(next_node['pi']):
                    raise SystemError("Node {} has {} input(s) and cannot meet"
                                      "pipeline requirement of {} input(s)"
                                      .format(key, len(next_node['pi']),
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
                        ci = self._c_dict[
                            self._relative_path(ip._fullpath)]['ci'][0]
                        if iii == len(l1) - 1:
                            consumer = key
                            pi = self._c_dict[consumer]['pi'][ii]
                        else:
                            consumer = self._relative_path(
                                cle_list[i][ii][iii+1]._fullpath)
                            pi = self._c_dict[consumer]['pi'][0]

                        if not np.where(switch_conf == ci)[0].size:
                            switch_conf[pi] = ci
                            label = labelcolor + 'ci=' + str(ci) + ' pi=' + \
                                str(pi) + '</font>>'
                            graph.edge(self._relative_path(ip._fullpath),
                                       consumer, label=label)
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
                ci = self._c_dict[self._relative_path(ip._fullpath)]['ci']
                if not isinstance(cle_list[i+1], list):
                    key = self._relative_path(cle_list[i+1]._fullpath)
                    pi = self._c_dict[key]['pi']

                    if not np.where(switch_conf == ci[0])[0].size:
                        switch_conf[pi[0]] = ci[0]
                        label = labelcolor + 'ci=' + str(ci[0]) + ' pi=' + \
                            str(pi[0]) + '</font>>'
                        graph.edge(self._relative_path(ip._fullpath), key,
                                   label=label)
                    else:
                        raise SystemError("IP: {} is already being used in the"
                                          " provided pipeline. An IP instance "
                                          "can only be used once"
                                          .format(ip._fullpath))

                elif len(cle_list[i+1]) != len(ci):
                    raise SystemError("Node {} has {} output(s) and cannot "
                                      "meet pipeline requirement of {} "
                                      "output(s)".format(l0._fullpath, len(ci),
                                      len(cle_list[i+1])))
                else:
                    for j in range(len(ci)):
                        nextip = cle_list[i+1][j][0]
                        if nextip != 1:
                            nextkey = self._relative_path(nextip._fullpath)
                            pi = self._c_dict[nextkey]['pi'][0]
                        else:
                            nextip = cle_list[i+2]
                            nextkey = self._relative_path(nextip._fullpath)
                            pi = self._c_dict[nextkey]['pi'][j]

                        if not np.where(switch_conf == ci[j])[0].size:
                            switch_conf[pi] = ci[j]
                            label = labelcolor + 'ci=' + str(ci[j]) + ' pi=' +\
                                str(pi) + '</font>>'
                            graph.edge(self._relative_path(ip._fullpath),
                                       self._relative_path(nextip._fullpath),
                                       label=label)
                        else:
                            raise SystemError("IP: {} is already being used "
                                              "in the provided pipeline. An IP"
                                              " instance can only be used once"
                                              .format(ip._fullpath))

        if self._soft_reset is not None:
            self._soft_reset[0].write(1)
            self._soft_reset[0].write(0)

        self._configure_switch(switch_conf)

        for ip in flat_list:
            if "pynq.lib.video.pipeline" not in str(type(ip)):
                if not isinstance(ip, UnloadedIP):
                    if hasattr(ip, 'start'):
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
                        raise SystemError("Two partial bitstreams cannot be "
                                          "loaded into the same DFX region. "
                                          "Pipeline requires {} and {} in dfx"
                                          " region {}".format(
                                    bit_dict[pr]['bitstream'], bitname, pr))

        path = os.path.dirname(self._bitfile) + '/'
        for pr in bit_dict:
            if not bit_dict[pr]['loaded']:
                self._dfx_control[self._dfx_dict[pr]['decouple']].write(1)
                for i in range(5):
                    try:
                        self._pr_download(pr, path + bit_dict[pr]['bitstream'])
                        break
                    except TimeoutError:
                        if i == 4:
                            raise TimeoutError("{} partial bitstream could not"
                                               " be downloaded".format(
                                               bit_dict[pr]['bitstream']))
                        continue

                self._dfx_control[self._dfx_dict[pr]['decouple']].write(0)

    def remove(self, iplist: list=None) -> None:
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

    def tap(self, ip: Union[Type[DefaultIP], int]=None) -> None:
        """Observe the output of an IP object in the current pipeline

        Tap into the output of any of the IP cores in the current pipeline
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
                                 " a branch ".format(ip, ip._fullpath
                                 if hasattr(ip, '_fullpath') else ''))

        ip = self._current_pipeline[index]
        new_list = self._current_pipeline[0:index+1]

        if index < len(self._current_pipeline)-1:
            key = self._relative_path(ip._fullpath)
            if len(self._c_dict[key]['ci']) != 1:
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
            return PRRegion(self, name)
        elif name in self._paths:
            return getattr(self._ol, self._paths[name]['fullpath'])
        else:
            try:
                attr = super().__getattr__(name)
            except AttributeError:
                attr = getattr(self._ol, name)
            return attr

    def __dir__(self):
        return sorted(set(super().__dir__() +
                          list(self.__dict__.keys()) +
                          list(self._c_dict.keys()) +
                          list(self._default_ip.keys())))

    def _configure_switch(self, new_sw_config: dict) -> None:
        """Verify that default values are set and configure the switch"""

        switch_conf = np.copy(new_sw_config)

        for idx, val in enumerate(switch_conf):
            if val < 0 and self._sw_default[idx] > 0:
                switch_conf[idx] = self._sw_default[idx]

        self._switch.pi = switch_conf


class PRRegion:
    """Class that wraps attributes for IP objects on dfx regions"""

    def __init__(self, cpipe: Composable, name: str):
        self._ol = cpipe._ol
        self._parent = cpipe._hier
        self._c_dict = cpipe._c_dict
        self.key = name

    def __getattr__(self, name: str):
        key = self.key + '/' + name
        if key in self._c_dict.keys():
            if not self._c_dict[key]['loaded']:
                return UnloadedIP(key)
            elif self._c_dict[key]['modtype'] in _mem_items:
                return BufferIP(key)
            else:
                return getattr(self._ol, self._parent + key)
        else:
            raise ValueError("IP \'{}\' does not exist in partial region "
                             "\'{}\'".format(name, self.key))


class UnloadedIP:
    """Handles IP objects that are not yet loaded into the hardware

    This can be consider a virtual IP object
    """

    def __init__(self, path: str):
        self._fullpath = path


class BufferIP:
    """Handles IP objects that are of buffering type

    Expose fullpath attribute for buffering type IP such as a) FIFOs
    b) Slice registers.
    """

    def __init__(self, path: str):
        self._fullpath = path


def _default_repr_composable(obj):
    return repr(obj)


def _add_status(node):
    if node['loaded']:
        return ' [loaded][default]' if node.get('default') else ' [loaded]'
    else:
        return ' [unloaded]'


class ReprDictComposable(dict):
    """Subclass of the built-in dict to display using the Jupyterlab JSON repr.

    The class is recursive in that any entries that are also dictionaries
    will be converted to ReprDict objects when returned.
    """

    def __init__(self, *args, rootname="root", expanded=False, **kwargs):
        """Dictionary constructor

        Parameters
        ----------
        rootname : str
            The value to display at the root of the tree
        expanded : bool
            Whether the view of the tree should start expanded
        """

        self._rootname = rootname
        self._expanded = expanded
        super().__init__(*args, **kwargs)

    def _filter_by_status(self, key, value: bool) -> dict:
        """Returns a new dictionary that matches boolean value of 'loaded'"""

        newdict = dict()
        for k, v in self.items():
            if value == v.get(key):
                newdict[k] = v

        return newdict

    @property
    def loaded(self):
        """Displays only loaded IP"""

        newdict = self._filter_by_status('loaded', True)
        return ReprDictComposable(newdict, expanded=self._expanded,
                                  rootname=self._rootname)

    @property
    def unloaded(self):
        """Displays only unloaded IP"""

        newdict = self._filter_by_status('loaded', False)
        return ReprDictComposable(newdict, expanded=self._expanded,
                                  rootname=self._rootname)

    @property
    def default(self):
        """Displays only default IP"""

        newdict = self._filter_by_status('default', True)
        return ReprDictComposable(newdict, expanded=self._expanded,
                                  rootname=self._rootname)

    def _repr_json_(self):
        if 'dfx' not in self:
            show_dict = dict()
            for i in self:
                new_key = i + _add_status(self[i])
                show_dict[new_key] = self[i]
        else:
            show_dict = self.copy()
        return json.loads(json.dumps(show_dict,
                          default=_default_repr_composable)), \
                          {'expanded': self._expanded, 'root': self._rootname}

    def __getitem__(self, key):
        obj = super().__getitem__(key)
        if type(obj) is dict:
            key = key + _add_status(obj)
            return ReprDictComposable(obj, expanded=self._expanded,
                                      rootname=key)
        else:
            return obj
