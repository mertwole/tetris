use atmega_hal::{
    Atmega, Usart,
    port::{Pin, mode::Output},
    usart::UsartOps,
};

use crate::IO_PIN_COUNT;

pub fn manual_test<USART, RX, TX, CLOCK>(
    mut serial: &mut Usart<USART, RX, TX, CLOCK>,
    mut io_pins: [Pin<Output>; IO_PIN_COUNT],
) -> !
where
    USART: UsartOps<Atmega, RX, TX>,
{
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

        let pin_idx = match read_bytes {
            1 => {
                if !pin_to_toggle[0].is_ascii_digit() {
                    ufmt::uwriteln!(&mut serial, "Wrong input format").unwrap();
                    continue;
                }

                pin_to_toggle[0] - b'0'
            }
            2 => {
                if !pin_to_toggle[0].is_ascii_digit() || !pin_to_toggle[1].is_ascii_digit() {
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

        io_pins[pin_idx as usize].toggle();
        ufmt::uwriteln!(&mut serial, "Toggled pin {}. Enabled pins:", pin_idx).unwrap();
        for (idx, pin) in io_pins.iter().enumerate() {
            if pin.is_set_high() {
                ufmt::uwriteln!(&mut serial, "{}", idx).unwrap();
            }
        }
        ufmt::uwriteln!(&mut serial, "").unwrap();
    }
}
