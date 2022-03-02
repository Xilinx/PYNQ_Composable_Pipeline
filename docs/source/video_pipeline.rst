..
  Copyright (C) 2021 Xilinx, Inc
  
  SPDX-License-Identifier: BSD-3-Clause

.. video-pipeline:

*****************************
The Composable Video Pipeline
*****************************

To demonstrate the benefits of the composable overlay, we are providing a
composable video pipeline that you can use out-of-the-box. An overview of the
composable video pipeline is shown in the image below.

.. image:: images/cv-4pr-pynq-z2.png
   :align: center

This version implements several standard vision functions. The most common
functions are implemented in the static region, these account for 6 functions.
The composable overlay also provides 12 dynamic functions implemented across
4 DFX regions, note that ``pr_0`` and ``pr_1`` provide pairs of functions.


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


.. list-table::
   :header-rows: 1
   :align: center

   * - Dynamic IP
     - DFX Region
   * - absdiff
     - pr_join
   * - add
     - pr_join
   * - bitwise_add
     - pr_join
   * - cornerHarris
     - pr_1
   * - dilate
     - pr_0 & pr_1
   * - duplicate
     - pr_fork
   * - erode
     - pr_0 & pr_1
   * - fast
     - pr_0
   * - fifo
     - pr_0 & pr_1
   * - filter2d
     - pr_0
   * - rgb2xyz
     - pr_fork
   * - subtract
     - pr_join 

You can rebuild the video pipeline by running ``make`` in the 
`Pynq-Z2 <https://github.com/Xilinx/PYNQ_Composable_Pipeline/tree/main/boards/Pynq-Z2>`_
folder

You can also rebuild the composable overlay for 
`Pynq-ZU <https://github.com/Xilinx/PYNQ_Composable_Pipeline/tree/main/boards/Pynq-ZU>`_ 
and 
`Kria KV260 <https://github.com/Xilinx/PYNQ_Composable_Pipeline/tree/main/boards/KV260>`_


The Composable Video Pipeline also uses the following python modules:

  * :mod:`pynq_composable.libs`  - Drivers to control the vision IP cores.
  * :mod:`pynq_composable.video`  - Drivers to control video sources and sinks.
  * :mod:`pynq_composable.apps`  - API for higher level applications and
    pre-configured applications.

.. toctree::
    :hidden:

    video_pipeline/libs.rst
    video_pipeline/video.rst
    video_pipeline/apps.rst