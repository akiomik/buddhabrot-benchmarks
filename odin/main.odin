package main

import "core:bufio"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strings"

main :: proc() {
  width: u32 = 1000
  height: u32 = 1000

  hist := buddhabrot(width, height, 1000000, 1000)

  write_pgm("buddhabrot.pgm", width, height, max(hist), hist)
}

buddhabrot :: proc(width: u32, height: u32, samples: u32, max_iter: u32) -> []u32 {
  hist := make([]u32, width * height)
  paths := make([][2]f64, max_iter)

  xmin := -2.0
  xmax := 1.0
  ymin := -1.5
  ymax := 1.5

  x_range := xmax - xmin
  y_range := ymax - ymin
  x_scale := cast(f64)width / x_range
  y_scale := cast(f64)height / y_range

  for _ in 0..<samples {
    cr := rand_range(xmin, xmax)
    ci := rand_range(ymin, ymax)

    zr := 0.0
    zi := 0.0

    escaped := false
    path_count: u32 = 0

    for i in 0..<max_iter {
      // z = z^2 + c
      zr2 := zr * zr - zi * zi + cr
      zi2 := 2.0 * zr * zi + ci
      zr = zr2
      zi = zi2

      paths[i] = [2]f64{zr, zi}
      path_count = i + 1

      if zr * zr + zi * zi > 4.0 {
        escaped = true
        break
      }
    }

    if escaped {
      for path in paths[:path_count] {
        xr := path[0]
        yi := path[1]

        if xmin <= xr && xr <= xmax && ymin <= yi && yi <= ymax {
          px := cast(i32)((xr - xmin) * x_scale)
          py := cast(i32)((yi - ymin) * y_scale)
          px_u32 := cast(u32)px
          py_u32 := cast(u32)py

          if px >= 0 && py >= 0 && px_u32 < width && py_u32 < height {
            hist[py_u32 * width + px_u32] += 1
          }
        }
      }
    }
  }

  return hist
}

write_pgm :: proc(
    path: string,
    width: u32,
    height: u32,
    max: u32,
    data: []u32,
) {
  estimated_size := 100 + len(data) * 12 // header + data
  builder := strings.builder_make(0, estimated_size)
  defer strings.builder_destroy(&builder)

  // P2: Portable graymap (ASCII)
  fmt.sbprintf(&builder, "P2\n%v %v\n%v\n", width, height, max)
  
  for v in data {
    fmt.sbprintf(&builder, "%v ", v)
  }

  content := strings.to_string(builder)
  success := os.write_entire_file(path, transmute([]u8)content)
  if !success {
    fmt.eprintf("Failed to write file")
  }
}

max :: proc(xs: []u32) -> u32 {
  if len(xs) == 0 {
    return 0
  }

  max := xs[0]
  for x in xs {
    if x > max {
      max = x
    }
  }

  return max
}

rand_range :: proc(a: f64, b: f64) -> f64 {
    return a + (b - a) * rand.float64()
}
