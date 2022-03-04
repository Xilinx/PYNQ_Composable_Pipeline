# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from xml.etree import ElementTree
from typing import Union
import re
import os
import glob
import hashlib
import pickle as pkl
import argparse

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"

_m_type = ['MASTER', 'INITIATOR']
_s_type = ['SLAVE', 'TARGET']
_mem_items = ['axis_register_slice', 'axis_data_fifo', 'fifo_generator',
              'axis_dwidth_converter', 'axis_subset_converter',
              'axis_clock_converter']

_dfx_item = ['dfx_decoupler']
_axis_vlnv = 'xilinx.com:interface:axis:1.0'


def _normalize_type(i_type: str) -> str:
    """Normalize AXI4-Stream names"""

    if i_type in _m_type:
        i_type = 'INITIATOR'
    elif i_type in _s_type:
        i_type = 'TARGET'
    else:
        raise ValueError("Unknown BUSINTERFACE type {}".format(i_type))

    return i_type


def _find_connected_node(slot: dict, tree: ElementTree) -> tuple:
    """Find the the INSTANCE connected to/from current node"""

    s = slot.copy()
    busname = s['busname']
    search_term = "MODULES/*BUSINTERFACES/*/[@BUSNAME=\'" + \
                  busname + "\']....."
    node = tree.findall(search_term)
    for n in node:
        if n.get('FULLNAME') != s['fullname']:
            for m in n.iter("BUSINTERFACE"):
                if m.get('BUSNAME') == busname:
                    n_type = n.get('MODTYPE')
                    fullname = n.get('FULLNAME')
                    name = m.get('NAME')
                    s['fullname'] = fullname
                    s['modtype'] = n_type
                    s['name'] = name
                    if 'xilinx.com:module_ref' in n.get('VLNV'):
                        s['interface'] = fullname + '/' + name

                    return s, n_type in (_mem_items + _dfx_item)
    # Return same slot for elements that are not connected to another module
    return s, False


def _dfx_get_oposite_port(port: str) -> str:
    """Get corresponding opposite port for a dfx decoupler"""

    return 's' + port[2::] if 'rp' in port else 'rp' + port[1::]


def _get_dfxdecoupler_decouple_gpio_pin(signame: str,
                        tree: ElementTree,
                        module: ElementTree.Element=None) -> Union[int, None]:
    """Find the gpio pins that controls the DFX decoupler pin"""

    search_term = "MODULES/*PORTS/*/[@SIGNAME=\'" + signame + "\']....."
    node = tree.findall(search_term)
    for m in node:
        if 'xilinx.com:ip:xlslice' in (vlnv := m.get('VLNV')):
            din_from = int(m.find("./PARAMETERS/*[@NAME='DIN_FROM']")
                           .get('VALUE'))
            din_to = int(m.find("./PARAMETERS/*[@NAME='DIN_FROM']")
                         .get('VALUE'))
            if din_from != din_to:
                raise ValueError("{} cannot be more than 1-bit wide"
                                 .format(signame))
            return din_to
        elif 'xilinx.com:ip:xpm_cdc_gen' in vlnv and m != module:
            return _get_dfxdecoupler_decouple_gpio_pin(
                m.find("./PORTS/*[@NAME='src_in']").get('SIGNAME'), tree, m)
    return None


def _get_dfxdecoupler_status_gpio_pin(signame: str,
                        tree: ElementTree,
                        module: ElementTree.Element=None) -> Union[int, None]:
    """Find the gpio pins that gets the DFX status pin"""

    search_term = "MODULES/*PORTS/*/[@SIGNAME=\'" + signame + "\']....."
    node = tree.findall(search_term)
    for m in node:
        if 'xilinx.com:ip:xlconcat' in (vlnv := m.get('VLNV')):
            return int(re.findall(r'\d+',
                m.find(f"./PORTS/*[@SIGNAME='{signame}']").get('NAME'))[0])
        elif 'xilinx.com:ip:xpm_cdc_gen' in vlnv and m != module:
            return _get_dfxdecoupler_status_gpio_pin(
                m.find("./PORTS/*[@NAME='dest_out']").get('SIGNAME'), tree, m)
    return None


