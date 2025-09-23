const std = @import("std");

const api = @import("../engine/api.zig");
const engine = @import("../engine/engine.zig");
pub fn UiRectangle(comptime Renderer: type) type {
    const API = api.API(Renderer);
    const window = API.window();
    return struct {
        position: engine.Vector2,
        size: engine.Vector2,
        color: engine.Color,

        pub const Preset = struct {
            x: f32,
            y: f32,
            width: f32,
            height: f32,
            color: engine.Color,
        };

        pub fn init(preset: Preset) @This() {
            API.log("Initializating UiRectangle\n");
            return .{
                .position = .{
                    .x = preset.x * window.scale + @as(f32, @floatFromInt(window.left_padding)),
                    .y = preset.y * window.scale + @as(f32, @floatFromInt(window.top_padding)),
                },
                .size = .{
                    .x = preset.width * window.scale,
                    .y = preset.height * window.scale,
                },
                .color = preset.color,
            };
        }

        pub fn initAlloc(allocator: std.mem.Allocator, preset: Preset) !*@This() {
            const ret = try allocator.create(@This());
            ret.* = init(preset);
            return ret;
        }

        pub fn deinitGeneral(_: *const @This(), _: std.mem.Allocator) void {}

        pub fn draw(self: *@This()) void {
            engine.drawRectangleV(self.position, self.size, self.color);
        }
    };
}
