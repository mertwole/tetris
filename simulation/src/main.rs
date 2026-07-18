use std::{
    io::{self, Stdout, Write},
    time::Duration,
};

use crossterm::{
    ExecutableCommand, QueueableCommand, cursor,
    event::{Event, EventStream, KeyCode, KeyEvent, KeyModifiers},
    style::{self, Stylize},
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
    field.set_color_at(0, 0, Color::Blue);
    field.set_color_at(3, 3, Color::Cyan);
    field.set_color_at(4, 4, Color::Yellow);

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

        field.render(stdout);
    }
}

struct Field {
    rows: [[Color; FIELD_WIDTH]; FIELD_HEIGHT],
}

#[derive(Clone, Copy)]
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

impl Field {
    fn new() -> Self {
        Self {
            rows: [[Color::None; 10]; 20],
        }
    }

    fn color_at(&self, x: usize, y: usize) -> Color {
        self.rows[y][x]
    }

    fn set_color_at(&mut self, x: usize, y: usize, color: Color) {
        self.rows[y][x] = color;
    }

    fn render(&self, stdout: &mut Stdout) {
        stdout
            .execute(terminal::Clear(terminal::ClearType::All))
            .unwrap();

        for y in 0..FIELD_HEIGHT {
            for x in 0..FIELD_WIDTH {
                let color = self.color_at(x, y);
                let symbol = match color {
                    Color::None => "██".black(),
                    Color::Yellow => "██".yellow(),
                    Color::Red => "██".red(),
                    Color::DarkYellow => "██".dark_yellow(),
                    Color::Blue => "██".blue(),
                    Color::Cyan => "██".cyan(),
                    Color::Magenta => "██".magenta(),
                    Color::Green => "██".green(),
                };

                stdout
                    .queue(cursor::MoveTo(x as u16 * 2, (FIELD_HEIGHT - 1 - y) as u16))
                    .unwrap()
                    .queue(style::PrintStyledContent(symbol))
                    .unwrap();
            }
        }

        stdout.flush().unwrap();
    }
}
