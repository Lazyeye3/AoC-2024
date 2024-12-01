const std = @import("std");

const ParsedArgs = struct { day: u8, exersize: u8 };

const ArgParseError = error{
    MissingArgument,
    InvalidNumber,
    InvalidSeed,
    UnknownArgument,
    PrintHelp,
};

fn parseArgs(allocator: std.mem.Allocator) !ParsedArgs {
    const args = std.process.argsAlloc(allocator) catch |err| {
        std.debug.print("Failed to allocate arguments\n", .{});
        return err;
    };

    var day: u8 = 1;
    var exersize: u8 = 1;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "-d") or std.mem.eql(u8, arg, "--day")) {
            i += 1;
            if (i >= args.len) {
                std.debug.print("Missing argument for -d\n", .{});
                return ArgParseError.MissingArgument;
            }
            day = std.fmt.parseInt(u8, args[i], 10) catch {
                std.debug.print("Invalid number for -d\n", .{});
                return ArgParseError.InvalidNumber;
            };
        } else if (std.mem.eql(u8, arg, "-e") or std.mem.eql(u8, arg, "--exersize")) {
            i += 1;
            if (i >= args.len) {
                std.debug.print("Missing argument for -e\n", .{});
                return ArgParseError.MissingArgument;
            }
            exersize = std.fmt.parseInt(u8, args[i], 10) catch {
                std.debug.print("Invalid seed for -e\n", .{});
                return ArgParseError.InvalidSeed;
            };
        } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            // printHelp() catch |err| {
            //     std.debug.print("Failed to print help\n", .{});
            //     return err;
            // };
            return ArgParseError.PrintHelp;
        } else {
            std.debug.print("Unknown argument: {s}\n", .{arg});
            return ArgParseError.UnknownArgument;
        }
    }

    const parsed_args = ParsedArgs{ .day = day, .exersize = exersize };

    return parsed_args;
}

pub fn main() !void {
    const default_allocator = std.heap.page_allocator;
    // Initialize arguments
    // Then deinitialize at the end of scope
    const args = try parseArgs(default_allocator);

    switch (args.day) {
        1 => {
            var file = try std.fs.cwd().openFile("./inputs/day1.txt", .{});
            defer file.close();
            if (args.exersize == 1) {
                try ex_1(default_allocator, file);
            } else if (args.exersize == 2) {
                try ex_2(default_allocator, file);
            } else {
                std.debug.print("Unknown exersize ({d}) for day {d}\n", .{ args.exersize, args.day });
                return ArgParseError.UnknownArgument;
            }
        },
        else => {
            std.debug.print("Day {d} is not yet implemented\n", .{args.day});
            return error.NotImplemented;
        },
    }
}

fn ex_1(allocator: std.mem.Allocator, file: std.fs.File) !void {
    var left = std.ArrayList(i32).init(allocator);
    defer left.deinit();

    var right = std.ArrayList(i32).init(allocator);
    defer right.deinit();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.splitAny(u8, line, " ");
        var is_right = false;
        while (it.next()) |x| {
            if (x.len == 0) {
                continue;
            }
            const val = try std.fmt.parseInt(i32, x, 10);
            if (is_right) {
                try right.append(val);
            } else {
                try left.append(val);
            }
            is_right = !is_right;
        }
    }

    const xl = try left.toOwnedSlice();
    const xr = try right.toOwnedSlice();
    std.mem.sort(i32, xl, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, xr, {}, comptime std.sort.asc(i32));

    var total_diff: u32 = 0;
    for (xl, 0..) |left_value, i| {
        const right_item = xr[i];

        const diff: u32 = @abs(left_value - right_item);
        total_diff += diff;
    }

    std.debug.print("total {d}\n", .{total_diff});
}

fn ex_2(allocator: std.mem.Allocator, file: std.fs.File) !void {
    var left = std.AutoHashMap(u32, u8).init(allocator);
    defer left.deinit();

    var right = std.AutoHashMap(u32, u8).init(allocator);
    defer right.deinit();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.splitAny(u8, line, "   ");
        var is_right = false;
        while (it.next()) |x| {
            if (x.len == 0) {
                continue;
            }
            const val = try std.fmt.parseInt(u32, x, 10);
            if (is_right) {
                const map_result = try right.getOrPut(val);
                if (map_result.found_existing) {
                    map_result.value_ptr.* += 1;
                } else {
                    try right.put(val, 1);
                }
            } else {
                const map_result = try left.getOrPut(val);
                if (map_result.found_existing) {
                    map_result.value_ptr.* += 1;
                } else {
                    try left.put(val, 1);
                }
            }
            is_right = !is_right;
        }
    }

    var total_sim: u64 = 0;
    var it = left.keyIterator();
    while (it.next()) |key| {
        const value = key.*;
        if (!right.contains(value)) {
            continue;
        }

        const right_val: u8 = right.get(value).?;
        const left_val: u8 = left.get(value).?;

        total_sim += value * right_val * left_val;
    }
    std.debug.print("total {d}\n", .{total_sim});
}
