`timescale 1ns / 1ps

module scores_fixture (
    inout wire[55:0] io
);
    wire clk = io[48];
    wire reset_n = io[49];

    assign io[55:52] = 4'b0100;

    scores scores_inst(
        .clk(clk),
        .reset_n(reset_n),

        .line_burned(io[0]),
        .commit_burned_lines(io[1]),

        .soft_dropping(io[2]),
        .reset_soft_drop_score(io[3]),
        .commit_soft_drop_score(io[4]),

        .score(io[24:5]),
        .lines_burned_bcd(io[36:25]),
        .level(io[41:37]),

        .debug_lines_burned_from_last_time(io[47:45])
    );

endmodule
