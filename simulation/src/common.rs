#[derive(Clone, Copy, Debug)]
pub struct Vec2(pub isize, pub isize);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Color {
    None,
    Yellow,
    Red,
    DarkYellow,
    Blue,
    Cyan,
    Magenta,
    Green,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum RotationDirection {
    Cw,
    Ccw,
}
