..
  Copyright (C) 2021 Xilinx, Inc
  
  SPDX-License-Identifier: BSD-3-Clause

.. 
  PYNQ: Composable Overlays documentation master file, created by
  sphinx-quickstart on Tue Nov  2 09:09:13 2021.
  You can adapt this file completely to your liking, but it should at least
  contain the root `toctree` directive.

*************************************
PYNQ Composable Overlays Introduction
*************************************

A composable overlay provides run time configuration as well as runtime
hardware composability. It is based on three pillars:

* An AXI4-Stream Switch that provides the runtime hardware composability,
  defining how data flow from one IP core to another.
* `DFX <https://www.xilinx.com/products/design-tools/vivado/high-level-design.html#dfx>`_
  regions that brings new functionality to the design at runtime.

* A Python API, built on top of pynq, that exposes the functionality to control
  the composable overlay in a pythonic way. 


The AXI4-Stream Switch is cornerstone in achieving composability, its runtime
configuration allows us to modify our design without redesigning the overlay,
hence being more productive. This is the key of the composable overlay.

DFX regions are optional in a composable overlay, however, having them brings
an extra dimension of flexibility making the applicability of a composable
overlay broader. For instance, not all application need the same functions
or some functions are rarely used.

The Composable Overlays Overview
================================

.. raw:: html

    <embed>
       <div style="text-align: center;">
         <iframe width="560" height="315" src="https://www.youtube.com/embed/nKu8dVKDweg" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
       </div>
    </embed>




.. toctree::
   :maxdepth: 2
   :hidden:

   getting_started
   video_pipeline
   pynq_composable