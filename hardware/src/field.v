// This module grants an access to the field.
//
// Field itself has the dimensions of 10x20 but origin is offset so the corrdinates of the corner cells are:
//  left top -       (3, 22)       right top -    (12, 22)
//  left bottom -    (3, 3)        right bottom - (12, 3)
module field (
    input wire clk,

    input wire[3:0] x,
    input wire[4:0] y,

    input wire write_enable,
    input wire[3:0] din,

    output wire[3:0] dout
);

wire address = {y - 3, x - 3};
wire address_valid = y >= 3 && y <= 22 && x >= 3 && x <= 12;

wire dout_raw;
assign dout = address_valid ? dout_raw : 0;

wire wea = write_enable & address_valid;

// This BRAM has the write depth of 320 while only 200 addresses will be used.
field_state field_state_inst (
    .addra(address),
    .clka(clk),
    .dina(din),
    .douta(dout_raw),
    .wea(wea)
);

endmodule
