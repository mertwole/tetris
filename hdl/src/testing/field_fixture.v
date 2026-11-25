`timescale 1ns / 1ps

module field_fixture (
    inout wire[55:0] io
);
    wire clk = io[48];
    wire reset_n = io[49];

    assign io[55:52] = 4'b0011;

    field field_inst(
        .clk(clk),

        .x_coord(io[3:0]),
        .y_coord(io[8:4]),

        .dout(io[12:10]),

        .write_enable(io[13]),
        .din(io[16:14]),

        .debug_address_valid(io[47])
    );

endmodule
