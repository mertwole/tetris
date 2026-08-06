module game_loop(
    input wire clk,

    input wire[4:0] current_level,

    output reg[1:0] piece_movement = 'b00
);

localparam CLK_PER_FRAME = 100;

localparam STATE_INIT = 'b0000;
localparam STATE_PROCESSING_INPUT = 'b0001;
localparam STATE_ARE = 'b0010;
localparam STATE_GRAVITY = 'b0011;
localparam STATE_SETTLEMENT = 'b0100;

reg[3:0] state = STATE_INIT;

reg soft_dropping = 0;
reg[4:0] are_timer = 0;
reg[5:0] frames_from_last_fall = 0;

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
                
                state <= STATE_SETTLEMENT;
            end else begin
                frames_from_last_fall <= frames_from_last_fall + 1;
            end
        end
        STATE_SETTLEMENT: begin
            piece_movement <= 'b00;

            // TODO: Check if the piece is settled.
        end
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