def _dfx_ip_discovery(partial_region: str, partial_hwh: str) -> dict:
    """Hardware discovery on partial bitstreams

    Parse partial HWH file and return dictionary with IP and interface
    connections
    """

    tree = ElementTree.parse(partial_hwh)
    ext_if = dict()

    for mod in tree.findall('EXTERNALINTERFACES/BUSINTERFACE'):
        key = '/' + mod.get('NAME')
        try:
            protocol = mod.find(".//*[@NAME='PROTOCOL']").get('VALUE')
        except AttributeError:
            protocol = 'Unknown'

        if protocol == 'Unknown':
            ext_if[key] = dict()
            ext_if[key]['busname'] = mod.get('BUSNAME')
            ext_if[key]['name'] = mod.get('NAME')
            ext_if[key]['type'] = _normalize_type(mod.get('TYPE'))

    _deep_exp = []
    for k in ext_if:
        search_text = "MODULES/*BUSINTERFACES/*/[@BUSNAME=\'" + \
                     ext_if[k]['busname'] + "\']....."
        mod = tree.findall(search_text)

        for i in mod:
            fullname = i.get('FULLNAME')
            ext_if[k]['fullname'] = fullname
            ext_if[k]['modtype'] = i.get('MODTYPE')
            if ext_if[k]['modtype'] in _mem_items:
                _deep_exp.append(k)

    while _deep_exp:
        k = _deep_exp[0]
        fullname = ext_if[k]['fullname']
        search_text = "MODULES/*/[@FULLNAME=\'" + fullname + "\']"
        mod = tree.find(search_text)
        for i in mod.iter('BUSINTERFACE'):
            if i.get('BUSNAME') != ext_if[k]['busname']:
                ext_if[k]['busname'] = i.get('BUSNAME')
                ext_if[k], ismem = _find_connected_node(ext_if[k], tree)
                if not ismem:
                    del _deep_exp[0]
                break

    dfx_dict = dict()
    for j in ext_if:
        if 'fullname' in ext_if[j].keys():
            key = partial_region + ext_if[j]['fullname']
            if key not in dfx_dict.keys():
                dfx_dict[key] = dict()
                dfx_dict[key]['interface'] = list()

            dfx_dict[key]['interface'].append('/' + partial_region + j)
            dfx_dict[key]['modtype'] = ext_if[j]['modtype']
            dfx_dict[key]['bitstream'] = os.path.splitext(partial_hwh)[0] \
                + '.bit'

    return dfx_dict


