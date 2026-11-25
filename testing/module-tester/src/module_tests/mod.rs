use core::mem;

use atmega_hal::{
    Atmega, Usart,
    port::{
        Pin,
        mode::{Floating, Input},
    },
    usart::UsartOps,
};

use crate::{ClockSpeed, IO_PIN_COUNT};

mod burn;

const MODULE_SPECIFIC_PIN_COUNT: usize = IO_PIN_COUNT - 8;

pub fn run<USART, RX, TX, CLOCK>(
    mut serial: &mut Usart<USART, RX, TX, CLOCK>,
    io_pins: [Pin<Input<Floating>>; IO_PIN_COUNT],
) -> !
where
    USART: UsartOps<Atmega, RX, TX>,
{
    let (module_specific, common): (
        [Pin<Input<Floating>>; MODULE_SPECIFIC_PIN_COUNT],
        [Pin<Input<Floating>>; IO_PIN_COUNT - MODULE_SPECIFIC_PIN_COUNT],
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
    Invalid(u8),
}

fn read_board_id(board_id_pins: &[Pin<Input<Floating>>; 4]) -> BoardId {
    let value = board_id_pins
        .iter()
        .rev()
        .enumerate()
        .map(|(idx, pin)| if pin.is_high() { 1 << idx } else { 0 })
        .sum();

    match value {
        1 => BoardId::Burn,
        invalid => BoardId::Invalid(invalid),
    }
}
