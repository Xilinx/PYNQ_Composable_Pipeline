# HDMI/DVI Encoder

## Overview

The HDMI/DVI encoder translates VGA signal according to HDMI specification 1.3a with interfaces for audio and auxilary data.
It can also work in DVI mode with audio and auxilary data disabled for monitors that are not compliant with HDMI specification.

Part of the codes in this IP core originates from [XAPP460: Video Connectivity Using TMDS I/O in Spartan-3A FPGAs] written by Bob Feng.

**Note**:  
For monitor (even ones that with HDMI port) that are not fully compliant with HDMI specification, the video guardband defined in the HDMI specification can be interpreted as two extra pixels by the monitor.
As a result, you may see a two-pixel-wide light pink vertical line on the left of the monitor.
If you see this, configure the core in DVI mode (so that video guardband and preambles are both disabled) or see if there is an "AV" settings on your monitor to force it into HDMI compliant mode.

## Functional Description


## Core Configuration

**Data Width**: integer, default 32-bit (for Linux)
**Red Channel Data Width**: integer, default 8-bit  
**Green Channel Data Width**: integer, default 8-bit  
**Blue Channel Data Width**: integer, default 8-bit  
**Mode**: HDMI or DVI, default DVI

The RGB input should be connected to the output of the "AXI4-Stream to Video Out" block for the typical DMA-based design used with Linux.

## Example Projects

### Blackboard Rev. A

To generate example project targeting BlackBoard rev.A, you can source the `create_project.tcl` under `example_designs/BlackboardRevA/tcl/` in Vivado 2018.3.

```bash
> vivado -mode batch -source tcl/create_project.tcl -tclargs --project_dir ./hdmi_example --project_name example
```

The command arguments `--project_dir` and `--project_name` are optional.

### BlackBoard Rev. D

To generate example project targeting BlackBoard rev.D, you can source the `create_project.tcl` under `example_designs/BlackboardRevD/tcl/` in Vivado 2018.3.

```bash
> vivado -mode batch -source tcl/create_project.tcl -tclargs --project_dir ./hdmi_example --project_name example
```

The command arguments `--project_dir` and `--project_name` are optional.

[XAPP460: Video Connectivity Using TMDS I/O in Spartan-3A FPGAs]:https://www.xilinx.com/support/documentation/application_notes/xapp460.pdf


------------------------------------------------------
<p align="center">Copyright @ 2017-2019 RealDigital.org</p>
