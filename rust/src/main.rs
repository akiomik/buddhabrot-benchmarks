#![feature(random)]

use std::fs;
use std::path::Path;
use std::random::random;

fn main() -> Result<(), std::io::Error> {
    let width = 1000;
    let height = 1000;

    let hist = buddhabrot(width, height, 1_000_000, 1_000);
    let max = hist.iter().copied().max().unwrap_or(0);

    write_pgm("buddhabrot.pgm", width, height, max, hist)
}

fn buddhabrot(width: usize, height: usize, samples: usize, max_iter: usize) -> Vec<u32> {
    let mut hist = vec![0u32; width * height];

    let xmin = -2.0;
    let xmax = 1.0;
    let ymin = -1.5;
    let ymax = 1.5;

    let x_range = xmax - xmin;
    let y_range = ymax - ymin;
    let x_scale = width as f64 / x_range;
    let y_scale = height as f64 / y_range;

    for _ in 0..samples {
        let cr = rand_range(xmin, xmax);
        let ci = rand_range(ymin, ymax);

        let mut zr = 0.0;
        let mut zi = 0.0;
        let mut path = Vec::with_capacity(max_iter);

        let mut escaped = false;

        for _ in 0..max_iter {
            // z = z^2 + c
            let zr2 = zr * zr - zi * zi + cr;
            let zi2 = 2.0 * zr * zi + ci;
            zr = zr2;
            zi = zi2;

            path.push((zr, zi));

            if zr * zr + zi * zi > 4.0 {
                escaped = true;
                break;
            }
        }

        if escaped {
            for (xr, yi) in path {
                if xmin <= xr && xr <= xmax && ymin <= yi && yi <= ymax {
                    let px = ((xr - xmin) * x_scale) as isize;
                    let py = ((yi - ymin) * y_scale) as isize;
                    let px_usize = px as usize;
                    let py_usize = py as usize;

                    if px >= 0 && py >= 0 && px_usize < width && py_usize < height {
                        hist[py_usize * width + px_usize] += 1;
                    }
                }
            }
        }
    }

    hist
}

fn write_pgm(
    path: impl AsRef<Path>,
    width: usize,
    height: usize,
    max: u32,
    data: Vec<u32>,
) -> Result<(), std::io::Error> {
    let estimated_size = 100 + data.len() * 12; // header + data
    let mut content = String::with_capacity(estimated_size);

    content.push_str(&format!("P2\n{} {}\n{}\n", width, height, max));

    for v in data {
        content.push_str(&format!("{} ", v));
    }

    fs::write(path, content)
}

// returns [0,1)
fn rand() -> f64 {
    let r: u32 = random(..);
    (r as f64) / (u32::MAX as f64 + 1.0)
}

fn rand_range(a: f64, b: f64) -> f64 {
    a + (b - a) * rand()
}
