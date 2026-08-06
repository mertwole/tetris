module game_loop(
    input wire clk,

    input wire[4:0] current_level,

    output reg[1:0] piece_movement = 'b00,

    output reg current_piece_read_enable = 0,
    output wire[1:0] current_piece_read_index,

    input wire[3:0] current_piece_read_cell_x,
    input wire[4:0] current_piece_read_cell_y,

    output reg field_read_enable = 0,

    output reg[3:0] field_x,
    output reg[4:0] field_y,
    
    input wire[2:0] field_cell_read_value
);

localparam CLK_PER_FRAME = 100;

localparam STATE_INIT = 'b0000;
localparam STATE_PROCESSING_INPUT = 'b0001;
localparam STATE_ARE = 'b0010;
localparam STATE_GRAVITY = 'b0011;
localparam STATE_PREPARE_TO_SETTLEMENT_CHECK = 'b0100;
localparam STATE_SETTLEMENT_CHECK = 'b0101;
localparam STATE_SETTLE = 'b0110;

reg[3:0] state = STATE_INIT;

reg soft_dropping = 0;
reg[4:0] are_timer = 0;
reg[5:0] frames_from_last_fall = 0;
reg[2:0] settlement_check_step = 0;

assign current_piece_read_index = settlement_check_step[1:0];
wire[5:0] current_gravity = soft_dropping ? 2 : gravity_by_level(current_level);

always @(posedge clk) begin
    case (state)
        STATE_INIT: begin
            // Initialize piece, field and so on.
        end
        STATE_PROCESSING_INPUT: begin
            // TODO

            state <= STATE_ARE;
        end
        STATE_ARE: begin
            are_timer <= are_timer - 1;
            if (are_timer == 1) begin
                state <= STATE_GRAVITY;
            end
        end
        STATE_GRAVITY: begin
            if (frames_from_last_fall + 1 >= current_gravity) begin
                frames_from_last_fall <= 0;

                // TODO: Increment soft drop score;

                piece_movement <= 'b01; // TODO: use param.
                current_piece_read_enable <= 1;
                settlement_check_step <= 0;
                
                state <= STATE_PREPARE_TO_SETTLEMENT_CHECK;
            end else begin
                frames_from_last_fall <= frames_from_last_fall + 1;
            end
        end
        STATE_PREPARE_TO_SETTLEMENT_CHECK: begin
            piece_movement <= 'b00;

            field_read_enable <= 1;
            field_x <= current_piece_read_cell_x;
            field_y <= current_piece_read_cell_y;
            settlement_check_step <= settlement_check_step + 1;

            state <= STATE_SETTLEMENT_CHECK;
        end
        STATE_SETTLEMENT_CHECK: begin
            if (settlement_check_step == 4) begin
                if (field_cell_read_value != 'b000) begin
                    state <= STATE_SETTLED;
                end else begin
                    state <= // TODO: Transition to the state where the piece is not settled.
                end
            end else begin
                settlement_check_step <= settlement_check_step + 1;

                field_x <= current_piece_read_cell_x;
                field_y <= current_piece_read_cell_y;

                if (field_cell_read_value != 'b000) begin
                    state <= STATE_SETTLED;
                end
            end
        end
        SETTLED: begin
            current_piece_read_enable <= 0;
            field_read_enable <= 0;
            piece_movement <= 'b01; // TODO: Use movement Up.

            // - Update ARE timer.
        end
        
        // - Write the current piece cells to the field.
        // - If soft dropping update the score with soft drop score 
        //        + reset soft drop score(unconditionally) + disable soft dropping
        // - Iterate over burn
        // - Generate new piece
        // - Process lose
        // - Render
        // - Padding delay
    endcase
end

function [5:0] gravity_by_level(input [4:0] level);
	begin
        case(level) 
            0: gravity_by_level = 48;
            1: gravity_by_level = 43;
            2: gravity_by_level = 38;
            3: gravity_by_level = 33;
            4: gravity_by_level = 28;
            5: gravity_by_level = 23;
            6: gravity_by_level = 18;
            7: gravity_by_level = 13;
            8: gravity_by_level = 8;
            9: gravity_by_level = 6;
            10, 11, 12: gravity_by_level = 5;
            13, 14, 15: gravity_by_level = 4;
            16, 17, 18: gravity_by_level = 3;
            19, 20, 21, 22, 23, 24, 25, 26, 27, 28: gravity_by_level = 2;
            default: gravity_by_level = 1;
        endcase
    end
endfunction

endmodule