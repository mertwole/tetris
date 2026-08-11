module scores(
    input wire clk,

    // Signalize that one line was burned.
    //
    // This should be used during the burn animation by setting it every time an individual line gets burned.
    input wire line_burned,

    // Signalize the end of the single burn.
    //
    // This should be set after the burn animation finishes to commit amount of lines burned during it. This 
    // will also update the score correspondingly.
    input wire commit_burned_lines,

    // Signalize a single movement in the soft drop mode.
    //
    // Should be set every time a piece moves down in the soft drop mode.
    input wire soft_dropping,
    
    // Reset current soft drop score.
    //
    // Should be set when soft drop interrupts.
    input wire reset_soft_drop_score,

    // Commit the soft drop score.
    //
    // Should be set when soft dropped piece settles, which will result in the updated score.
    input wire commit_soft_drop_score,

    // Total score in the current game.
    output reg[19:0] score,

    // Total amound of burned lines in the current game.
    //
    // Encoded as 3-digit BCD.
    output reg[11:0] lines_burned_bcd
);

reg[2:0] lines_burned_from_last_time = 0;
reg[4:0] soft_drop_score = 0;

wire[4:0] level = lines_burned_bcd[11:8] * 10 + lines_burned_bcd[7:4];

wire[3:0] lines_burned_digit_0_inc = lines_burned_bcd[11:8] + 1;
wire[3:0] lines_burned_digit_1_inc = lines_burned_bcd[7:4] + 1;
wire[3:0] lines_burned_digit_2_inc = lines_burned_bcd[3:0] + 1;

always @(posedge clk) begin
    if (line_burned) begin
        soft_drop_score <= 0;

        lines_burned_from_last_time <= lines_burned_from_last_time + 1;

        case({lines_burned_bcd[7:4] == 9, lines_burned_bcd[3:0] == 9})
            'b00, 'b10: lines_burned_bcd <= {lines_burned_bcd[11:4], lines_burned_digit_2_inc};
            'b01:       lines_burned_bcd <= {lines_burned_bcd[11:8], lines_burned_digit_1_inc, 4'b0000};
            'b11:       lines_burned_bcd <= {lines_burned_digit_0_inc, 4'b0000, 4'b0000};
        endcase
    end else if (commit_burned_lines) begin
        soft_drop_score <= 0;

        lines_burned_from_last_time <= 0;

        case (lines_burned_from_last_time) 
            1: score <= score + 40 * (level + 1);
            2: score <= score + 100 * (level + 1);
            3: score <= score + 200 * (level + 1);
            4: score <= score + 1200 * (level + 1);
        endcase
    end else if (soft_dropping) begin
        soft_drop_score <= soft_drop_score + 1;
    end else if (reset_soft_drop_score) begin
        soft_drop_score <= 0;
    end else if (commit_soft_drop_score) begin
        soft_drop_score <= 0;
        score <= score + commit_soft_drop_score;
    end
end

endmodule