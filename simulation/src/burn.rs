use std::{io::Stdout, time::Duration};

use crate::{
    Score,
    common::*,
    field::{Field, HEIGHT as FIELD_HEIGHT, WIDTH as FIELD_WIDTH},
    piece::Piece,
    render,
};

pub struct Burn {
    rows: Vec<usize>,
}

impl Burn {
    pub fn new(field: &Field) -> Option<Self> {
        let mut rows = vec![];
        for row in 3..FIELD_HEIGHT + 3 {
            let to_burn = (3..FIELD_WIDTH + 3)
                .map(|x| field.color_at(x, row))
                .all(|color| !matches!(color, None | Some(Color::None)));

            if to_burn {
                rows.push(row);
            }
        }

        if rows.is_empty() {
            None
        } else {
            Some(Self { rows })
        }
    }

    pub fn get_row_count(&self) -> usize {
        self.rows.len()
    }

    pub async fn animate(
        self,
        field: &mut Field,
        next_piece: &Piece,
        score: &mut Score,
        level: u8,
        stdout: &mut Stdout,
    ) {
        for step in 0..FIELD_WIDTH {
            for row in &self.rows {
                field.set_color_at(step + 3, *row, Color::None);
            }

            tokio::time::sleep(Duration::from_millis(20)).await;
            // Invariant: Piece is not visible during the burn.
            render::render(field, *score, level, None, next_piece, stdout);
        }

        *score += match self.rows.len() {
            1 => 40 * (level as u64 + 1),
            2 => 100 * (level as u64 + 1),
            3 => 300 * (level as u64 + 1),
            4 => 1200 * (level as u64 + 1),
            _ => unreachable!(),
        };

        for (already_processed, mut row) in self.rows.into_iter().enumerate() {
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
    }
}
