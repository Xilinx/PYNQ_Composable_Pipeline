# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import json
import hashlib
import os
import pickle as pkl
from .mock_device import MockDevice, MockOverlay, MockIPDevice, MockRegisterIP
from pynq_composable import Composable, switch, virtual
import pytest
import pynq


with open('tests/files/composable_test_composable.json') as f:
    c_dict, dfx_dict = json.load(f)


with open('tests/files/composable_test.hwh', 'rb') as file:
    hwhdigest = hashlib.md5(file.read()).hexdigest()


with open('tests/files/composable_test_composable.pkl', 'wb') as file:
    pkl.dump([hwhdigest, c_dict, dfx_dict], file)


@pytest.fixture
def ipdevice():
    ip = MockRegisterIP(desc["phys_addr"], desc["addr_range"])
    device = MockIPDevice(ip, "ipdevice")
    pynq.Device.active_device = device
    yield device
    pynq.Device.active_device = None


with open('tests/files/composable_test.hwh') as f:
    hier_desc = json.load(f)
    hier_desc['device'] = MockDevice(f.name)


class MockOverlayComposable(MockOverlay):
    def __init__(self, desc):
        self.sw = switch.StreamSwitch(desc)
        self.sw._fullpath = desc['fullpath']
        self.hierarchies = {'composable': {'ip': None}}
        self.ip_dict = dict()
        self.f9 = pynq.DefaultIP({
                                  'phys_addr': 12288,
                                  'addr_range': 1024,
                                  'fullpath': 'composable/pr/f9',
                                  'registers': {}
                                 })
        self.f8 = virtual.DFXRegion(self, 'composable/pr/f8')

    def __getattr__(self, name):
        # TODO check why composable is included two times
        if 'composable/axis_switch' in name:
            return self.sw
        elif 'f9' in name:
            return self.f9
        elif 'f8' in name:
            return self.f8
        return super()


desc = {"parameters":
        {"C_BASEADDR": "0x0", "C_HIGHADDR": "0xFFFF", "NUM_MI": 15},
        "phys_addr": 0x0, "addr_range": 0xFFFF,
        "fullpath": "composable/axis_switch"}


@pytest.fixture
def hierarchy(ipdevice):
    hier_desc['overlay'] = MockOverlayComposable(desc)
    cpipe = Composable(hier_desc)
    yield cpipe, ipdevice


def test_composable_class(hierarchy):
    cpipe, _ = hierarchy
    cpipe.compose([cpipe.f1, cpipe.f2])
    assert True


pipes_join_exc = [
    "[cpipe.f1, cpipe.fork, [[cpipe.f3], [1]], cpipe.f2]",
    "[cpipe.f1, cpipe.fork, [[1], [cpipe.f3]], cpipe.f2]",
    "[cpipe.f1, cpipe.fork, [[1], [1]], cpipe.f2]"
]

pipes_fork_exc = [
    "[cpipe.f1, [[cpipe.f3], [1]], cpipe.join , cpipe.f2]",
    "[cpipe.f1, [[1], [cpipe.f3]], cpipe.join, cpipe.f2]",
    "[cpipe.f1, [[1], [1]], cpipe.join, cpipe.f2]",
    "[cpipe.f1, [[cpipe.f3, [[cpipe.f4], [1]]], [1]], cpipe.f2]"
]

broken_pipelines = [
    "[cpipe.f1, cpipe.f3, cpipe.join, cpipe.f2]",
    "[cpipe.f1, cpipe.fork, cpipe.f3, cpipe.f2]"
]


@pytest.mark.parametrize('pipeline', pipes_join_exc)
def test_composable_exception_join(hierarchy, pipeline):
    cpipe, _ = hierarchy
    with pytest.raises(SystemError) as excinfo:
        cpipe.compose(eval(pipeline))
    assert "cannot meet pipeline requirement of" in str(excinfo.value)


@pytest.mark.parametrize('pipeline', pipes_fork_exc)
def test_composable_exception_fork(hierarchy, pipeline):
    cpipe, _ = hierarchy
    with pytest.raises(SystemError) as excinfo:
        cpipe.compose(eval(pipeline))
    assert "cannot meet pipeline requirement of" in str(excinfo.value)


