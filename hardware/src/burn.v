module burn (
    input wire clk,

    // Start checking the complete lines and playing the burn animation.
    input wire start,
    // Asserted when all the burn-related operations are complete.
    output wire done,

    // X coordinate of the field cell, used for both read and write operations.
    output reg[3:0] field_x = 3,
    // Y coordinate of the field cell, used for both read and write operations.
    output reg[4:0] field_y = 3,

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
    output reg[2:0] field_cell_write_value = 0
);

localparam STATE_IDLE = 'b000;
localparam STATE_SCANNING = 'b001;
localparam STATE_PREPARE_TO_BURN = 'b010;
localparam STATE_BURNING = 'b011;
localparam STATE_PREPARE_TO_FALL = 'b100;
localparam STATE_FALLING = 'b101;

reg[2:0] state = STATE_IDLE;

assign done = state == STATE_IDLE;

reg is_current_line_complete = 1;

reg[4:0] lines_to_burn [3:0];
reg[2:0] amount_of_lines_to_burn = 0;
reg[2:0] currently_burning_y = 0;

always @(posedge clk) begin
    case(state)
        STATE_IDLE: begin
            if (start) begin
                field_x <= 3;
                field_y <= 3;
                field_write_enable <= 0;
                field_read_enable <= 1;
                is_current_line_complete <= 1;
                amount_of_lines_to_burn <= 0;
                currently_burning_y <= 0;

                state <= STATE_SCANNING;
            end
        end
        STATE_SCANNING: begin
            if (field_x == 12) begin
                field_x <= 3;
                field_y <= field_y + 1;

                if (is_current_line_complete & (field_cell_read_value != 0)) begin
                    lines_to_burn[amount_of_lines_to_burn] <= field_y;
                    amount_of_lines_to_burn <= amount_of_lines_to_burn + 1;

                    if (amount_of_lines_to_burn == 3) begin
                        field_read_enable <= 0;

                        // We can early exit scanning here as `amount_of_lines_to_burn` cannot be bigger than 4.
                        state <= STATE_PREPARE_TO_BURN;
                    end
                end else if (field_y == 22) begin
                    field_read_enable <= 0;

                    state <= STATE_PREPARE_TO_BURN;
                end
            end else begin
                field_x <= field_x + 1;
                is_current_line_complete <= is_current_line_complete & (field_cell_read_value != 0);
            end
        end
        STATE_PREPARE_TO_BURN: begin
            if (amount_of_lines_to_burn == 0) begin
                state <= STATE_IDLE;
            end else begin
                field_x <= 3;
                state <= STATE_BURNING;
            end
        end
        STATE_BURNING: begin // TODO: Play animation.
            field_y <= lines_to_burn[currently_burning_y];

            if (currently_burning_y + 1 == amount_of_lines_to_burn) begin
                field_x <= field_x + 1;
                currently_burning_y <= 0;

                if (field_x == 12) begin
                    field_write_enable <= 0;
                    state <= STATE_PREPARE_TO_FALL;
                end else begin
                    field_write_enable <= 1;
                end
            end else begin
                currently_burning_y <= currently_burning_y + 1;
                field_write_enable <= 1;
            end
        end
        STATE_PREPARE_TO_FALL: begin
            field_read_enable <= 1;
            field_write_enable <= 0;
            field_x <= 3;
            field_y <= lines_to_burn[amount_of_lines_to_burn - 1] + 1;
            state <= STATE_FALLING;
        end
        STATE_FALLING: begin // TODO: Play animation.
            if (field_read_enable && !field_write_enable) begin
                field_y <= field_y - 1;

                field_read_enable <= 0;
            end else if(!field_read_enable && !field_write_enable) begin
                field_cell_write_value <= field_cell_read_value;

                field_write_enable <= 1;
            end else begin
                if (field_x == 12) begin
                    field_x <= 3;
                    if (field_y == 21) begin
                        if (amount_of_lines_to_burn == 1) begin
                            state <= STATE_IDLE;
                        end else begin
                            // NOTE: `amount_of_lines_to_burn` counter is reused here.
                            amount_of_lines_to_burn <= amount_of_lines_to_burn - 1;
                            field_y <= lines_to_burn[amount_of_lines_to_burn - 2] + 1;

                            field_read_enable <= 1;
                        end
                    end else begin
                        field_y <= field_y + 2;

                        field_read_enable <= 1;
                    end
                end else begin
                    field_x <= field_x + 1;
                    field_y <= field_y + 1;

                    field_read_enable <= 1;
                end

                field_write_enable <= 0;
            end
        end
    endcase
end

endmodule
