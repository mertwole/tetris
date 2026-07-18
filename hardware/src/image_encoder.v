module image_encoder (
    input wire clk,
    input wire reset,

    // output reg  [11:0] pixel_read_request_x,
    // output reg  [11:0] pixel_read_request_y,
    // input  wire [23:0] read_pixel_data,

    output reg vsync,
    output reg hsync,

    output wire [7:0] pixel_r,
    output wire [7:0] pixel_g,
    output wire [7:0] pixel_b,
    output reg pixel_valid
);
  parameter X_RESOLUTION_DIVISION = 4;
  parameter Y_RESOLUTION_DIVISION = 4;

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

  reg [12:0] x;
  reg [12:0] y;

  reg [11:0] pixel_read_request_x;
  reg [11:0] pixel_read_request_y;

  reg [23:0] pixel;
  assign {pixel_b, pixel_g, pixel_r} = pixel;

  always @(posedge clk) begin
    pixel <= {x, y};
  end

  always @(posedge clk) begin
    if (reset == 1) begin
      x <= 0;
    end else if (x == H_TOTAL) begin
      x <= 0;
    end else if (x != H_TOTAL) begin
      x <= x + 1;
    end

    if (reset == 1) begin
      y <= 0;
    end else if (y == V_TOTAL && x == H_TOTAL) begin
      y <= 0;
    end else if (x == H_TOTAL) begin
      y <= y + 1;
    end
  end

  always @(posedge clk) begin
    if (reset == 1) begin
      hsync <= 1;
    end else if (x == H_TOTAL) begin
      hsync <= 1;
    end else if (x == H_SYNC) begin
      hsync <= 0;
    end

    if (reset == 1) begin
      vsync <= 1;
    end else if (y == V_TOTAL && x == H_TOTAL) begin
      vsync <= 1;
    end else if (y == V_SYNC && x == H_TOTAL) begin
      vsync <= 0;
    end
  end

  always @(posedge clk) begin
    if (reset == 1) begin
      pixel_valid <= 0;
    end else if ((x >= H_START) && (x < H_END) && (y >= V_START) && (y < V_END)) begin
      pixel_valid <= 1;
    end else begin
      pixel_valid <= 0;
    end
  end

  integer read_request_x_divisor = 0;
  integer read_request_y_divisor = 0;

  always @(posedge clk) begin
    if (reset == 1) begin
      pixel_read_request_x   <= 0;
      pixel_read_request_y   <= 0;

      read_request_x_divisor <= 0;
      read_request_y_divisor <= 0;
    end else if (x == H_START - 3) begin
      pixel_read_request_x   <= 0;
      read_request_x_divisor <= 0;

      if (y == V_START) begin
        pixel_read_request_y   <= 0;
        read_request_y_divisor <= 0;
      end else if (y > V_START && y < V_END) begin
        if (read_request_y_divisor == Y_RESOLUTION_DIVISION - 1) begin
          read_request_y_divisor <= 0;

          pixel_read_request_y   <= pixel_read_request_y + 1;
        end else begin
          read_request_y_divisor <= read_request_y_divisor + 1;
        end
      end
    end else if (x > H_START - 3 && x < H_END - 3) begin
      if (read_request_x_divisor == X_RESOLUTION_DIVISION - 1) begin
        read_request_x_divisor <= 0;

        pixel_read_request_x   <= pixel_read_request_x + 1;
      end else begin
        read_request_x_divisor <= read_request_x_divisor + 1;
      end
    end
  end
endmodule
