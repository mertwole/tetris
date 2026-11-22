module parallel_to_serial (
    input wire clk1x,
    input wire clk5x,
    input wire rst,
    input wire [9:0] din,
    output wire dout_p,
    output wire dout_n
);

  wire dout;
  wire shift_in1;
  wire shift_in2;

  OBUFDS #(
      .IOSTANDARD("DEFAULT"),
      .SLEW("SLOW")
  ) OBUFDS_inst (
      .O (dout_p),
      .OB(dout_n),
      .I (dout)
  );

  OSERDESE2 #(
      .DATA_RATE_OQ("DDR"),
      .DATA_RATE_TQ("SDR"),
      .DATA_WIDTH(10),
      .INIT_OQ(1'b0),
      .INIT_TQ(1'b0),
      .SERDES_MODE("MASTER"),
      .SRVAL_OQ(1'b0),
      .SRVAL_TQ(1'b0),
      .TBYTE_CTL("FALSE"),
      .TBYTE_SRC("FALSE"),
      .TRISTATE_WIDTH(1)
  ) OSERDESE2_inst_master (
      .OFB(),
      .OQ(dout),
      .SHIFTOUT1(),
      .SHIFTOUT2(),
      .TBYTEOUT(),
      .TFB(),
      .TQ(),
      .CLK(clk5x),
      .CLKDIV(clk1x),
      .D1(din[0]),
      .D2(din[1]),
      .D3(din[2]),
      .D4(din[3]),
      .D5(din[4]),
      .D6(din[5]),
      .D7(din[6]),
      .D8(din[7]),
      .OCE(1'b1),
      .RST(rst),
      .SHIFTIN1(shift_in1),
      .SHIFTIN2(shift_in2),
      .T1(1'b0),
      .T2(1'b0),
      .T3(1'b0),
      .T4(1'b0),
      .TBYTEIN(1'b0),
      .TCE(1'b0)
  );

  OSERDESE2 #(
      .DATA_RATE_OQ  ("DDR"),
      .DATA_RATE_TQ  ("SDR"),
      .DATA_WIDTH    (10),
      .INIT_OQ       (1'b0),
      .INIT_TQ       (1'b0),
      .SERDES_MODE   ("SLAVE"),
      .SRVAL_OQ      (1'b0),
      .SRVAL_TQ      (1'b0),
      .TBYTE_CTL     ("FALSE"),
      .TBYTE_SRC     ("FALSE"),
      .TRISTATE_WIDTH(1)
  ) OSERDESE2_inst_slave (
      .OFB(),
      .OQ(),
      .SHIFTOUT1(shift_in1),
      .SHIFTOUT2(shift_in2),
      .TBYTEOUT(),
      .TFB(),
      .TQ(),
      .CLK(clk5x),
      .CLKDIV(clk1x),
      .D1(),
      .D2(),
      .D3(din[8]),
      .D4(din[9]),
      .D5(),
      .D6(),
      .D7(),
      .D8(),
      .OCE(1'b1),
      .RST(rst),
      .SHIFTIN1(),
      .SHIFTIN2(),
      .T1(1'b0),
      .T2(1'b0),
      .T3(1'b0),
      .T4(1'b0),
      .TBYTEIN(1'b0),
      .TCE(1'b0)
  );

endmodule
