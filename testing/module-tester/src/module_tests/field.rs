use atmega_hal::{Atmega, Usart, delay::Delay, port::Pin, usart::UsartOps};

use crate::{
    ClockSpeed,
    module_tests::{InputPin, MODULE_SPECIFIC_PIN_COUNT, OutputPin},
};

pub fn run<USART, RX, TX, CLOCK>(
    mut serial: &mut Usart<USART, RX, TX, CLOCK>,
    mut clk: OutputPin,
    _reset_n: OutputPin,
    io_pins: [InputPin; MODULE_SPECIFIC_PIN_COUNT],
) where
    USART: UsartOps<Atmega, RX, TX>,
{
    let mut _io = Io::parse(io_pins);

    let mut _delay = Delay::<ClockSpeed>::new();
}

struct Io {
    x_coord: [OutputPin; 4],
    y_coord: [OutputPin; 5],
    read_enable: OutputPin,
    dout: [InputPin; 3],
    write_enable: OutputPin,
    din: [OutputPin; 3],

    address_valid: InputPin,
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
            _io_45,
            _io_46,
            io_47,
        ] = pins;

        Self {
            x_coord: [io_3, io_2, io_1, io_0].map(Pin::into_output),
            y_coord: [io_8, io_7, io_6, io_5, io_4].map(Pin::into_output),
            read_enable: io_9.into_output(),
            dout: [io_12, io_11, io_10],
            write_enable: io_13.into_output(),
            din: [io_16, io_15, io_14].map(Pin::into_output),

            address_valid: io_47,
        }
    }
}
