module game_loop(
    input wire clk,

    // Button for clockwise piece rotation.
    input wire button_rotate_cw,
    // Button for counter-clockwise piece rotation.
    input wire button_rotate_ccw,
    // Button for moving the piece left.
    input wire button_left,
    // Button for moving the piece right.
    input wire button_right,
    // Button for soft drop activation.
    input wire button_down,
    // A button that may start, stop or pause the game.
    input wire button_start,

    // A current level.
    input wire[4:0] current_level,

    // Move the current piece.
    output reg[2:0] piece_movement = 'b000,
    // Rotate the current piece.
    output reg[1:0] piece_rotation = 'b00,

    // Y coordinate of the current piece center.
    input wire[4:0] current_piece_center_y,

    // A type of the current piece.
    input wire[2:0] current_piece_type,

    // Start processing the burn.
    output reg start_burn = 0,
    // Signalizes that the burn has completed.
    input wire burn_done,

    // Start checking for lose.
    output reg start_lose_check = 0,
    // The result of the lose check.
    input wire[1:0] lose_result,

    // Randomly generate the new piece.
    output reg generate_new_piece = 0,

    // Signalize a single movement in the soft drop mode.
    output reg soft_dropping_movement = 0,
    // Reset current soft drop score.
    output reg reset_soft_drop_score = 0,
    // Commit the soft drop score.
    output reg commit_soft_drop_score = 0,

    // Reset all the scores.
    output reg reset_scores = 0,

    // The current game state.
    //
    // 'b00 - initial
    // 'b01 - playing
    // 'b10 - paused
    // 'b11 - game over
    output wire[1:0] game_state_out,

    // Start an operation on the current piece.
    output reg[1:0] start_piece_operation,
    // Result of the piece operation started by setting `piece_start_operation`.
    input wire[1:0] piece_operation_result
);

localparam STATE_INIT = 'b0000;
localparam STATE_PROCESSING_INPUT = 'b0001;
localparam STATE_BOUNDS_CHECK = 'b0010;
localparam STATE_ARE = 'b0011;
localparam STATE_GRAVITY = 'b0100;
localparam STATE_SETTLEMENT_CHECK = 'b0101;
localparam STATE_SETTLE = 'b0110;
localparam STATE_WRITE_PIECE_TO_FIELD = 'b0111;
localparam STATE_BURNING = 'b1000;
localparam STATE_CHECK_LOSE = 'b1001;
localparam STATE_PUT_PIECE_TO_FIELD = 'b1010;
localparam STATE_RENDER = 'b1011;
localparam STATE_REMOVE_PIECE_FROM_FIELD = 'b1100;
localparam STATE_PADDING = 'b1101;

localparam PIECE_MOVEMENT_NONE = 'b000;
localparam PIECE_MOVEMENT_DOWN = 'b001;
localparam PIECE_MOVEMENT_LEFT = 'b010;
localparam PIECE_MOVEMENT_RIGHT = 'b011;
localparam PIECE_MOVEMENT_UP = 'b100;

localparam PIECE_OPERATION_NONE = 'b00;
localparam PIECE_OPERATION_COLLISION_CHECK = 'b01;
localparam PIECE_OPERATION_WRITE = 'b10;
localparam PIECE_OPERATION_ERASE = 'b11;

localparam PIECE_NO_COLLISIONS_DETECTED = 'b01;
localparam PIECE_COLLISION_DETECTED = 'b10;

localparam GAME_STATE_INIT = 'b00;
localparam GAME_STATE_PLAY = 'b01;
localparam GAME_STATE_PAUSE = 'b10;
localparam GAME_STATE_GAME_OVER = 'b11;

reg[3:0] state = STATE_INIT;

reg[1:0] game_state = GAME_STATE_INIT;
assign game_state_out = game_state;

reg rotate_cw_prev_state = 0;
reg rotate_ccw_prev_state = 0;
reg left_prev_state = 0;
reg right_prev_state = 0;
reg start_prev_state = 0;

wire rotate_cw_just_pressed = button_rotate_cw & !rotate_cw_prev_state;
wire rotate_ccw_just_pressed = button_rotate_ccw & !rotate_ccw_prev_state;
wire start_just_pressed = button_start & !start_prev_state;

wire left_just_pressed = button_left & !left_prev_state;
wire right_just_pressed = button_right & !right_prev_state;

