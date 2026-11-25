`timescale 1ns / 1ps

module burn_fixture (
    inout wire[55:0] io
);
    wire clk = io[48];
    wire reset_n = io[49];

    wire[3:0] board_id = io[52:55];
    assign board_id = 4'b0001;

    burn burn_inst(
        .clk(clk),

        .start(io[24]),
        .result(io[25:26]),

        .field_x(io[0:3]),
        .field_y(io[4:8]),

        .field_read_enable(io[9]),
        .field_cell_read_value(io[10:12]),

        .field_write_enable(io[13]),
        .field_cell_write_value(io[14:16]),

        .line_burned(io[27]),
        .commit_burned_lines(io[28]),

        .debug_state(io[45:47])
    );

endmodule
