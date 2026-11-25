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
| board_id[4] | [52:55] |

All the buses are encoded starting from the MSB, i.e. for the `board_id` it means that MSB will be on the io#52.

## Board IDs

| module       | board ID(bin) | board ID(dec) |
| ------------ | :-----------: | :-----------: |
| burn         | 0001          | 1             |

## Burn module

| wire                      | io#     |
| ------------------------- | ------- |
| **field read/write**      |         |
| field_x[4]                | [0:3]   |
| field_y[5]                | [4:8]   |
| field_read_enable         | 9       |
| field_cell_read_value[3]  | [10:12] |
| field_write_enable        | 13      |
| field_cell_write_value[3] | [14:16] |
| **control**               |         |
| start                     | 24      |
| result[2]                 | [25:26] |
| **reporting**             |         |  
| line_burned               | 27      |
| commit_burned_lines       | 28      |
| **debug**                 |         |
| state[3]                  | [45:47] |
