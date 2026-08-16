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

    // Start a field operation.
    //
    // 'b00 - None
    // 'b01 - Bounds and collisions check
    // 'b10 - Write piece to field
    // 'b11 - Remove piece from the field
    input wire[1:0] start_operation,

    // The field operation result
    //
    // 'b00 - Operation in progress
    // 'b01 - Operation complete
    // 'b10 - Operation complete
    // 
    // After the bounds check operation result of 'b01 means that no collisions/out of bounds were detected, 
    // while result of 'b10 means that the collision/out of bounds was detected.
    output reg[1:0] operation_result = 0,

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
    output reg[2:0] type,

    // X coordinate of the field cell, used for both read and write operations.
    output wire[3:0] field_x,
    // Y coordinate of the field cell, used for both read and write operations.
    output wire[4:0] field_y,

    // Request to read the field cell at coordinates (`field_x`, `field_y`).
    //
    // NOTE: Will never be active simultaneously with `field_write_enable`.
    output reg field_read_enable = 0,
    // Result of the field read operation initiated by asserting `field_read_enable`.
    input wire[2:0] field_cell_read_value,

    // Request to write the value `field_cell_write_value` to the field cell at coordinates 
    // (`field_x`, `field_y`).
    //
    // NOTE: Will never be active simultaneously with `field_read_enable`.
    output reg field_write_enable = 0,
    // The value that will be written to the field cell at coordinates (`field_x`, `field_y`) when 
    // `field_write_enable` is asserted.
    output reg[2:0] field_cell_write_value
);

localparam MOVE_TYPE_NONE = 'b000;
localparam MOVE_TYPE_DOWN = 'b001;
localparam MOVE_TYPE_LEFT = 'b010;
localparam MOVE_TYPE_RIGHT = 'b011;
localparam MOVE_TYPE_UP = 'b100;

localparam ROTATE_NONE = 'b00;
localparam ROTATE_CW = 'b01;
localparam ROTATE_CCW = 'b10;

localparam RESULT_NONE = 'b00;
localparam RESULT_DONE = 'b01;
localparam RESULT_NO_COLLISION = 'b01;
localparam RESULT_COLLISION = 'b10;

reg [3:0] x;
reg [4:0] y;

assign center_y = y;

// Rotation of the piece.
// 
// Value of 'b00 corresponds to spawn orientation, 'b01 - spawn orientation turned clockwise and so on.
reg[1:0] rotation;

wire[3:0] cell_x_offset;
wire[4:0] cell_y_offset;

reg[1:0] read_index = 0;

assign {cell_x_offset, cell_y_offset} = get_cell_offsets(type, rotation, read_index);
assign field_x = x + cell_x_offset;
assign field_y = y + cell_y_offset;

localparam OP_STATE_INIT = 'b00;
localparam OP_STATE_CHECKING = 'b01;
localparam OP_STATE_WRITING = 'b10;

reg[1:0] op_state = OP_STATE_INIT;

reg field_read_delay = 0;

always @(posedge clk) begin
    case(op_state)
        OP_STATE_INIT: begin
            case(start_operation)
                'b01: begin
                    field_read_enable <= 1;
                    field_read_delay <= 0;
                    op_state <= OP_STATE_CHECKING;
                end
                'b10: begin
                    field_cell_write_value <= type;
                    field_write_enable <= 1;
                    op_state <= OP_STATE_WRITING;
                end
                'b11: begin
                    field_cell_write_value <= 'b000;
                    field_write_enable <= 1;
                    op_state <= OP_STATE_WRITING;
                end
            endcase

            if(start_operation != 0) begin
                operation_result <= 0;
                read_index <= 0;
            end
        end
        OP_STATE_CHECKING: begin
            field_read_delay <= ~field_read_delay;
            if (field_read_delay != 0) begin
                read_index <= read_index + 1;

                if (field_cell_read_value != 'b000 || field_x < 3 || field_x > 12 || field_y < 3) begin
                    operation_result <= RESULT_COLLISION;
                    field_read_enable <= 0;
                    op_state <= OP_STATE_INIT;
                end else if(read_index == 3) begin
                    operation_result <= RESULT_NO_COLLISION;
                    field_read_enable <= 0;
                    op_state <= OP_STATE_INIT;
                end
            end
        end 
        OP_STATE_WRITING: begin
            read_index <= read_index + 1;
            
            if(read_index == 3) begin
                operation_result <= RESULT_DONE;
                field_write_enable <= 0;
                op_state <= OP_STATE_INIT;
            end
        end
    endcase
end

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
