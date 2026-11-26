`timescale 1ns / 1ps

module piece_fixture (
    inout wire[55:0] io
);
    wire clk = io[48];
    wire reset_n = io[49];

    assign io[55:52] = 4'b0110;

    piece piece_inst(
        .clk(clk),
        .reset_n(reset_n),

        .field_x(io[3:0]),
        .field_y(io[8:4]),
        .field_read_enable(io[9]),
        .field_cell_read_value(io[12:10]),
        .field_write_enable(io[13]),
        .field_cell_write_value(io[16:14]),

        .spawned_type(io[19:17]),

        .movement_in(io[22:20]),
        .rotation_in(io[24:23]),

        .start_operation(io[26:25]),
        .operation_result(io[28:27]),

        .center_y(io[33:29]),

        .type(io[36:34]),

        .debug_center_x(io[43:40]),
        .debug_rotation(io[45:44]),
        .debug_op_state(io[47:46])
    );

endmodule
