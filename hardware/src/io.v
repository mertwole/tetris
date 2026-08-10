module io(
    input wire clk,

    output reg[10:0] digits = 'b11111111111,
    output reg[6:0] segments = 'b1111111,

    output reg[7:0] next_piece_leds = 0,

    output reg[3:0] game_state_leds = 0,

    input wire button_start,
    input wire button_rotate_cw,
    input wire button_rotate_ccw,
    input wire button_right,
    input wire button_down,
    input wire button_left,

    output wire button_start_pressed,
    output wire button_rotate_cw_pressed,
    output wire button_rotate_ccw_pressed,
    output wire button_right_pressed,
    output wire button_down_pressed,
    output wire button_left_pressed,
    
    output wire[1:0] next_piece_read_index,
    input wire[1:0] next_piece_cell_x,
    input wire next_piece_cell_y,
    input wire[2:0] next_piece_type,

    input wire[1:0] game_state
);

reg[1:0] button_start_buffer = 0;
reg[1:0] button_rotate_cw_buffer = 0;
reg[1:0] button_rotate_ccw_buffer = 0;
reg[1:0] button_right_buffer = 0;
reg[1:0] button_down_buffer = 0;
reg[1:0] button_left_buffer = 0;

assign button_start_pressed = button_start_buffer[0];
assign button_rotate_cw_pressed = button_rotate_cw_buffer[0];
assign button_rotate_ccw_pressed = button_rotate_ccw_buffer[0];
assign button_right_pressed = button_right_buffer[0];
assign button_down_pressed = button_down_buffer[0];
assign button_left_pressed = button_left_buffer[0];

always @(posedge clk) begin
    button_start_buffer <= {button_start, button_start_buffer[1]};
    button_rotate_cw_buffer <= {button_rotate_cw, button_rotate_cw_buffer[1]};
    button_rotate_ccw_buffer <= {button_rotate_ccw, button_rotate_ccw_buffer[1]};
    button_right_buffer <= {button_right, button_right_buffer[1]};
    button_down_buffer <= {button_down, button_down_buffer[1]};
    button_left_buffer <= {button_left, button_left_buffer[1]};
end

always @* begin
    case (game_state)
        'b00: game_state_leds = 'b1000;
        'b01: game_state_leds = 'b0100;
        'b10: game_state_leds = 'b0010;
        'b11: game_state_leds = 'b0001;
    endcase
end

reg[2:0] next_piece_read_stage = 0;
assign next_piece_read_index = next_piece_read_stage[1:0];

reg[7:0] next_piece_leds_buffer = 0;

always @(posedge clk) begin
    digits <= {digits[0], digits[10:1]};

    if (next_piece_read_stage == 4) begin
        next_piece_read_stage <= 0;

        next_piece_leds_buffer <= 0;
        if (next_piece_type == 'b000) begin
            next_piece_leds <= 0;
        end else begin
            next_piece_leds <= next_piece_leds_buffer;
        end
    end else begin
        next_piece_read_stage <= next_piece_read_stage + 1;

        next_piece_leds_buffer[{next_piece_cell_y, next_piece_cell_x}] <= 1;
    end
end

endmodule