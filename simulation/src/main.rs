use std::{
    io::{self, Stdout, Write},
    time::Duration,
    unreachable,
};

use crossterm::{
    ExecutableCommand, QueueableCommand, cursor,
    event::{Event, EventStream, KeyCode, KeyEvent, KeyModifiers},
    style::{self, StyledContent, Stylize},
    terminal,
};
use futures::StreamExt;

const FIELD_WIDTH: usize = 10;
const FIELD_HEIGHT: usize = 20;

#[tokio::main]
async fn main() {
    let mut stdout = io::stdout();

    stdout.execute(terminal::EnterAlternateScreen).unwrap();
    stdout.execute(cursor::Hide).unwrap();
    terminal::enable_raw_mode().unwrap();

    game_loop(&mut stdout).await;

    stdout.execute(cursor::Show).unwrap();
    stdout.execute(terminal::LeaveAlternateScreen).unwrap();
    terminal::disable_raw_mode().unwrap();
}

async fn game_loop(stdout: &mut Stdout) {
    let mut events = EventStream::new();

    let mut field = Field::new();
    let mut piece = Piece::spawn();

    let ctrl_c = Event::Key(KeyEvent::new(KeyCode::Char('c'), KeyModifiers::CONTROL));
    let move_left = Event::Key(KeyEvent::new(KeyCode::Left, KeyModifiers::empty()));
    let move_right = Event::Key(KeyEvent::new(KeyCode::Right, KeyModifiers::empty()));
    let rotate = Event::Key(KeyEvent::new(KeyCode::Char(' '), KeyModifiers::empty()));

    loop {
        tokio::select! {
            event = events.next() => {
                let event = event.unwrap().unwrap();

                if event == ctrl_c {
                    return;
                }

                if event == move_left {
                    piece.try_move(&field, Vec2(-1, 0));
                }

                if event == move_right {
                    piece.try_move(&field, Vec2(1, 0));
                }

                if event == rotate {
                    piece.try_rotate(&field);
                }
            }
            _ = tokio::time::sleep(Duration::from_millis(200)) => {
                if !piece.try_move(&field, Vec2(0, -1)) {
                    piece.settle(&mut field);
                    piece = Piece::spawn();
                }
            }
        }

        stdout
            .execute(terminal::Clear(terminal::ClearType::All))
            .unwrap();

        render(&field, &piece, stdout);
    }
}

#[derive(Clone, Copy, Debug)]
struct Vec2(isize, isize);

#[derive(Clone, Debug)]
struct Piece {
    ty: PieceType,
    position: Vec2,
    // In range 0..4
    rotation: u8,
}

#[derive(Clone, Copy, Debug)]
enum PieceType {
    I,
    J,
    O,
    L,
    S,
    T,
    Z,
}

impl Piece {
    fn spawn() -> Self {
        let ty = rand::random_range(0..7usize);
        let ty = match ty {
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
            position: Vec2(7, 23),
            rotation: 0,
        }
    }

