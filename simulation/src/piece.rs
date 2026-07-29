use crate::{
    common::*,
    field::{Field, WIDTH as FIELD_WIDTH},
};

#[derive(Clone, Debug)]
pub struct Piece {
    pub ty: PieceType,
    pub position: Vec2,
    // In range 0..4
    rotation: u8,
}

#[derive(Clone, Copy, Debug)]
#[repr(usize)]
pub enum PieceType {
    I = 0,
    J,
    O,
    L,
    S,
    T,
    Z,
}

impl Piece {
    pub fn spawn(last_piece: Option<PieceType>) -> Self {
        let mut roll = rand::random_range(0..8usize);
        let last_piece = last_piece.map(|piece| piece as usize).unwrap_or(7);
        if roll == 7 || roll == last_piece {
            roll = rand::random_range(0..7usize);
        }

        let ty = match roll {
            0 => PieceType::I,
            1 => PieceType::J,
            2 => PieceType::O,
            3 => PieceType::L,
            4 => PieceType::S,
            5 => PieceType::T,
            6 => PieceType::Z,
            _ => unreachable!(),
        };

        Self {
            ty,
            position: Vec2(8, 22),
            rotation: 0,
        }
    }

    pub fn get_color(&self) -> Color {
        match self.ty {
            PieceType::I => Color::Blue,
            PieceType::J => Color::Cyan,
            PieceType::L => Color::DarkYellow,
            PieceType::O => Color::Green,
            PieceType::S => Color::Magenta,
            PieceType::Z => Color::Red,
            PieceType::T => Color::Yellow,
        }
    }

    pub fn get_positions(&self) -> [Vec2; 4] {
        let positions = match (self.ty, self.rotation) {
            (PieceType::J, 0) => [Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0), Vec2(1, -1)],
            (PieceType::J, 1) => [Vec2(0, 1), Vec2(0, 0), Vec2(-1, -1), Vec2(0, -1)],
            (PieceType::J, 2) => [Vec2(-1, 1), Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0)],
            (PieceType::J, 3) => [Vec2(0, 1), Vec2(1, 1), Vec2(0, 0), Vec2(0, -1)],

            (PieceType::L, 0) => [Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0), Vec2(-1, -1)],
            (PieceType::L, 1) => [Vec2(-1, 1), Vec2(0, 1), Vec2(0, 0), Vec2(0, -1)],
            (PieceType::L, 2) => [Vec2(1, 1), Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0)],
            (PieceType::L, 3) => [Vec2(0, 1), Vec2(0, 0), Vec2(0, -1), Vec2(1, -1)],

            (PieceType::S, 0 | 2) => [Vec2(0, 0), Vec2(1, 0), Vec2(-1, -1), Vec2(0, -1)],
            (PieceType::S, 1 | 3) => [Vec2(0, 1), Vec2(0, 0), Vec2(1, 0), Vec2(1, -1)],

            (PieceType::Z, 0 | 2) => [Vec2(-1, 0), Vec2(0, 0), Vec2(0, -1), Vec2(1, -1)],
            (PieceType::Z, 1 | 3) => [Vec2(1, 1), Vec2(0, 0), Vec2(1, 0), Vec2(0, -1)],

            (PieceType::T, 0) => [Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0), Vec2(0, -1)],
            (PieceType::T, 1) => [Vec2(0, 1), Vec2(-1, 0), Vec2(0, 0), Vec2(0, -1)],
            (PieceType::T, 2) => [Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0), Vec2(0, 1)],
            (PieceType::T, 3) => [Vec2(0, 1), Vec2(0, 0), Vec2(1, 0), Vec2(0, -1)],

            (PieceType::I, 0 | 2) => [Vec2(-2, 0), Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0)],
            (PieceType::I, 1 | 3) => [Vec2(0, 2), Vec2(0, 1), Vec2(0, 0), Vec2(0, -1)],

            (PieceType::O, _) => [Vec2(-1, 0), Vec2(0, 0), Vec2(-1, -1), Vec2(0, -1)],
            _ => unreachable!(),
        };

        positions.map(|pos| Vec2(pos.0 + self.position.0, pos.1 + self.position.1))
    }

    pub fn try_move(&mut self, field: &Field, direction: Vec2) -> bool {
        let prev_position = self.position;

        self.position.0 += direction.0;
        self.position.1 += direction.1;

        for position in self.get_positions() {
            match field.color_at(position.0 as usize, position.1 as usize) {
                Some(Color::None) => {}
                None => {
                    if position.1 < 3 || position.0 < 3 || position.0 > FIELD_WIDTH as isize + 3 - 1
                    {
                        self.position = prev_position;
                        return false;
                    }
                }
                _ => {
                    self.position = prev_position;
                    return false;
                }
            }
        }

        true
    }

    pub fn try_rotate(&mut self, field: &Field, direction: RotationDirection) -> bool {
        let prev_rotation = self.rotation;

        self.rotation = match direction {
            RotationDirection::Cw => self.rotation + 1,
            RotationDirection::Ccw => self.rotation + 3,
        } % 4;

        let fits = self.get_positions().into_iter().all(|pos| {
            match field.color_at(pos.0 as usize, pos.1 as usize) {
                Some(Color::None) => true,
                None if (3..=FIELD_WIDTH + 3 - 1).contains(&(pos.0 as usize)) && pos.1 > 3 => true,
                _ => false,
            }
        });

        if fits {
            return true;
        }

        self.rotation = prev_rotation;

        false
    }

    pub fn settle(&self, field: &mut Field) {
        for position in self.get_positions() {
            field.set_color_at(position.0 as usize, position.1 as usize, self.get_color());
        }
    }
}
