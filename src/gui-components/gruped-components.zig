//! DEPRECATED

const std = @import("std");
const debug = @import("../../debug.zig");
const tools = undefined;

const render_structures = @import("../render-structures.zig");

const global_scene = @import("../../app/scenes/global-scene.zig");

const engine = @import("../engine.zig");
const renderer = @import("../../main.zig").renderer;
const Window = @import("../renderer.zig").Window;

const hover_color = engine.Color.init(200, 200, 200, 255);

// TO DO: UiText already ported, REMOVE WHEN PORTED ALL
pub const UiText = struct {
    text: [:0]u8,
    position: engine.Vector2,
    font_size: f32,
    spacing: f32,
    color: engine.Color,

    pub fn init(comptime fmt: []const u8, args: anytype, preset: *const render_structures.TextLocationAndSize) !@This() {
        debug.print("Initializating UiText\n");
        const tmp_text = try tools.format(fmt, args);
        const tmp_font_size = preset.font_size * renderer.window.scale;
        const tmp_spacing = preset.spacing * renderer.window.scale;
        return .{
            .text = tmp_text,
            .position = .{
                .x = preset.x * renderer.window.scale + @as(f32, @floatFromInt(renderer.window.left_padding)),
                .y = preset.y * renderer.window.scale + @as(f32, @floatFromInt(renderer.window.top_padding)),
            },
            .font_size = tmp_font_size,
            .spacing = tmp_spacing,
            .color = preset.color,
        };
    }

    pub fn initAlloc(comptime fmt: []const u8, args: anytype, preset: *const render_structures.TextLocationAndSize) !*@This() {
        const ret = try tools.allocator.create(@This());
        ret.* = try init(fmt, args, preset);
        return ret;
    }

    pub fn deinit(self: *UiText) void {
        tools.allocator.free(self.text);
    }

    pub fn reinit(self: *UiText, comptime fmt: []const u8, args: anytype) !void {
        self.deinit();
        const tmp_text = try tools.format(fmt, args);
        self.text = tmp_text;
    }

    pub fn draw(self: *const UiText) void {
        engine.drawTextEx(global_scene.font, self.text, self.position, self.font_size, self.spacing, self.color);
    }
    pub fn drawWithOffset(self: *const @This(), offset_x: f32, offset_y: f32) void {
        engine.drawTextEx(global_scene.font, self.text, .{
            .x = self.position.x + offset_x,
            .y = self.position.y + offset_y,
        }, self.font_size, self.spacing, self.color);
    }
};

pub const UiTextDrawnLeft = struct {
    text: [:0]u8,
    position: engine.Vector2,
    font_size: f32,
    spacing: f32,
    size: engine.Vector2,
    color: engine.Color,

    pub fn init(comptime fmt: []const u8, args: anytype, preset: *const render_structures.TextLocationAndSize) UiTextDrawnLeft {
        debug.print("Initializating UiTextDrawnLeft\n");
        const tmp_text = try tools.format(fmt, args);
        const tmp_font_size = preset.font_size * renderer.window.scale;
        const tmp_spacing = preset.spacing * renderer.window.scale;
        const tmp_size = engine.measureTextEx(global_scene.font, tmp_text, tmp_font_size, tmp_spacing);
        return .{
            .text = tmp_text,
            .position = .{
                .x = preset.x * renderer.window.scale + @as(f32, @floatFromInt(renderer.window.left_padding)) - tmp_size.x,
                .y = preset.y * renderer.window.scale + @as(f32, @floatFromInt(renderer.window.top_padding)),
            },
            .font_size = tmp_font_size,
            .spacing = tmp_spacing,
            .size = tmp_size,
            .color = preset.color,
        };
    }

    pub fn initAlloc(comptime fmt: []const u8, args: anytype, preset: *const render_structures.TextLocationAndSize) !*@This() {
        const ret = try tools.allocator.create(@This());
        ret.* = try init(fmt, args, preset);
        return ret;
    }

    pub fn deinit(self: *UiTextDrawnLeft) void {
        tools.allocator.free(self.text);
    }

    pub fn reinit(self: *UiTextDrawnLeft, comptime fmt: []const u8, args: anytype) void {
        self.deinit();
        const tmp_text = try tools.format(fmt, args);
        const tmp_size = engine.measureTextEx(global_scene.font, tmp_text, self.font_size, self.spacing);
        self.text = tmp_text;
        self.position = .{
            .x = self.position.x + self.size.x - tmp_size.x,
            .y = self.position.x,
        };
        self.size = tmp_size;
    }

    pub fn draw(self: *const UiTextDrawnLeft) void {
        engine.drawTextEx(global_scene.font, self.text, self.position, self.font_size, self.spacing, self.color);
    }
};