    fn get_color(&self) -> Color {
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

    fn get_positions(&self) -> [Vec2; 4] {
        let positions = match (self.ty, self.rotation) {
            (PieceType::J, 0) => [Vec2(-1, 1), Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0)],
            (PieceType::J, 1) => [Vec2(0, -1), Vec2(0, 0), Vec2(0, 1), Vec2(1, 1)],
            (PieceType::J, 2) => [Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0), Vec2(1, -1)],
            (PieceType::J, 3) => [Vec2(-1, -1), Vec2(0, -1), Vec2(0, 0), Vec2(0, 1)],

            (PieceType::L, 0) => [Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0), Vec2(1, 1)],
            (PieceType::L, 1) => [Vec2(0, 1), Vec2(0, 0), Vec2(0, -1), Vec2(1, -1)],
            (PieceType::L, 2) => [Vec2(-1, -1), Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0)],
            (PieceType::L, 3) => [Vec2(-1, 1), Vec2(0, 1), Vec2(0, 0), Vec2(0, -1)],

            (PieceType::S, 0) => [Vec2(-1, 0), Vec2(0, 0), Vec2(0, 1), Vec2(1, 1)],
            (PieceType::S, 1) => [Vec2(0, 1), Vec2(0, 0), Vec2(1, 0), Vec2(1, -1)],
            (PieceType::S, 2) => [Vec2(-1, -1), Vec2(0, -1), Vec2(0, 0), Vec2(1, 0)],
            (PieceType::S, 3) => [Vec2(-1, 1), Vec2(-1, 0), Vec2(0, 0), Vec2(0, -1)],

            (PieceType::Z, 0) => [Vec2(-1, 1), Vec2(0, 1), Vec2(0, 0), Vec2(1, 0)],
            (PieceType::Z, 1) => [Vec2(1, 1), Vec2(1, 0), Vec2(0, 0), Vec2(0, -1)],
            (PieceType::Z, 2) => [Vec2(-1, 0), Vec2(0, 0), Vec2(0, -1), Vec2(1, -1)],
            (PieceType::Z, 3) => [Vec2(0, 1), Vec2(0, 0), Vec2(-1, 0), Vec2(-1, -1)],

            (PieceType::T, 0) => [Vec2(-1, 0), Vec2(0, 0), Vec2(0, 1), Vec2(1, 0)],
            (PieceType::T, 1) => [Vec2(0, 1), Vec2(0, 0), Vec2(1, 0), Vec2(0, -1)],
            (PieceType::T, 2) => [Vec2(-1, 0), Vec2(0, 0), Vec2(0, -1), Vec2(1, 0)],
            (PieceType::T, 3) => [Vec2(-1, 0), Vec2(0, 0), Vec2(0, 1), Vec2(0, -1)],

            (PieceType::I, 0) => [Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0), Vec2(2, 0)],
            (PieceType::I, 1) => [Vec2(1, 1), Vec2(1, 0), Vec2(1, -1), Vec2(1, -2)],
            (PieceType::I, 2) => [Vec2(-1, -1), Vec2(0, -1), Vec2(1, -1), Vec2(2, -1)],
            (PieceType::I, 3) => [Vec2(0, 1), Vec2(0, 0), Vec2(0, -1), Vec2(0, -2)],

            (PieceType::O, _) => [Vec2(0, 0), Vec2(0, 1), Vec2(1, 1), Vec2(1, 0)],
            _ => unreachable!(),
        };

        positions.map(|pos| Vec2(pos.0 + self.position.0, pos.1 + self.position.1))
    }

    fn try_move(&mut self, field: &Field, direction: Vec2) -> bool {
        let prev_position = self.position;

        self.position.0 = self.position.0 + direction.0;
        self.position.1 = self.position.1 + direction.1;

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

    fn try_rotate(&mut self, field: &Field) -> bool {
        let prev_rotation = self.rotation;

        self.rotation = (self.rotation + 1) % 4;

        for position in self.get_positions() {
            match field.color_at(position.0 as usize, position.1 as usize) {
                Some(Color::None) => {}
                None => {
                    if position.1 < 3 || position.0 < 3 || position.0 > FIELD_WIDTH as isize + 3 - 1
                    {
                        self.rotation = prev_rotation;
                        return false;
                    }
                }
                _ => {
                    self.rotation = prev_rotation;
                    return false;
                }
            }
        }

        true
    }

    fn settle(&self, field: &mut Field) {
        for position in self.get_positions() {
            field.set_color_at(position.0 as usize, position.1 as usize, self.get_color());
        }
    }
}

struct Field {
    rows: [[Color; FIELD_WIDTH]; FIELD_HEIGHT],
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Color {
    None,
    Yellow,
    Red,
    DarkYellow,
    Blue,
    Cyan,
    Magenta,
    Green,
}

impl Color {
    fn apply_to_text<'a>(&self, text: &'a str) -> StyledContent<&'a str> {
        match self {
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
}

impl Field {
    fn new() -> Self {
        Self {
            rows: [[Color::None; 10]; 20],
        }
    }

    fn is_out_of_bounds(x: usize, y: usize) -> bool {
        x < 3 || x > FIELD_WIDTH + 3 - 1 || y < 3 || y > FIELD_HEIGHT + 3 - 1
    }

    fn color_at(&self, mut x: usize, mut y: usize) -> Option<Color> {
        if Self::is_out_of_bounds(x, y) {
            return None;
        }

        x -= 3;
        y -= 3;

        Some(self.rows[y][x])
    }

    fn set_color_at(&mut self, mut x: usize, mut y: usize, color: Color) {
        if Self::is_out_of_bounds(x, y) {
            panic!("Out of bounds")
        }

        x -= 3;
        y -= 3;

        self.rows[y][x] = color;
    }
}

fn render(field: &Field, piece: &Piece, stdout: &mut Stdout) {
    for y in 0..FIELD_HEIGHT + 3 {
        for x in 0..FIELD_WIDTH + 3 {
            let color = field.color_at(x, y);

            let Some(color) = color else {
                continue;
            };

            let symbol = color.apply_to_text("██");

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

    for position in piece.get_positions() {
        if Field::is_out_of_bounds(position.0 as usize, position.1 as usize) {
            continue;
        }

        let symbol = piece.get_color().apply_to_text("██");

        stdout
            .queue(cursor::MoveTo(
                position.0 as u16 * 2,
                (FIELD_HEIGHT + 3 - 1 - position.1 as usize) as u16,
            ))
            .unwrap()
            .queue(style::PrintStyledContent(symbol))
            .unwrap();
    }

    stdout.flush().unwrap();
}
