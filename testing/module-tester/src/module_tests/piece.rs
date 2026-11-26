use atmega_hal::{Atmega, Usart, delay::Delay, port::Pin, usart::UsartOps};

use crate::{
    ClockSpeed,
    module_tests::{InputPin, MODULE_SPECIFIC_PIN_COUNT, OutputPin},
};

pub fn run<USART, RX, TX, CLOCK>(
    mut serial: &mut Usart<USART, RX, TX, CLOCK>,
    mut clk: OutputPin,
    mut reset_n: OutputPin,
    io_pins: [InputPin; MODULE_SPECIFIC_PIN_COUNT],
) where
    USART: UsartOps<Atmega, RX, TX>,
{
    let mut _io = Io::parse(io_pins);

    let mut _delay = Delay::<ClockSpeed>::new();
}

struct Io {
    field_x: [InputPin; 4],
    field_y: [InputPin; 5],
    field_read_enable: InputPin,
    field_cell_read_value: [OutputPin; 3],
    field_write_enable: InputPin,
    field_cell_write_value: [InputPin; 3],

    spawned_type: [OutputPin; 3],

    movement_in: [OutputPin; 3],
    rotation_in: [OutputPin; 2],

    start_operation: [OutputPin; 2],
    operation_result: [InputPin; 2],

    center_y: [InputPin; 5],

    type_: [InputPin; 3],

    debug_center_x: [InputPin; 4],
    debug_rotation: [InputPin; 2],
    debug_op_state: [InputPin; 2],
}

impl Io {
    fn parse(pins: [InputPin; MODULE_SPECIFIC_PIN_COUNT]) -> Self {
        let [
            io_0,
            io_1,
            io_2,
            io_3,
            io_4,
            io_5,
            io_6,
            io_7,
            io_8,
            io_9,
            io_10,
            io_11,
            io_12,
            io_13,
            io_14,
            io_15,
            io_16,
            io_17,
            io_18,
            io_19,
            io_20,
            io_21,
            io_22,
            io_23,
            io_24,
            io_25,
            io_26,
            io_27,
            io_28,
            io_29,
            io_30,
            io_31,
            io_32,
            io_33,
            io_34,
            io_35,
            io_36,
            io_37,
            io_38,
            io_39,
            io_40,
            io_41,
            io_42,
            io_43,
            io_44,
            io_45,
            io_46,
            io_47,
        ] = pins;

        Self {
            field_x: [io_3, io_2, io_1, io_0],
            field_y: [io_8, io_7, io_6, io_5, io_4],
            field_read_enable: io_9,
            field_cell_read_value: [io_12, io_11, io_10].map(Pin::into_output),
            field_write_enable: io_13,
            field_cell_write_value: [io_16, io_15, io_14],

            spawned_type: [io_19, io_18, io_17].map(Pin::into_output),

            movement_in: [io_22, io_21, io_20].map(Pin::into_output),
            rotation_in: [io_24, io_23].map(Pin::into_output),

            start_operation: [io_26, io_25].map(Pin::into_output),
            operation_result: [io_28, io_27],

            center_y: [io_33, io_32, io_31, io_30, io_29],

            type_: [io_36, io_35, io_34],

            debug_center_x: [io_43, io_42, io_41, io_40],
            debug_rotation: [io_45, io_44],
            debug_op_state: [io_47, io_46],
        }
    }
}
