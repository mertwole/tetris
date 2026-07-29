use std::io::{Stdout, Write};

use crossterm::{
    ExecutableCommand, QueueableCommand, cursor,
    style::{self, StyledContent, Stylize},
    terminal,
};

use crate::{
    Piece, Score,
    common::*,
    field::{Field, HEIGHT as FIELD_HEIGHT, WIDTH as FIELD_WIDTH},
};

pub fn render(
    field: &Field,
    score: Score,
    level: u8,
    piece: Option<&Piece>,
    next_piece: &Piece,
    stdout: &mut Stdout,
) {
    stdout
        .execute(terminal::Clear(terminal::ClearType::All))
        .unwrap();

    for y in 3..FIELD_HEIGHT + 3 {
        for x in 3..FIELD_WIDTH + 3 {
            let color = field.color_at(x, y);

            let Some(color) = color else {
                continue;
            };

            let symbol = apply_color_to_text(color, "██");

            stdout
                .queue(cursor::MoveTo(
                    x as u16 * 2,
                    (FIELD_HEIGHT + 3 - 1 - y) as u16,
                ))
                .unwrap()
                .queue(style::PrintStyledContent(symbol))
                .unwrap();
        }
    }

    stdout
        .queue(cursor::MoveTo(6, FIELD_HEIGHT as u16))
        .unwrap()
        .queue(style::PrintStyledContent(
            format!("score: {}  level: {}", score, level).dark_magenta(),
        ))
        .unwrap();

    let mut next_piece = next_piece.clone();
    next_piece.position.1 -= 2;
    next_piece.position.0 += FIELD_WIDTH as isize;
    render_piece(&next_piece, stdout);

    if let Some(piece) = piece {
        render_piece(piece, stdout);
    }

    stdout.flush().unwrap();
}

fn render_piece(piece: &Piece, stdout: &mut Stdout) {
    for position in piece.get_positions() {
        let symbol = apply_color_to_text(piece.get_color(), "██");

        stdout
            .queue(cursor::MoveTo(
                position.0 as u16 * 2,
                (FIELD_HEIGHT + 3 - 1 - position.1 as usize) as u16,
            ))
            .unwrap()
            .queue(style::PrintStyledContent(symbol))
            .unwrap();
    }
}

fn apply_color_to_text(color: Color, text: &str) -> StyledContent<&str> {
    match color {
        Color::None => text.black(),
        Color::Yellow => text.yellow(),
        Color::Red => text.red(),
        Color::DarkYellow => text.dark_yellow(),
        Color::Blue => text.blue(),
        Color::Cyan => text.cyan(),
        Color::Magenta => text.magenta(),
        Color::Green => text.green(),
    }
}
