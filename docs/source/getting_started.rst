..
  Copyright (C) 2021 Xilinx, Inc
  
  SPDX-License-Identifier: BSD-3-Clause


***************
Getting Started
***************

Supported Boards
================

* `Pynq-Z1 <https://digilent.com/reference/programmable-logic/pynq-z1/start>`_
* `Pynq-Z2 <https://www.tul.com.tw/ProductsPYNQ-Z2.html>`_
* `Pynq-ZU <https://www.tul.com.tw/ProductsPYNQ-ZU.html>`_
* `KV260 <https://www.xilinx.com/products/som/kria/kv260-vision-starter-kit.html>`_

Get the Composable Video Pipeline
=================================

If you have one of the supported boards with ``pynq 2.7`` up and running,
install the composable video pipeline by executing the following code in a
Jupyter lab terminal

.. code-block:: bash

  git clone https://github.com/Xilinx/PYNQ_Composable_Pipeline
  python3 -m pip install PYNQ_Composable_Pipeline/ --no-build-isolation

Once the installation is done, you can deliver the notebooks by running

.. code-block:: bash

  pynq-get-notebooks pynq-composable -p $PYNQ_JUPYTER_NOTEBOOKS

Get Help
========

You can get help in the `PYNQ support forum <https://discuss.pynq.io/>`_. Or by
opening an `issue on GitHub <https://github.com/Xilinx/PYNQ_Composable_Pipeline/issues>`_

Contribute
==========

We welcome contributions, please review the
`contributing guidelines <https://github.com/Xilinx/PYNQ_Composable_Pipeline/blob/main/CONTRIBUTING.md>`_
to contribute.