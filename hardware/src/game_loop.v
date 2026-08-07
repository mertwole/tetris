module game_loop(
    input wire clk,

    // A current level.
    input wire[4:0] current_level,

    // Move the current piece.
    output reg[1:0] piece_movement = 'b00,

    // Enable read for the current piece.
    //
    // When it's enabled, piece cell coordinates will appear on `current_piece_read_cell_x` and 
    // `current_piece_read_cell_y` when `current_piece_read_index` is set to the corresponding cell index.
    output reg current_piece_read_enable = 0,
    // An index of the current piece cell that's being read.
    output wire[1:0] current_piece_read_index,
    // X coordinate of the current piece cell that's being read.
    input wire[3:0] current_piece_read_cell_x,
    // Y coordinate of the current piece cell that's being read.
    input wire[4:0] current_piece_read_cell_y,

    // Y coordinate of the current piece center.
    input wire[4:0] current_piece_center_y,

    // A type of the current piece.
    input wire[2:0] current_piece_type,

    // X coordinate of the field cell, used for both read and write operations.
    output reg[3:0] field_x,
    // Y coordinate of the field cell, used for both read and write operations.
    output reg[4:0] field_y,

    // Request to read the field cell at coordinates (`field_x`, `field_y`).
    //
    // NOTE: Will never be active simultaneously with `field_write_enable`.
    output reg field_read_enable = 0,
    // Result of the field read operation initiated by asserting `field_read_enable`.
    input wire[2:0] field_cell_read_value,

    // Request to write the value `field_cell_write_value` to the field cell at coordinates 
    // (`field_x`, `field_y`).
    //
    // NOTE: Will never be active simultaneously with `field_read_enable`.
    output reg field_write_enable = 0,
    // The value that will be written to the field cell at coordinates (`field_x`, `field_y`) when 
    // `field_write_enable` is asserted.
    output wire[2:0] field_cell_write_value,

    // Start processing the burn.
    output reg start_burn = 0,
    // Signalizes that the burn has completed.
    input wire burn_done,

    // Start processing the lose.
    output reg start_lose = 0,
    // Signalizes that the lose has completed.
    input wire lose_done,

    // Randomly generate the new piece.
    output reg generate_new_piece = 0
);

localparam STATE_INIT = 'b0000;
localparam STATE_PROCESSING_INPUT = 'b0001;
localparam STATE_ARE = 'b0010;
localparam STATE_GRAVITY = 'b0011;
localparam STATE_PREPARE_TO_SETTLEMENT_CHECK = 'b0100;
localparam STATE_SETTLEMENT_CHECK = 'b0101;
localparam STATE_SETTLE = 'b0110;
localparam STATE_PREPARE_TO_WRITE_PIECE_TO_FIELD = 'b0111;
localparam STATE_WRITE_PIECE_TO_FIELD = 'b1000;
localparam STATE_BURNING = 'b1001;
localparam STATE_CHECK_LOSE = 'b1010;
localparam STATE_RENDER = 'b1011;
localparam STATE_PADDING = 'b1100;

reg[3:0] state = STATE_INIT;

localparam CLK_PER_FRAME = 100_000;

reg[17:0] current_frame_duration = 0;

reg soft_dropping = 0;
reg[4:0] are_timer = 0;
reg[5:0] frames_from_last_fall = 0;
reg[2:0] settlement_check_step = 0;

assign current_piece_read_index = settlement_check_step[1:0];
wire[5:0] current_gravity = soft_dropping ? 2 : gravity_by_level(current_level);

// Game loop can only write the piece type to the field.
assign field_cell_write_value = current_piece_type; 

always @(posedge clk) begin
    current_frame_duration <= current_frame_duration + 1;

    case (state)
        STATE_INIT: begin
            // TODO: Initialize piece, field and so on.
        end
        STATE_PROCESSING_INPUT: begin
            // TODO: Implement.

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
                    state <= STATE_RENDER;
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
        STATE_SETTLED: begin
            field_read_enable <= 0;
            piece_movement <= 'b01; // TODO: Use movement Up.

            are_timer <= are_by_piece_position(current_piece_center_y);

            // TODO:
            // - If soft dropping update the score with soft drop score 
            //        + reset soft drop score(unconditionally) + disable soft dropping

            current_piece_read_enable <= 1;
            // TODO: Rename as it's used in 2 places.
            settlement_check_step <= 0;

            state <= STATE_PREPARE_TO_WRITE_PIECE_TO_FIELD;
        end
        STATE_PREPARE_TO_WRITE_PIECE_TO_FIELD: begin
            field_write_enable <= 1;
            field_x <= current_piece_read_cell_x;
            field_y <= current_piece_read_cell_y;
            settlement_check_step <= settlement_check_step + 1;

            state <= STATE_WRITE_PIECE_TO_FIELD;
        end
        STATE_WRITE_PIECE_TO_FIELD: begin
            if (settlement_check_step == 4) begin
                field_write_enable <= 0;
                current_piece_read_enable <= 0;
                start_burn <= 1;

                state <= STATE_BURNING;
            end else begin
                settlement_check_step <= settlement_check_step + 1;

                field_x <= current_piece_read_cell_x;
                field_y <= current_piece_read_cell_y;
            end
        end
        STATE_BURNING: begin
            start_burn <= 0;

            if (burn_done) begin
                generate_new_piece <= 1;
                start_lose <= 1;

                state <= STATE_CHECK_LOSE;
            end
        end
        STATE_CHECK_LOSE: begin
            generate_new_piece <= 0;
            start_lose <= 0;

            if(lose_done) begin
                state <= STATE_RENDER; // TODO: Check the result.
            end
        end
        STATE_RENDER: begin
            // TODO: Implement it later.
            state <= STATE_PADDING;
        end
        STATE_PADDING: begin
            if (current_frame_duration == CLK_PER_FRAME - 1) begin
                current_frame_duration <= 0;       
            end
        end
    endcase
end

function [4:0] are_by_piece_position(input [4:0] current_piece_y);
    begin
        are_by_piece_position = 10 + (current_piece_y >> 2) << 1;
    end
endfunction

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