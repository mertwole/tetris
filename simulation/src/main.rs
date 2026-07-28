use std::{
    io::{self, Stdout},
    time::Duration,
};

use crossterm::{
    ExecutableCommand, cursor,
    event::{
        Event, EventStream, KeyCode, KeyEvent, KeyEventKind, KeyModifiers,
        KeyboardEnhancementFlags, PushKeyboardEnhancementFlags,
    },
    terminal,
};
use futures::StreamExt;
use tokio::sync::mpsc;

mod field;
use field::Field;

mod common;
use common::*;

mod piece;
use piece::Piece;

mod burn;
use burn::Burn;

mod lose;
mod render;

const FALL_PERIOD_SOFT_DROP: usize = 2;

const SOFT_DROP_SCORE_PER_CELL: u64 = 1;

type Score = u64;

#[tokio::main]
async fn main() {
    let mut stdout = io::stdout();

    stdout.execute(terminal::EnterAlternateScreen).unwrap();
    stdout.execute(cursor::Hide).unwrap();
    stdout
        .execute(PushKeyboardEnhancementFlags(
            KeyboardEnhancementFlags::REPORT_EVENT_TYPES,
        ))
        .unwrap();
    terminal::enable_raw_mode().unwrap();

    game_loop(&mut stdout).await;

    terminal::disable_raw_mode().unwrap();
    stdout.execute(cursor::Show).unwrap();
    stdout.execute(terminal::LeaveAlternateScreen).unwrap();
}

async fn game_loop(stdout: &mut Stdout) {
    let mut field = Field::new();

    let mut piece = Piece::spawn(None);
    let mut next_piece = Piece::spawn(Some(piece.ty));

    let mut score: Score = 0;

    let ctrl_c = Event::Key(KeyEvent::new(KeyCode::Char('c'), KeyModifiers::CONTROL));
    let move_left = Event::Key(KeyEvent::new(KeyCode::Left, KeyModifiers::empty()));
    let move_right = Event::Key(KeyEvent::new(KeyCode::Right, KeyModifiers::empty()));

    let rotate_cw = Event::Key(KeyEvent::new(KeyCode::Char(' '), KeyModifiers::empty()));
    let rotate_ccw = Event::Key(KeyEvent::new(KeyCode::Backspace, KeyModifiers::empty()));

    let soft_drop_pressed = Event::Key(KeyEvent::new_with_kind(
        KeyCode::Down,
        KeyModifiers::empty(),
        KeyEventKind::Press,
    ));
    let soft_drop_released = Event::Key(KeyEvent::new_with_kind(
        KeyCode::Down,
        KeyModifiers::empty(),
        KeyEventKind::Release,
    ));

    let mut events = listen_events();

    let mut frames_from_last_fall = 0;
    let mut fall_period_normal = gravity_by_level(0);
    let mut fall_period = fall_period_normal;

    let mut lines_cleared = 0;

    loop {
        tokio::time::sleep(Duration::from_millis(1000 / 60)).await;

        if !events.is_empty() {
            let event = events.recv().await.unwrap();

            if event == ctrl_c {
                return;
            }

            if event == move_left {
                piece.try_move(&field, Vec2(-1, 0));
            }

            if event == move_right {
                piece.try_move(&field, Vec2(1, 0));
            }

            if event == rotate_cw {
                piece.try_rotate(&field, RotationDirection::Cw);
            }

            if event == rotate_ccw {
                piece.try_rotate(&field, RotationDirection::Ccw);
            }

            if event == soft_drop_pressed {
                fall_period = FALL_PERIOD_SOFT_DROP;
            }

            if event == soft_drop_released {
                fall_period = fall_period_normal;
            }
        }

        frames_from_last_fall += 1;
        if frames_from_last_fall >= fall_period {
            frames_from_last_fall = 0;

            if fall_period == FALL_PERIOD_SOFT_DROP {
                score += SOFT_DROP_SCORE_PER_CELL;
            }

            if !piece.try_move(&field, Vec2(0, -1)) {
                piece.settle(&mut field);

                if let Some(burn) = Burn::new(&field) {
                    lines_cleared += burn.get_row_count();
                    let level = (lines_cleared / 10) as u8;

                    fall_period_normal = gravity_by_level(level);

                    burn.animate(&mut field, &next_piece, &mut score, level, stdout)
                        .await;
                }

                fall_period = fall_period_normal;

                lose::try_lose(
                    &mut field,
                    &next_piece,
                    &mut score,
                    &mut lines_cleared,
                    stdout,
                )
                .await;

                piece = next_piece;
                next_piece = Piece::spawn(Some(piece.ty));
            }
        }

        let level = (lines_cleared / 10) as u8;
        render::render(&field, score, level, Some(&piece), &next_piece, stdout);
    }
}

fn gravity_by_level(level: u8) -> usize {
    match level {
        0 => 48,
        1 => 43,
        2 => 38,
        3 => 33,
        4 => 28,
        5 => 23,
        6 => 18,
        7 => 13,
        8 => 8,
        9 => 6,
        10..=12 => 5,
        13..=15 => 4,
        16..=18 => 3,
        19..=28 => 2,
        _ => 1,
    }
}

fn listen_events() -> mpsc::Receiver<Event> {
    let (sender, receiver) = mpsc::channel(1024);

    let mut events = EventStream::new();

    tokio::spawn(async move {
        loop {
            let event = events.next().await.unwrap().unwrap();
            sender.send(event).await.unwrap();
        }
    });

    receiver
}