pub const AnimatedImage = struct {
    position: engine.Vector2,
    textures: SharedTextureSet,
    index: usize,
    draws_per_change: u16,
    current_draw_number: u16,

    pub fn init(draws_per_change: u16, begin_at: usize, textures: SharedTextureSet, preset: *const render_structures.ItemLocation) AnimatedImage {
        return .{
            .position = .{
                .x = preset.x * renderer.window.scale + @as(f32, @floatFromInt(renderer.window.left_padding)),
                .y = preset.y * renderer.window.scale + @as(f32, @floatFromInt(renderer.window.top_padding)),
            },
            .textures = textures,
            .index = begin_at,
            .draws_per_change = draws_per_change,
            .current_draw_number = 0,
        };
    }

    pub fn draw(self: *AnimatedImage) void {
        if (self.current_draw_number == self.draws_per_change) {
            self.index += 1;
            if (self.index >= self.textures.textures.len) {
                self.index = 0;
            }
            self.current_draw_number = 0;
        }
        self.current_draw_number += 1;
        engine.drawTextureV(self.textures.textures[self.index], self.position, engine.Color.white);
    }
};

pub const SharedTextureSet = struct {
    textures: []engine.Texture2D,

    pub fn init(comptime images: []const []const u8, preset: *const render_structures.ItemSize) !SharedTextureSet {
        var textures = try tools.allocator.alloc(engine.Texture2D, images.len);
        for (images, 0..) |image, i| {
            var rlib_image = try engine.loadImageFromMemory(".png", image);
            defer engine.unloadImage(rlib_image);
            debug.printf("Image loaded successfully: {d}x{d}\n", .{ rlib_image.width, rlib_image.height });
            engine.imageResizeNN(
                &rlib_image,
                @intFromFloat(preset.width * renderer.window.scale),
                @intFromFloat(preset.height * renderer.window.scale),
            );
            debug.printf("Image resized to: {d}x{d}\n", .{ rlib_image.width, rlib_image.height });
            textures[i] = engine.loadTextureFromImage(rlib_image);
            debug.print("Texture created from image\n");
        }
        return .{
            .textures = textures,
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.textures) |*texture| {
            engine.unloadTexture(texture.*);
            debug.print("Texture unloaded\n");
        }
        tools.allocator.free(self.textures);
    }
};

pub const CountedSharedTexture = struct {
    texture: engine.Texture2D,
    image: []const u8,
    size: render_structures.ItemSize,
    count: usize,

    pub fn init(image: []const u8, preset: *const render_structures.ItemSize) CountedSharedTexture {
        return .{
            .texture = undefined,
            .image = image,
            .size = preset.*,
            .count = 0,
        };
    }

    pub fn deinit(self: *@This()) void {
        if (self.count == 0) return;
        engine.unloadTexture(self.texture);
        debug.print("Texture unloaded\n");
    }

    pub fn increment(self: *@This()) !void {
        if (self.count == 0) {
            var rlib_image = try engine.loadImageFromMemory(".png", self.image);
            defer engine.unloadImage(rlib_image);
            debug.printf("Image loaded successfully: {d}x{d}\n", .{ rlib_image.width, rlib_image.height });
            engine.imageResizeNN(
                &rlib_image,
                @intFromFloat(self.size.width * renderer.window.scale),
                @intFromFloat(self.size.height * renderer.window.scale),
            );
            debug.printf("Image resized to: {d}x{d}\n", .{ rlib_image.width, rlib_image.height });
            self.texture = engine.loadTextureFromImage(rlib_image);
            debug.print("Texture created from image\n");
        }
        self.count += 1;
    }

    pub fn decrement(self: *@This()) !void {
        if (self.count == 0) return error.TextureCurrentlyNotLoaded;
        self.count -= 1;
        if (self.count == 0) {
            engine.unloadTexture(self.texture);
            debug.print("Texture unloaded\n");
        }
    }

    pub fn get(self: @This()) !engine.Texture2D {
        if (self.count == 0) return error.TextureCurrentlyNotLoaded;
        return self.texture;
    }
};

pub const CountedSharedTextureSet = struct {
    textures: []CountedSharedTexture,

    pub fn init(comptime images: []const []const u8, preset: *const render_structures.ItemSize) !@This() {
        var textures = try tools.allocator.alloc(CountedSharedTexture, images.len);
        for (images, 0..) |image, i| {
            textures[i] = CountedSharedTexture.init(image, preset);
        }
        return .{
            .textures = textures,
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.textures) |*texture| {
            texture.deinit();
        }
        tools.allocator.free(self.textures);
    }

    pub fn increment(self: *@This(), index: usize) void {
        self.textures[index].increment();
    }

    pub fn decrement(self: *@This(), index: usize) void {
        self.textures[index].decrement();
    }

    pub fn get(self: @This(), index: usize) engine.Texture2D {
        return self.textures[index].get();
    }
};

pub const UiSharedImage = struct {
    position: engine.Vector2,
    textures: SharedTextureSet,

    pub fn init(textures: SharedTextureSet, preset: *const render_structures.ItemLocation) UiSharedImage {
        return .{
            .position = .{
                .x = preset.x * renderer.window.scale + @as(f32, @floatFromInt(renderer.window.left_padding)),
                .y = preset.y * renderer.window.scale + @as(f32, @floatFromInt(renderer.window.top_padding)),
            },
            .textures = textures,
        };
    }

    pub fn draw(self: *UiSharedImage, index: usize) void {
        engine.drawTextureV(self.textures.textures[index], self.position, engine.Color.white);
    }
};

