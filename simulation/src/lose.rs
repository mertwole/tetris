use std::{io::Stdout, time::Duration};

use crate::{
    Score,
    common::*,
    field::{Field, HEIGHT as FIELD_HEIGHT, WIDTH as FIELD_WIDTH},
    piece::Piece,
    render,
};

pub async fn try_lose(
    field: &mut Field,
    next_piece: &Piece,
    score: &mut Score,
    lines_cleared: &mut usize,
    stdout: &mut Stdout,
) {
    let y = FIELD_HEIGHT + 3 - 1;
    let lost = (3..FIELD_WIDTH + 3)
        .map(|x| field.color_at(x, y))
        .any(|color| color != Some(Color::None));

    if lost {
        for y in (3..FIELD_HEIGHT + 3).rev() {
            for x in 3..FIELD_WIDTH + 3 {
                field.set_color_at(x, y, Color::None);
            }

            tokio::time::sleep(Duration::from_millis(100)).await;
            // Invariant: Piece is not visible during the lose.
            render::render(
                field,
                *score,
                (*lines_cleared / 10) as u8,
                None,
                next_piece,
                stdout,
            );
        }

        *score = 0;
        *lines_cleared = 0;
    }
}