@pytest.mark.parametrize('pipeline', broken_pipelines)
def test_composable_exception_connection(hierarchy, pipeline):
    cpipe, _ = hierarchy
    with pytest.raises(SystemError) as excinfo:
        cpipe.compose(eval(pipeline))
    assert "pipeline was not connected correctly." in str(excinfo.value)


pipelines = [
    ("[cpipe.f0, cpipe.f1, cpipe.f2, cpipe.f3, cpipe.f4, cpipe.f5, cpipe.f6,\
       cpipe.f7]",
     {'0': 2, '64': 1 << 31, '68': 0, '72': 1, '76': 2, '80': 3, '84': 4,
      '88': 5, '92': 6, '96': 1 << 31, '100': 1 << 31, '104': 1 << 31,
      '108': 1 << 31, '112': 1 << 31, '116': 1 << 31, '120': 1 << 31}),

    ("[cpipe.f0, cpipe.f1, cpipe.f2, cpipe.f3, cpipe.f4]",
     {'0': 2, '64': 1 << 31, '68': 0, '72': 1, '76': 2, '80': 3,
      '84': 1 << 31, '88': 1 << 31, '92': 1 << 31, '96': 1 << 31,
      '100': 1 << 31, '104': 1 << 31, '108': 1 << 31, '112': 1 << 31,
      '116': 1 << 31, '120': 1 << 31}),

    ("[cpipe.f0, cpipe.f1, cpipe.f2, cpipe.f3, cpipe.f4, cpipe.f6, cpipe.f7]",
     {'0': 2, '64': 1 << 31, '68': 0, '72': 1, '76': 2, '80': 3,
      '84': 1 << 31, '88': 4, '92': 6, '96': 1 << 31, '100': 1 << 31,
      '104': 1 << 31, '108': 1 << 31, '112': 1 << 31, '116': 1 << 31,
      '120': 1 << 31}),

    ("[cpipe.f0, cpipe.f5, cpipe.f2, cpipe.f3, cpipe.f4, cpipe.f6, cpipe.f7]",
     {'0': 2, '64': 1 << 31, '68': 1 << 31, '72': 5, '76': 2, '80': 3,
      '84': 0, '88': 4, '92': 6, '96': 1 << 31, '100': 1 << 31,
      '104': 1 << 31, '108': 1 << 31, '112': 1 << 31, '116': 1 << 31,
      '120': 1 << 31}),

    ("[cpipe.f1, cpipe.fork, [[cpipe.f3], [1]], cpipe.join, cpipe.f2]",
     {'0': 2, '64': 1 << 31, '68': 1 << 31, '72': 8, '76': 9, '80': 1 << 31,
      '84': 1 << 31, '88': 1 << 31, '92': 1 << 31, '96': 3, '100': 10,
      '104': 1, '108': 1 << 31, '112': 1 << 31, '116': 1 << 31,
      '120': 1 << 31}),

    ("[cpipe.f1, cpipe.fork, [[cpipe.f7], [1]], cpipe.join, cpipe.f2]",
     {'0': 2, '64': 1 << 31, '68': 1 << 31, '72': 8, '76': 1 << 31,
      '80': 1 << 31, '84': 1 << 31, '88': 1 << 31, '92': 9, '96': 7, '100': 10,
      '104': 1, '108': 1 << 31, '112': 1 << 31, '116': 1 << 31,
      '120': 1 << 31}),

    ("[cpipe.f7, cpipe.fork, [[1], [1]], cpipe.join, cpipe.f0, cpipe.f2]",
     {'0': 2, '64': 8, '68': 1 << 31, '72': 0, '76': 1 << 31, '80': 1 << 31,
      '84': 1 << 31, '88': 1 << 31, '92': 1 << 31, '96': 9, '100': 10,
      '104': 7, '108': 1 << 31, '112': 1 << 31, '116': 1 << 31,
      '120': 1 << 31}),

    ("[cpipe.f7, cpipe.fork, [[cpipe.dual, cpipe.f0], [cpipe.dual]], \
        cpipe.join, cpipe.f3, cpipe.f2]",
     {'0': 2, '64': 13, '68': 1 << 31, '72': 3, '76': 8, '80': 1 << 31,
      '84': 1 << 31, '88': 1 << 31, '92': 1 << 31, '96': 0, '100': 14,
      '104': 7, '108': 1 << 31, '112': 1 << 31, '116': 9,
      '120': 10}),

    ("[cpipe.f7, cpipe.fork, [[cpipe.f9], [1]], cpipe.join, cpipe.f0]",
     {'0': 2, '64': 8, '68': 1 << 31, '72': 1 << 31, '76': 1 << 31,
      '80': 1 << 31, '84': 1 << 31, '88': 1 << 31, '92': 1 << 31, '96': 11,
      '100': 10, '104': 7, '108': 9, '112': 1 << 31, '116': 1 << 31,
      '120': 1 << 31})
]


