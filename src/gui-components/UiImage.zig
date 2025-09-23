const std = @import("std");

const api = @import("../engine/api.zig");
const engine = @import("../engine/engine.zig");

pub const InitPreset = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

pub fn UiImage(comptime Renderer: type) type {
    const API = api.API(Renderer);
    const window = API.window();
    return struct {
        presets: *const [API.preset_size]InitPreset,
        position: engine.Vector2,
        texture: engine.Texture2D,

        pub const Preset = InitPreset;

        pub fn init(image: []const u8, presets: *const [API.preset_size]Preset) !@This() {
            const preset = presets[API.activePresetIndex()];
            var rlib_image = try engine.loadImageFromMemory(".png", image);
            defer engine.unloadImage(rlib_image);
            API.log("Image loaded successfully: {d}x{d}\n", .{ rlib_image.width, rlib_image.height });
            engine.imageResizeNN(
                &rlib_image,
                @intFromFloat(preset.width * window.scale),
                @intFromFloat(preset.height * window.scale),
            );
            API.log("Image resized to: {d}x{d}\n", .{ rlib_image.width, rlib_image.height });
            const texture = try engine.loadTextureFromImage(rlib_image);
            API.log("Texture created from image\n", .{});
            return .{
                .position = .{
                    .x = preset.x * window.scale + @as(f32, @floatFromInt(window.left_padding)),
                    .y = preset.y * window.scale + @as(f32, @floatFromInt(window.top_padding)),
                },
                .texture = texture,
                .presets = presets,
            };
        }

        pub fn initAlloc(allocator: std.mem.Allocator, image: []const u8, preset: Preset) !*@This() {
            const ret = try allocator.create(@This());
            ret.* = try init(image, preset);
            return ret;
        }

        pub fn deinit(self: *@This()) void {
            engine.unloadTexture(self.texture);
            API.log("Texture unloaded\n", .{});
        }

        pub fn deinitGeneric(self: *@This(), _: std.mem.Allocator) void {
            self.deinit();
        }

        pub fn draw(self: *const @This()) void {
            engine.drawTextureV(self.texture, self.position, engine.Color.white);
        }
    };
}
