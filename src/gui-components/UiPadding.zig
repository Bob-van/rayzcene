const std = @import("std");
const api = @import("../engine/api.zig");
const engine = @import("../engine/engine.zig");

/// Adds colored blocks to the edges of screen (when window size is not exact fit)
pub fn UiPadding(comptime Renderer: type) type {
    const API = api.API(Renderer);
    const window = API.window();
    return struct {
        color: engine.Color,

        pub fn init(color: engine.Color) @This() {
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
            // top
            engine.drawRectangle(0, 0, window.real_width, window.top_padding, self.color);
            // right
            engine.drawRectangle(window.inner_width + window.left_padding, 0, window.right_padding, window.real_height, self.color);
            // bot
            engine.drawRectangle(0, window.inner_height + window.top_padding, window.real_width, window.bot_padding, self.color);
            // left
            engine.drawRectangle(0, 0, window.left_padding, window.real_width, self.color);
        }
    };
}
