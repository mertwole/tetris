module burn (
    input wire clk,

    input wire start,
    output wire done,

    output reg[3:0] field_x = 3,
    output reg[4:0] field_y = 3,

    output reg field_read_enable = 0,
    input wire[2:0] field_cell_read_value,

    output reg field_write_enable = 0,
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
            field_x <= 3;
            field_y <= lines_to_burn[amount_of_lines_to_burn - 1] + 1;
            state <= STATE_FALLING;
        end
        STATE_FALLING: begin // TODO: Play animation.
            field_read_enable <= ~field_read_enable;
            field_write_enable <= ~field_write_enable;

            if (field_read_enable) begin
                field_y <= field_y - 1;
                field_cell_write_value <= field_cell_read_value;
            end else begin
                if (field_x == 12) begin
                    field_x <= 3;
                    if (field_y == 21) begin
                        // Reuse this counter here.
                        amount_of_lines_to_burn <= amount_of_lines_to_burn - 1;
                        field_y <= lines_to_burn[amount_of_lines_to_burn - 2] + 1;
                        if (amount_of_lines_to_burn == 0) begin
                            // TODO: Disable read_enable.
                            state <= STATE_IDLE;
                        end
                    end else begin
                        field_y <= field_y + 2;
                    end
                end else begin
                    field_x <= field_x + 1;
                    field_y <= field_y + 1;
                end
            end
        end
    endcase
end

endmodule
