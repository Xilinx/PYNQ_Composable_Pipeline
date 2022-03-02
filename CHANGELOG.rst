PYNQ Composable Overlays ChangeLog
----------------------------------

1.0.0
~~~~~
Added
.....

* Update package name to ``pynq_composable``
* Composable logic must be inside a hierarchy, to leverage pynq ``DefaultHierarchy`` API
* Cache dictionaries to speedup run time, up to 50x
* Allow for offline automatic hardware discovery, caching dict
* Created ``VideoStream`` metaClass to handle all combination of video sources and sinks
* Video resolution is stored in ``/tmp/resolution.json`` to automatically configure video IP
* Support for pure stream IP
* Python code improvements
* Support for Kria KV260 Vision Started Kit
* Support for the PYNQ-Z1 with the same overlay as PYNQ-Z2
* Default paths concept
* Initial pytest support and code linting in a workflow
* Read The Docs documentation
* Contributing guidelines
* Support for python ``3.8`` and ``3.9``

Removed
.......

* Deprecated ``_debug_switch`` method. Use the AXI4-Stream Switch driver
* Deprecated support for python ``3.6`` and ``3.7``

0.9.0
~~~~~

First version