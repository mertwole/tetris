module piece(
    input wire clk,

    input wire[2:0] spawned_type,

    input wire[1:0] move_type,

    input wire [1:0] rotation_type,

    input wire[1:0] read_index,
    output wire[3:0] cell_x,
    output wire[4:0] cell_y,

    /// Rotation of the piece.
    /// 
    /// Value of 'b00 corresponds to spawn orientation, 'b01 - spawn orientation turned clockwise and so on.
    output reg[1:0] rotation,

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

localparam MOVE_TYPE_NONE = 'b00;
localparam MOVE_TYPE_DOWN = 'b01;
localparam MOVE_TYPE_LEFT = 'b10;
localparam MOVE_TYPE_RIGHT = 'b11;

localparam ROTATE_NONE = 'b00;
localparam ROTATE_CW = 'b01;
localparam ROTATE_CCW = 'b10;

reg [3:0] x;
reg [4:0] y;

wire cell_x_offset;
wire cell_y_offset;

assign {cell_x_offset, cell_y_offset} = get_cell_offsets(type, rotation, read_index);
assign cell_x = x + cell_x_offset;
assign cell_y = y + cell_y_offset;

always @(posedge clk) begin
    if spawn begin
        rotation <= 0;
        x <= 8;
        y <= 22;
        type <= spawned_type;
    end else begin
        case(rotation_type)
            ROTATE_CW: rotation <= rotation + 1;
            ROTATE_CCW: rotation <= rotation - 1;
            default: rotation <= rotation;
        endcase

        type <= type;

        case (move_type)
            MOVE_TYPE_NONE: begin
                x <= x;
                y <= y;
            end
            MOVE_TYPE_DOWN: begin
                x <= x;
                y <= y - 1;
            end
            MOVE_TYPE_LEFT: begin
                x <= x - 1;
                y <= y;
            end
            MOVE_TYPE_RIGHT: begin
                x <= x + 1;
                y <= y;
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
            'b001_00_00, 'b001_10_00: get_cell_offsets = {-4'2, 5'0}; 
            'b001_00_01, 'b001_10_01: get_cell_offsets = {-4'1, 5'0};
            'b001_00_10, 'b001_10_10: get_cell_offsets = {4'0, 5'0};
            'b001_00_11, 'b001_10_11: get_cell_offsets = {4'1, 5'0};

            // I, vertical
            'b001_01_00, 'b001_11_00: get_cell_offsets = {4'0, 5'2}; 
            'b001_01_01, 'b001_11_01: get_cell_offsets = {4'0, 5'1};
            'b001_01_10, 'b001_11_10: get_cell_offsets = {4'0, 5'0};
            'b001_01_11, 'b001_11_11: get_cell_offsets = {4'0, -5'1};

            // J, down
            'b010_00_00: get_cell_offsets = {-4'1, 5'0}; 
            'b010_00_01: get_cell_offsets = {4'0, 5'0};
            'b010_00_10: get_cell_offsets = {4'1, 5'0};
            'b010_00_11: get_cell_offsets = {4'1, -5'1};

            // J, left
            'b010_01_00: get_cell_offsets = {4'0, 5'1}; 
            'b010_01_01: get_cell_offsets = {4'0, 5'0};
            'b010_01_10: get_cell_offsets = {-4'1, -5'1};
            'b010_01_11: get_cell_offsets = {4'0, -5'1};

            // J, up
            'b010_10_00: get_cell_offsets = {-4'1, 5'1}; 
            'b010_10_01: get_cell_offsets = {-4'1, 5'0};
            'b010_10_10: get_cell_offsets = {4'0, 5'0};
            'b010_10_11: get_cell_offsets = {4'1, 5'0};

            // J, right
            'b010_11_00: get_cell_offsets = {4'0, 5'1}; 
            'b010_11_01: get_cell_offsets = {4'1, 5'1};
            'b010_11_10: get_cell_offsets = {4'0, 5'0};
            'b010_11_11: get_cell_offsets = {4'0, -5'1};

            // O
            'b011_00_00, 'b011_01_00, 'b011_10_00, 'b011_11_00: get_cell_offsets = {-4'1, 5'0}; 
            'b011_00_01, 'b011_01_01, 'b011_10_01, 'b011_11_01: get_cell_offsets = {4'0, 5'0};
            'b011_00_10, 'b011_01_10, 'b011_10_10, 'b011_11_10: get_cell_offsets = {-4'1, -5'1};
            'b011_00_11, 'b011_01_11, 'b011_10_11, 'b011_11_11: get_cell_offsets = {4'0, -5'1};

            // L, down
            'b100_00_00: get_cell_offsets = {-4'1, 5'0}; 
            'b100_00_01: get_cell_offsets = {4'0, 5'0};
            'b100_00_10: get_cell_offsets = {4'1, 5'0};
            'b100_00_11: get_cell_offsets = {-4'1, -5'1};

            // L, left
            'b100_01_00: get_cell_offsets = {-4'1, 5'1}; 
            'b100_01_01: get_cell_offsets = {4'0, 5'1};
            'b100_01_10: get_cell_offsets = {4'0, 5'0};
            'b100_01_11: get_cell_offsets = {4'0, -5'1};

            // L, up
            'b100_10_00: get_cell_offsets = {4'1, 5'1}; 
            'b100_10_01: get_cell_offsets = {-4'1, 5'0};
            'b100_10_10: get_cell_offsets = {4'0, 5'0};
            'b100_10_11: get_cell_offsets = {4'1, 5'0};

            // L, right
            'b100_11_00: get_cell_offsets = {4'0, 5'1}; 
            'b100_11_01: get_cell_offsets = {4'0, 5'0};
            'b100_11_10: get_cell_offsets = {4'0, -5'1};
            'b100_11_11: get_cell_offsets = {4'1, -5'1};

            // S, horizontal
            'b101_00_00, 'b101_10_00: get_cell_offsets = {4'0, 5'0}; 
            'b101_00_01, 'b101_10_01: get_cell_offsets = {4'1, 5'0};
            'b101_00_10, 'b101_10_10: get_cell_offsets = {-4'1, -5'1};
            'b101_00_11, 'b101_10_11: get_cell_offsets = {4'0, -5'1};

            // S, vertical
            'b101_01_00, 'b101_11_00: get_cell_offsets = {4'0, 5'1}; 
            'b101_01_01, 'b101_11_01: get_cell_offsets = {4'0, 5'0};
            'b101_01_10, 'b101_11_10: get_cell_offsets = {4'1, 5'0};
            'b101_01_11, 'b101_11_11: get_cell_offsets = {4'1, -5'1};

            // T, down
            'b110_00_00: get_cell_offsets = {-4'1, 5'0}; 
            'b110_00_01: get_cell_offsets = {4'0, 5'0};
            'b110_00_10: get_cell_offsets = {4'1, 5'0};
            'b110_00_11: get_cell_offsets = {4'0, -5'1};

            // T, left
            'b110_01_00: get_cell_offsets = {4'0, 5'1}; 
            'b110_01_01: get_cell_offsets = {-4'1, 5'0};
            'b110_01_10: get_cell_offsets = {4'0, 5'0};
            'b110_01_11: get_cell_offsets = {4'0, -5'1};

            // T, up
            'b110_10_00: get_cell_offsets = {-4'1, 5'0}; 
            'b110_10_01: get_cell_offsets = {4'0, 5'0};
            'b110_10_10: get_cell_offsets = {4'1, 5'0};
            'b110_10_11: get_cell_offsets = {4'0, 5'1};

            // T, right
            'b110_11_00: get_cell_offsets = {4'0, 5'1}; 
            'b110_11_01: get_cell_offsets = {4'0, 5'0};
            'b110_11_10: get_cell_offsets = {4'1, 5'0};
            'b110_11_11: get_cell_offsets = {4'0, -5'1};

            // Z, horizontal
            'b111_00_00, 'b111_10_00: get_cell_offsets = {-4'1, 5'0}; 
            'b111_00_01, 'b111_10_01: get_cell_offsets = {4'0, 5'0};
            'b111_00_10, 'b111_10_10: get_cell_offsets = {4'0, -5'1};
            'b111_00_11, 'b111_10_11: get_cell_offsets = {4'1, -5'1};

            // Z, vertical
            'b111_01_00, 'b111_11_00: get_cell_offsets = {4'1, 5'1}; 
            'b111_01_01, 'b111_11_01: get_cell_offsets = {4'0, 5'0};
            'b111_01_10, 'b111_11_10: get_cell_offsets = {4'1, 5'0};
            'b111_01_11, 'b111_11_11: get_cell_offsets = {4'0, -5'1};
        endcase
	end
endfunction

endmodule
