use core::mem;

use atmega_hal::{
    Atmega, Usart,
    delay::Delay,
    port::{
        Pin,
        mode::{Floating, Input},
    },
    usart::UsartOps,
};
use embedded_hal::delay::DelayNs;

use crate::{ClockSpeed, IO_PIN_COUNT};

pub fn fpga_communication_test<USART, RX, TX, CLOCK>(
    mut serial: &mut Usart<USART, RX, TX, CLOCK>,
    io_pins: [Pin<Input<Floating>>; IO_PIN_COUNT],
) -> !
where
    USART: UsartOps<Atmega, RX, TX>,
{
    let (outputs, inputs): (
        [Pin<Input<Floating>>; IO_PIN_COUNT - 6],
        [Pin<Input<Floating>>; 6],
    ) = unsafe { mem::transmute(io_pins) };
    let mut outputs = outputs.map(|pin| pin.into_output());

    let read_inputs = || -> usize {
        inputs
            .iter()
            .enumerate()
            .map(|(idx, input)| if input.is_high() { 1 << idx } else { 0 })
            .sum()
    };

    let mut delay = Delay::<ClockSpeed>::new();

    for output in &mut outputs {
        output.set_low();
    }

    loop {
        // Wait for any input.
        let _ = serial.read_byte();

        for i in 0..IO_PIN_COUNT - 6 {
            outputs[i].set_high();
            delay.delay_ms(100);

            ufmt::uwrite!(&mut serial, "testing io_{}...", i).unwrap();
            let result = read_inputs();
            if result == i {
                ufmt::uwriteln!(&mut serial, "success").unwrap();
            } else {
                ufmt::uwriteln!(&mut serial, "failed(got {})", result).unwrap();
            }
            outputs[i].set_low();
            delay.delay_ms(100);
        }
    }
}
