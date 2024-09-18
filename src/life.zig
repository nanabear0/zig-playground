const std = @import("std");

const Pointer = struct {
    x: i32,
    y: i32,
};

const Direction = struct {
    x: i2,
    y: i2,
};

const neightbour_matrix = [8]Direction{
    .{ .x = -1, .y = 1 },
    .{ .x = 0, .y = 1 },
    .{ .x = 1, .y = 1 },
    .{ .x = -1, .y = 0 },
    .{ .x = 1, .y = 0 },
    .{ .x = -1, .y = -1 },
    .{ .x = 0, .y = -1 },
    .{ .x = 1, .y = -1 },
};

const range_x: u32 = 100;
const range_y: u32 = 20;

const PointerContext = struct {
    pub fn hash(_: @This(), key: Pointer) u32 {
        return @intCast(key.x * range_x + key.y);
    }
    pub fn eql(_: @This(), key1: Pointer, key2: Pointer, _: usize) bool {
        return key1.x == key2.x and key1.y == key2.y;
    }
};

const PointerHashMap = std.ArrayHashMap(Pointer, bool, PointerContext, true);

fn printMap(map: *PointerHashMap, allocator: std.mem.Allocator) !void {
    var str_builder = std.ArrayList(u8).init(allocator);
    defer str_builder.deinit();

    for (0..range_y) |iy| {
        for (0..range_x) |ix| {
            const char: u8 = if (map.get(.{ .x = @intCast(ix), .y = @intCast(iy) }) orelse false) '#' else '.';
            try str_builder.writer().print("{c}", .{char});
        }

        try str_builder.writer().print("\n", .{});
    }
    try str_builder.writer().print("\x1B[H", .{});
    std.debug.print("{s}", .{str_builder.items});
}

fn countLiveNeighbours(map: *PointerHashMap, pointer: *Pointer) u8 {
    var count: u8 = 0;
    for (neightbour_matrix) |v| {
        const xc: i32 = @mod(pointer.x + v.x + range_x, range_x);
        const yc: i32 = @mod(pointer.y + v.y + range_y, range_y);
        count += if (map.get(.{ .x = xc, .y = yc }) orelse false) 1 else 0;
    }

    return count;
}

fn tick(map: *PointerHashMap, allocator: std.mem.Allocator) !PointerHashMap {
    defer map.deinit();
    var new_map = PointerHashMap.init(allocator);

    var iter = map.iterator();
    while (iter.next()) |entry| {
        const n = countLiveNeighbours(map, entry.key_ptr);
        if (entry.value_ptr.*) {
            try new_map.put(entry.key_ptr.*, n == 2 or n == 3);
        } else {
            try new_map.put(entry.key_ptr.*, n == 3);
        }
    }

    return new_map;
}

fn life() !void {
    std.debug.print("\x1B[2J\x1B[H", .{});

    var map = PointerHashMap.init(std.heap.page_allocator);
    defer map.deinit();

    for (0..range_y) |iy| {
        for (0..range_x) |ix| {
            try map.put(.{ .x = @intCast(ix), .y = @intCast(iy) }, std.crypto.random.boolean());
        }
    }

    try printMap(&map, std.heap.page_allocator);
    while (true) {
        std.time.sleep(70_000_000);
        map = try tick(&map, std.heap.page_allocator);
        try printMap(&map, std.heap.page_allocator);
    }
}

pub export fn run() void {
    life() catch unreachable;
}
