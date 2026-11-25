use atmega_hal::{
    Atmega, Usart,
    delay::Delay,
    port::{
        Pin,
        mode::{Floating, Input, Output},
    },
    usart::UsartOps,
};
use embedded_hal::delay::DelayNs;

use crate::{ClockSpeed, module_tests::MODULE_SPECIFIC_PIN_COUNT};

pub fn run<USART, RX, TX, CLOCK>(
    mut serial: &mut Usart<USART, RX, TX, CLOCK>,
    mut clk: Pin<Output>,
    mut reset_n: Pin<Output>,
    io_pins: [Pin<Input<Floating>>; MODULE_SPECIFIC_PIN_COUNT],
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
    field_x: [Pin<Output>; 4],
    field_y: [Pin<Output>; 5],
    field_read_enable: Pin<Output>,
    field_cell_read_value: [Pin<Input<Floating>>; 3],
    field_write_enable: Pin<Output>,
    field_cell_write_value: [Pin<Output>; 3],

    start: Pin<Output>,
    result: [Pin<Input<Floating>>; 2],

    line_burned: Pin<Input<Floating>>,
    commit_burned_lines: Pin<Input<Floating>>,

    state: [Pin<Input<Floating>>; 3],
}

impl Io {
    fn parse(pins: [Pin<Input<Floating>>; MODULE_SPECIFIC_PIN_COUNT]) -> Self {
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
            _io_17,
            _io_18,
            _io_19,
            _io_20,
            _io_21,
            _io_22,
            _io_23,
            io_24,
            io_25,
            io_26,
            io_27,
            io_28,
            _io_29,
            _io_30,
            _io_31,
            _io_32,
            _io_33,
            _io_34,
            _io_35,
            _io_36,
            _io_37,
            _io_38,
            _io_39,
            _io_40,
            _io_41,
            _io_42,
            _io_43,
            _io_44,
            io_45,
            io_46,
            io_47,
        ] = pins;

        Self {
            field_x: [io_3, io_2, io_1, io_0].map(Pin::into_output),
            field_y: [io_8, io_7, io_6, io_5, io_4].map(Pin::into_output),
            field_read_enable: io_9.into_output(),
            field_cell_read_value: [io_12, io_11, io_10],
            field_write_enable: io_13.into_output(),
            field_cell_write_value: [io_16, io_15, io_14].map(Pin::into_output),

            start: io_24.into_output(),
            result: [io_26, io_25],

            line_burned: io_27,
            commit_burned_lines: io_28,

            state: [io_47, io_46, io_45],
        }
    }
}