def test_composable_exception_compose(hierarchy):
    cpipe, _ = hierarchy
    with pytest.raises(TypeError) as excinfo:
        cpipe.compose((cpipe.f1, cpipe.f2))
    assert "The composable pipeline must be a list" in str(excinfo.value)


def test_composable_exception_multiple_bad_slots(hierarchy):
    cpipe, _ = hierarchy
    with pytest.raises(SystemError) as excinfo:
        cpipe.compose([cpipe.f1, cpipe.f2, cpipe.f3, cpipe.f4, cpipe.f5,
                       cpipe.f6, cpipe.f1, cpipe.f2, cpipe.f3, cpipe.f4,
                       cpipe.f5, cpipe.f1, cpipe.f2, cpipe.f3, cpipe.f4,
                       cpipe.f1])
    assert "Number of slots in the list is bigger than" in str(excinfo.value)


def test_composable_exception_compose_unloaded_ip(hierarchy):
    cpipe, _ = hierarchy
    with pytest.raises(AttributeError) as excinfo:
        cpipe.compose([cpipe.source_data, cpipe.pr.f8, cpipe.sink_data])
    assert "is not loaded, load IP before composing" in str(excinfo.value)


@pytest.mark.parametrize('pipeline', pipelines)
def test_composable_pipeline(hierarchy, pipeline):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipeline[0])
    cpipe._graph_debug = True
    cpipe.compose(pipe)
    name = f'pipeline{pipelines.index(pipeline)}'
    cpipe.graph.render(format='png', outfile=f'tests/graph_output/{name}.png')
    assert ipdevice.ip.memory == pipeline[1]


