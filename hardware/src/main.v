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
  reg right_just_pressed = 0;

  reg prev_frame_down_pressed = 0;
  reg down_just_pressed = 0;

  reg prev_frame_left_pressed = 0;
  reg left_just_pressed = 0;

  reg prev_frame_rotate_cw_pressed = 0;
  reg rotate_cw_just_pressed = 0;

  reg prev_frame_rotate_ccw_pressed = 0;
  reg rotate_ccw_just_pressed = 0;

  reg prev_frame_start_pressed = 0;
  reg start_just_pressed = 0;

  always @(posedge clk1x) begin
    if (frame_clock == 1_000_000) begin
      frame_clock <= 0;

      prev_frame_right_pressed <= button_right_pressed;
      right_just_pressed <= !prev_frame_right_pressed && button_right_pressed;

      prev_frame_down_pressed <= button_down_pressed;
      down_just_pressed <= !prev_frame_down_pressed && button_down_pressed;

      prev_frame_left_pressed <= button_left_pressed;
      left_just_pressed <= !prev_frame_left_pressed && button_left_pressed;

      prev_frame_rotate_cw_pressed <= button_rotate_cw_pressed;
      rotate_cw_just_pressed <= !prev_frame_rotate_cw_pressed && button_rotate_cw_pressed;

      prev_frame_rotate_ccw_pressed <= button_rotate_ccw_pressed;
      rotate_ccw_just_pressed <= !prev_frame_rotate_ccw_pressed && button_rotate_ccw_pressed;

      prev_frame_start_pressed <= button_start_pressed;
      start_just_pressed <= !prev_frame_start_pressed && button_start_pressed;
    end else begin 
      frame_clock <= frame_clock + 1;

      right_just_pressed <= 0;
      down_just_pressed <= 0;
      left_just_pressed <= 0;
      rotate_cw_just_pressed <= 0;
      rotate_ccw_just_pressed <= 0;
      start_just_pressed <= 0;
    end
  end

  wire generate_next_piece;

  next_piece next_piece_inst(
    .clk(clk1x),

    .gen(generate_next_piece),

    .read_index(next_piece_read_index),
    .cell_x(next_piece_cell_x),
    .cell_y(next_piece_cell_y),
    .type(next_piece_type)
  );

  wire line_burned;
  wire commit_burned_lines;

  wire soft_dropping;
  wire reset_soft_drop_score;
  wire commit_soft_drop_score;

  scores scores_inst(
    .clk(clk1x),
    .line_burned(line_burned),
    .commit_burned_lines(commit_burned_lines),
    .soft_dropping(soft_dropping),
    .reset_soft_drop_score(reset_soft_drop_score),
    .commit_soft_drop_score(commit_soft_drop_score),
    .score(score),
    .lines_burned_bcd(lines_burned_bcd)
  );

  wire[3:0] field_rendering_x;
  wire[4:0] field_rendering_y;
  wire[2:0] field_rendering_data;

  wire[3:0] field_x;
  wire[4:0] field_y;
  wire field_write_enable;
  wire[2:0] field_din;
  wire[2:0] field_dout;

  field field_inst (
    .clk(clk1x),

    .x_coord(field_x),
    .y_coord(field_y),
    .write_enable(field_write_enable),
    .din(field_din),
    .dout(field_dout),

    .rendering_x(field_rendering_x),
    .rendering_y(field_rendering_y),
    .rendering_dout(field_rendering_data)
  );

  wire start_burn;
  wire burn_done;

  burn burn_inst(
    .clk(clk1x),

    .start(start_burn),
    .done(burn_done),

    .field_x(field_x),
    .field_y(field_y),

    //.field_read_enable(),
    .field_cell_read_value(field_dout),

    .field_write_enable(field_write_enable),
    .field_cell_write_value(field_din),

    .line_burned(line_burned),
    .commit_burned_lines(commit_burned_lines)
  );

  wire[2:0] piece_movement;

  wire[1:0] piece_rotation_signal = {rotate_ccw_just_pressed, rotate_cw_just_pressed};

  wire[1:0] current_piece_read_index;
  wire[3:0] current_piece_cell_x;
  wire[4:0] current_piece_cell_y;

  wire[2:0] current_piece_type;

  piece piece_inst(
    .clk(clk1x),

    //.spawned_type() TODO: Read from next_piece.
    
    .movement_in(piece_movement),
    .rotation_in(piece_rotation_signal),

    .read_index(current_piece_read_index),
    .cell_x(current_piece_cell_x),
    .cell_y(current_piece_cell_y),
    .type(current_piece_type)
  );

  game_loop game_loop_inst(
    .clk(clk1x),
    
    //.current_level() TODO
    
    .piece_movement(piece_movement),

    // .current_piece_read_enable()
    .current_piece_read_index_out(current_piece_read_index),
    .current_piece_read_cell_x(current_piece_cell_x),
    .current_piece_read_cell_y(current_piece_cell_y),

    // .current_piece_center_y(), TODO: expose in piece module.
    .current_piece_type(current_piece_type),

    .field_x(),
    .field_y(),

    .field_read_enable(),
    .field_cell_read_value(field_dout),

    .field_write_enable(),
    .field_cell_write_value(),

    .start_burn(start_burn),
    .burn_done(burn_done),

    // .start_lose_check(), TODO
    .lose_done(1), // TODO

    .generate_new_piece(generate_next_piece),

    .soft_dropping_movement(soft_dropping),
    .reset_soft_drop_score(reset_soft_drop_score),
    .commit_soft_drop_score(commit_soft_drop_score)
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
