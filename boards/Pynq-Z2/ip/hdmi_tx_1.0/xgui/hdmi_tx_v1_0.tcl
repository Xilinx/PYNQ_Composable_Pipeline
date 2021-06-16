# Copyright @ 2017-2019 RealDigital.org
#
# License: BSD 3-Clause
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this 
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, 
#    this list of conditions and the following disclaimer in the documentation 
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors 
#    may be used to endorse or promote products derived from this software 
#    without specific prior written permission.
#
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_BLUE_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_GREEN_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_RED_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MODE" -parent ${Page_0} -widget comboBox


}

proc update_PARAM_VALUE.C_BLUE_WIDTH { PARAM_VALUE.C_BLUE_WIDTH } {
	# Procedure called to update C_BLUE_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_BLUE_WIDTH { PARAM_VALUE.C_BLUE_WIDTH } {
	# Procedure called to validate C_BLUE_WIDTH
	return true
}

proc update_PARAM_VALUE.C_GREEN_WIDTH { PARAM_VALUE.C_GREEN_WIDTH } {
	# Procedure called to update C_GREEN_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_GREEN_WIDTH { PARAM_VALUE.C_GREEN_WIDTH } {
	# Procedure called to validate C_GREEN_WIDTH
	return true
}

proc update_PARAM_VALUE.C_RED_WIDTH { PARAM_VALUE.C_RED_WIDTH } {
	# Procedure called to update C_RED_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_RED_WIDTH { PARAM_VALUE.C_RED_WIDTH } {
	# Procedure called to validate C_RED_WIDTH
	return true
}

proc update_PARAM_VALUE.MODE { PARAM_VALUE.MODE } {
	# Procedure called to update MODE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MODE { PARAM_VALUE.MODE } {
	# Procedure called to validate MODE
	return true
}


proc update_MODELPARAM_VALUE.MODE { MODELPARAM_VALUE.MODE PARAM_VALUE.MODE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MODE}] ${MODELPARAM_VALUE.MODE}
}

proc update_MODELPARAM_VALUE.C_RED_WIDTH { MODELPARAM_VALUE.C_RED_WIDTH PARAM_VALUE.C_RED_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RED_WIDTH}] ${MODELPARAM_VALUE.C_RED_WIDTH}
}

proc update_MODELPARAM_VALUE.C_GREEN_WIDTH { MODELPARAM_VALUE.C_GREEN_WIDTH PARAM_VALUE.C_GREEN_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_GREEN_WIDTH}] ${MODELPARAM_VALUE.C_GREEN_WIDTH}
}

proc update_MODELPARAM_VALUE.C_BLUE_WIDTH { MODELPARAM_VALUE.C_BLUE_WIDTH PARAM_VALUE.C_BLUE_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_BLUE_WIDTH}] ${MODELPARAM_VALUE.C_BLUE_WIDTH}
}