def test_composable_tap(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[0][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[0][1]
    cpipe.tap(pipe[4])
    assert ipdevice.ip.memory == pipelines[1][1]
    cpipe.untap()
    assert ipdevice.ip.memory == pipelines[0][1]


def test_composable_tap_by_index(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[0][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[0][1]
    cpipe.tap(4)
    assert ipdevice.ip.memory == pipelines[1][1]
    cpipe.untap()
    assert ipdevice.ip.memory == pipelines[0][1]


def test_composable_tap_nopipeline(hierarchy):
    cpipe, _ = hierarchy
    with pytest.raises(SystemError) as excinfo:
        cpipe.tap(4)
    assert "A pipeline has not been composed yet" == str(excinfo.value)


def test_composable_tap_bigindex(hierarchy):
    cpipe, _ = hierarchy
    pipe = eval(pipelines[0][0])
    cpipe.compose(pipe)
    with pytest.raises(ValueError) as excinfo:
        cpipe.tap(22)
    assert "is out of range, supported indexes are int" in str(excinfo.value)


def test_composable_tap_wrongip(hierarchy):
    cpipe, _ = hierarchy
    pipe = eval(pipelines[0][0])
    cpipe.compose(pipe)
    with pytest.raises(ValueError) as excinfo:
        cpipe.tap(cpipe.join)
    assert "does not exist in the list or IP is in" in str(excinfo.value)


def test_composable_tap_multiple_outputs(hierarchy):
    cpipe, _ = hierarchy
    pipe = eval(pipelines[4][0])
    cpipe.compose(pipe)
    with pytest.raises(SystemError) as excinfo:
        cpipe.tap(pipe[1])
    assert "tap into an IP with multiple outputs is" in str(excinfo.value)


def test_composable_untap_nopipeline(hierarchy):
    cpipe, _ = hierarchy
    with pytest.raises(SystemError) as excinfo:
        cpipe.untap()
    assert "There is nothing to untap" == str(excinfo.value)


def test_composable_remove(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[0][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[0][1]
    cpipe.remove([pipe[5]])
    assert ipdevice.ip.memory == pipelines[2][1]


def test_composable_remove_nolist(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[0][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[0][1]
    with pytest.raises(ValueError) as excinfo:
        cpipe.remove(None)
    assert "remove requires a list of IP object" == str(excinfo.value)


def test_composable_remove_badip(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[0][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[0][1]
    with pytest.raises(ValueError) as excinfo:
        cpipe.remove([cpipe.fork])
    assert "does not exit in current pipeline" in str(excinfo.value)


def test_composable_remove_exc(hierarchy):
    cpipe, _ = hierarchy
    pipe = eval(pipelines[0][0])
    with pytest.raises(SystemError) as excinfo:
        cpipe.remove([pipe[5]])
    assert "A pipeline has not been composed yet" == str(excinfo.value)


def test_composable_replace_linear(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[2][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[2][1]
    cpipe.replace((pipe[1], cpipe.f5))
    assert ipdevice.ip.memory == pipelines[3][1]


def test_composable_replace_branch(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[4][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[4][1]
    cpipe.replace((pipe[2][0][0], cpipe.f7))
    assert ipdevice.ip.memory == pipelines[5][1]


def test_composable_replace_notuple(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[2][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[2][1]
    with pytest.raises(ValueError) as excinfo:
        cpipe.replace(pipe[1])
    assert "replace expects a tuple as an argument" == str(excinfo.value)


def test_composable_replace_bad_tuple(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[2][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[2][1]
    with pytest.raises(ValueError) as excinfo:
        cpipe.replace((pipe[1], cpipe.f5, cpipe.f6))
    assert "replace expects a tuple with two IP objects" == str(excinfo.value)


def test_composable_replace_badip(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[2][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[2][1]
    with pytest.raises(ValueError) as excinfo:
        cpipe.replace((cpipe.fork, cpipe.f5))
    assert "is not in the current pipeline" in str(excinfo.value)


def test_composable_insert(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[2][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[2][1]
    cpipe.insert((cpipe.f5, 5))
    assert ipdevice.ip.memory == pipelines[0][1]


def test_composable_insert_list(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[1][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[1][1]
    cpipe.insert(([cpipe.f5, cpipe.f6, cpipe.f7], 5))
    assert ipdevice.ip.memory == pipelines[0][1]


def test_composable_insert_notuple(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[2][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[2][1]
    with pytest.raises(ValueError) as excinfo:
        cpipe.insert([cpipe.f5])
    assert "insert expects a tuple as an argument" == str(excinfo.value)


def test_composable_insert_badlen(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[2][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[2][1]
    with pytest.raises(ValueError) as excinfo:
        cpipe.insert((cpipe.f5, 5, 6))
    assert "insert expects a tuple with two elements" == str(excinfo.value)


def test_composable_insert_bad_index_type(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[2][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[2][1]
    with pytest.raises(ValueError) as excinfo:
        cpipe.insert((cpipe.f5, cpipe.f5))
    assert "insert expects an integer as index" == str(excinfo.value)


def test_composable_insert_bad_index(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[2][0])
    cpipe.compose(pipe)
    assert ipdevice.ip.memory == pipelines[2][1]
    with pytest.raises(ValueError) as excinfo:
        cpipe.insert((cpipe.f5, 50))
    assert "index cannot be bigger than current pipeline" in str(excinfo.value)


def test_composable_current_pipeline(hierarchy):
    cpipe, ipdevice = hierarchy
    pipe = eval(pipelines[2][0])
    cpipe.compose(pipe)
    assert cpipe.current_pipeline == pipe


def test_composable_checkhierarchy(hierarchy):
    cpipe, _ = hierarchy
    assert cpipe.checkhierarchy(hier_desc)


def test_composable_c_dict(hierarchy):
    cpipe, _ = hierarchy
    assert cpipe.c_dict


def test_composable_dfx_dict(hierarchy):
    cpipe, _ = hierarchy
    assert cpipe.dfx_dict


def test_composable_dfx_unloaded_ip(hierarchy):
    cpipe, _ = hierarchy
    assert isinstance(cpipe.pr.f8, virtual.VirtualIP)


def test_composable_dfx_loaded_ip(hierarchy):
    cpipe, _ = hierarchy
    assert isinstance(cpipe.pr.f9, virtual.StreamingIP)


def test_composable_soft_reset_mode_disable(hierarchy):
    cpipe, _ = hierarchy
    cpipe.soft_reset_mode = False
    assert not cpipe.soft_reset_mode


def test_composable_soft_reset_mode_enable(hierarchy):
    cpipe, _ = hierarchy
    cpipe.soft_reset_mode = True
    # Should check for warning
    assert not cpipe.soft_reset_mode


def test_composable_dfx_decouple_mode_disable(hierarchy):
    cpipe, _ = hierarchy
    cpipe.dfx_decouple_mode = False
    assert not cpipe.dfx_decouple_mode


def test_composable_dfx_decouple_mode_enable(hierarchy):
    cpipe, _ = hierarchy
    cpipe.dfx_decouple_mode = True
    # Should check for warning
    assert not cpipe.dfx_decouple_mode


def test_composable_dfx_download(hierarchy):
    cpipe, _ = hierarchy
    cpipe.load([cpipe.pr.f9])
    assert isinstance(cpipe.pr.f9, virtual.StreamingIP)
    assert isinstance(cpipe.pr.f8, virtual.VirtualIP)


def test_composable_dfx_download_str(hierarchy):
    cpipe, _ = hierarchy
    cpipe.load(["pr/f9"])
    assert isinstance(cpipe.pr.f9, virtual.StreamingIP)
    assert isinstance(cpipe.pr.f8, virtual.VirtualIP)


def test_composable_exception_dfx_download(hierarchy):
    cpipe, _ = hierarchy
    with open((file1 := 'tests/files/pr_f8.bit'), 'w') as f:
        f.write('empty')
    with open((file2 := 'tests/files/pr_f9.bit'), 'w') as f:
        f.write('empty')

    with pytest.raises(SystemError) as excinfo:
        cpipe.load([cpipe.pr.f9, cpipe.pr.f8])
    os.remove(file1)
    os.remove(file2)
    assert "cannot be loaded into the same DFX" in str(excinfo.value)


def test_default_paths(ipdevice):
    hier_desc['overlay'] = MockOverlayComposable(desc)
    paths = {
        "composable": {
            "data": {
                "si": {
                            "port": 12,
                            "Description": "Input data path"
                    },
                "mi": {
                            "port": 12,
                            "Description": "Output data path"
                }
            }
        }
    }
    with open((file := 'tests/files/composable_test_paths.json'), 'w') as f:
        json.dump(paths, f)
    cpipe = Composable(hier_desc)
    os.remove(file)
    assert cpipe.axis_switch.mi[12] == 12
    cpipe.compose([cpipe.data_in, cpipe.f0, cpipe.data_out])
    assert cpipe.axis_switch.mi[0] == 12
    assert cpipe.axis_switch.mi[12] == 0
    cpipe.tap(0)
    assert cpipe.axis_switch.mi[12] == 12
    pipe = eval(pipelines[0][0])
    cpipe.compose(pipe)
    conf1 = pipelines[0][1].copy()
    conf1['112'] = 12
    assert ipdevice.ip.memory == conf1
    cpipe.tap(4)
    conf2 = pipelines[1][1].copy()
    conf2['112'] = 12
    assert ipdevice.ip.memory == conf2
