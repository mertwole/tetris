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
    output reg[8:0] lines_burned,

    // Current level.
    output reg[4:0] level
);

reg[2:0] lines_burned_from_last_time = 0;
reg[3:0] lines_burned_mod_10 = 0;
reg[4:0] soft_drop_score = 0;

always @(posedge clk) begin
    if (line_burned) begin
        soft_drop_score <= 0;

        lines_burned_from_last_time <= lines_burned_from_last_time + 1;
        lines_burned <= lines_burned + 1;
        score <= score;
        
        if (lines_burned_mod_10 == 9) begin
            lines_burned_mod_10 <= 0;
            level <= level + 1;
        end else begin
            lines_burned_mod_10 <= lines_burned_mod_10 + 1;
            level <= level;
        end
    end else if (commit_burned_lines) begin
        soft_drop_score <= 0;

        lines_burned_from_last_time <= 0;
        lines_burned <= lines_burned;
        lines_burned_mod_10 <= lines_burned_mod_10;
        level <= level;

        case (lines_burned_from_last_time) 
            0: score <= score;
            1: score <= score + 40 * (level + 1);
            2: score <= score + 100 * (level + 1);
            3: score <= score + 200 * (level + 1);
            4: score <= score + 1200 * (level + 1);
        endcase
    end else if (soft_dropping) begin
        soft_drop_score <= soft_drop_score + 1;

        lines_burned_from_last_time <= 0;
        lines_burned <= lines_burned;
        lines_burned_mod_10 <= lines_burned_mod_10;
        level <= level;
        score <= score;
    end else if (reset_soft_drop_score) begin
        soft_drop_score <= 0;

        lines_burned_from_last_time <= 0;
        lines_burned <= lines_burned;
        lines_burned_mod_10 <= lines_burned_mod_10;
        level <= level;
        score <= score;
    end else if (commit_soft_drop_score) begin
        soft_drop_score <= 0;
        score <= score + commit_soft_drop_score;

        lines_burned_from_last_time <= 0;
        lines_burned <= lines_burned;
        lines_burned_mod_10 <= lines_burned_mod_10;
        level <= level;
    end
end

endmodule