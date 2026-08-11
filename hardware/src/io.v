module io(
    input wire clk,

    output reg[10:0] digits = 'b10000000000,
    output reg[6:0] segments = 'b1111111,

    output reg[7:0] next_piece_leds = 0,

    output reg[3:0] game_state_leds = 0,

    input wire button_start,
    input wire button_rotate_cw,
    input wire button_rotate_ccw,
    input wire button_right,
    input wire button_down,
    input wire button_left,

    input wire[19:0] score, // + 28
    input wire[8:0] lines_burned, // + 12
    input wire[4:0] level, // + 8

    output wire[1:0] next_piece_read_index,
    input wire[1:0] next_piece_cell_x,
    input wire next_piece_cell_y,
    input wire[2:0] next_piece_type,

    input wire[1:0] game_state,

    output wire button_start_pressed,
    output wire button_rotate_cw_pressed,
    output wire button_rotate_ccw_pressed,
    output wire button_right_pressed,
    output wire button_down_pressed,
    output wire button_left_pressed
);

integer digit_switch_counter = 0;

always @(posedge clk) begin
    if (digit_switch_counter == 10_000) begin
        digit_switch_counter <= 0;

        digits <= {digits[0], digits[10:1]};
    end else begin
        digit_switch_counter <= digit_switch_counter + 1;
    end
end

reg[12:0] level_scratch_space = 0;
wire[7:0] level_bcd = level_scratch_space[12:5];
reg[20:0] level_dd_step = 0;

wire[3:0] level_scratch_space_next_0 = level_scratch_space[12:9] >= 5 ? level_scratch_space[12:9] + 3 : level_scratch_space[12:9];
wire[3:0] level_scratch_space_next_1 = level_scratch_space[8:5] >= 5 ? level_scratch_space[8:5] + 3 : level_scratch_space[8:5];
wire[12:0] level_scratch_space_next = {
    level_scratch_space_next_0, 
    level_scratch_space_next_1, 
    level_scratch_space[4:0]
};

always @(posedge clk) begin
    if(level_dd_step == 10) begin
        level_dd_step <= 0;

        case (digits)
            'b00000000010: begin
                segments <= bcd_to_digit(level_bcd[7:4]);
            end
            'b00000000001: begin
                segments <= bcd_to_digit(level_bcd[3:0]);
            end
            default: begin
                segments <= 0;
            end
        endcase

        level_scratch_space <= {8'b0000_0000, level};
    end else begin
        level_dd_step <= level_dd_step + 1;

        if (level_dd_step[0] == 0) begin
            level_scratch_space <= level_scratch_space_next;
        end else begin
            level_scratch_space <= level_scratch_space << 1;
        end
    end
end

function [6:0] bcd_to_digit(input [3:0] bcd);
    begin
        case(bcd)
            0: bcd_to_digit = 'b1111110;
            1: bcd_to_digit = 'b0110000;
            2: bcd_to_digit = 'b1101101;
            3: bcd_to_digit = 'b1111001;
            4: bcd_to_digit = 'b0110011;
            5: bcd_to_digit = 'b1011011;
            6: bcd_to_digit = 'b1011111;
            7: bcd_to_digit = 'b1110000;
            8: bcd_to_digit = 'b1111111;
            9: bcd_to_digit = 'b1111011;
            default: bcd_to_digit = 'b1111001;
        endcase
    end 
endfunction

reg[2:0] next_piece_read_stage = 0;
assign next_piece_read_index = next_piece_read_stage[1:0];

reg[7:0] next_piece_leds_buffer = 0;

always @(posedge clk) begin
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

always @* begin
    case (game_state)
        'b00: game_state_leds = 'b1000;
        'b01: game_state_leds = 'b0100;
        'b10: game_state_leds = 'b0010;
        'b11: game_state_leds = 'b0001;
    endcase
end

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

endmodule