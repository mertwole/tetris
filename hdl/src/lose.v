module lose(
    input wire clk,

    // Start checking the current piece cells and playing the lose animation(if required).
    input wire start,
    // Result of the lose check.
    //
    // 'b00 - check is not yet complete
    // 'b01 - check is negative
    // 'b10 - check is positive
    // 'b11 - animation frame done
    output reg[1:0] result,

    // X coordinate of the field cell, used for both read and write operations.
    output reg[3:0] field_x,
    // Y coordinate of the field cell, used for both read and write operations.
    output reg[4:0] field_y,

    // Request to write the value `field_cell_write_value` to the field cell at coordinates 
    // (`field_x`, `field_y`).
    output reg field_write_enable = 0,
    // The value that will be written to the field cell at coordinates (`field_x`, `field_y`) when 
    // `field_write_enable` is asserted.
    output wire[2:0] field_cell_write_value,

    // Start an operation on the current piece.
    output reg[1:0] piece_start_operation = 0,
    // Result of the piece operation started by setting `piece_start_operation`.
    input wire[1:0] piece_operation_result
);

localparam STATE_IDLE = 'b000;
localparam STATE_SCANNING = 'b001;
localparam STATE_PREPARE_TO_ANIMATE = 'b010;
localparam STATE_ANIMATING = 'b011;
localparam STATE_ANIMATING_INTERRUPTED = 'b100;

localparam PIECE_OPERATION_NONE = 'b00;
localparam PIECE_OPERATION_COLLISION_CHECK = 'b01;

localparam PIECE_NO_COLLISIONS_DETECTED = 'b01;
localparam PIECE_COLLISION_DETECTED = 'b10;

localparam RESULT_NOT_COMPLETE = 'b00;
localparam RESULT_NEGATIVE = 'b01;
localparam RESULT_POSITIVE = 'b10;
localparam RESULT_ANIMATION_FRAME_DONE = 'b11;

reg[2:0] state = STATE_IDLE;

assign field_cell_write_value = 0; // Lose animation can only erase the cells.

always @(posedge clk) begin
    case(state)
        STATE_IDLE: begin
            if (start) begin
                result <= RESULT_NOT_COMPLETE;
                piece_start_operation <= PIECE_OPERATION_COLLISION_CHECK;

                state <= STATE_SCANNING;
            end
        end
        STATE_SCANNING: begin
            piece_start_operation <= PIECE_OPERATION_NONE;
            if (piece_start_operation != PIECE_OPERATION_COLLISION_CHECK) begin
                case (piece_operation_result)
                    PIECE_COLLISION_DETECTED: begin
                        state <= STATE_PREPARE_TO_ANIMATE;
                    end
                    PIECE_NO_COLLISIONS_DETECTED: begin
                        result <= RESULT_NEGATIVE;
                        state <= STATE_IDLE;
                    end
                endcase
            end
        end
        STATE_PREPARE_TO_ANIMATE: begin
            field_write_enable <= 1;

            field_x <= 3;
            field_y <= 22;

            state <= STATE_ANIMATING;
        end
        STATE_ANIMATING: begin
            if (field_x == 12) begin
                field_x <= 3;

                field_write_enable <= 0;

                if (field_y == 3) begin
                    result <= RESULT_POSITIVE;
                    state <= STATE_IDLE;
                end else begin
                    field_y <= field_y - 1;

                    result <= RESULT_ANIMATION_FRAME_DONE;
                    state <= STATE_ANIMATING_INTERRUPTED;
                end
            end else begin
                field_x <= field_x + 1;
            end
        end
        STATE_ANIMATING_INTERRUPTED: begin
            if(start) begin
                field_write_enable <= 1;
                result <= RESULT_NOT_COMPLETE;
                state <= STATE_ANIMATING;
            end
        end
    endcase
end

endmodule