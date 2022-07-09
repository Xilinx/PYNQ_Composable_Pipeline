# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

import json

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"


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

    def __init__(self, *args, rootname: str = "root", expanded: bool = False,
                 **kwargs):
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
