## Interfacing Basys 3 FPGA with two OV7670 Cameras
## Pin assignment

## Clock signal
set_property PACKAGE_PIN W5 [get_ports clk100]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk100]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk100]
#	create_clock -period 10 [get_ports clk100]
    #create_clock -name sysclk -waveform {0 5} [get_ports clk100]
  #  create_clock -name CLK50MHZ -source [get_ports clk100] -divide_by 2 \ [get_pins CLK50MHZ_clk_wiz_0]
#_generated
    ##VGA Connector
    set_property PACKAGE_PIN G19 [get_ports {vga_r[0]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[0]}]
    set_property PACKAGE_PIN H19 [get_ports {vga_r[1]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[1]}]
    set_property PACKAGE_PIN J19 [get_ports {vga_r[2]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[2]}]
    set_property PACKAGE_PIN N19 [get_ports {vga_r[3]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[3]}]
    set_property PACKAGE_PIN N18 [get_ports {vga_b[0]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[0]}]
    set_property PACKAGE_PIN L18 [get_ports {vga_b[1]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[1]}]
    set_property PACKAGE_PIN K18 [get_ports {vga_b[2]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[2]}]
    set_property PACKAGE_PIN J18 [get_ports {vga_b[3]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[3]}]
    set_property PACKAGE_PIN J17 [get_ports {vga_g[0]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[0]}]
    set_property PACKAGE_PIN H17 [get_ports {vga_g[1]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[1]}]
    set_property PACKAGE_PIN G17 [get_ports {vga_g[2]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[2]}]
    set_property PACKAGE_PIN D17 [get_ports {vga_g[3]}]                
        set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[3]}]
    set_property PACKAGE_PIN P19 [get_ports vga_hsync]                        
        set_property IOSTANDARD LVCMOS33 [get_ports vga_hsync]
    set_property PACKAGE_PIN R19 [get_ports vga_vsync]                        
        set_property IOSTANDARD LVCMOS33 [get_ports vga_vsync]

## LEDs
set_property PACKAGE_PIN U16 [get_ports {config_finished_l}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {config_finished_l}]

set_property PACKAGE_PIN L1 [get_ports {config_finished_r}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {config_finished_r}]
					
##Buttons
#set_property PACKAGE_PIN U18 [get_ports btnc]						
#	set_property IOSTANDARD LVCMOS33 [get_ports btnc]
set_property PACKAGE_PIN W19 [get_ports btnl]                        
     set_property IOSTANDARD LVCMOS33 [get_ports btnl]
set_property PACKAGE_PIN T17 [get_ports btnr]						
         set_property IOSTANDARD LVCMOS33 [get_ports btnr]
         
set_property PACKAGE_PIN V17 [get_ports {btnc}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {btnc}]
#set_property PACKAGE_PIN V16 [get_ports {btnl}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {btnl}]
#set_property PACKAGE_PIN W16 [get_ports {btnr}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {btnr}]

## OV7670 Camera header pins

# Switches

##Pmod Header JB
##Sch name = JB1
set_property PACKAGE_PIN A14 [get_ports {ov7670_pwdn_l}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_pwdn_l}]
##Sch name = JB2
set_property PACKAGE_PIN A16 [get_ports {ov7670_data_l[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_l[0]}]
##Sch name = JB3
set_property PACKAGE_PIN B15 [get_ports {ov7670_data_l[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_l[2]}]
##Sch name = JB4
set_property PACKAGE_PIN B16 [get_ports {ov7670_data_l[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_l[4]}]
##Sch name = JB7
set_property PACKAGE_PIN A15 [get_ports {ov7670_reset_l}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_reset_l}]
##Sch name = JB8
set_property PACKAGE_PIN A17 [get_ports {ov7670_data_l[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_l[1]}]
##Sch name = JB9
set_property PACKAGE_PIN C15 [get_ports {ov7670_data_l[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_l[3]}]
##Sch name = JB10 
set_property PACKAGE_PIN C16 [get_ports {ov7670_data_l[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_l[5]}]
  

##Pmod Header JC
##Sch name = JC1
set_property PACKAGE_PIN K17 [get_ports {ov7670_data_l[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_l[6]}]
##Sch name = JC2
set_property PACKAGE_PIN M18 [get_ports ov7670_xclk_l]					
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_xclk_l]
##Sch name = JC3
set_property PACKAGE_PIN N17 [get_ports ov7670_href_l]					
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_href_l]
##Sch name = JC4
set_property PACKAGE_PIN P18 [get_ports ov7670_siod_l]					
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_siod_l]
	set_property PULLUP TRUE [get_ports ov7670_siod_l]
##Sch name = JC7
set_property PACKAGE_PIN L17 [get_ports {ov7670_data_l[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_l[7]}]
##Sch name = JC8
set_property PACKAGE_PIN M19 [get_ports ov7670_pclk_l]					
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_pclk_l]
    set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {ov7670_pclk_l_IBUF}]
##Sch name = JC9
set_property PACKAGE_PIN P17 [get_ports ov7670_vsync_l]					
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_vsync_l]
##Sch name = JC10
set_property PACKAGE_PIN R18 [get_ports ov7670_sioc_l]					
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_sioc_l]


##Pmod Header JA
##Sch name = JA1
set_property PACKAGE_PIN J1 [get_ports {ov7670_pwdn_r}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_pwdn_r}]
#Sch name = JA2
set_property PACKAGE_PIN L2 [get_ports {ov7670_data_r[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_r[0]}]
#Sch name = JA3
set_property PACKAGE_PIN J2 [get_ports {ov7670_data_r[2]}]						
    set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_r[2]}]
#Sch name = JA4
set_property PACKAGE_PIN G2 [get_ports {ov7670_data_r[4]}]						
    set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_r[4]}]
#Sch name = JA7
set_property PACKAGE_PIN H1 [get_ports {ov7670_reset_r}]						
    set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_reset_r}]
#Sch name = JA8
set_property PACKAGE_PIN K2 [get_ports {ov7670_data_r[1]}]						
    set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_r[1]}]
#Sch name = JA9
set_property PACKAGE_PIN H2 [get_ports {ov7670_data_r[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_r[3]}]
#Sch name = JA10
set_property PACKAGE_PIN G3 [get_ports {ov7670_data_r[5]}]						
    set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_r[5]}]
	
	
#Pmod Header JXADC
#Sch name = XA1_P
set_property PACKAGE_PIN J3 [get_ports {ov7670_data_r[6]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_r[6]}]
#Sch name = XA2_P
set_property PACKAGE_PIN L3 [get_ports ov7670_xclk_r]				
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_xclk_r]
#Sch name = XA3_P
set_property PACKAGE_PIN M2 [get_ports ov7670_href_r]				
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_href_r]
#Sch name = XA4_P
set_property PACKAGE_PIN N2 [get_ports ov7670_siod_r]
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_siod_r]
	set_property PULLUP TRUE [get_ports ov7670_siod_r]
#Sch name = XA1_N
set_property PACKAGE_PIN K3 [get_ports {ov7670_data_r[7]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data_r[7]}]
#Sch name = XA2_N
set_property PACKAGE_PIN M3 [get_ports ov7670_pclk_r]				
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_pclk_r]
	set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {ov7670_pclk_r_IBUF}]
#Sch name = XA3_N
set_property PACKAGE_PIN M1 [get_ports ov7670_vsync_r]				
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_vsync_r]
#Sch name = XA4_N
set_property PACKAGE_PIN N1 [get_ports ov7670_sioc_r]				
	set_property IOSTANDARD LVCMOS33 [get_ports ov7670_sioc_r]



