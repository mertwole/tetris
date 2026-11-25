`timescale 1ns / 1ps

module lose_fixture (
    inout wire[55:0] io
);
    wire clk = io[48];
    wire reset_n = io[49];

    assign io[55:52] = 4'b0010;

  lose lose_inst(
    .clk(clk),
    .reset_n(reset_n),

    .start(io[29]),
    .result(io[31:30]),

    .field_x(io[3:0]),
    .field_y(io[8:4]),

    .field_write_enable(io[13]),
    .field_cell_write_value(io[16:14]),

    .piece_start_operation(io[33:32]),
    .piece_operation_result(io[35:34]),

    .debug_state(io[44:42])
  );

endmodule
