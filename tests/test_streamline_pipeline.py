# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause


from pynq_composable import composable
import pytest


__author__ = "Conor Powderly"

test_data = [
    (['a', 'b', [['c', 'd'], [1]], 'f', 'g'],
        [['a', 'b', 'c', 'd', 'f', 'g'], ['b', 'f']]),
    (['a', 'b', 'c', 'd', 'e', 'f', 'g'],
        [['a', 'b', 'c', 'd', 'e', 'f', 'g']]),
    (['a', 'b', [['c', 'd'], ['e']], 'f', 'g'],
        [['a', 'b', 'c', 'd', 'f', 'g'], ['b', 'e', 'f']]),
    (['a', 'b', [['c', 'd'], ['e'], ['z']], 'f', 'g'],
        [['a', 'b', 'c', 'd', 'f', 'g'], ['b', 'e', 'f'], ['b', 'z', 'f']]),
    (['a', 'b', [['c', 'd'], []], 'f', 'g'],
        [['a', 'b', 'c', 'd', 'f', 'g'], ['b', 'f']]),
    (['a', [['b'], ['c', 'd']]], [['a', 'b'], ['a', 'c', 'd']]),
    (['a', 'b', [['c'], ['d'], ['e']], 'f', 'g'],
        [['a', 'b', 'c', 'f', 'g'], ['b', 'd', 'f'], ['b', 'e', 'f']]),
    (['a', 'b', [['c', 'd'], ['h', [['z'], ['j']], 'w']], 'f', 'g'],
        [['a', 'b', 'c', 'd', 'f', 'g'], ['b', 'h', 'z', 'w', 'f'],
         ['h', 'j', 'w']]),
]

exception_list = [
    (['a', 'b', [['c', 'd'], ['h', ['z'], ['j']], 'k'], 'f', 'g'],
        "branch needs at least two elements"),
]


@pytest.mark.parametrize('pipe', exception_list)
def test_exception(pipe):
    with pytest.raises(ValueError) as excinfo:
        _ = composable._streamline_pipeline(pipe[0])
    assert str(excinfo.value) == pipe[1]


@pytest.mark.parametrize('pipe', test_data)
def test_pipeline(pipe):
    assert pipe[1] == composable._streamline_pipeline(pipe[0])
