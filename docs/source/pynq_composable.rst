..
  Copyright (C) 2021 Xilinx, Inc
  
  SPDX-License-Identifier: BSD-3-Clause

.. _composable-package:

***************************
``pynq_composable`` Package
***************************

All ``pynq_composable`` code is contained in the *pynq_composable* Python
package and can be found on the on the 
`Github repository <https://github.com/Xilinx/PYNQ_Composable_Pipeline/>`_.


The key modules are:

  * :mod:`pynq_composable.composable` - This modules provides the APIs to
    compose overlays at runtime.
  * :mod:`pynq_composable.switch` - This module is the driver to interact with
    the AXI4-Stream Switch.
  * :mod:`pynq_composable.parser` - This module parses the metadata in the hwh
    files and provide the ``c_dict`` and ``dfx_dict`` dictionaries.

.. toctree::
    :hidden:

    modules/composable.rst
    modules/switch.rst
    modules/parser.rst
