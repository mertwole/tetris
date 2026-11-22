// This module grants an access to the field.
//
// Field itself has the dimensions of 10x20 but origin is offset so the corrdinates of the corner cells are:
//  left top -       (3, 22)       right top -    (12, 22)
//  left bottom -    (3, 3)        right bottom - (12, 3)
module field (
    input wire clk,

    input wire[3:0] x_coord,
    input wire[4:0] y_coord,

    input wire write_enable,
    input wire[2:0] din,

    output wire[2:0] dout,

    input wire[3:0] rendering_x,
    input wire[4:0] rendering_y,

    output wire[2:0] rendering_dout
);

wire[4:0] address_y = y_coord - 3;
wire[3:0] address_x = x_coord - 3;
wire[8:0] address = {address_y, address_x};
wire address_valid = y_coord >= 3 && y_coord <= 22 && x_coord >= 3 && x_coord <= 12;

wire[4:0] rendering_address_y = rendering_y - 3;
wire[3:0] rendering_address_x = rendering_x - 3;
wire[8:0] rendering_address = {rendering_address_y, rendering_address_x};

wire[2:0] dout_raw;
assign dout = address_valid ? dout_raw : 0;

wire wea = write_enable & address_valid;

// This BRAM has the write depth of 320 while only 200 addresses will be used.
field_state field_state_inst (
    .addra(address),
    .clka(clk),
    .dina(din),
    .douta(dout_raw),
    .wea(wea),

    .addrb(rendering_address),
    .clkb(clk),
    .dinb(0),
    .doutb(rendering_dout),
    .web(0)
);

endmodule
