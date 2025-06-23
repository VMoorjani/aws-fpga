# =============================================================================
# Amazon FPGA Hardware Development Kit
#
# Copyright 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.
# =============================================================================


#set curr_wave [current_wave_config]
#if { [string length $curr_wave] == 0 } {
#  if { [llength [get_objects]] > 0} {
#    add_wave /
#    set_property needs_save false [current_wave_config]
#  } else {
#     send_msg_id Add_Wave-1 WARNING "No top level signals found. Simulator will start without a wave window. If you want to open a wave window go to 'File->New Waveform Configuration' or type 'create_wave_config' in the TCL console."
#  }
#}
#
#run -all
#quit

open_vcd tb_waves.vcd

# Log specific signals to VCD
log_vcd /tb/card/fpga/CL/clk_main_a0
log_vcd /tb/card/fpga/CL/rst_main_n

# Simple register signals
log_vcd /tb/card/fpga/CL/simple_register_inst/counter_reg
log_vcd /tb/card/fpga/CL/simple_register_inst/reset_value_reg
log_vcd /tb/card/fpga/CL/simple_register_inst/control_reg
log_vcd /tb/card/fpga/CL/simple_register_inst/counter_enable

# OCL interface signals
log_vcd /tb/card/fpga/CL/ocl_cl_awvalid
log_vcd /tb/card/fpga/CL/ocl_cl_awaddr
log_vcd /tb/card/fpga/CL/ocl_cl_wvalid
log_vcd /tb/card/fpga/CL/ocl_cl_wdata
log_vcd /tb/card/fpga/CL/cl_ocl_rvalid
log_vcd /tb/card/fpga/CL/cl_ocl_rdata

# Run simulation
run -all

# Close VCD
close_vcd

quit
