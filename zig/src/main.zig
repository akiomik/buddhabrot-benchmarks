const std = @import("std");

const assert = std.debug.assert;
const bufPrint = std.fmt.bufPrint;
const cwd = std.fs.cwd;

pub fn main() !void {
    const width = 1000;
    const height = 1000;
    const max_iter = 1000;

    var hist = [_]u32{0} ** (width * height);
    var paths = [_]?struct{f64, f64}{null} ** max_iter;
    buddhabrot(&hist, &paths, width, height, 1_000_000, max_iter);

    try writePgm("buddhabrot.pgm", width, height, maxOf(&hist), &hist);
}

fn buddhabrot(
    hist: []u32,
    paths: []?struct {f64, f64},
    width: u32,
    height: u32,
    samples: u32,
    max_iter: u32
) void {
    assert(hist.len == width * height);
    assert(paths.len == max_iter);

    const xmin = -2.0;
    const xmax = 1.0;
    const ymin = -1.5;
    const ymax = 1.5;

    const x_range = xmax - xmin;
    const y_range = ymax - ymin;
    const x_scale = @as(f64, @floatFromInt(width)) / x_range;
    const y_scale = @as(f64, @floatFromInt(height)) / y_range;

    var prng = std.Random.DefaultPrng.init(0);
    const random = prng.random();

    for (0 .. samples) |_| {
        const cr = randRange(random, xmin, xmax);
        const ci = randRange(random, ymin, ymax);

        var zr: f64 = 0.0;
        var zi: f64 = 0.0;

        var escaped = false;
        var path_count: u32 = 0;

        for (0 .. max_iter) |iter| {
            // z = z^2 + c
            const zr2 = zr * zr - zi * zi + cr;
            const zi2 = 2.0 * zr * zi + ci;
            zr = zr2;
            zi = zi2;

            paths[iter] = .{zr, zi};
            path_count = @intCast(iter + 1);

            if (zr * zr + zi * zi > 4.0) {
                escaped = true;
                break;
            }
        }

        if (escaped) {
            for (paths[0..path_count]) |path| {
                const xr, const yi = path.?;

                if (xmin <= xr and xr <= xmax and ymin <= yi and yi <= ymax) {
                    const px = @as(i32, @intFromFloat((xr - xmin) * x_scale));
                    const py = @as(i32, @intFromFloat((yi - ymin) * y_scale));

                    if (px >= 0 and py >= 0 and px < width and py < height) {
                        hist[@as(usize, @intCast(py)) * width + @as(usize, @intCast(px))] += 1;
                    }
                }
            }
        }
    }
}

fn writePgm(
    path: []const u8,
    width: u32,
    height: u32,
    max: u32,
    data: []const u32,
) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Build the entire content as a string first
    var output = try std.ArrayList(u8).initCapacity(allocator, 16 * 1024);
    defer output.deinit(allocator);

    const writer = output.writer(allocator);

    // P2: Portable graymap (ASCII)
    try writer.print("P2\n{} {}\n{}\n", .{width, height, max});

    for (data) |v| {
        try writer.print("{} ", .{v});
    }

    // Write all at once
    const file = try cwd().createFile(path, .{});
    defer file.close();
    try file.writeAll(output.items);
}

fn randRange(random: std.Random, a: f64, b: f64) f64 {
    const r = random.float(f64); // [0,1)
    return a + (b - a) * r;
}

fn maxOf(data: []const u32) u32 {
    if (data.len == 0) {
        return 0;
    }

    var max = data[0];
    for (data) |x| {
        max = @max(x, max);
    }

    return max;
}