localparam CLK_PER_FRAME = 1_000_000;

integer current_frame_duration = 0;

reg soft_dropping = 0;
reg[4:0] are_timer = 0;
reg[5:0] frames_from_last_fall = 0;

wire[5:0] current_gravity = soft_dropping ? 2 : gravity_by_level(current_level);

integer init_stage = 0;

reg[2:0] piece_movement_inverse = 0;
reg[1:0] piece_rotation_inverse = 0;

always @(posedge clk) begin
    current_frame_duration <= current_frame_duration + 1;

    case (state)
        STATE_INIT: begin
            init_stage <= init_stage + 1;

            case(init_stage)
                0: begin
                    generate_new_piece <= 1;
                end
                1: begin
                    generate_new_piece <= 0;
                end
                2: begin
                    generate_new_piece <= 1;
                    state <= STATE_PROCESSING_INPUT;
                end
            endcase

            // TODO: Initialize piece, field and so on.
        end
        STATE_PROCESSING_INPUT: begin
            generate_new_piece <= 0;
            
            rotate_cw_prev_state = button_rotate_cw;
            rotate_ccw_prev_state = button_rotate_ccw;
            left_prev_state = button_left;
            right_prev_state = button_right;
            start_prev_state = button_start;

            if (start_just_pressed) begin
                case (game_state) 
                    GAME_STATE_INIT: game_state <= GAME_STATE_PLAY;
                    GAME_STATE_PLAY: game_state <= GAME_STATE_PAUSE;
                    GAME_STATE_PAUSE: game_state <= GAME_STATE_PLAY;
                    GAME_STATE_GAME_OVER: game_state <= GAME_STATE_INIT;
                endcase

                // TODO: Set `start_piece_operation` inside of the corresponding case branch.
                start_piece_operation <= PIECE_OPERATION_WRITE;
                state <= STATE_PUT_PIECE_TO_FIELD;
            end else if(game_state == GAME_STATE_PLAY) begin
                piece_rotation <= {rotate_ccw_just_pressed, rotate_cw_just_pressed};
                piece_rotation_inverse <= ~{rotate_ccw_just_pressed, rotate_cw_just_pressed};

                soft_dropping <= button_down;

                // TODO: DAS.
                case ({left_just_pressed, right_just_pressed})
                    'b10: begin
                        piece_movement <= PIECE_MOVEMENT_LEFT;
                        piece_movement_inverse <= PIECE_MOVEMENT_RIGHT;
                    end
                    'b01: begin
                        piece_movement <= PIECE_MOVEMENT_RIGHT;
                        piece_movement_inverse <= PIECE_MOVEMENT_LEFT;
                    end
                    default: begin
                        piece_movement <= PIECE_MOVEMENT_NONE;
                        piece_movement_inverse <= PIECE_MOVEMENT_NONE;
                    end
                endcase

                start_piece_operation <= PIECE_OPERATION_COLLISION_CHECK;
                state <= STATE_BOUNDS_CHECK;
            end else begin 
                // TODO: Set `start_piece_operation` inside of the corresponding case branch.
                start_piece_operation <= PIECE_OPERATION_WRITE;
                state <= STATE_PUT_PIECE_TO_FIELD;
            end
        end
        STATE_BOUNDS_CHECK: begin
            soft_dropping_movement <= 0;
            
            if (start_piece_operation == PIECE_OPERATION_NONE) begin
                case(piece_operation_result) 
                    PIECE_COLLISION_DETECTED: begin
                        piece_movement <= piece_movement_inverse;
                        piece_rotation <= piece_rotation_inverse;

                        state <= STATE_ARE;
                    end
                    PIECE_NO_COLLISIONS_DETECTED: begin
                        state <= STATE_ARE;
                    end
                endcase
            end else begin
                piece_rotation <= 0;
                piece_movement <= PIECE_MOVEMENT_NONE;
                start_piece_operation <= PIECE_OPERATION_NONE;
            end
        end
        STATE_ARE: begin
            piece_movement <= 0;
            piece_rotation <= 0;

            if (are_timer <= 1) begin
                state <= STATE_GRAVITY;
            end else begin
                are_timer <= are_timer - 1;
                state <= STATE_RENDER;
            end
        end
        STATE_GRAVITY: begin
            if (frames_from_last_fall >= current_gravity) begin
                frames_from_last_fall <= 1;

                if (soft_dropping) begin
                    soft_dropping_movement <= 1;
                end

                piece_movement <= PIECE_MOVEMENT_DOWN;
                start_piece_operation <= PIECE_OPERATION_COLLISION_CHECK;
                
                state <= STATE_SETTLEMENT_CHECK;
            end else begin
                frames_from_last_fall <= frames_from_last_fall + 1;
                    
                start_piece_operation <= PIECE_OPERATION_WRITE;
                state <= STATE_PUT_PIECE_TO_FIELD;
            end
        end
        STATE_SETTLEMENT_CHECK: begin
            if(start_piece_operation == PIECE_OPERATION_NONE) begin
                case(piece_operation_result) 
                    PIECE_COLLISION_DETECTED: begin
                        piece_movement <= PIECE_MOVEMENT_UP;
                        state <= STATE_SETTLE;
                    end
                    PIECE_NO_COLLISIONS_DETECTED: begin
                        start_piece_operation <= PIECE_OPERATION_WRITE;
                        state <= STATE_PUT_PIECE_TO_FIELD;
                    end
                endcase
            end else begin
                start_piece_operation <= PIECE_OPERATION_NONE;
                soft_dropping_movement <= 0;
                piece_movement <= PIECE_MOVEMENT_NONE;
            end
        end
        STATE_SETTLE: begin
            piece_movement <= PIECE_MOVEMENT_NONE;

            are_timer <= are_by_piece_position(current_piece_center_y);

            if (soft_dropping) begin
                commit_soft_drop_score <= 1;
            end
            soft_dropping <= 0;

            start_piece_operation <= PIECE_OPERATION_WRITE;

            state <= STATE_WRITE_PIECE_TO_FIELD;
        end
        STATE_WRITE_PIECE_TO_FIELD: begin
            if(start_piece_operation == PIECE_OPERATION_NONE) begin
                if (piece_operation_result != 0) begin
                    start_burn <= 1;
                    state <= STATE_BURNING;
                end
            end else begin
                start_piece_operation <= PIECE_OPERATION_NONE;
                commit_soft_drop_score <= 0;
            end
        end
        STATE_BURNING: begin
            start_burn <= 0;

            if (!start_burn && burn_done) begin
                generate_new_piece <= 1;
                frames_from_last_fall <= 0;
                start_lose_check <= 1;

                state <= STATE_CHECK_LOSE;
            end
        end
        STATE_CHECK_LOSE: begin
            generate_new_piece <= 0;
            start_lose_check <= 0;

            if(!start_lose_check && (lose_result != 0)) begin
                if (lose_result == 'b10) begin
                    reset_scores <= 1;
                end

                state <= STATE_RENDER;
            end
        end
        STATE_PUT_PIECE_TO_FIELD: begin
            if(start_piece_operation == PIECE_OPERATION_NONE) begin
                if (piece_operation_result != 0) begin
                    state <= STATE_RENDER;
                end
            end else begin
                start_piece_operation <= PIECE_OPERATION_NONE;
            end
        end
        STATE_RENDER: begin
            reset_scores <= 0;

            // TODO: Implement rendering later.

            // TODO: Move this condition to the `STATE_PADDING`.
            // This delay is here because we're stopping state changes in a state where the current piece 
            // is written to the field, so the renderer which works async have the biggest chance of seeing
            // the field in the appropriate state.
            if (current_frame_duration == CLK_PER_FRAME - 1) begin
                current_frame_duration <= 0;

                start_piece_operation <= PIECE_OPERATION_ERASE;
                state <= STATE_REMOVE_PIECE_FROM_FIELD;  
            end
        end
        STATE_REMOVE_PIECE_FROM_FIELD: begin
            if(start_piece_operation == PIECE_OPERATION_NONE) begin
                if (piece_operation_result != 0) begin
                    state <= STATE_PADDING;
                end
            end else begin
                start_piece_operation <= PIECE_OPERATION_NONE;
            end
        end
        STATE_PADDING: begin
            //if (current_frame_duration == CLK_PER_FRAME - 1) begin
            //    current_frame_duration <= 0;    
                state <= STATE_PROCESSING_INPUT;   
            //end
        end
    endcase
end

function [4:0] are_by_piece_position(input [4:0] current_piece_y);
    begin
        are_by_piece_position = 10 + ((current_piece_y >> 2) << 1);
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