module image_encoder (
    input wire clk,
    input wire reset,

    output wire[3:0] field_x_out,
    output wire[4:0] field_y_out,

    input wire[2:0] field_cell_value,

    output reg vsync,
    output reg hsync,

    output wire [7:0] pixel_r,
    output wire [7:0] pixel_g,
    output wire [7:0] pixel_b,
    output reg pixel_valid
);
  localparam FIELD_CELL_SIZE = 20;

  reg[7:0] field_x = 3;
  reg[7:0] field_y = 3;

  wire coords_valid = field_x >= 3 && field_x <= 12 && field_y >= 3 && field_y <= 22;
  assign field_x_out = coords_valid ? field_x : 3;
  assign field_y_out = coords_valid ? 25 - field_y : 3;

  parameter H_TOTAL = 1650 - 1;
  parameter H_SYNC = 40 - 1;
  parameter H_START = 220 - 1;
  parameter H_END = 1500 - 1;

  parameter V_TOTAL = 750 - 1;
  parameter V_SYNC = 5 - 1;
  parameter V_START = 20 - 1;
  parameter V_END = 740 - 1;

  parameter SCREEN_X = 1280;
  parameter SCREEN_Y = 720;

  reg [12:0] x_coord;
  reg [12:0] y_coord;

  reg [23:0] pixel;
  assign {pixel_b, pixel_g, pixel_r} = pixel;

  always @(posedge clk) begin
    if (coords_valid) begin
      pixel <= field_cell_color(field_cell_value);
    end else begin
      pixel <= 'h000000;
    end
  end

  always @(posedge clk) begin
    if (reset == 1) begin
      x_coord <= 0;
    end else if (x_coord == H_TOTAL) begin
      x_coord <= 0;
    end else if (x_coord != H_TOTAL) begin
      x_coord <= x_coord + 1;
    end

    if (reset == 1) begin
      y_coord <= 0;
    end else if (y_coord == V_TOTAL && x_coord == H_TOTAL) begin
      y_coord <= 0;
    end else if (x_coord == H_TOTAL) begin
      y_coord <= y_coord + 1;
    end
  end

  always @(posedge clk) begin
    if (reset == 1) begin
      hsync <= 1;
    end else if (x_coord == H_TOTAL) begin
      hsync <= 1;
    end else if (x_coord == H_SYNC) begin
      hsync <= 0;
    end

    if (reset == 1) begin
      vsync <= 1;
    end else if (y_coord == V_TOTAL && x_coord == H_TOTAL) begin
      vsync <= 1;
    end else if (y_coord == V_SYNC && x_coord == H_TOTAL) begin
      vsync <= 0;
    end
  end

  always @(posedge clk) begin
    if (reset == 1) begin
      pixel_valid <= 0;
    end else if ((x_coord >= H_START) && (x_coord < H_END) && (y_coord >= V_START) && (y_coord < V_END)) begin
      pixel_valid <= 1;
    end else begin
      pixel_valid <= 0;
    end
  end

  integer field_x_divisor = 0;
  integer field_y_divisor = 0;

  always @(posedge clk) begin
    if (reset == 1) begin
      field_x <= 0;
      field_y <= 0;

      field_x_divisor <= 0;
      field_y_divisor <= 0;
    end else if (x_coord == H_START - 3) begin
      field_x <= 0;
      field_x_divisor <= 0;

      if (y_coord == V_START) begin
        field_y <= 0;
        field_y_divisor <= 0;
      end else if (y_coord > V_START && y_coord < V_END) begin
        if (field_y_divisor == FIELD_CELL_SIZE - 1) begin
          field_y_divisor <= 0;

          field_y <= field_y + 1;
        end else begin
          field_y_divisor <= field_y_divisor + 1;
        end
      end
    end else if (x_coord > H_START - 3 && x_coord < H_END - 3) begin
      if (field_x_divisor == FIELD_CELL_SIZE - 1) begin
        field_x_divisor <= 0;

        field_x <= field_x + 1;
      end else begin
        field_x_divisor <= field_x_divisor + 1;
      end
    end
  end

  function[23:0] field_cell_color(input [2:0] cell_value);
    begin
      case(cell_value) 
        'b000: field_cell_color = 'h101010;
        'b001: field_cell_color = 'hFF0000;
        'b010: field_cell_color = 'h00FF00;
        'b011: field_cell_color = 'h0000FF;
        'b100: field_cell_color = 'hFFFF00;
        'b101: field_cell_color = 'hFF00FF;
        'b110: field_cell_color = 'h00FFFF;
        'b111: field_cell_color = 'hFFFFFF;
      endcase
    end
  endfunction
endmodule
