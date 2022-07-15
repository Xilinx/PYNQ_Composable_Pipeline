..
  Copyright (C) 2021 Xilinx, Inc
  
  SPDX-License-Identifier: BSD-3-Clause

.. _video-pipeline:

*****************************
The Composable Video Pipeline
*****************************

To demonstrate the benefits of the composable overlay, we are providing a
composable video pipeline that you can use out-of-the-box. An overview of the
composable video pipeline is shown in the image below.

.. image:: images/cv-4pr-pynq-z2.png
   :align: center

This version implements several standard vision functions. The most common
functions are implemented in the static region, these account for 7 functions.
The composable overlay also provides 12 dynamic functions implemented across
3 DFX regions, note that ``pr_0`` and ``pr_1`` provide pairs of functions.


.. list-table::
   :header-rows: 1
   :align: center

   * - Static IP
   * - colorthresholding
   * - filter2d
   * - gray2rgb
   * - lut
   * - rgb2gray
   * - rgb2hsv
   * - duplicate


.. list-table::
   :header-rows: 1
   :align: center

   * - Dynamic IP
     - DFX Region
   * - absdiff
     - pr_2
   * - add
     - pr_2
   * - bitwise_add
     - pr_2
   * - cornerHarris
     - pr_1
   * - dilate
     - pr_0 & pr_1
   * - erode
     - pr_0 & pr_1
   * - fast
     - pr_0
   * - fifo
     - pr_0 & pr_1
   * - filter2d
     - pr_1
   * - rgb2xyz
     - pr_2
   * - subtract
     - pr_2

Rebuild Composable Video Pipeline
=================================

To rebuild the composable video pipeline, you will have to clone the
repository recursively (to pull submodules).

.. code-block:: bash

  git clone https://github.com/Xilinx/PYNQ_Composable_Pipeline --recursive

You also need Vitis and Vivado ``2022.1`` installed.

Then to rebuild the video pipeline you can run ``make`` in the
`boards/Pynq-Z2 <https://github.com/Xilinx/PYNQ_Composable_Pipeline/tree/main/boards/Pynq-Z2>`_
folder.
You can also rebuild the composable overlay for the
`Pynq-ZU <https://github.com/Xilinx/PYNQ_Composable_Pipeline/tree/main/boards/Pynq-ZU>`_ 
and 
`Kria KV260 <https://github.com/Xilinx/PYNQ_Composable_Pipeline/tree/main/boards/KV260>`_


The build process is scripted using a Makefile, when you run ``make`` the build
process will do the following steps

1. Vision IP will be generated

2. PYNQ HLS IP will be generated

3. The Vivado project is created along with the IPI design

4. The bitstream generation is launched

5. The bitstreams and hwh files are copied to the ``overlay`` folder

6. A cached dictionary is created

7. Files are versioned

Note that you do not need to rebuild the project to use the composable
video pipeline, we provide a pre-built design. This is deliver when you
install the ``pynq_composable`` package on your board, please refer to
:ref:`composable-video-pipeline`.

If you are interested in building your own composable overlay, check out the
tutorial :ref:`composable-overlay-tutorial`

The Composable Video Pipeline also uses the following Python modules:

  * :mod:`pynq_composable.libs`  - Drivers to control the vision IP cores.
  * :mod:`pynq_composable.video`  - Drivers to control video sources and sinks.
  * :mod:`pynq_composable.apps`  - API for higher level applications and
    pre-configured applications.

.. toctree::
    :hidden:

    video_pipeline/libs.rst
    video_pipeline/video.rst
    video_pipeline/apps.rst