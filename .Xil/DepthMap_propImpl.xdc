set_property SRC_FILE_INFO {cfile:c:/Users/Aruna/Documents/Vivado/DepthMap_implementaion_basys3_320x240/depthMap.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc rfile:../depthMap.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc id:1 order:EARLY scoped_inst:Inst_ClockDev/inst} [current_design]
current_instance Inst_ClockDev/inst
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.1
