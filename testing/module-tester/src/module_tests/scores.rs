use atmega_hal::{Atmega, Usart, delay::Delay, usart::UsartOps};

use crate::{
    ClockSpeed,
    module_tests::{InputPin, MODULE_SPECIFIC_PIN_COUNT, OutputPin},
};

pub fn run<USART, RX, TX, CLOCK>(
    mut _serial: &mut Usart<USART, RX, TX, CLOCK>,
    mut _clk: OutputPin,
    mut _reset_n: OutputPin,
    io_pins: [InputPin; MODULE_SPECIFIC_PIN_COUNT],
) where
    USART: UsartOps<Atmega, RX, TX>,
{
    let mut _io = Io::parse(io_pins);

    let mut _delay = Delay::<ClockSpeed>::new();
}

struct Io {
    line_burned: OutputPin,
    commit_burned_lines: OutputPin,

    soft_dropping: OutputPin,
    reset_soft_drop_score: OutputPin,
    commit_soft_drop_score: OutputPin,

    score: [InputPin; 20],
    lines_burned_bcd: [InputPin; 12],
    level: [InputPin; 5],

    lines_burned_from_last_time: [InputPin; 3],
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
            _io_42,
            _io_43,
            _io_44,
            io_45,
            io_46,
            io_47,
        ] = pins;

        Self {
            line_burned: io_0.into_output(),
            commit_burned_lines: io_1.into_output(),

            soft_dropping: io_2.into_output(),
            reset_soft_drop_score: io_3.into_output(),
            commit_soft_drop_score: io_4.into_output(),

            score: [
                io_24, io_23, io_22, io_21, io_20, io_19, io_18, io_17, io_16, io_15, io_14, io_13,
                io_12, io_11, io_10, io_9, io_8, io_7, io_6, io_5,
            ],
            lines_burned_bcd: [
                io_36, io_35, io_34, io_33, io_32, io_31, io_30, io_29, io_28, io_27, io_26, io_25,
            ],
            level: [io_41, io_40, io_39, io_38, io_37],

            lines_burned_from_last_time: [io_47, io_46, io_45],
        }
    }
}
