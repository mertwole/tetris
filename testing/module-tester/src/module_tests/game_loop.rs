use atmega_hal::{Atmega, Usart, delay::Delay, port::Pin, usart::UsartOps};

use crate::{
    ClockSpeed,
    module_tests::{InputPin, MODULE_SPECIFIC_PIN_COUNT, OutputPin},
};

pub fn run<USART, RX, TX, CLOCK>(
    mut serial: &mut Usart<USART, RX, TX, CLOCK>,
    mut clk: OutputPin,
    mut reset_n: OutputPin,
    io_pins: [InputPin; MODULE_SPECIFIC_PIN_COUNT],
) where
    USART: UsartOps<Atmega, RX, TX>,
{
    let mut _io = Io::parse(io_pins);

    let mut _delay = Delay::<ClockSpeed>::new();
}

struct Io {
    button_rotate_cw: OutputPin,
    button_rotate_ccw: OutputPin,
    button_left: OutputPin,
    button_right: OutputPin,
    button_down: OutputPin,
    button_start: OutputPin,

    current_level: [OutputPin; 5],

    piece_movement: [InputPin; 3],
    piece_rotation: [InputPin; 2],

    current_piece_center_y: [OutputPin; 5],
    current_piece_type: [OutputPin; 3],

    start_burn: InputPin,
    burn_result: [OutputPin; 2],

    start_lose_check: InputPin,
    lose_result: [OutputPin; 2],

    generate_new_piece: InputPin,

    soft_dropping_movement: InputPin,
    reset_soft_drop_score: InputPin,
    commit_soft_drop_score: InputPin,

    reset_scores: InputPin,

    game_state_out: [InputPin; 2],

    start_piece_operation: [InputPin; 2],
    piece_operation_result: [OutputPin; 2],

    debug_state: [InputPin; 4],
    debug_animating_burn: InputPin,
    debug_animating_lose: InputPin,
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
            _io_41,
            io_42,
            io_43,
            io_44,
            io_45,
            io_46,
            io_47,
        ] = pins;

        Self {
            button_rotate_cw: io_0.into_output(),
            button_rotate_ccw: io_1.into_output(),
            button_left: io_2.into_output(),
            button_right: io_3.into_output(),
            button_down: io_4.into_output(),
            button_start: io_5.into_output(),

            current_level: [io_10, io_9, io_8, io_7, io_6].map(Pin::into_output),

            piece_movement: [io_13, io_12, io_11],
            piece_rotation: [io_15, io_14],

            current_piece_center_y: [io_20, io_19, io_18, io_17, io_16].map(Pin::into_output),
            current_piece_type: [io_23, io_22, io_21].map(Pin::into_output),

            start_burn: io_24,
            burn_result: [io_26, io_25].map(Pin::into_output),

            start_lose_check: io_27,
            lose_result: [io_29, io_28].map(Pin::into_output),

            generate_new_piece: io_30,

            soft_dropping_movement: io_31,
            reset_soft_drop_score: io_32,
            commit_soft_drop_score: io_33,

            reset_scores: io_34,

            game_state_out: [io_36, io_35],

            start_piece_operation: [io_38, io_37],
            piece_operation_result: [io_40, io_39].map(Pin::into_output),

            debug_state: [io_45, io_44, io_43, io_42],
            debug_animating_burn: io_46,
            debug_animating_lose: io_47,
        }
    }
}
