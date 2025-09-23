const std = @import("std");

const api = @import("../engine/api.zig");
const engine = @import("../engine/engine.zig");

pub const InitPreset = struct {
    x: f32,
    y: f32,
    font_size: f32,
    spacing: f32,
};

pub fn UiText(comptime Renderer: type) type {
    const API = api.API(Renderer);
    const window = API.window();
    return struct {
        presets: *const [API.preset_size]InitPreset,
        text: [:0]u8,
        position: engine.Vector2,
        font_size: f32,
        spacing: f32,
        font: *const engine.Font,
        color: engine.Color,

        pub const Preset = InitPreset;

        pub fn init(allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype, font: *const engine.Font, color: engine.Color, presets: *const [API.preset_size]Preset) !@This() {
            const preset = presets[API.activePresetIndex()];
            API.log("Initializating UiText\n", .{});
            const tmp_text = try std.fmt.allocPrintSentinel(allocator, fmt, args, 0);
            const tmp_font_size = preset.font_size * window.scale;
            const tmp_spacing = preset.spacing * window.scale;
            return .{
                .presets = presets,
                .text = tmp_text,
                .position = .{
                    .x = preset.x * window.scale + @as(f32, @floatFromInt(window.left_padding)),
                    .y = preset.y * window.scale + @as(f32, @floatFromInt(window.top_padding)),
                },
                .font_size = tmp_font_size,
                .spacing = tmp_spacing,
                .font = font,
                .color = color,
            };
        }

        pub fn initAlloc(allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype, font: *const engine.Font, color: engine.Color, presets: *const [API.preset_size]Preset) !*@This() {
            const ret = try allocator.create(@This());
            ret.* = try init(allocator, fmt, args, font, color, presets);
            return ret;
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.text);
        }

        pub fn deinitGeneric(self: *@This(), allocator: std.mem.Allocator) void {
            self.deinit(allocator);
        }

        pub fn reinit(self: *@This(), allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
            self.deinit(allocator);
            const tmp_text = try std.fmt.allocPrintSentinel(allocator, fmt, args, 0);
            self.text = tmp_text;
        }

        pub fn draw(self: *const @This()) void {
            engine.drawTextEx(self.font.*, self.text, self.position, self.font_size, self.spacing, self.color);
        }

        pub fn drawWithOffset(self: *const @This(), offset_x: f32, offset_y: f32) void {
            engine.drawTextEx(self.font.*, self.text, .{
                .x = self.position.x + offset_x,
                .y = self.position.y + offset_y,
            }, self.font_size, self.spacing, self.color);
        }
    };
}