class HWHComposable:
    """Parse the HWH file(s) to create the composable connectivity map

    Attributes
    ----------
    c_dict : dict
        All the IP cores connected to the AXI4-Stream Switch. Key is the name
        of the IP; value is a dictionary mapping the producer and consumer to
        the switch port, whether the IP is in a dfx region and loaded

        {str: {'si' : list, 'mi' : list, 'modtype': str,
        'dfx': bool, 'loaded': bool, 'bitstream: str'}}

    dfx_dict : dict
        All the DFX regions in the hierarchy. Key is the name of the dfx region
        value is a dictionary with DFX decoupler, PS GPIO that controls the DFX
        decoupler and partial bitstreams associated to the region

        {str: {'decoupler' : str, 'gpio' : {'decouple' : int, 'status' : int},
        'ip': dict}}

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
    def __init__(self, hwh_file: str, switch_name: str, cache=True):
        """Return a new HWHComposable object.

        Performs a hardware discovery where the different IP cores connected
        to the switch are added to the c_dict and the DFX regions are added
        to the dfx_dict

        Parameters
        ----------
        hwh_file : str
            global hwh file
        switch_name : str
            AXI4-Stream Switch name
        cache : bool
            Use cache file
        """

        self._hwh_name = hwh_file
        if switch_name.startswith('/'):
            self._switch_name = switch_name
        else:
            self._switch_name = '/' + switch_name
        self._hier = switch_name.rsplit('/', 1)[0]
        self._dir_name = os.path.dirname(hwh_file)

        with open(self._hwh_name, 'rb') as file:
            hwhdigest = hashlib.md5(file.read()).hexdigest()
        cached_digest = None

        pklfile = os.path.splitext(self._hwh_name)[0] + '_' + \
            self._hier + '.pkl'
        if os.path.isfile(pklfile) and cache:
            with open(pklfile, "rb") as file:
                cached_digest, self.c_dict, self.dfx_dict = pkl.load(file)
        if not os.path.isfile(pklfile) or cached_digest != hwhdigest:
            self._hardware_discovery()
            self._dfx_regions_discovery()
            self._partial_bitstreams_discovery()
            self._insert_dfx_ip()
            with open(pklfile, "wb") as file:
                pkl.dump([hwhdigest, self.c_dict, self.dfx_dict], file)

    def _hardware_discovery(self) -> None:
        """Discover how functions are connected to the switch"""

        tree = ElementTree.parse(self._hwh_name)
        switch_conn = {}
        self._deep_exp = []

        search_term = "MODULES/*/[@FULLNAME=\'" + self._switch_name + "\']"
        node = tree.find(search_term)

        if not node:
            raise AttributeError("AXI4-Switch {} does not exist in the hwh "
                                 "file".format(self._switch_name.lstrip('/')))

        for m in node.iter("BUSINTERFACE"):
            i_type = _normalize_type(m.get('TYPE'))
            if m.get('VLNV') == _axis_vlnv:
                switch_conn[m.get('NAME')] = {
                    'busname': m.get('BUSNAME'),
                    'type': i_type,
                    'fullname': node.get('FULLNAME'),
                    'name': m.get('NAME'),
                    'dfx':  False
                }

        for s in switch_conn:
            switch_conn[s], ismem = _find_connected_node(switch_conn[s], tree)
            if ismem:
                self._deep_exp.append(s)

        deep_exp = self._deep_exp.copy()

        while deep_exp:
            port = deep_exp[0]
            port_type = switch_conn[port]['type']
            fullname = switch_conn[port]['fullname']
            search_term = "MODULES/*/[@FULLNAME=\'" + fullname + "\']"
            node = tree.find(search_term)
            mod_type = node.get('MODTYPE')
            oposite_port = _dfx_get_oposite_port(switch_conn[port]['name'])
            for bus in node.iter("BUSINTERFACE"):
                b_type = _normalize_type(bus.get('TYPE'))
                vnvl = bus.get('VLNV')
                busname = bus.get('BUSNAME')
                name = bus.get('NAME')
                if mod_type in _mem_items and port_type == b_type and \
                        busname != switch_conn[port]['busname']:
                    switch_conn[port]['busname'] = busname
                    conn, ismem = _find_connected_node(switch_conn[port], tree)

                    if 'axis_switch' not in conn['modtype']:
                        switch_conn[port] = conn
                    if not ismem:
                        del deep_exp[0]
                    break
                elif mod_type in _dfx_item and port_type == b_type and \
                        vnvl == _axis_vlnv and oposite_port == name:
                    switch_conn[port]['busname'] = busname
                    switch_conn[port]['type'] = b_type
                    switch_conn[port]['dfx'] = True
                    switch_conn[port]['decoupler'] = node.get('FULLNAME')
                    switch_conn[port], ismem = \
                        _find_connected_node(switch_conn[port], tree)
                    if not ismem:
                        del deep_exp[0]
                    break

        self._switch_conn = switch_conn
        static_dict = dict()
        default_dfx_dict = dict()

        for d in switch_conn:
            if switch_conn[d]['busname'] == '__NOC__':
                continue
            p = int(re.findall(r'\d+', d)[0])
            port_type = switch_conn[d]['type']
            k = 'mi' if port_type == 'INITIATOR' else 'si'
            if not switch_conn[d]['dfx']:
                key = switch_conn[d]['fullname'].lstrip('/')
                dictionary = static_dict
            else:
                key = switch_conn[d].get('interface')
                if not key:
                    key = switch_conn[d].get('fullname')
                dictionary = default_dfx_dict
            key = key.replace(self._hier, '').lstrip('/')
            if key not in static_dict.keys():
                dictionary[key] = dict()

            if k in dictionary[key].keys():
                port = list(dictionary[key][k])
                port.append(p)
            else:
                port = [p]

            dictionary[key][k] = port
            dictionary[key]['dfx'] = switch_conn[d]['dfx']
            dictionary[key]['loaded'] = not switch_conn[d]['dfx']
            dictionary[key]['modtype'] = switch_conn[d].get('modtype')
            if switch_conn[d]['dfx']:
                dictionary[key]['decoupler'] = switch_conn[d]['decoupler']

        self.c_dict = static_dict
        self._static_dict = static_dict
        self._default_dfx_dict = default_dfx_dict

    def _dfx_regions_discovery(self) -> None:
        """Discover DFX regions in the overlay and create dfx_dict dict

        The .dfx_dict dictionary contains relevant information about the
        DFX regions
            - decoupler name
            - decouple gpio pin that control the decoupler
            - status gpio pin, decupler status
            - reconfigurable module (rm), list of partial bitstreams and their
              available IP
        If the design has no DFX region the dictionary will be empty
        """

        dfx_dict = dict()
        for k, v in self._switch_conn.items():
            if v['dfx']:
                key = v['fullname'].replace(self._hier, '').lstrip('/')
                if key not in dfx_dict.keys():
                    dfx_dict[key] = dict()
                dfx_dict[key]['decoupler'] = v['decoupler']

        tree = ElementTree.parse(self._hwh_name)

        for d in dfx_dict:
            decoupler = dfx_dict[d]['decoupler']
            search_term = "MODULES/*/[@FULLNAME=\'" + decoupler + "\']"
            node = tree.find(search_term)
            dfx_dict[d]['decouple'] = _get_dfxdecoupler_decouple_gpio_pin(
                node.find("./PORTS/*[@NAME='decouple']").get('SIGNAME'), tree)
            dfx_dict[d]['status'] = _get_dfxdecoupler_status_gpio_pin(
                node.find("./PORTS/*[@NAME='decouple_status']")
                .get('SIGNAME'), tree)

        self.dfx_dict = dfx_dict

    def _partial_bitstreams_discovery(self) -> None:
        """Search for partial bitstreams and add them to the dictionary"""

        filelist = glob.glob(self._dir_name + '/*.bit')
        working_list = filelist.copy()

        for key in self.dfx_dict:
            bitkey = key.replace('/', '_')
            for f in working_list:
                file = os.path.split(f)[1]
                if bitkey in file:
                    if 'rm' not in self.dfx_dict[key].keys():
                        self.dfx_dict[key]['rm'] = dict()
                    self.dfx_dict[key]['rm'][file] = dict()
                    filelist.remove(f)
            working_list = filelist.copy()

    def _insert_dfx_ip(self) -> None:
        """Insert IP from dfx regions into the c_dict

        Iterate over partial bitstreams and add all IP within dfx regions
        into the self.c_dict
        """

        for r in self.dfx_dict:
            for b in self.dfx_dict[r].get('rm', list()):
                hwh_name = self._dir_name + '/' + \
                    os.path.splitext(b)[0] + '.hwh'
                if os.path.exists(hwh_name):
                    dfx_dict = _dfx_ip_discovery(r, hwh_name)
                    self.dfx_dict[r]['rm'][b] = dfx_dict
                    self._update_ip_dict_with_dfx(r, dfx_dict)

    def _update_ip_dict_with_dfx(self, partial_region: str,
                                 dfx_dict: dict) -> None:
        """Insert IP cores from partial bitstream to c_dict"""

        updated_dict = self.c_dict.copy()

        for k in dfx_dict:
            updated_dict[k] = dict()
            for i in dfx_dict[k]['interface']:
                key = i.lstrip('/')
                if 'mi' in self._default_dfx_dict[key].keys():
                    if 'mi' not in updated_dict[k].keys():
                        port = list()

                    port.append(self._default_dfx_dict[key]['mi'][0])
                    updated_dict[k]['mi'] = port
                else:
                    if 'si' not in updated_dict[k].keys():
                        port = list()
                    port.append(self._default_dfx_dict[key]['si'][0])
                    updated_dict[k]['si'] = port

            updated_dict[k]['modtype'] = dfx_dict[k]['modtype']
            updated_dict[k]['bitstream'] = dfx_dict[k]['bitstream']
            updated_dict[k]['dfx'] = True
            updated_dict[k]['loaded'] = False

        self.c_dict = updated_dict


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate composable cached file"
    )
    parser.add_argument(
        "--hwh", help="global hwh file", required=True
    )
    args = parser.parse_args()

    print(args.hwh)

    tree = ElementTree.parse(args.hwh)
    tree_root = tree.getroot()

    for mod in tree_root.iter("MODULE"):
        mod_type = mod.get('MODTYPE')
        if mod_type == 'axis_switch':
            switch_name = mod.get('FULLNAME').lstrip('/')
            HWHComposable(args.hwh, switch_name, False)
            print("Cache file for {} generated".format(switch_name))
