## Common

For every module, the following wires must be present:

- clk
- reset_n
- board id (4 wires)

They are connected as follows:

| wire        | io#     |
| ----------- | ------- |
| clk         | 48      |
| reset_n     | 49      |
| board_id[4] | [55:52] |

All the buses are encoded starting from the MSB, i.e. for the `board_id` it means that MSB will be on the io#55.

Remark: `burn` and `lose` module pinouts are designed such that it's possible to implement these 2 modules sharing a single connection to the base board.

## Board IDs

| module       | board ID(bin) | board ID(dec) |
| ------------ | :-----------: | :-----------: |
| burn         | 0001          | 1             |
| lose         | 0010          | 2             |
| field        | 0011          | 3             |
| scores       | 0100          | 4             |
| game_loop    | 0101          | 5             |
| piece        | 0110          | 6             |

## Burn module

| wire                      | io#     |
| ------------------------- | ------- |
| **field read/write**      |         |
| field_x[4]                | [3:0]   |
| field_y[5]                | [8:4]   |
| field_read_enable         | 9       |
| field_cell_read_value[3]  | [12:10] |
| field_write_enable        | 13      |
| field_cell_write_value[3] | [16:14] |
| **control**               |         |
| start                     | 24      |
| result[2]                 | [26:25] |
| **reporting**             |         |  
| line_burned               | 27      |
| commit_burned_lines       | 28      |
| **debug**                 |         |
| state[3]                  | [47:45] |

## Lose module

| wire                      | io#     |
| ------------------------- | ------- |
| **field write**           |         |
| field_x[4]                | [3:0]   |
| field_y[5]                | [8:4]   |
| field_write_enable        | 13      |
| field_cell_write_value[3] | [16:14] |
| **control**               |         |
| start                     | 29      |
| result[2]                 | [31:30] |
| **piece operation**       |         |  
| piece_start_operation[2]  | [33:32] |
| piece_operation_result[2] | [35:34] |
| **debug**                 |         |
| state[3]                  | [44:42] |

## Field module

| wire                      | io#     |
| ------------------------- | ------- |
| **read/write control**    |         |
| x_coord[4]                | [3:0]   |
| y_coord[5]                | [8:4]   |
| read_enable               | 9       |
| dout[3]                   | [12:10] |
| write_enable              | 13      |
| din[3]                    | [16:14] |
| **debug**                 |         |
| address_valid             | 47      |

## Scores module

| wire                           | io#     |
| ------------------------------ | ------- |
| **burn reporting**             |         |
| line_burned                    | 0       |
| commit_burned_lines            | 1       |
| **soft drop reporting**        |         |
| soft_dropping                  | 2       |
| reset_soft_drop_score          | 3       |
| commit_soft_drop_score         | 4       |
| **scores**                     |         |    
| score[20]                      | [24:5]  |
| lines_burned_bcd[12]           | [36:25] |
| level[5]                       | [41:37] |
| **debug**                      |         |
| lines_burned_from_last_time[3] | [47:45] |

## Game loop module

| wire                           | io#     |
| ------------------------------ | ------- |
| **input**                      |         |
| button_rotate_cw               | 0       |
| button_rotate_ccw              | 1       |
| button_left                    | 2       |
| button_right                   | 3       |
| button_down                    | 4       |
| button_start                   | 5       |
| **current level**              |         |
| current_level[5]               | [10:6]  |
| **move/rotate current piece**  |         |
| piece_movement[3]              | [13:11] |
| piece_rotation[2]              | [15:14] |
| **current piece data**         |         |
| current_piece_center_y[5]      | [20:16] |
| current_piece_type[3]          | [23:21] |
| **burn control**               |         |
| start_burn                     | 24      |
| burn_result[2]                 | [26:25] |
| **lose control**               |         |
| start_lose_check               | 27      |
| lose_result[2]                 | [29:28] |
| **generate new piece**         |         |
| generate_new_piece             | 30      |
| **soft drop reporting**        |         |
| soft_dropping_movement         | 31      |
| reset_soft_drop_score          | 32      |
| commit_soft_drop_score         | 33      |
| **reset scores**               |         |
| reset_scores                   | 34      |
| **game state**                 |         |
| game_state_out[2]              | [36:35] |
| **current piece operation**    |         |
| start_piece_operation[2]       | [38:37] |
| piece_operation_result[2]      | [40:39] |
| **debug**                      |         |
| state[4]                       | [45:42] |
| animating_burn                 | 46      |
| animating_lose                 | 47      |

## Piece module

| wire                      | io#     |
| ------------------------- | ------- |
| **field read/write**      |         |
| field_x[4]                | [3:0]   |
| field_y[5]                | [8:4]   |
| field_read_enable         | 9       |
| field_cell_read_value[3]  | [12:10] |
| field_write_enable        | 13      |
| field_cell_write_value[3] | [16:14] |
| **spawn**                 |         |
| spawned_type[3]           | [19:17] |
| **move/rotate**           |         |
| movement_in[3]            | [22:20] |
| rotation_in[2]            | [24:23] |
| **operation**             |         |
| start_operation[2]        | [26:25] |
| operation_result[2]       | [28:27] |
| **center position**       |         |
| center_y[5]               | [33:29] |
| **type**                  |         |
| type[3]                   | [36:34] |
| **debug**                 |         |
| center_x[4]               | [43:40] |
| rotation[2]               | [45:44] |
| op_state[2]               | [47:46] |
