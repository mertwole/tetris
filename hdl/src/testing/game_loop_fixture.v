`timescale 1ns / 1ps

module game_loop_fixture (
    inout wire[55:0] io
);
    wire clk = io[48];
    wire reset_n = io[49];

    assign io[55:52] = 4'b0101;

    game_loop game_loop_inst(
        .clk(clk),
        .reset_n(reset_n),

        .button_rotate_cw(io[0]),
        .button_rotate_ccw(io[1]),
        .button_left(io[2]),
        .button_right(io[3]),
        .button_down(io[4]),
        .button_start(io[5]),

        .current_level(io[10:6]),

        .piece_movement(io[13:11]),
        .piece_rotation(io[15:14]),

        .current_piece_center_y(io[20:16]),
        .current_piece_type(io[23:21]),

        .start_burn(io[24]),
        .burn_result(io[26:25]),

        .start_lose_check(io[27]),
        .lose_result(io[29:28]),

        .generate_new_piece(io[30]),

        .soft_dropping_movement(io[31]),
        .reset_soft_drop_score(io[32]),
        .commit_soft_drop_score(io[33]),

        .reset_scores(io[34]),

        .game_state_out(io[36:35]),

        .start_piece_operation(io[38:37]),
        .piece_operation_result(io[40:39]),

        .debug_state(io[45:42]),
        .debug_animating_burn(io[46]),
        .debug_animating_lose(io[47])
    );

endmodule
