module piece(
    input wire clk,

    // Spawn a piece.
    // 
    // Setting this wire to any value except 'b000 will cause the piece to change its type to the 
    // corresponding value and reset coordinates and rotation on the current clock cycle. Setting 'b000 will 
    // have no effect.
    input wire[2:0] spawned_type,

    // Move the piece.
    //
    // Setting this wire to any value except 'b000 will cause the piece to move one block on the current clock 
    // cycle. 
    // 
    // Direction of the movement is defined as follows:
    // 'b000 - No movement
    // 'b001 - Move down
    // 'b010 - Move left
    // 'b011 - Move right
    // 'b100 - Move up
    input wire[2:0] movement_in,

    // Rotate the piece.
    //
    // Setting this wire to any value except 'b00 will cause the piece to rotate on the current clock cycle. 
    // Direction of the rotation is defined as follows:
    // 'b00 - No rotation
    // 'b01 - Clockwise
    // 'b10 - Counter-clockwise
    // 'b11 - No rotation
    input wire [1:0] rotation_in,

    // Request to read specific cell.
    // 
    // Every piece consists of 4 cells, indexed from 0 to 3(inclusive). When `read_index` is set to some
    // value, coordinates of the corresponding cell will appear on `cell_x` and `cell_y`.
    //
    // NOTE: Valid values appear on `cell_x` and `cell_y` immediately.
    input wire[1:0] read_index,

    // X coordinate of the cell being read.
    //
    // See `read_index` description for more details.
    output wire[3:0] cell_x,

    // Y coordinate of the cell being read.
    //
    // See `read_index` description for more details.
    output wire[4:0] cell_y,

    // Y coordinate of the center cell.
    //
    // Used for the ARE timer setup.
    output wire[4:0] center_y,

    // Type of the piece.
    //
    // 'b000 - invalid
    // 'b001 - I
    // 'b010 - J
    // 'b011 - O
    // 'b100 - L
    // 'b101 - S
    // 'b110 - T
    // 'b111 - Z
    output reg[2:0] type
);

localparam MOVE_TYPE_NONE = 'b000;
localparam MOVE_TYPE_DOWN = 'b001;
localparam MOVE_TYPE_LEFT = 'b010;
localparam MOVE_TYPE_RIGHT = 'b011;
localparam MOVE_TYPE_UP = 'b100;

localparam ROTATE_NONE = 'b00;
localparam ROTATE_CW = 'b01;
localparam ROTATE_CCW = 'b10;

reg [3:0] x;
reg [4:0] y;

assign center_y = y;

// Rotation of the piece.
// 
// Value of 'b00 corresponds to spawn orientation, 'b01 - spawn orientation turned clockwise and so on.
reg[1:0] rotation;

wire[3:0] cell_x_offset;
wire[4:0] cell_y_offset;

assign {cell_x_offset, cell_y_offset} = get_cell_offsets(type, rotation, read_index);
assign cell_x = x + cell_x_offset;
assign cell_y = y + cell_y_offset;

