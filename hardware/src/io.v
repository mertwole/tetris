module io(
    input wire clk,

    output reg[10:0] digits = 'b10000000000,
    output reg[6:0] segments = 'b1111111,

    output reg[7:0] next_piece_leds = 0,

    output wire[3:0] game_state_leds,

    input wire button_start,
    input wire button_rotate_cw,
    input wire button_rotate_ccw,
    input wire button_right,
    input wire button_down,
    input wire button_left,

    input wire[19:0] score,
    input wire[11:0] lines_burned_bcd,

    output wire[1:0] next_piece_read_index,
    input wire[1:0] next_piece_cell_x,
    input wire next_piece_cell_y,
    input wire[2:0] next_piece_type,

    input wire[3:0] game_state,

    output wire button_start_pressed,
    output wire button_rotate_cw_pressed,
    output wire button_rotate_ccw_pressed,
    output wire button_right_pressed,
    output wire button_down_pressed,
    output wire button_left_pressed
);

assign game_state_leds = game_state;

integer digit_switch_counter = 0;

always @(posedge clk) begin
    if (digit_switch_counter == 10_000) begin
        digit_switch_counter <= 0;

        digits <= {digits[0], digits[10:1]};
    end else begin
        digit_switch_counter <= digit_switch_counter + 1;
    end
end

reg[43:0] score_scratch_space = 0;
wire[23:0] score_bcd = score_scratch_space[43:20];
reg[5:0] score_dd_step = 0;

wire[3:0] score_scratch_space_next_0 = score_scratch_space[43:40] >= 5 ? score_scratch_space[43:40] + 3 : score_scratch_space[43:40];
wire[3:0] score_scratch_space_next_1 = score_scratch_space[39:36] >= 5 ? score_scratch_space[39:36] + 3 : score_scratch_space[39:36];
wire[3:0] score_scratch_space_next_2 = score_scratch_space[35:32] >= 5 ? score_scratch_space[35:32] + 3 : score_scratch_space[35:32];
wire[3:0] score_scratch_space_next_3 = score_scratch_space[31:28] >= 5 ? score_scratch_space[31:28] + 3 : score_scratch_space[31:28];
wire[3:0] score_scratch_space_next_4 = score_scratch_space[27:24] >= 5 ? score_scratch_space[27:24] + 3 : score_scratch_space[27:24];
wire[3:0] score_scratch_space_next_5 = score_scratch_space[23:20] >= 5 ? score_scratch_space[23:20] + 3 : score_scratch_space[23:20];

wire[43:0] score_scratch_space_next = {
    score_scratch_space_next_0, 
    score_scratch_space_next_1, 
    score_scratch_space_next_2, 
    score_scratch_space_next_3, 
    score_scratch_space_next_4, 
    score_scratch_space_next_5, 
    score_scratch_space[19:0]
};

always @(posedge clk) begin
    if (score_dd_step == 40) begin
        score_dd_step <= 0;

        case (digits)
            'b10000000000: begin
                segments <= bcd_to_digit(score_scratch_space[43:40]);
            end
            'b01000000000: begin
                segments <= bcd_to_digit(score_scratch_space[39:36]);
            end
            'b00100000000: begin
                segments <= bcd_to_digit(score_scratch_space[35:32]);
            end
            'b00010000000: begin
                segments <= bcd_to_digit(score_scratch_space[31:28]);
            end
            'b00001000000: begin
                segments <= bcd_to_digit(score_scratch_space[27:24]);
            end
            'b00000100000: begin
                segments <= bcd_to_digit(score_scratch_space[23:20]);
            end
            'b00000010000: begin
                segments <= bcd_to_digit(lines_burned_bcd[11:8]);
            end
            'b00000001000: begin
                segments <= bcd_to_digit(lines_burned_bcd[7:4]);
            end
            'b00000000100: begin
                segments <= bcd_to_digit(lines_burned_bcd[3:0]);
            end
            'b00000000010: begin
                segments <= bcd_to_digit(lines_burned_bcd[11:8]);
            end
            'b00000000001: begin
                segments <= bcd_to_digit(lines_burned_bcd[7:4]);
            end
        endcase

        score_scratch_space <= {24'd0, score};
    end else begin
        score_dd_step <= score_dd_step + 1;

        if (score_dd_step[0] == 0) begin
            score_scratch_space <= score_scratch_space_next;
        end else begin
            score_scratch_space <= score_scratch_space << 1;
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