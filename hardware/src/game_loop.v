module game_loop(
    input wire clk,

    // A current level.
    input wire[4:0] current_level,

    // Move the current piece.
    output reg[2:0] piece_movement = 'b000,

    // Enable read for the current piece.
    //
    // When it's enabled, piece cell coordinates will appear on `current_piece_read_cell_x` and 
    // `current_piece_read_cell_y` when `current_piece_read_index_out` is set to the corresponding cell index.
    output reg current_piece_read_enable = 0,
    // An index of the current piece cell that's being read.
    output wire[1:0] current_piece_read_index_out,
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
    output reg[2:0] field_cell_write_value,

    // Start processing the burn.
    output reg start_burn = 0,
    // Signalizes that the burn has completed.
    input wire burn_done,

    // Start checking for lose.
    output reg start_lose_check = 0,
    // Signalizes that the lose check/animation has completed.
    input wire lose_done,

    // Randomly generate the new piece.
    output reg generate_new_piece = 0,

    // Signalize a single movement in the soft drop mode.
    output reg soft_dropping_movement = 0,
    // Reset current soft drop score.
    output reg reset_soft_drop_score = 0,
    // Commit the soft drop score.
    output reg commit_soft_drop_score = 0
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
localparam STATE_PREPARE_TO_PUT_PIECE_TO_FIELD = 'b1011;
localparam STATE_PUT_PIECE_TO_FIELD = 'b1100;
localparam STATE_RENDER = 'b1101;
localparam STATE_REMOVE_PIECE_FROM_FIELD = 'b1110;
localparam STATE_PADDING = 'b1111;

localparam PIECE_MOVEMENT_NONE = 'b000;
localparam PIECE_MOVEMENT_DOWN = 'b001;
localparam PIECE_MOVEMENT_LEFT = 'b010;
localparam PIECE_MOVEMENT_RIGHT = 'b011;
localparam PIECE_MOVEMENT_UP = 'b100;

reg[3:0] state = STATE_INIT;

localparam CLK_PER_FRAME = 1_000_000;

reg[17:0] current_frame_duration = 0;

reg soft_dropping = 0;
reg[4:0] are_timer = 0;
reg[5:0] frames_from_last_fall = 0;

reg[2:0] current_piece_read_index = 0;
assign current_piece_read_index_out = current_piece_read_index[1:0];

wire[5:0] current_gravity = soft_dropping ? 2 : gravity_by_level(current_level);

always @(posedge clk) begin
    current_frame_duration <= current_frame_duration + 1;

    case (state)
        STATE_INIT: begin
            generate_new_piece <= 1;

            // TODO: Initialize piece, field and so on.

            state <= STATE_PROCESSING_INPUT;
        end
        STATE_PROCESSING_INPUT: begin
            generate_new_piece <= 0;
            
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

                if (soft_dropping) begin
                    soft_dropping_movement <= 1;
                end

                piece_movement <= PIECE_MOVEMENT_DOWN;
                current_piece_read_enable <= 1;
                current_piece_read_index <= 0;
                
                state <= STATE_PREPARE_TO_SETTLEMENT_CHECK;
            end else begin
                frames_from_last_fall <= frames_from_last_fall + 1;

                state <= STATE_PROCESSING_INPUT;
            end
        end
        STATE_PREPARE_TO_SETTLEMENT_CHECK: begin
            soft_dropping_movement <= 0;

            piece_movement <= PIECE_MOVEMENT_NONE;

            field_read_enable <= 1;
            field_x <= current_piece_read_cell_x;
            field_y <= current_piece_read_cell_y;
            current_piece_read_index <= current_piece_read_index + 1;

            state <= STATE_SETTLEMENT_CHECK;
        end
        STATE_SETTLEMENT_CHECK: begin
            if (current_piece_read_index == 4) begin
                if (field_cell_read_value != 'b000) begin
                    state <= STATE_SETTLE;
                end else begin
                    state <= STATE_PREPARE_TO_PUT_PIECE_TO_FIELD;
                end
            end else begin
                current_piece_read_index <= current_piece_read_index + 1;

                field_x <= current_piece_read_cell_x;
                field_y <= current_piece_read_cell_y;

                if (field_cell_read_value != 'b000) begin
                    state <= STATE_SETTLE;
                end
            end
        end
        STATE_SETTLE: begin
            field_read_enable <= 0;
            piece_movement <= PIECE_MOVEMENT_UP;

            are_timer <= are_by_piece_position(current_piece_center_y);

            if (soft_dropping) begin
                commit_soft_drop_score <= 1;
            end
            soft_dropping <= 0;

            current_piece_read_enable <= 1;
            current_piece_read_index <= 0;

            state <= STATE_PREPARE_TO_WRITE_PIECE_TO_FIELD;
        end
        STATE_PREPARE_TO_WRITE_PIECE_TO_FIELD: begin
            commit_soft_drop_score <= 0;

            piece_movement <= PIECE_MOVEMENT_NONE;

            field_write_enable <= 1;
            field_x <= current_piece_read_cell_x;
            field_y <= current_piece_read_cell_y;
            current_piece_read_index <= current_piece_read_index + 1;

            state <= STATE_WRITE_PIECE_TO_FIELD;
        end
        STATE_WRITE_PIECE_TO_FIELD: begin
            if (current_piece_read_index == 4) begin
                field_write_enable <= 0;
                current_piece_read_enable <= 0;
                start_burn <= 1;

                state <= STATE_BURNING;
            end else begin
                current_piece_read_index <= current_piece_read_index + 1;

                field_x <= current_piece_read_cell_x;
                field_y <= current_piece_read_cell_y;
            end
        end
        STATE_BURNING: begin
            start_burn <= 0;

            if (burn_done) begin
                generate_new_piece <= 1;
                start_lose_check <= 1;

                state <= STATE_CHECK_LOSE;
            end
        end
        STATE_CHECK_LOSE: begin
            generate_new_piece <= 0;
            start_lose_check <= 0;

            if(lose_done) begin
                state <= STATE_PREPARE_TO_PUT_PIECE_TO_FIELD; // TODO: Check the lose result.
            end
        end
        STATE_PREPARE_TO_PUT_PIECE_TO_FIELD: begin
            current_piece_read_enable <= 1;
            current_piece_read_index <= 0;
            field_cell_write_value <= current_piece_type;

            state <= STATE_PUT_PIECE_TO_FIELD;
        end
        STATE_PUT_PIECE_TO_FIELD: begin
            field_x <= current_piece_read_cell_x;
            field_y <= current_piece_read_cell_y;
            field_write_enable <= 1;

            if (current_piece_read_index == 3) begin
                current_piece_read_enable <= 0;
                
                state <= STATE_RENDER;
            end else begin
                current_piece_read_index <= current_piece_read_index + 1;
            end
        end
        STATE_RENDER: begin
            field_write_enable <= 0;

            // TODO: Implement rendering later.

            current_piece_read_enable <= 1;
            current_piece_read_index <= 0;
            field_cell_write_value <= 'b000;

            state <= STATE_REMOVE_PIECE_FROM_FIELD;
        end
        STATE_REMOVE_PIECE_FROM_FIELD: begin
            field_x <= current_piece_read_cell_x;
            field_y <= current_piece_read_cell_y;
            field_write_enable <= 1;

            if (current_piece_read_index == 3) begin
                current_piece_read_enable <= 0;
                
                state <= STATE_PADDING;
            end else begin
                current_piece_read_index <= current_piece_read_index + 1;
            end
        end
        STATE_PADDING: begin
            field_write_enable <= 0;

            if (current_frame_duration == CLK_PER_FRAME - 1) begin
                current_frame_duration <= 0;    
                state <= STATE_PROCESSING_INPUT;   
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