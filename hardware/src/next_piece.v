module next_piece (
    input wire clk,

    // Generate the next piece.
    input wire gen,

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
    lfsr_buffer <= {lfsr_buffer[9] ^ lfsr_buffer[1], lfsr_buffer[15:1]}

    if gen begin
        spawn_count <= spawn_count == 5 ? 0 : spawn_count + 1;

        if (first_roll == 0 || first_roll == type) begin
            type <= second_roll == 0 ? spawn_count + 1 : second_roll;
        end else begin 
            type <= first_roll;
        end
    end else begin
        spawn_count <= spawn_count
    end
end

endmodule;