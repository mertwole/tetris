module lose(
    input wire clk,

    // Start checking the current piece cells and playing the lose animation(if required).
    input wire start,
    // Asserted when all the lose-related operations are complete.
    output wire done,

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
    output wire[2:0] field_cell_write_value = 0, // Lose animation can only erase the cells.

    output reg current_piece_read_enable = 0,
    output reg [1:0] current_piece_read_index = 0,
    input wire[3:0] current_piece_cell_x,
    input wire[4:0] current_piece_cell_y
);

localparam STATE_IDLE = 'b000;
localparam STATE_SCANNING = 'b001;
localparam STATE_PREPARE_TO_ANIMATE = 'b010;
localparam STATE_ANIMATING = 'b011;

reg[2:0] state = STATE_IDLE;

assign done = state == STATE_IDLE;

always @(posedge clk) begin
    case(state)
        STATE_IDLE: begin
            if (start) begin
                current_piece_read_enable <= 1;
                current_piece_read_index <= 0;
                field_read_enable <= 1;

                field_x <= current_piece_cell_x;
                field_y <= current_piece_cell_y;

                state <= STATE_SCANNING;
            end
        end
        STATE_SCANNING: begin
            if (current_piece_read_index == 3) begin
                current_piece_read_index <= 0;

                if (field_cell_read_value != 'b000) begin
                    state <= STATE_PREPARE_TO_ANIMATE;
                end else begin
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
        STATE_PREPARE_TO_ANIMATE: begin
            field_read_enable <= 0;
            field_write_enable <= 1;

            field_x <= 3;
            field_y <= 22;

            state <= STATE_ANIMATING;
        end
        STATE_ANIMATING: begin
            if (field_x == 12) begin
                field_x <= 3;

                if (field_y == 3) begin
                    state <= STATE_IDLE;
                    field_write_enable <= 0;
                end else begin
                    field_y -= 1;
                end
            end else begin
                field_x <= field_x + 1;
            end
        end
    endcase    
end

endmodule