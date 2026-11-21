#![no_std]
#![no_main]

use atmega_hal::{delay::Delay, prelude::*, usart::Baudrate, Usart};
use panic_halt as _;

type ClockSpeed = atmega_hal::clock::MHz8;

#[atmega_hal::entry]
fn main() -> ! {
    let dp = atmega_hal::Peripherals::take().unwrap();
    let pins = atmega_hal::pins!(dp);

    let mut serial = Usart::new(
        dp.USART0,
        pins.pe0,
        pins.pe1.into_output(),
        Baudrate::<ClockSpeed>::new(9600),
    );

    let mut delay = Delay::<ClockSpeed>::new();

    loop {
        ufmt::uwriteln!(&mut serial, "Hello from ATmega!").unwrap();
        delay.delay_ms(1_000u16);
    }
}
