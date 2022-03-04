..
  Copyright (C) 2021 Xilinx, Inc
  
  SPDX-License-Identifier: BSD-3-Clause

.. default-paths:

*************
Default Paths
*************

In a composable overlay, a default path specifies the nodes that are source
and sink in a design, this is consumer and producer. These default paths are
annotated with the keyword ``[default]`` in the ``c_dict``. 

Default paths are an optional and are loaded when the
:class:`pynq_composable.composable.Composable` driver is assigned. 
Default paths are specified in a unique json file with the name
``<overlay_name>_paths.json``. This file must be placed next to the overlay. 
The structure of this dictionary is as follows:

* The first level key indicates the hierarchy
* The second level key provides an arbitrary name for the path.
* The third level key defines the si (Subordinate) and mi (Manager) interfaces on
  the AXI4-Stream Switch that the path is connected to.

The default paths appear in the ``c_dict`` by appending the second level key
with ``in``, for `si` ports and ``out`` for `mi` ports.

The default paths are also added as attribute to the ``Composable`` object and
are a handy way to compose your pipeline. For instance

.. code-block:: python

    video.compose([video.hdmi_source_in, f1, f2, ..., video.hdmi_source_out])

An example json file to define default paths can be found below.

.. code-block:: json

    {
        "video": {
            "hdmi_source": {
                "si": {
                            "port": 0,
                            "Description": "HDMI IN frontend PL path"
                    },
                "mi": {
                            "port": 0,
                            "Description": "HDMI IN frontend PS path"
                }
            },
            "hdmi_sink": {
                "si": {
                            "port": 1,
                            "Description": "HDMI OUT frontend PS path"
                    },
                "mi": {
                            "port": 1,
                            "Description": "HDMI OUT frontend PL path"
                }
            },
        }
        "audio": {
            "mic": {
                "si": {
                            "port": 0,
                            "Description": "Microphone frontend PL path"
                    },
                "mi": {
                            "port": 0,
                            "Description": "Microphone frontend PS path"
                }
            },
            "speaker": {
                "si": {
                            "port": 5,
                            "Description": "Speaker frontend PS path"
                    },
                "mi": {
                            "port": 5,
                            "Description": "Speaker frontend PL path"
                }
            },
        }
    }

