#![no_std]
#![no_main]

use core::mem;

use atmega_hal::{
    Atmega, Usart,
    delay::Delay,
    port::{Pin, mode::Output},
    usart::{Baudrate, UsartOps},
};
use embedded_hal::delay::DelayNs;
use panic_halt as _;

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
        pins.pc0.downgrade(),
        pins.pc1.downgrade(),
        pins.pc2.downgrade(),
        pins.pc3.downgrade(),
        pins.pc4.downgrade(),
        pins.pc5.downgrade(),
        pins.pc6.downgrade(),
        pins.pc7.downgrade(),
        // Port A
        pins.pa7.downgrade(),
        pins.pa6.downgrade(),
        pins.pa5.downgrade(),
        pins.pa4.downgrade(),
        pins.pa3.downgrade(),
        pins.pa2.downgrade(),
        pins.pa1.downgrade(),
        pins.pa0.downgrade(),
        // Port K.
        pins.pk7.downgrade(),
        pins.pk6.downgrade(),
        pins.pk5.downgrade(),
        pins.pk4.downgrade(),
        pins.pk3.downgrade(),
        pins.pk2.downgrade(),
        pins.pk1.downgrade(),
        pins.pk0.downgrade(),
        // Port D.
        pins.pd7.downgrade(),
        pins.pd6.downgrade(),
        pins.pd5.downgrade(),
        pins.pd4.downgrade(),
        pins.pd3.downgrade(),
        pins.pd2.downgrade(),
        pins.pd1.downgrade(),
        pins.pd0.downgrade(),
        // Port L.
        pins.pl7.downgrade(),
        pins.pl6.downgrade(),
        pins.pl5.downgrade(),
        pins.pl4.downgrade(),
        pins.pl3.downgrade(),
        pins.pl2.downgrade(),
        pins.pl1.downgrade(),
        pins.pl0.downgrade(),
        // Port H.
        pins.ph7.downgrade(),
        pins.ph6.downgrade(),
        pins.ph5.downgrade(),
        pins.ph4.downgrade(),
        pins.ph3.downgrade(),
        pins.ph2.downgrade(),
        pins.ph1.downgrade(),
        pins.ph0.downgrade(),
        // Port F.
        pins.pf7.downgrade(),
        pins.pf6.downgrade(),
        pins.pf5.downgrade(),
        pins.pf4.downgrade(),
        pins.pf3.downgrade(),
        pins.pf2.downgrade(),
        pins.pf1.downgrade(),
        pins.pf0.downgrade(),
    ];

    fpga_communication_test(&mut serial, io_pins.map(|pin| pin.into_output()));
}

fn manual_test<USART, RX, TX, CLOCK>(
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

fn fpga_communication_test<USART, RX, TX, CLOCK>(
    mut serial: &mut Usart<USART, RX, TX, CLOCK>,
    io_pins: [Pin<Output>; IO_PIN_COUNT],
) -> !
where
    USART: UsartOps<Atmega, RX, TX>,
{
    let (mut outputs, inputs): ([Pin<Output>; IO_PIN_COUNT - 6], [Pin<Output>; 6]) =
        unsafe { mem::transmute(io_pins) };
    let inputs = inputs.map(|pin| pin.into_floating_input());

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
