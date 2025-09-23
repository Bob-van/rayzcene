const std = @import("std");

const api = @import("../engine/api.zig");
const engine = @import("../engine/engine.zig");

pub fn UiBackground(comptime Renderer: type) type {
    const API = api.API(Renderer);
    return struct {
        color: engine.Color,

        pub fn init(color: engine.Color) @This() {
            API.log("Initializating UiBackground\n", .{});
            return .{
                .color = color,
            };
        }

        pub fn initAlloc(allocator: std.mem.Allocator, color: engine.Color) !*@This() {
            const ret = try allocator.create(@This());
            ret.* = init(color);
            return ret;
        }

        pub fn deinitGeneric(_: @This(), _: std.mem.Allocator) void {}

        pub fn draw(self: @This()) void {
            engine.clearBackground(self.color);
        }
    };
}
