`timescale 1ns / 1ps

module main (
  input  wire clk,
  input  wire rst_n,

  output wire hdmi_tx_clk_n,
  output wire hdmi_tx_clk_p,
  output wire hdmi_tx_chn_r_n,
  output wire hdmi_tx_chn_r_p,
  output wire hdmi_tx_chn_g_n,
  output wire hdmi_tx_chn_g_p,
  output wire hdmi_tx_chn_b_n,
  output wire hdmi_tx_chn_b_p,

  output wire debug_bus_7,
  output wire debug_bus_6,
  output wire debug_bus_5,
  output wire debug_bus_4,
  output wire debug_bus_3,
  output wire debug_bus_2,
  output wire debug_bus_1,
  output wire debug_bus_0,

  output wire debug_0,
  output wire debug_1,
  output wire debug_2,
  output wire debug_3,
  output wire debug_4
);
  wire [7:0] debug_bus = {debug_bus_7, debug_bus_6, debug_bus_5, debug_bus_4, debug_bus_3, debug_bus_2, debug_bus_1, debug_bus_0};

  wire rst;
  wire clk1x;
  wire clk5x;
  
  wire clock_locked;
  wire clock_divider_locked;

  assign rst = ~(clock_locked || clock_divider_locked);

  clock clock_inst (
    .clk_out1(clk5x),
    .resetn  (rst_n),
    .locked  (clock_locked),
    .clk_in1 (clk)
  );

  clock_divider clock_divider_inst (
    .clk_out1(clk1x),
    .resetn  (rst_n),
    .locked  (clock_divider_locked),
    .clk_in1 (clk5x)
  );
  
  field field_inst (
    .clk(clk1x)
    //.x(),
    //.y(),
    //.write_enable(),
    //.din(),
    //.dout()
  );

  wire [7:0] pixel_r;
  wire [7:0] pixel_g;
  wire [7:0] pixel_b;
  wire pixel_valid;
  wire hsync;
  wire vsync;

  image_encoder image_encoder_inst (
    .clk(clk1x),
    .reset(rst),
    .vsync(vsync),
    .hsync(hsync),
    .pixel_r(pixel_r),
    .pixel_g(pixel_g),
    .pixel_b(pixel_b),
    .pixel_valid(pixel_valid)
  );

  hdmi_tx hdmi_tx_inst (
    .clk1x(clk1x),
    .clk5x(clk5x),
    .rst(rst),
    .image_r(pixel_r),
    .image_g(pixel_g),
    .image_b(pixel_b),
    .vsync(vsync),
    .hsync(hsync),
    .de(pixel_valid),
    .hdmi_tx_clk_n(hdmi_tx_clk_n),
    .hdmi_tx_clk_p(hdmi_tx_clk_p),
    .hdmi_tx_chn_r_n(hdmi_tx_chn_r_n),
    .hdmi_tx_chn_r_p(hdmi_tx_chn_r_p),
    .hdmi_tx_chn_g_n(hdmi_tx_chn_g_n),
    .hdmi_tx_chn_g_p(hdmi_tx_chn_g_p),
    .hdmi_tx_chn_b_n(hdmi_tx_chn_b_n),
    .hdmi_tx_chn_b_p(hdmi_tx_chn_b_p)
  );
endmodule
