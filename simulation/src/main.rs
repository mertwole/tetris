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

    loop {
        tokio::select! {
            event = events.next() => {
                let event = event.unwrap().unwrap();
                if event == ctrl_c {
                    return;
                }
            }
            _ = tokio::time::sleep(Duration::from_millis(100)) => {}
        }

        stdout
            .execute(terminal::Clear(terminal::ClearType::All))
            .unwrap();

        if !piece.try_move_down(&field) {
            piece.settle(&mut field);
            piece = Piece::spawn();
        }

        render(&field, &piece, stdout);
    }
}

#[derive(Clone, Copy, Debug)]
struct Vec2(usize, usize);

#[derive(Clone, Debug)]
struct Piece {
    positions: [Vec2; 4],
    color: Color,
}

impl Piece {
    fn spawn() -> Self {
        let ty = rand::random_range(0..7usize);
        let positions = match ty {
            0 => [Vec2(6, 23), Vec2(7, 23), Vec2(8, 23), Vec2(9, 23)], // I
            1 => [Vec2(7, 24), Vec2(7, 23), Vec2(8, 23), Vec2(9, 23)], // J
            2 => [Vec2(7, 24), Vec2(7, 23), Vec2(8, 24), Vec2(8, 23)], // O
            3 => [Vec2(7, 23), Vec2(8, 23), Vec2(9, 23), Vec2(9, 24)], // L
            4 => [Vec2(7, 23), Vec2(8, 23), Vec2(8, 24), Vec2(9, 24)], // S
            5 => [Vec2(6, 23), Vec2(7, 23), Vec2(7, 24), Vec2(8, 23)], // T
            6 => [Vec2(6, 24), Vec2(7, 24), Vec2(7, 23), Vec2(8, 23)], // Z
            _ => unreachable!(),
        };
        let color = match ty {
            0 => Color::Blue,
            1 => Color::Cyan,
            2 => Color::DarkYellow,
            3 => Color::Green,
            4 => Color::Magenta,
            5 => Color::Red,
            6 => Color::Yellow,
            _ => unreachable!(),
        };

        Self { positions, color }
    }

    fn try_move_down(&mut self, field: &Field) -> bool {
        let updated_positions = self.positions.map(|pos| Vec2(pos.0, pos.1 - 1));

        for position in updated_positions {
            match field.color_at(position.0, position.1) {
                Some(Color::None) => {}
                None => {
                    if position.1 < 3 {
                        return false;
                    }
                }
                _ => {
                    return false;
                }
            }
        }

        self.positions = updated_positions;

        true
    }

    fn settle(&self, field: &mut Field) {
        for position in self.positions {
            field.set_color_at(position.0, position.1, self.color);
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

    fn color_at(&self, mut x: usize, mut y: usize) -> Option<Color> {
        if x < 3 || x > FIELD_WIDTH + 3 - 1 || y < 3 || y > FIELD_HEIGHT + 3 - 1 {
            return None;
        }

        x -= 3;
        y -= 3;

        Some(self.rows[y][x])
    }

    fn set_color_at(&mut self, mut x: usize, mut y: usize, color: Color) {
        if x < 3 || x > FIELD_WIDTH + 3 - 1 || y < 3 || y > FIELD_HEIGHT + 3 - 1 {
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

    for position in piece.positions {
        let symbol = piece.color.apply_to_text("██");

        stdout
            .queue(cursor::MoveTo(
                position.0 as u16 * 2,
                (FIELD_HEIGHT + 3 - 1 - position.1) as u16,
            ))
            .unwrap()
            .queue(style::PrintStyledContent(symbol))
            .unwrap();
    }

    stdout.flush().unwrap();
}
