#![no_std]
#![no_main]

use atmega_hal::{Usart, usart::Baudrate};
use panic_halt as _;

mod fpga_communication_test;
mod manual_test;
mod module_tests;

type ClockSpeed = atmega_hal::clock::MHz8;

const IO_PIN_COUNT: usize = 56;

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

    let io_pins: [_; IO_PIN_COUNT] = [
        // Port C.
        pins.pc0.into_floating_input().downgrade(),
        pins.pc1.into_floating_input().downgrade(),
        pins.pc2.into_floating_input().downgrade(),
        pins.pc3.into_floating_input().downgrade(),
        pins.pc4.into_floating_input().downgrade(),
        pins.pc5.into_floating_input().downgrade(),
        pins.pc6.into_floating_input().downgrade(),
        pins.pc7.into_floating_input().downgrade(),
        // Port A
        pins.pa7.into_floating_input().downgrade(),
        pins.pa6.into_floating_input().downgrade(),
        pins.pa5.into_floating_input().downgrade(),
        pins.pa4.into_floating_input().downgrade(),
        pins.pa3.into_floating_input().downgrade(),
        pins.pa2.into_floating_input().downgrade(),
        pins.pa1.into_floating_input().downgrade(),
        pins.pa0.into_floating_input().downgrade(),
        // Port K.
        pins.pk7.into_floating_input().downgrade(),
        pins.pk6.into_floating_input().downgrade(),
        pins.pk5.into_floating_input().downgrade(),
        pins.pk4.into_floating_input().downgrade(),
        pins.pk3.into_floating_input().downgrade(),
        pins.pk2.into_floating_input().downgrade(),
        pins.pk1.into_floating_input().downgrade(),
        pins.pk0.into_floating_input().downgrade(),
        // Port D.
        pins.pd7.into_floating_input().downgrade(),
        pins.pd6.into_floating_input().downgrade(),
        pins.pd5.into_floating_input().downgrade(),
        pins.pd4.into_floating_input().downgrade(),
        pins.pd3.into_floating_input().downgrade(),
        pins.pd2.into_floating_input().downgrade(),
        pins.pd1.into_floating_input().downgrade(),
        pins.pd0.into_floating_input().downgrade(),
        // Port L.
        pins.pl7.into_floating_input().downgrade(),
        pins.pl6.into_floating_input().downgrade(),
        pins.pl5.into_floating_input().downgrade(),
        pins.pl4.into_floating_input().downgrade(),
        pins.pl3.into_floating_input().downgrade(),
        pins.pl2.into_floating_input().downgrade(),
        pins.pl1.into_floating_input().downgrade(),
        pins.pl0.into_floating_input().downgrade(),
        // Port H.
        pins.ph7.into_floating_input().downgrade(),
        pins.ph6.into_floating_input().downgrade(),
        pins.ph5.into_floating_input().downgrade(),
        pins.ph4.into_floating_input().downgrade(),
        pins.ph3.into_floating_input().downgrade(),
        pins.ph2.into_floating_input().downgrade(),
        pins.ph1.into_floating_input().downgrade(),
        pins.ph0.into_floating_input().downgrade(),
        // Port F.
        pins.pf7.into_floating_input().downgrade(),
        pins.pf6.into_floating_input().downgrade(),
        pins.pf5.into_floating_input().downgrade(),
        pins.pf4.into_floating_input().downgrade(),
        pins.pf3.into_floating_input().downgrade(),
        pins.pf2.into_floating_input().downgrade(),
        pins.pf1.into_floating_input().downgrade(),
        pins.pf0.into_floating_input().downgrade(),
    ];

    module_tests::run(&mut serial, io_pins);
}
