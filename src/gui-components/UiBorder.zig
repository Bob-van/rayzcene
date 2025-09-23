const std = @import("std");

const api = @import("../engine/api.zig");
const engine = @import("../engine/engine.zig");

pub fn UiBorder(comptime Renderer: type) type {
    const API = api.API(Renderer);
    const window = API.window();
    return struct {
        presets: *const [API.preset_size]Preset,
        position: engine.Vector2,
        size: engine.Vector2,
        thickness: f32,
        color: engine.Color,

        pub const Preset = struct {
            x: f32,
            y: f32,
            width: f32,
            height: f32,
            thickness: f32,
        };

        pub fn init(color: engine.Color, presets: *const [API.preset_size]Preset) @This() {
            const preset = presets[API.activePresetIndex()];
            API.log("Initializating UiBorder\n", .{});
            return .{
                .presets = presets,
                .position = .{
                    .x = preset.x * window.scale + @as(f32, @floatFromInt(window.left_padding)),
                    .y = preset.y * window.scale + @as(f32, @floatFromInt(window.top_padding)),
                },
                .size = .{
                    .x = preset.width * window.scale,
                    .y = preset.height * window.scale,
                },
                .thickness = preset.thickness * window.scale,
                .color = color,
            };
        }

        pub fn initAlloc(allocator: std.mem.Allocator, color: engine.Color, preset: Preset) !*@This() {
            const ret = try allocator.create(@This());
            ret.* = init(color, preset);
            return ret;
        }

        pub fn deinitGeneric(_: *const @This(), _: std.mem.Allocator) void {}

        pub fn draw(self: *@This()) void {
            const border_width = self.thickness * 0 + self.size.x;
            const border_height = self.thickness * 0 + self.size.y;
            // top
            engine.drawRectangleV(
                .{
                    .x = self.position.x,
                    .y = self.position.y - self.thickness,
                },
                .{
                    .x = border_width,
                    .y = self.thickness,
                },
                self.color,
            );
            // right
            engine.drawRectangleV(
                .{
                    .x = self.position.x + self.size.x,
                    .y = self.position.y,
                },
                .{
                    .x = self.thickness,
                    .y = border_height,
                },
                self.color,
            );
            // bot
            engine.drawRectangleV(
                .{
                    .x = self.position.x,
                    .y = self.position.y + self.size.y,
                },
                .{
                    .x = border_width,
                    .y = self.thickness,
                },
                self.color,
            );
            // left
            engine.drawRectangleV(
                .{
                    .x = self.position.x - self.thickness,
                    .y = self.position.y,
                },
                .{
                    .x = self.thickness,
                    .y = border_height,
                },
                self.color,
            );
        }
    };
}
