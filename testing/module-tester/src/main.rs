#![no_std]
#![no_main]

use atmega_hal::{Usart, delay::Delay, usart::Baudrate};
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

    let mut output_pins: [_; 56] = [
        // Port C.
        pins.pc0.into_output().downgrade(),
        pins.pc1.into_output().downgrade(),
        pins.pc2.into_output().downgrade(),
        pins.pc3.into_output().downgrade(),
        pins.pc4.into_output().downgrade(),
        pins.pc5.into_output().downgrade(),
        pins.pc6.into_output().downgrade(),
        pins.pc7.into_output().downgrade(),
        // Port A
        pins.pa7.into_output().downgrade(),
        pins.pa6.into_output().downgrade(),
        pins.pa5.into_output().downgrade(),
        pins.pa4.into_output().downgrade(),
        pins.pa3.into_output().downgrade(),
        pins.pa2.into_output().downgrade(),
        pins.pa1.into_output().downgrade(),
        pins.pa0.into_output().downgrade(),
        // Port K.
        pins.pk7.into_output().downgrade(),
        pins.pk6.into_output().downgrade(),
        pins.pk5.into_output().downgrade(),
        pins.pk4.into_output().downgrade(),
        pins.pk3.into_output().downgrade(),
        pins.pk2.into_output().downgrade(),
        pins.pk1.into_output().downgrade(),
        pins.pk0.into_output().downgrade(),
        // Port D.
        pins.pd7.into_output().downgrade(),
        pins.pd6.into_output().downgrade(),
        pins.pd5.into_output().downgrade(),
        pins.pd4.into_output().downgrade(),
        pins.pd3.into_output().downgrade(),
        pins.pd2.into_output().downgrade(),
        pins.pd1.into_output().downgrade(),
        pins.pd0.into_output().downgrade(),
        // Port L.
        pins.pl7.into_output().downgrade(),
        pins.pl6.into_output().downgrade(),
        pins.pl5.into_output().downgrade(),
        pins.pl4.into_output().downgrade(),
        pins.pl3.into_output().downgrade(),
        pins.pl2.into_output().downgrade(),
        pins.pl1.into_output().downgrade(),
        pins.pl0.into_output().downgrade(),
        // Port H.
        pins.ph7.into_output().downgrade(),
        pins.ph6.into_output().downgrade(),
        pins.ph5.into_output().downgrade(),
        pins.ph4.into_output().downgrade(),
        pins.ph3.into_output().downgrade(),
        pins.ph2.into_output().downgrade(),
        pins.ph1.into_output().downgrade(),
        pins.ph0.into_output().downgrade(),
        // Port F.
        pins.pf7.into_output().downgrade(),
        pins.pf6.into_output().downgrade(),
        pins.pf5.into_output().downgrade(),
        pins.pf4.into_output().downgrade(),
        pins.pf3.into_output().downgrade(),
        pins.pf2.into_output().downgrade(),
        pins.pf1.into_output().downgrade(),
        pins.pf0.into_output().downgrade(),
    ];

    loop {
        let mut pin_to_toggle = [0u8; 2];
        let mut read_bytes = 0;
        loop {
            let byte = serial.read_byte();

            if byte == b'\n' || byte == 0 {
                break;
            }

            if read_bytes < pin_to_toggle.len() {
                pin_to_toggle[read_bytes] = byte;
            }

            read_bytes += 1;
        }

        let is_valid_digit = |char: u8| -> bool { char >= b'0' && char <= b'9' };

        let pin_idx = match read_bytes {
            1 => {
                if !is_valid_digit(pin_to_toggle[0]) {
                    ufmt::uwriteln!(&mut serial, "Wrong input format").unwrap();
                    continue;
                }

                pin_to_toggle[0] - b'0'
            }
            2 => {
                if !is_valid_digit(pin_to_toggle[0]) || !is_valid_digit(pin_to_toggle[1]) {
                    ufmt::uwriteln!(&mut serial, "Wrong input format").unwrap();
                    continue;
                }

                10 * (pin_to_toggle[0] - b'0') + pin_to_toggle[1] - b'0'
            }
            _ => {
                ufmt::uwriteln!(&mut serial, "Wrong input length").unwrap();
                continue;
            }
        };

        if pin_idx >= 56 {
            ufmt::uwriteln!(&mut serial, "Wrong pin index: {}", pin_idx).unwrap();
            continue;
        }

        output_pins[pin_idx as usize].toggle();
        ufmt::uwriteln!(&mut serial, "Toggled pin {}. Enabled pins:", pin_idx).unwrap();
        for (idx, pin) in output_pins.iter().enumerate() {
            if pin.is_set_high() {
                ufmt::uwriteln!(&mut serial, "{}", idx).unwrap();
            }
        }
        ufmt::uwriteln!(&mut serial, "").unwrap();
    }
}
