module lose(
    input wire clk,

    // Start checking the current piece cells and playing the lose animation(if required).
    input wire start,
    // Result of the lose check.
    //
    // 'b00 - check is not yet complete.
    // 'b01 - check is negative
    // 'b10 - check is positive
    output reg[1:0] result,

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

    // Request to read the current piece cell at index `current_piece_read_index`.
    output reg current_piece_read_enable = 0, // TODO: Remove in favor of moving all the checks to `piece`.
    // Index to read the current piece when `current_piece_read_enable` is asserted.
    output wire [1:0] current_piece_read_index_out,
    // X coordinate of the cell of the current piece.
    input wire[3:0] current_piece_cell_x,
    // Y coordinate of the cell of the current piece.
    input wire[4:0] current_piece_cell_y
);

localparam STATE_IDLE = 'b000;
localparam STATE_PREPARE_TO_SCAN = 'b001;
localparam STATE_SCANNING = 'b010;
localparam STATE_PREPARE_TO_ANIMATE = 'b011;
localparam STATE_ANIMATING = 'b100;

reg[2:0] state = STATE_IDLE;

assign field_cell_write_value = 0; // Lose animation can only erase the cells.

reg[2:0] current_piece_read_index = 0;
assign current_piece_read_index_out = current_piece_read_index[1:0];

reg read_delay = 0;

always @(posedge clk) begin
    case(state)
        STATE_IDLE: begin
            if (start) begin
                result <= 0;

                current_piece_read_enable <= 1;
                current_piece_read_index <= 0;

                state <= STATE_PREPARE_TO_SCAN;
            end else begin
                field_read_enable <= 0;
                current_piece_read_enable <= 0;
            end
        end
        STATE_PREPARE_TO_SCAN: begin
            field_x <= current_piece_cell_x;
            field_y <= current_piece_cell_y;   
            field_read_enable <= 1;
            read_delay <= 1;
            current_piece_read_index <= current_piece_read_index + 1;

            state <= STATE_SCANNING;
        end
        STATE_SCANNING: begin
            read_delay <= ~read_delay;
            if(!read_delay) begin
                // It's checked with 4 because `field_cell_read_value` contains value of the field cell read in
                // the previous clock cycle.
                if (current_piece_read_index == 4) begin
                    if (field_cell_read_value != 'b000) begin
                        state <= STATE_PREPARE_TO_ANIMATE;
                    end else begin
                        result <= 'b01;

                        state <= STATE_IDLE;
                    end
                end else begin
                    current_piece_read_index <= current_piece_read_index + 1;

                    field_x <= current_piece_cell_x;
                    field_y <= current_piece_cell_y;

                    if (field_cell_read_value != 'b000) begin
                        state <= STATE_PREPARE_TO_ANIMATE;
                    end
                end
            end
        end
        STATE_PREPARE_TO_ANIMATE: begin
            current_piece_read_enable <= 0;
            field_read_enable <= 0;
            field_write_enable <= 1;

            field_x <= 3;
            field_y <= 22;

            state <= STATE_ANIMATING;
        end
        STATE_ANIMATING: begin // TODO: Animate.
            if (field_x == 12) begin
                field_x <= 3;

                if (field_y == 3) begin
                    result <= 'b10;
                    field_write_enable <= 0;

                    state <= STATE_IDLE;
                end else begin
                    field_y <= field_y - 1;
                end
            end else begin
                field_x <= field_x + 1;
            end
        end
    endcase    
end

endmodule