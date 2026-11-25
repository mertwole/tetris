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
