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

## Board IDs

| module       | board ID(bin) | board ID(dec) |
| ------------ | :-----------: | :-----------: |
| burn         | 0001          | 1             |

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
