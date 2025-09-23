const std = @import("std");

const api = @import("../engine/api.zig");
const engine = @import("../engine/engine.zig");

pub fn UiButton(comptime Renderer: type) type {
    const API = api.API(Renderer);
    const window = API.window();
    return struct {
        presets: *const [API.preset_size]Preset,
        position: engine.Vector2,
        texture: engine.Texture2D,
        hovered: bool,

        pub const Preset = struct {
            x: f32,
            y: f32,
            width: f32,
            height: f32,
        };

        const hover_color = engine.Color.init(200, 200, 200, 255);

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
                .presets = presets,
                .position = .{
                    .x = preset.x * window.scale + @as(f32, @floatFromInt(window.left_padding)),
                    .y = preset.y * window.scale + @as(f32, @floatFromInt(window.top_padding)),
                },
                .texture = texture,
                .hovered = false,
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
            if (self.hovered) {
                engine.beginBlendMode(.alpha);
                engine.drawTextureV(self.texture, self.position, hover_color);
                engine.endBlendMode();
            }
        }

        pub fn drawExt(self: *const @This(), position: engine.Vector2) void {
            engine.drawTextureV(self.texture, position, engine.Color.white);
            if (self.hovered) {
                engine.beginBlendMode(.alpha);
                engine.drawTextureV(self.texture, position, hover_color);
                engine.endBlendMode();
            }
        }

        pub fn isPressed(self: *const @This(), mouse: engine.Vector2) bool {
            return engine.checkCollisionPointRec(
                mouse,
                .{
                    .x = self.position.x,
                    .y = self.position.y,
                    .width = @floatFromInt(self.texture.width),
                    .height = @floatFromInt(self.texture.height),
                },
            );
        }

        pub fn checkForHover(self: *@This(), mouse: engine.Vector2) void {
            self.hovered = if (engine.checkCollisionPointRec(
                mouse,
                .{
                    .x = self.position.x,
                    .y = self.position.y,
                    .width = @floatFromInt(self.texture.width),
                    .height = @floatFromInt(self.texture.height),
                },
            ))
                true
            else
                false;
        }
    };
}
