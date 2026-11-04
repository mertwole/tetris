module burn (
    input wire clk,

    // Start checking the complete lines and playing the burn animation.
    input wire start,
    // A result of the burn operation.
    //
    // 'b00 - operation is in progress
    // 'b01 - animation frame done
    // 'b10 - complete
    output reg[1:0] result = 'b10,

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
    output reg[2:0] field_cell_write_value = 0,

    // Signalize that a single line was burned.
    //
    // Used to compute the burned lines amount by `scores`.
    //
    // Will be asserted for a single clock cycle.
    output reg line_burned = 0,
    // Signalize that all the burn operations are complete.
    //
    // Will be asserted for a single clock cycle.
    output reg commit_burned_lines = 0
);

localparam STATE_IDLE = 'b000;
localparam STATE_SCANNING = 'b001;
localparam STATE_PREPARE_TO_BURN = 'b010;
localparam STATE_BURNING = 'b011;
localparam STATE_PLAYING_ANIMATION = 'b100;
localparam STATE_PREPARE_TO_FALL = 'b101;
localparam STATE_FALLING = 'b110;

localparam RESULT_IN_PROGRESS = 'b00;
localparam RESULT_ANIMATION_FRAME_DONE = 'b01;
localparam RESULT_DONE = 'b11;

reg[2:0] state = STATE_IDLE;

reg is_current_line_complete = 1;

reg[4:0] lines_to_burn [3:0];
reg[2:0] amount_of_lines_to_burn = 0;
reg[2:0] currently_burning_y = 0;

reg delay_after_read = 0;

always @(posedge clk) begin
    case(state)
        STATE_IDLE: begin
            commit_burned_lines <= 0;

            if (start) begin
                field_x <= 3;
                field_y <= 3;
                field_write_enable <= 0;
                field_read_enable <= 1;
                delay_after_read <= 1;
                is_current_line_complete <= 1;
                amount_of_lines_to_burn <= 0;
                currently_burning_y <= 0;

                result <= RESULT_IN_PROGRESS;
                state <= STATE_SCANNING;
            end
        end
        STATE_SCANNING: begin
            delay_after_read <= ~delay_after_read;

            if (!delay_after_read) begin
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

                    is_current_line_complete <= 1;
                end else begin
                    field_x <= field_x + 1;
                    is_current_line_complete <= is_current_line_complete & (field_cell_read_value != 0);
                end
            end
        end
        STATE_PREPARE_TO_BURN: begin
            if (amount_of_lines_to_burn == 0) begin
                result <= RESULT_DONE;
                state <= STATE_IDLE;
            end else begin
                field_x <= 3 - 1; // Will be incremented on the first iteration of `STATE_BURNING`.
                state <= STATE_BURNING;
            end
        end
        STATE_BURNING: begin
            field_y <= lines_to_burn[currently_burning_y];

            if (currently_burning_y == 0) begin
                field_x <= field_x + 1;
            end

            if (currently_burning_y + 1 == amount_of_lines_to_burn) begin
                currently_burning_y <= 0;
                
                if (field_x == 12) begin
                    state <= STATE_PREPARE_TO_FALL;

                    field_write_enable <= 0;
                end else begin                    
                    state <= STATE_PLAYING_ANIMATION;
                    result <= RESULT_ANIMATION_FRAME_DONE;

                    field_write_enable <= 1;
                end
            end else begin
                currently_burning_y <= currently_burning_y + 1;
                field_write_enable <= 1;
            end
        end
        STATE_PLAYING_ANIMATION: begin
            field_write_enable <= 0;

            if (start) begin
                result <= RESULT_IN_PROGRESS;
                state <= STATE_BURNING;
            end
        end
        STATE_PREPARE_TO_FALL: begin
            field_read_enable <= 1;
            delay_after_read <= 1;
            field_write_enable <= 0;
            field_x <= 3;
            field_y <= lines_to_burn[amount_of_lines_to_burn - 1] + 1;
            state <= STATE_FALLING;

            line_burned <= 1;
        end
        STATE_FALLING: begin // TODO: Play animation.
            if (field_read_enable && !field_write_enable) begin
                line_burned <= 0;

                if (delay_after_read) begin
                    delay_after_read <= 0;
                end else begin
                    field_y <= field_y - 1;

                    field_cell_write_value <= field_cell_read_value;

                    field_read_enable <= 0;
                    field_write_enable <= 1;
                end
            end else begin
                if (field_x == 12) begin
                    field_x <= 3;
                    if (field_y == 21) begin
                        if (amount_of_lines_to_burn == 1) begin
                            commit_burned_lines <= 1;

                            result <= RESULT_DONE;
                            state <= STATE_IDLE;
                        end else begin
                            // NOTE: `amount_of_lines_to_burn` counter is reused here.
                            amount_of_lines_to_burn <= amount_of_lines_to_burn - 1;
                            field_y <= lines_to_burn[amount_of_lines_to_burn - 2] + 1;

                            line_burned <= 1;

                            field_read_enable <= 1;
                            delay_after_read <= 1;
                        end
                    end else begin
                        field_y <= field_y + 2;

                        field_read_enable <= 1;
                        delay_after_read <= 1;
                    end
                end else begin
                    field_x <= field_x + 1;
                    field_y <= field_y + 1;

                    field_read_enable <= 1;
                    delay_after_read <= 1;
                end

                field_write_enable <= 0;
            end
        end
    endcase
end

endmodule
