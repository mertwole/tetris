module scores(
    input wire clk,

    input wire line_burned,
    input wire commit_burned_lines,

    output reg[19:0] score,
    output reg[8:0] lines_burned,
    output reg[4:0] level
);

reg[2:0] lines_burned_from_last_time = 0;
reg[3:0] lines_burned_mod_10 = 0;

always @(posedge clk) begin
    if (line_burned) begin
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
    end
end

endmodule