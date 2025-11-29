app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br",
    rand: "https://github.com/lukewilliamboswell/roc-random/releases/download/0.5.0/yDUoWipuyNeJ-euaij4w_ozQCWtxCsywj68H0PlJAdE.tar.br"
}

import cli.File
import cli.Arg exposing [Arg]
import rand.Random

main! : List Arg => Result {} _
main! = |_args|
    width = 1000
    height = 1000
    samples = 1000000
    max_iter = 1000

    hist = buddhabrot(width, height, samples, max_iter)
    max = find_max(hist)

    write_pgm!("buddhabrot.pgm", width, height, max, hist)?

    Ok({})

# マンデルブロ軌道の計算と軌道記録
compute_orbit : F64, F64, U32 -> { escaped : Bool, path : List { x : F64, y : F64 } }
compute_orbit = |cr, ci, max_iter|
    compute_orbit_helper(0.0, 0.0, cr, ci, 0, max_iter, [])

compute_orbit_helper : F64, F64, F64, F64, U32, U32, List { x : F64, y : F64 } -> { escaped : Bool, path : List { x : F64, y : F64 } }
compute_orbit_helper = |zr, zi, cr, ci, iter, max_iter, path|
    if iter >= max_iter then
        { escaped: Bool.false, path: path }
    else
        # z = z^2 + c
        zr2 = zr * zr - zi * zi + cr
        zi2 = 2.0 * zr * zi + ci

        new_path = List.append(path, { x: zr2, y: zi2 })

        if zr2 * zr2 + zi2 * zi2 > 4.0 then
            { escaped: Bool.true, path: new_path }
        else
            compute_orbit_helper(zr2, zi2, cr, ci, iter + 1, max_iter, new_path)

update_histogram : List U32, { x : F64, y : F64 }, U32, U32, F64, F64, F64, F64 -> List U32
update_histogram = |hist, point, width, height, xmin, xmax, ymin, ymax|
    xr = point.x
    yi = point.y

    if xmin <= xr && xr <= xmax && ymin <= yi && yi <= ymax then
        x_range = xmax - xmin
        y_range = ymax - ymin
        x_scale = Num.to_f64(width) / x_range
        y_scale = Num.to_f64(height) / y_range

        px_f = (xr - xmin) * x_scale
        py_f = (yi - ymin) * y_scale
        px = Num.round(px_f) |> Num.to_u32
        py = Num.round(py_f) |> Num.to_u32

        if px < width && py < height then
            index = py * width + px
            index_u64 = Num.to_u64(index)
            update_histogram_at_index(hist, index_u64)
        else
            hist
    else
        hist

update_histogram_at_index : List U32, U64 -> List U32
update_histogram_at_index = |hist, index|
    when List.get(hist, index) is
        Ok(val) -> List.set(hist, index, val + 1)
        Err(_) -> hist

buddhabrot : U32, U32, U32, U32 -> List U32
buddhabrot = |width, height, samples, max_iter|
    xmin = -2.0
    xmax = 1.0
    ymin = -1.5
    ymax = 1.5

    hist_size = width * height
    hist_size_u64 = Num.to_u64(hist_size)
    initial_hist = List.repeat(0, hist_size_u64)

    initial_state = Random.seed(0)

    result = buddhabrot_samples(initial_hist, width, height, samples, max_iter, xmin, xmax, ymin, ymax, 0, initial_state)
    result.hist

buddhabrot_samples : List U32, U32, U32, U32, U32, F64, F64, F64, F64, U32, Random.State -> { hist : List U32, state : Random.State }
buddhabrot_samples = |hist, width, height, samples, max_iter, xmin, xmax, ymin, ymax, current_sample, state|
    if current_sample >= samples then
        { hist: hist, state: state }
    else
        cr_result = rand_range(xmin, xmax, state)
        ci_result = rand_range(ymin, ymax, cr_result.state)

        orbit_result = compute_orbit(cr_result.value, ci_result.value, max_iter)

        new_hist =
            if orbit_result.escaped then
                update_histogram_for_path(hist, orbit_result.path, width, height, xmin, xmax, ymin, ymax)
            else
                hist

        buddhabrot_samples(new_hist, width, height, samples, max_iter, xmin, xmax, ymin, ymax, current_sample + 1, ci_result.state)

update_histogram_for_path : List U32, List { x : F64, y : F64 }, U32, U32, F64, F64, F64, F64 -> List U32
update_histogram_for_path = |hist, path, width, height, xmin, xmax, ymin, ymax|
    List.walk(path, hist, |acc, point|
        update_histogram(acc, point, width, height, xmin, xmax, ymin, ymax))

find_max : List U32 -> U32
find_max = |xs|
    List.walk(xs, 0, |max, x|
        if x > max then x else max)

write_pgm! : Str, U32, U32, U32, List U32 => Result {} _
write_pgm! = |path, width, height, max, data|
    header_p1 = Str.concat("P2\n", Num.to_str(width))
    header_p2 = Str.concat(header_p1, " ")
    header_p3 = Str.concat(header_p2, Num.to_str(height))
    header_p4 = Str.concat(header_p3, "\n")
    header_p5 = Str.concat(header_p4, Num.to_str(max))
    header = Str.concat(header_p5, "\n")

    data_str = List.walk(data, "", |acc_str, val|
        val_str = Num.to_str(val)
        val_with_space = Str.concat(val_str, " ")
        Str.concat(acc_str, val_with_space))

    content = Str.concat(header, data_str)

    File.write_utf8!(content, path)

# returns [0, 1)
rand : Random.State -> { value: F64, state : Random.State }
rand = |state|
    result = Random.u32(state)
    value = Num.to_f64(result.value) / Num.to_f64(4294967295) # 2^32 - 1
    { value: value, state: result.state }

rand_range : F64, F64, Random.State -> { value : F64, state : Random.State }
rand_range = |min, max, state|
    r = rand(state)
    value = min + (max - min) * r.value
    { value: value, state: r.state }

