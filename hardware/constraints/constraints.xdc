create_clock -period 20.000 [get_ports clk]

set_property PACKAGE_PIN N18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

set_property PACKAGE_PIN P16 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# HDMI
set_property PACKAGE_PIN U18 [get_ports hdmi_tx_clk_p]
set_property PACKAGE_PIN N20 [get_ports {hdmi_tx_chn_b_p}]
set_property PACKAGE_PIN T20 [get_ports {hdmi_tx_chn_g_p}]
set_property PACKAGE_PIN V20 [get_ports {hdmi_tx_chn_r_p}]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_tx_chn_r_p]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_tx_chn_g_p]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_tx_chn_b_p]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_tx_clk_p]

# Debug bus
set_property PACKAGE_PIN G18 [get_ports debug_bus_7]
set_property PACKAGE_PIN B20 [get_ports debug_bus_6]
set_property PACKAGE_PIN J16 [get_ports debug_bus_5]
set_property PACKAGE_PIN H18 [get_ports debug_bus_4]
set_property PACKAGE_PIN G20 [get_ports debug_bus_3]
set_property PACKAGE_PIN H17 [get_ports debug_bus_2]
set_property PACKAGE_PIN D18 [get_ports debug_bus_1]
set_property PACKAGE_PIN D20 [get_ports debug_bus_0]
set_property IOSTANDARD LVCMOS33 [get_ports debug_bus_7]
set_property IOSTANDARD LVCMOS33 [get_ports debug_bus_6]
set_property IOSTANDARD LVCMOS33 [get_ports debug_bus_5]
set_property IOSTANDARD LVCMOS33 [get_ports debug_bus_4]
set_property IOSTANDARD LVCMOS33 [get_ports debug_bus_3]
set_property IOSTANDARD LVCMOS33 [get_ports debug_bus_2]
set_property IOSTANDARD LVCMOS33 [get_ports debug_bus_1]
set_property IOSTANDARD LVCMOS33 [get_ports debug_bus_0]

# Debug pins
set_property PACKAGE_PIN H20 [get_ports debug_0]
set_property PACKAGE_PIN J19 [get_ports debug_1]
set_property PACKAGE_PIN M20 [get_ports debug_2]
set_property PACKAGE_PIN F20 [get_ports debug_3]
set_property PACKAGE_PIN L20 [get_ports debug_4]
set_property IOSTANDARD LVCMOS33 [get_ports debug_0]
set_property IOSTANDARD LVCMOS33 [get_ports debug_1]
set_property IOSTANDARD LVCMOS33 [get_ports debug_2]
set_property IOSTANDARD LVCMOS33 [get_ports debug_3]
set_property IOSTANDARD LVCMOS33 [get_ports debug_4]

