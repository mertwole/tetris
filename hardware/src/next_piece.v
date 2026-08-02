module next_piece (
    input wire clk,

    // Generate the next piece.
    input wire gen,

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
    output wire[1:0] cell_x,

    // Y coordinate of the cell being read.
    //
    // See `read_index` description for more details.
    output wire cell_y,

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

// Arbitrary initial value.
reg [15:0] lfsr_buffer = 'h8988;

// Spawn count modulo 6.
reg [2:0] spawn_count = 0;

wire[2:0] first_roll = lfsr_buffer[10:8];
wire[2:0] second_roll = lfsr_buffer[13:11];

always @(posedge clk) begin
    lfsr_buffer <= {lfsr_buffer[9] ^ lfsr_buffer[1], lfsr_buffer[15:1]};

    if (gen) begin
        spawn_count <= spawn_count == 5 ? 0 : spawn_count + 1;

        if (first_roll == 0 || first_roll == type) begin
            type <= second_roll == 0 ? spawn_count + 1 : second_roll;
        end else begin 
            type <= first_roll;
        end
    end else begin
        spawn_count <= spawn_count;
    end
end

assign {cell_x, cell_y} = get_cell_positions(type, read_index);

function [2:0] get_cell_positions(
    input [2:0] type,
    input [1:0] read_index
);
	begin
		case({type, read_index})
            // I
            'b001_00: get_cell_positions = {2'd0, 1'd1}; 
            'b001_01: get_cell_positions = {2'd1, 1'd1};
            'b001_10: get_cell_positions = {2'd2, 1'd1};
            'b001_11: get_cell_positions = {2'd3, 1'd1};

            // J
            'b010_00: get_cell_positions = {2'd1, 1'd1}; 
            'b010_01: get_cell_positions = {2'd2, 1'd1};
            'b010_10: get_cell_positions = {2'd3, 1'd1};
            'b010_11: get_cell_positions = {2'd3, 1'd0};

            // O
            'b011_00: get_cell_positions = {2'd1, 1'd1}; 
            'b011_01: get_cell_positions = {2'd2, 1'd1};
            'b011_10: get_cell_positions = {2'd1, 1'd0};
            'b011_11: get_cell_positions = {2'd2, 1'd0};

            // L
            'b100_00: get_cell_positions = {2'd1, 1'd1}; 
            'b100_01: get_cell_positions = {2'd2, 1'd1};
            'b100_10: get_cell_positions = {2'd3, 1'd1};
            'b100_11: get_cell_positions = {2'd1, 1'd0};

            // S
            'b101_00: get_cell_positions = {2'd2, 1'd1}; 
            'b101_01: get_cell_positions = {2'd3, 1'd1};
            'b101_10: get_cell_positions = {2'd1, 1'd0};
            'b101_11: get_cell_positions = {2'd2, 1'd0};

            // T
            'b110_00: get_cell_positions = {2'd1, 1'd1}; 
            'b110_01: get_cell_positions = {2'd2, 1'd1};
            'b110_10: get_cell_positions = {2'd3, 1'd1};
            'b110_11: get_cell_positions = {2'd2, 1'd0};

            // Z
            'b111_00: get_cell_positions = {2'd1, 1'd1}; 
            'b111_01: get_cell_positions = {2'd2, 1'd1};
            'b111_10: get_cell_positions = {2'd2, 1'd0};
            'b111_11: get_cell_positions = {2'd3, 1'd0};
        endcase
	end
endfunction

endmodule