always @(posedge clk) begin
    if (spawned_type != 'b000) begin
        rotation <= 0;
        x <= 8;
        y <= 22;
        type <= spawned_type;
    end else begin
        case(rotation_in)
            ROTATE_CW: rotation <= rotation + 1;
            ROTATE_CCW: rotation <= rotation - 1;
        endcase

        case (movement_in)
            MOVE_TYPE_DOWN: begin
                y <= y - 1;
            end
            MOVE_TYPE_LEFT: begin
                x <= x - 1;
            end
            MOVE_TYPE_RIGHT: begin
                x <= x + 1;
            end
            MOVE_TYPE_UP: begin
                y <= y + 1;
            end
        endcase
    end
end

function [8:0] get_cell_offsets(
    input [2:0] type,
    input [1:0] rotation,
    input [1:0] read_index
);
	begin
		case({type, rotation, read_index})
            // I, horizontal
            'b001_00_00, 'b001_10_00: get_cell_offsets = {-4'd2, 5'd0}; 
            'b001_00_01, 'b001_10_01: get_cell_offsets = {-4'd1, 5'd0};
            'b001_00_10, 'b001_10_10: get_cell_offsets = {4'd0, 5'd0};
            'b001_00_11, 'b001_10_11: get_cell_offsets = {4'd1, 5'd0};

            // I, vertical
            'b001_01_00, 'b001_11_00: get_cell_offsets = {4'd0, 5'd2}; 
            'b001_01_01, 'b001_11_01: get_cell_offsets = {4'd0, 5'd1};
            'b001_01_10, 'b001_11_10: get_cell_offsets = {4'd0, 5'd0};
            'b001_01_11, 'b001_11_11: get_cell_offsets = {4'd0, -5'd1};

            // J, down
            'b010_00_00: get_cell_offsets = {-4'd1, 5'd0}; 
            'b010_00_01: get_cell_offsets = {4'd0, 5'd0};
            'b010_00_10: get_cell_offsets = {4'd1, 5'd0};
            'b010_00_11: get_cell_offsets = {4'd1, -5'd1};

            // J, left
            'b010_01_00: get_cell_offsets = {4'd0, 5'd1}; 
            'b010_01_01: get_cell_offsets = {4'd0, 5'd0};
            'b010_01_10: get_cell_offsets = {-4'd1, -5'd1};
            'b010_01_11: get_cell_offsets = {4'd0, -5'd1};

            // J, up
            'b010_10_00: get_cell_offsets = {-4'd1, 5'd1}; 
            'b010_10_01: get_cell_offsets = {-4'd1, 5'd0};
            'b010_10_10: get_cell_offsets = {4'd0, 5'd0};
            'b010_10_11: get_cell_offsets = {4'd1, 5'd0};

            // J, right
            'b010_11_00: get_cell_offsets = {4'd0, 5'd1}; 
            'b010_11_01: get_cell_offsets = {4'd1, 5'd1};
            'b010_11_10: get_cell_offsets = {4'd0, 5'd0};
            'b010_11_11: get_cell_offsets = {4'd0, -5'd1};

            // O
            'b011_00_00, 'b011_01_00, 'b011_10_00, 'b011_11_00: get_cell_offsets = {-4'd1, 5'd0}; 
            'b011_00_01, 'b011_01_01, 'b011_10_01, 'b011_11_01: get_cell_offsets = {4'd0, 5'd0};
            'b011_00_10, 'b011_01_10, 'b011_10_10, 'b011_11_10: get_cell_offsets = {-4'd1, -5'd1};
            'b011_00_11, 'b011_01_11, 'b011_10_11, 'b011_11_11: get_cell_offsets = {4'd0, -5'd1};

            // L, down
            'b100_00_00: get_cell_offsets = {-4'd1, 5'd0}; 
            'b100_00_01: get_cell_offsets = {4'd0, 5'd0};
            'b100_00_10: get_cell_offsets = {4'd1, 5'd0};
            'b100_00_11: get_cell_offsets = {-4'd1, -5'd1};

            // L, left
            'b100_01_00: get_cell_offsets = {-4'd1, 5'd1}; 
            'b100_01_01: get_cell_offsets = {4'd0, 5'd1};
            'b100_01_10: get_cell_offsets = {4'd0, 5'd0};
            'b100_01_11: get_cell_offsets = {4'd0, -5'd1};

            // L, up
            'b100_10_00: get_cell_offsets = {4'd1, 5'd1}; 
            'b100_10_01: get_cell_offsets = {-4'd1, 5'd0};
            'b100_10_10: get_cell_offsets = {4'd0, 5'd0};
            'b100_10_11: get_cell_offsets = {4'd1, 5'd0};

            // L, right
            'b100_11_00: get_cell_offsets = {4'd0, 5'd1}; 
            'b100_11_01: get_cell_offsets = {4'd0, 5'd0};
            'b100_11_10: get_cell_offsets = {4'd0, -5'd1};
            'b100_11_11: get_cell_offsets = {4'd1, -5'd1};

            // S, horizontal
            'b101_00_00, 'b101_10_00: get_cell_offsets = {4'd0, 5'd0}; 
            'b101_00_01, 'b101_10_01: get_cell_offsets = {4'd1, 5'd0};
            'b101_00_10, 'b101_10_10: get_cell_offsets = {-4'd1, -5'd1};
            'b101_00_11, 'b101_10_11: get_cell_offsets = {4'd0, -5'd1};

            // S, vertical
            'b101_01_00, 'b101_11_00: get_cell_offsets = {4'd0, 5'd1}; 
            'b101_01_01, 'b101_11_01: get_cell_offsets = {4'd0, 5'd0};
            'b101_01_10, 'b101_11_10: get_cell_offsets = {4'd1, 5'd0};
            'b101_01_11, 'b101_11_11: get_cell_offsets = {4'd1, -5'd1};

            // T, down
            'b110_00_00: get_cell_offsets = {-4'd1, 5'd0}; 
            'b110_00_01: get_cell_offsets = {4'd0, 5'd0};
            'b110_00_10: get_cell_offsets = {4'd1, 5'd0};
            'b110_00_11: get_cell_offsets = {4'd0, -5'd1};

            // T, left
            'b110_01_00: get_cell_offsets = {4'd0, 5'd1}; 
            'b110_01_01: get_cell_offsets = {-4'd1, 5'd0};
            'b110_01_10: get_cell_offsets = {4'd0, 5'd0};
            'b110_01_11: get_cell_offsets = {4'd0, -5'd1};

            // T, up
            'b110_10_00: get_cell_offsets = {-4'd1, 5'd0}; 
            'b110_10_01: get_cell_offsets = {4'd0, 5'd0};
            'b110_10_10: get_cell_offsets = {4'd1, 5'd0};
            'b110_10_11: get_cell_offsets = {4'd0, 5'd1};

            // T, right
            'b110_11_00: get_cell_offsets = {4'd0, 5'd1}; 
            'b110_11_01: get_cell_offsets = {4'd0, 5'd0};
            'b110_11_10: get_cell_offsets = {4'd1, 5'd0};
            'b110_11_11: get_cell_offsets = {4'd0, -5'd1};

            // Z, horizontal
            'b111_00_00, 'b111_10_00: get_cell_offsets = {-4'd1, 5'd0}; 
            'b111_00_01, 'b111_10_01: get_cell_offsets = {4'd0, 5'd0};
            'b111_00_10, 'b111_10_10: get_cell_offsets = {4'd0, -5'd1};
            'b111_00_11, 'b111_10_11: get_cell_offsets = {4'd1, -5'd1};

            // Z, vertical
            'b111_01_00, 'b111_11_00: get_cell_offsets = {4'd1, 5'd1}; 
            'b111_01_01, 'b111_11_01: get_cell_offsets = {4'd0, 5'd0};
            'b111_01_10, 'b111_11_10: get_cell_offsets = {4'd1, 5'd0};
            'b111_01_11, 'b111_11_11: get_cell_offsets = {4'd0, -5'd1};
        endcase
	end
endfunction

endmodule
