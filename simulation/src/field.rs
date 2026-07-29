use crate::Color;

pub const WIDTH: usize = 10;
pub const HEIGHT: usize = 20;

pub struct Field {
    rows: [[Color; WIDTH]; HEIGHT],
}

impl Field {
    pub fn new() -> Self {
        Self {
            rows: [[Color::None; 10]; 20],
        }
    }

    pub fn is_out_of_bounds(x: usize, y: usize) -> bool {
        let is_inside = (3..=WIDTH + 3 - 1).contains(&x) && (3..=HEIGHT + 3 - 1).contains(&y);
        !is_inside
    }

    pub fn color_at(&self, mut x: usize, mut y: usize) -> Option<Color> {
        if Self::is_out_of_bounds(x, y) {
            return None;
        }

        x -= 3;
        y -= 3;

        Some(self.rows[y][x])
    }

    pub fn set_color_at(&mut self, mut x: usize, mut y: usize, color: Color) {
        if Self::is_out_of_bounds(x, y) {
            return;
        }

        x -= 3;
        y -= 3;

        self.rows[y][x] = color;
    }
}
