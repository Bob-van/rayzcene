const std = @import("std");

const api = @import("../engine/api.zig");
const engine = @import("../engine/engine.zig");

const UiTextValue = @import("UiTextValue.zig").UiTextValue;

pub fn UiTextInputField(comptime Renderer: type) type {
    const API = api.API(Renderer);
    const window = API.window();
    return struct {
        value: *UiTextValue,
        font: *const engine.Font,

        cycles_down: u8 = 0,
        first_cycle: bool = true,
        selected: bool = false,

        box_position: engine.Vector2,
        box_size: engine.Vector2,

        box_border_thickness: f32,

        text_position: engine.Vector2,
        text_font_size: f32,
        text_spacing: f32,
        text_color: engine.Color,

        pub const Preset = struct {
            box_x: f32,
            box_y: f32,
            box_width: f32,
            box_height: f32,

            border_thickness: f32,

            text_x: f32,
            text_y: f32,
            text_font_size: f32,
            text_spacing: f32,
            text_color: engine.Color,
        };

        pub fn init(value: *UiTextValue, font: *const engine.Font, preset: Preset) @This() {
            API.log("Initializating UiText\n", .{});
            const tmp_font_size = preset.text_font_size * window.scale;
            const tmp_spacing = preset.text_spacing * window.scale;
            return .{
                .value = value,
                .font = font,
                .box_position = .{
                    .x = preset.box_x * window.scale + @as(f32, @floatFromInt(window.left_padding)),
                    .y = preset.box_y * window.scale + @as(f32, @floatFromInt(window.top_padding)),
                },
                .box_size = .{
                    .x = preset.box_width * window.scale,
                    .y = preset.box_height * window.scale,
                },
                .box_border_thickness = preset.border_thickness * window.scale,
                .text_position = .{
                    .x = preset.text_x * window.scale + @as(f32, @floatFromInt(window.left_padding)),
                    .y = preset.text_y * window.scale + @as(f32, @floatFromInt(window.top_padding)),
                },
                .text_font_size = tmp_font_size,
                .text_spacing = tmp_spacing,
                .text_color = preset.text_color,
            };
        }

        pub fn initAlloc(allocator: std.mem.Allocator, value: *UiTextValue, font: *const engine.Font, preset: Preset) !*@This() {
            const ret = try allocator.create(@This());
            ret.* = init(value, font, preset);
            return ret;
        }

        pub fn deinit(_: *const @This()) void {}

        pub fn draw(self: *@This()) void {
            engine.drawRectangleV(self.box_position, self.box_size, engine.Color.red);
            engine.drawRectangleV(
                self.box_position.addValue(self.box_border_thickness),
                .{
                    .x = self.box_size.x - 2 * self.box_border_thickness,
                    .y = self.box_size.y - 2 * self.box_border_thickness,
                },
                engine.Color.light_gray,
            );
            engine.drawTextEx(self.font.*, self.value.getValueNullTerminated(), self.text_position, self.text_font_size, self.text_spacing, self.text_color);
        }

        pub fn checkIfSelected(self: *@This(), mouse: engine.Vector2) void {
            self.selected = engine.checkCollisionPointRec(
                mouse,
                .{
                    .x = self.box_position.x + self.box_border_thickness,
                    .y = self.box_position.y + self.box_border_thickness,
                    .width = self.box_size.x - 2 * self.box_border_thickness,
                    .height = self.box_size.y - 2 * self.box_border_thickness,
                },
            );
            if (!self.selected) {
                self.first_cycle = true;
            }
        }

        pub fn isSubmited(self: *const @This()) bool {
            return (self.selected and engine.isKeyPressed(.enter));
        }

        pub fn checkForInput(self: *@This()) void {
            if (self.selected) {
                if (engine.isKeyDown(.left_control) and engine.isKeyPressed(.c)) {
                    engine.setClipboardText(self.value.getValueNullTerminated());
                    return;
                }
                if (engine.isKeyDown(.left_control) and engine.isKeyPressed(.v)) {
                    const clipboardText = engine.getClipboardText();
                    var start: usize = 0;
                    var len: usize = 5;
                    while (len > 0) {
                        len = getFirstCharacterLen_Utf8(clipboardText[start..]);
                        if (self.value.value.len > self.value.curr_value_size + len) {
                            for (0..len) |i| {
                                self.value.value[self.value.curr_value_size + i] = clipboardText[start + i];
                            }
                            self.value.curr_value_size += len;
                        }
                        start += len;
                    }
                    return;
                }
                var pressed = engine.getCharPressed();
                var pressed_encode_buffer: [4]u8 = undefined;
                while (pressed > 0) : (pressed = engine.getCharPressed()) {
                    const len = std.unicode.utf8Encode(@intCast(pressed), &pressed_encode_buffer) catch continue;
                    if (self.value.value.len > self.value.curr_value_size + len) {
                        for (0..len) |i| {
                            self.value.value[self.value.curr_value_size + i] = pressed_encode_buffer[i];
                        }
                        self.value.curr_value_size += len;
                    }
                }
                if (engine.isKeyDown(.backspace)) {
                    if (self.cycles_down == 0) {
                        self.value.removeLastCharacter_Utf8();
                    }
                    self.cycles_down += 1;
                    if (self.first_cycle) {
                        if (self.cycles_down == 20) {
                            self.cycles_down = 0;
                            self.first_cycle = false;
                        }
                    } else if (self.cycles_down == 3) {
                        self.cycles_down = 0;
                    }
                } else {
                    self.cycles_down = 0;
                    self.first_cycle = true;
                }
            }
        }

        fn getFirstCharacterLen_Utf8(text: [*:0]const u8) usize {
            var i: usize = 0;
            // is not \0 and beggining utf8 character
            if (text[i] != 0 and (text[i] & 0b11000000) != 0b10000000) {
                i += 1;
                // is not \0 and follow utf8 character
                while (text[i] != 0 and (text[i] & 0b11000000) == 0b10000000) {
                    i += 1;
                }
            }
            return i;
        }
    };
}