pub const UiCountedSharedImage = struct {
    position: engine.Vector2,
    textures: CountedSharedTextureSet,

    pub fn init(textures: CountedSharedTextureSet, preset: *const render_structures.ItemLocation) UiCountedSharedImage {
        return .{
            .position = .{
                .x = preset.x * renderer.window.scale + @as(f32, @floatFromInt(renderer.window.left_padding)),
                .y = preset.y * renderer.window.scale + @as(f32, @floatFromInt(renderer.window.top_padding)),
            },
            .textures = textures,
        };
    }

    pub fn draw(self: *UiCountedSharedImage, index: usize) void {
        engine.drawTextureV(self.textures.get(index), self.position, engine.Color.white);
    }
};

pub const UiAreaWithInnerBorder = struct {
    border_position: engine.Vector2,
    border_size: render_structures.ItemSize,
    border_color: engine.Color,
    area_position: engine.Vector2,
    area_size: render_structures.ItemSize,
    area_color: engine.Color,

    pub fn init(preset: *const render_structures.ItemLocationAndSize, border_thickness: f32, area_color: engine.Color, border_color: engine.Color) @This() {
        const real_thickness: f32 = border_thickness * renderer.window.scale;
        return .{
            .border_position = preset.locationWithOffset(
                renderer.window.scale,
                @floatFromInt(renderer.window.left_padding),
                @floatFromInt(renderer.window.top_padding),
            ),
            .border_size = preset.size(renderer.window.scale),
            .border_color = border_color,
            .area_position = preset.locationWithOffset(
                renderer.window.scale,
                @as(f32, @floatFromInt(renderer.window.left_padding)) + real_thickness,
                @as(f32, @floatFromInt(renderer.window.top_padding)) + real_thickness,
            ),
            .area_size = preset.sizeWithOffset(
                renderer.window.scale,
                real_thickness,
                real_thickness,
            ),
            .area_color = area_color,
        };
    }

    pub fn draw(self: *const @This()) void {
        engine.drawRectangleV(self.border_position, self.border_size.vector(), self.border_color);
        engine.drawRectangleV(self.area_position, self.area_size.vector(), self.area_color);
    }
    pub fn drawWithOffset(self: *const @This(), offset_x: f32, offset_y: f32) void {
        engine.drawRectangleV(.{ .x = self.border_position.x + offset_x, .y = self.border_position.y + offset_y }, self.border_size.vector(), self.border_color);
        engine.drawRectangleV(.{ .x = self.area_position.x + offset_x, .y = self.area_position.y + offset_y }, self.area_size.vector(), self.area_color);
    }
};

pub const UiAreaWithText = struct {
    area: UiAreaWithInnerBorder,
    text: UiText,

    pub fn init(area: UiAreaWithInnerBorder, text: UiText) @This() {
        debug.print("Initializating UiAreaWithText\n");
        return .{
            .area = area,
            .text = text,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.text.deinit();
    }

    pub fn updateText(self: *@This(), comptime fmt: []const u8, args: anytype) !void {
        self.text.deinit();
        const tmp_text = try tools.format(fmt, args);
        self.text.text = tmp_text;
        self.text.size = engine.measureTextEx(global_scene.font, tmp_text, self.font_size, self.spacing);
    }

    pub fn draw(self: *const @This()) void {
        self.area.draw();
        self.text.draw();
    }

    pub fn drawWithOffset(self: *const @This(), offset_x: f32, offset_y: f32) void {
        self.area.drawWithOffset(offset_x, offset_y);
        self.text.drawWithOffset(offset_x, offset_y);
    }
};

pub const UiScrollableTextList = struct {
    const scroll_speed = 10;
    const Item = struct {
        value: UiAreaWithText,
        render: bool = false,
    };

    inside: []Item,
    all_text_list: [][]const u8,
    at_top_index: usize,
    item_height: f32,
    offset: f32,

    pub fn init() @This() {
        // zig fmt: off
        return .{
            
        };
        // zig fmt: on
    }

    fn shiftDown(self: *@This()) !void {
        self.inside[0].value.text.deinit();
        for (0..self.inside.len - 1) |i| {
            self.inside[i].value.text.text = self.inside[i + 1].value.text.text;
        }
        self.inside[self.inside.len - 1].value.text.text = try tools.format("{}", .{self.all_text_list[self.at_top_index + self.inside.len]});
        self.offset += self.item_height;
    }

    pub fn moveDown(self: *@This()) void {
        if (self.at_top_index + self.inside.len < self.all_text_list.len) {
            self.offset += scroll_speed;
            if (self.at_top_index + self.inside.len >= self.all_text_list.len) {
                self.offset = 0;
            }
            if (self.offset != 0) {
                for (self.inside) |*item| {
                    item.value.updatePosition(0, self.offset);
                }
            }
        } else {
            self.offset = 0;
        }
    }
};
