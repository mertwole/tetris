`timescale 1ns / 1ps

module testing (
    input wire clk,
    input wire rst_n,

    inout wire[55:0] io
);
    wire rst;
    wire clk1x;
    wire clk5x;

    wire clock_locked;
    wire clock_divider_locked;

    assign rst = ~(clock_locked || clock_divider_locked);

    clock clock_inst (
        .clk_out1(clk5x),
        .resetn  (rst_n),
        .locked  (clock_locked),
        .clk_in1 (clk)
    );

    clock_divider clock_divider_inst (
        .clk_out1(clk1x),
        .resetn  (rst_n),
        .locked  (clock_divider_locked),
        .clk_in1 (clk5x)
    );

    reg[5:0] scanned_pin_idx = 0;
    reg[5:0] reported_pin_idx = 0;
    wire all_pins_low = io[49:0] == 0;

    assign io[55:50] = all_pins_low ? 0 : reported_pin_idx;

    // Scan the io pins in range [49:0] and report the result to the pins [55:50].
    always @(posedge clk1x) begin
        if (scanned_pin_idx >= 49) begin
            scanned_pin_idx <= 0;
        end else begin
            scanned_pin_idx <= scanned_pin_idx + 1;
        end

        if (io[scanned_pin_idx] == 1) begin
            reported_pin_idx <= scanned_pin_idx;
        end
    end
endmodule
