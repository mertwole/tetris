use std::{io::Stdout, time::Duration};

use crate::{
    Score,
    common::*,
    field::{Field, HEIGHT as FIELD_HEIGHT, WIDTH as FIELD_WIDTH},
    piece::Piece,
    render,
};

pub struct BurnResult {
    pub burned_rows: usize,
}

pub async fn try_burn(
    field: &mut Field,
    next_piece: &Piece,
    score: &mut Score,
    level: u8,
    stdout: &mut Stdout,
) -> BurnResult {
    let rows = check_rows_to_burn(&*field);

    if rows.is_empty() {
        return BurnResult { burned_rows: 0 };
    }

    for step in 0..FIELD_WIDTH {
        for row in &rows {
            field.set_color_at(step + 3, *row, Color::None);
        }

        tokio::time::sleep(Duration::from_millis(20)).await;
        // Invariant: Piece is not visible during the burn.
        render::render(field, *score, level, None, next_piece, stdout);
    }

    *score += match rows.len() {
        1 => 40 * (level as u64 + 1),
        2 => 100 * (level as u64 + 1),
        3 => 300 * (level as u64 + 1),
        4 => 1200 * (level as u64 + 1),
        _ => unreachable!(),
    };

    for (already_processed, row) in rows.iter().enumerate() {
        let mut row = *row;
        row -= already_processed;

        for y in row + 1..FIELD_HEIGHT + 3 {
            for x in 3..FIELD_WIDTH + 3 {
                field.set_color_at(x, y - 1, field.color_at(x, y).unwrap());
            }
        }

        tokio::time::sleep(Duration::from_millis(100)).await;
        // Invariant: Piece is not visible during the burn.
        render::render(field, *score, level, None, next_piece, stdout);
    }

    BurnResult {
        burned_rows: rows.len(),
    }
}

fn check_rows_to_burn(field: &Field) -> Vec<usize> {
    let mut rows = vec![];
    for row in 3..FIELD_HEIGHT + 3 {
        let to_burn = (3..FIELD_WIDTH + 3)
            .map(|x| field.color_at(x, row))
            .all(|color| !matches!(color, None | Some(Color::None)));

        if to_burn {
            rows.push(row);
        }
    }

    rows
}
