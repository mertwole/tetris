use atmega_hal::{Atmega, Usart, delay::Delay, port::Pin, usart::UsartOps};
use embedded_hal::delay::DelayNs;

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
    let mut io = Io::parse(io_pins);

    let mut delay = Delay::<ClockSpeed>::new();

    clk.set_low();
    reset_n.set_low();

    delay.delay_ms(1);

    reset_n.set_high();
    io.start.set_high();

    delay.delay_ms(1);

    clk.set_high();

    let state = [
        io.state[0].is_high(),
        io.state[1].is_high(),
        io.state[2].is_high(),
    ];

    ufmt::uwriteln!(&mut serial, "state after start: {:?}", state).unwrap();
}

struct Io {
    field_x: [InputPin; 4],
    field_y: [InputPin; 5],
    field_write_enable: InputPin,
    field_cell_write_value: [InputPin; 3],

    start: OutputPin,
    result: [InputPin; 2],

    piece_start_operation: [InputPin; 2],
    piece_operation_result: [OutputPin; 2],

    state: [InputPin; 3],
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
            _io_9,
            _io_10,
            _io_11,
            _io_12,
            io_13,
            io_14,
            io_15,
            io_16,
            _io_17,
            _io_18,
            _io_19,
            _io_20,
            _io_21,
            _io_22,
            _io_23,
            _io_24,
            _io_25,
            _io_26,
            _io_27,
            _io_28,
            io_29,
            io_30,
            io_31,
            io_32,
            io_33,
            io_34,
            io_35,
            _io_36,
            _io_37,
            _io_38,
            _io_39,
            _io_40,
            _io_41,
            io_42,
            io_43,
            io_44,
            _io_45,
            _io_46,
            _io_47,
        ] = pins;

        Self {
            field_x: [io_3, io_2, io_1, io_0],
            field_y: [io_8, io_7, io_6, io_5, io_4],
            field_write_enable: io_13,
            field_cell_write_value: [io_16, io_15, io_14],

            start: io_29.into_output(),
            result: [io_31, io_30],

            piece_start_operation: [io_33, io_32],
            piece_operation_result: [io_35, io_34].map(Pin::into_output),

            state: [io_44, io_43, io_42],
        }
    }
}
