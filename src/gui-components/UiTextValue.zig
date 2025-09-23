const api = @import("../engine/api.zig");

pub fn UiTextValue(comptime Renderer: type) type {
    const API = api.API(Renderer);
    return struct {
        value: []u8,
        curr_value_size: usize,

        pub fn init(text_buffer: []u8) @This() {
            API.log("Initializating UiTextValue\n", .{});
            return .{
                .value = text_buffer,
                .curr_value_size = 0,
            };
        }

        pub fn getValue(self: *const @This()) []const u8 {
            return self.value[0..self.curr_value_size];
        }

        pub fn getValueNullTerminated(self: *@This()) [:0]const u8 {
            self.value[self.curr_value_size] = 0;
            return self.value[0..self.curr_value_size :0];
        }

        pub fn clearText(self: *@This()) void {
            self.curr_value_size = 0;
        }

        pub fn removeLastCharacter_Utf8(self: *@This()) void {
            while (self.curr_value_size > 0 and (self.value[self.curr_value_size - 1] & 0b11000000) == 0b10000000) {
                self.curr_value_size -= 1;
            }
            if (self.curr_value_size != 0) {
                self.curr_value_size -= 1;
            }
        }
    };
}
