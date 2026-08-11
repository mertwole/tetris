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

  output wire digit_0,
  output wire digit_1,
  output wire digit_2,
  output wire digit_3,
  output wire digit_4,
  output wire digit_5,
  output wire digit_6,
  output wire digit_7,
  output wire digit_8,
  output wire digit_9,
  output wire digit_10,

  output wire segment_0,
  output wire segment_1,
  output wire segment_2,
  output wire segment_3,
  output wire segment_4,
  output wire segment_5,
  output wire segment_6,

  output wire next_piece_led_0,
  output wire next_piece_led_1,
  output wire next_piece_led_2,
  output wire next_piece_led_3,
  output wire next_piece_led_4,
  output wire next_piece_led_5,
  output wire next_piece_led_6,
  output wire next_piece_led_7,

  output wire game_state_0,
  output wire game_state_1,
  output wire game_state_2,
  output wire game_state_3,

  input wire button_start,
  input wire button_rotate_cw,
  input wire button_rotate_ccw,
  input wire button_right,
  input wire button_down,
  input wire button_left
);
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

  wire [10:0] digit_bus = {
    digit_0, 
    digit_1, 
    digit_2, 
    digit_3, 
    digit_4, 
    digit_5, 
    digit_6, 
    digit_7, 
    digit_8, 
    digit_9, 
    digit_10
  };

  wire [6:0] segment_bus = {
    segment_0, 
    segment_1, 
    segment_2, 
    segment_3, 
    segment_4, 
    segment_5, 
    segment_6
  };

  wire [7:0] next_piece_bus = {
    next_piece_led_0,
    next_piece_led_1,
    next_piece_led_2,
    next_piece_led_3,
    next_piece_led_4,
    next_piece_led_5,
    next_piece_led_6,
    next_piece_led_7
  };

  wire [3:0] game_state_bus = {
    game_state_0,
    game_state_1,
    game_state_2,
    game_state_3
  };

  wire[1:0] next_piece_read_index;
  wire[1:0] next_piece_cell_x;
  wire next_piece_cell_y;
  wire[2:0] next_piece_type;

  wire[10:0] digit_bus_inv;
  wire[6:0] segment_bus_inv;

  assign digit_bus = ~digit_bus_inv;
  assign segment_bus = ~segment_bus_inv;

  wire button_start_pressed;

  wire[19:0] score;
  wire[11:0] lines_burned_bcd;

  wire button_right_pressed;
  wire button_down_pressed;
  wire button_left_pressed;
  wire button_rotate_cw_pressed;
  wire button_rotate_ccw_pressed;

  io io_inst(
    .clk(clk1x),

    .digits(digit_bus_inv),
    .segments(segment_bus_inv),

    .next_piece_leds(next_piece_bus),
    
    .game_state_leds(game_state_bus),

    .button_start(button_start),
    .button_rotate_cw(button_rotate_cw),
    .button_rotate_ccw(button_rotate_ccw),
    .button_right(button_right),
    .button_down(button_down),
    .button_left(button_left),

    .score(score),
    .lines_burned_bcd(lines_burned_bcd),

    .button_start_pressed(button_start_pressed),
    .button_rotate_cw_pressed(button_rotate_cw_pressed),
    .button_rotate_ccw_pressed(button_rotate_ccw_pressed),
    .button_right_pressed(button_right_pressed),
    .button_down_pressed(button_down_pressed),
    .button_left_pressed(button_left_pressed),
    
    .next_piece_read_index(next_piece_read_index),
    .next_piece_cell_x(next_piece_cell_x),
    .next_piece_cell_y(next_piece_cell_y),
    .next_piece_type(next_piece_type),

    .game_state('b01)
  );

  integer frame_clock = 0;

  reg prev_frame_right_pressed = 0;
  reg soft_dropping = 0;

  reg prev_frame_down_pressed = 0;
  reg reset_soft_drop_score = 0;

  reg prev_frame_left_pressed = 0;
  reg commit_soft_drop_score = 0;

  reg prev_frame_rotate_cw_pressed = 0;
  reg line_burned = 0;

  reg prev_frame_rotate_ccw_pressed = 0;
  reg commit_burned_lines = 0;

  reg prev_frame_start_pressed = 0;
  reg generate_next_piece = 0;

  always @(posedge clk1x) begin
    if (frame_clock == 1_000_000) begin
      frame_clock <= 0;

      prev_frame_right_pressed <= button_right_pressed;
      soft_dropping <= !prev_frame_right_pressed && button_right_pressed;

      prev_frame_down_pressed <= button_down_pressed;
      reset_soft_drop_score <= !prev_frame_down_pressed && button_down_pressed;

      prev_frame_left_pressed <= button_left_pressed;
      commit_soft_drop_score <= !prev_frame_left_pressed && button_left_pressed;

      prev_frame_rotate_cw_pressed <= button_rotate_cw_pressed;
      line_burned <= !prev_frame_rotate_cw_pressed && button_rotate_cw_pressed;

      prev_frame_rotate_ccw_pressed <= button_rotate_ccw_pressed;
      commit_burned_lines <= !prev_frame_rotate_ccw_pressed && button_rotate_ccw_pressed;

      prev_frame_start_pressed <= button_start_pressed;
      generate_next_piece <= !prev_frame_start_pressed && button_start_pressed;
    end else begin 
      frame_clock <= frame_clock + 1;

      soft_dropping <= 0;
      reset_soft_drop_score <= 0;
      commit_soft_drop_score <= 0;
      line_burned <= 0;
      commit_burned_lines <= 0;
      generate_next_piece <= 0;
    end
  end

  next_piece next_piece_inst(
    .clk(clk1x),

    .gen(generate_next_piece),

    .read_index(next_piece_read_index),
    .cell_x(next_piece_cell_x),
    .cell_y(next_piece_cell_y),
    .type(next_piece_type)
  );

  scores scores_inst(
    .clk(clk1x),
    .line_burned(line_burned), // rotate_cw
    .commit_burned_lines(commit_burned_lines), // rotate_ccw
    .soft_dropping(soft_dropping), // right
    .reset_soft_drop_score(reset_soft_drop_score), // down
    .commit_soft_drop_score(commit_soft_drop_score), // left
    .score(score),
    .lines_burned_bcd(lines_burned_bcd)
  );

  wire[3:0] field_rendering_x;
  wire[4:0] field_rendering_y;
  wire[2:0] field_rendering_data;

  reg[3:0] field_x = 5;
  reg[4:0] field_y = 5;
  reg field_write_enable = 0;
  reg[2:0] field_din = 3'b000;

  integer field_fill_counter = 0;

  always @(posedge clk1x) begin
    if (!rst) begin
      if (field_fill_counter != 10) begin
        field_fill_counter <= field_fill_counter + 1;

        field_x <= field_fill_counter + 3;
        field_y <= field_fill_counter + 3;
        field_din <= field_fill_counter;
        field_write_enable <= 1;
      end else begin
        field_write_enable <= 0;
      end
    end
  end

  field field_inst (
    .clk(clk1x),

    .x_coord(field_x),
    .y_coord(field_y),
    .write_enable(field_write_enable),
    .din(field_din),
    //.dout(),

    .rendering_x(field_rendering_x),
    .rendering_y(field_rendering_y),
    .rendering_dout(field_rendering_data)
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

    .field_x_out(field_rendering_x),
    .field_y_out(field_rendering_y),
    .field_cell_value(field_rendering_data),

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
