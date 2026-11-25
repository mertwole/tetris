use core::mem;

use atmega_hal::{
    Atmega, Usart,
    port::{
        Pin,
        mode::{Floating, Input, Output},
    },
    usart::UsartOps,
};

use crate::IO_PIN_COUNT;

mod burn;
mod field;
mod lose;

type InputPin = Pin<Input<Floating>>;
type OutputPin = Pin<Output>;

const MODULE_SPECIFIC_PIN_COUNT: usize = IO_PIN_COUNT - 8;

pub fn run<USART, RX, TX, CLOCK>(
    mut serial: &mut Usart<USART, RX, TX, CLOCK>,
    io_pins: [InputPin; IO_PIN_COUNT],
) -> !
where
    USART: UsartOps<Atmega, RX, TX>,
{
    let (module_specific, common): (
        [InputPin; MODULE_SPECIFIC_PIN_COUNT],
        [InputPin; IO_PIN_COUNT - MODULE_SPECIFIC_PIN_COUNT],
    ) = unsafe { mem::transmute(io_pins) };

    let [io_48, io_49, _io_50, _io_51, io_52, io_53, io_54, io_55] = common;

    let clk = io_48.into_output();
    let reset_n = io_49.into_output();
    let board_id = [io_55, io_54, io_53, io_52];

    loop {
        // Wait for any input.
        let _ = serial.read_byte();
        ufmt::uwrite!(&mut serial, "discovering modules...").unwrap();

        match read_board_id(&board_id) {
            BoardId::Burn => {
                ufmt::uwriteln!(&mut serial, "burn module found").unwrap();
                burn::run(serial, clk, reset_n, module_specific);
                panic!("Done");
            }
            BoardId::Lose => {
                ufmt::uwriteln!(&mut serial, "lose module found").unwrap();
                lose::run(serial, clk, reset_n, module_specific);
                panic!("Done");
            }
            BoardId::Field => {
                ufmt::uwriteln!(&mut serial, "field module found").unwrap();
                field::run(serial, clk, reset_n, module_specific);
                panic!("Done");
            }
            BoardId::Invalid(value) => {
                ufmt::uwriteln!(&mut serial, "invalid module with id={}", value).unwrap();
            }
        }
    }
}

#[repr(u8)]
enum BoardId {
    Burn,
    Lose,
    Field,
    Invalid(u8),
}

fn read_board_id(board_id_pins: &[InputPin; 4]) -> BoardId {
    let value = board_id_pins
        .iter()
        .rev()
        .enumerate()
        .map(|(idx, pin)| if pin.is_high() { 1 << idx } else { 0 })
        .sum();

    match value {
        1 => BoardId::Burn,
        2 => BoardId::Lose,
        3 => BoardId::Field,
        invalid => BoardId::Invalid(invalid),
    }
}
