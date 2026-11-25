`timescale 1ns / 1ps

module burn_fixture (
    inout wire[55:0] io
);
    wire clk = io[48];
    wire reset_n = io[49];

    assign io[55:52] = 4'b0001;

    burn burn_inst(
        .clk(clk),
        .reset_n(reset_n),

        .start(io[24]),
        .result(io[26:25]),

        .field_x(io[3:0]),
        .field_y(io[8:4]),

        .field_read_enable(io[9]),
        .field_cell_read_value(io[12:10]),

        .field_write_enable(io[13]),
        .field_cell_write_value(io[16:14]),

        .line_burned(io[27]),
        .commit_burned_lines(io[28]),

        .debug_state(io[47:45])
    );

endmodule
