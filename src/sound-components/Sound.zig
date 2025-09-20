const std = @import("std");

const engine = @import("../engine/engine.zig");

volume: f32,
music: engine.Sound,

comptime {
    // When analized (aka. imported by other code and used) it trips the compiler!
    @compileError("TO DO!");
}
