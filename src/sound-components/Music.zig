const std = @import("std");

const engine = @import("../engine/engine.zig");

volume: f32,
music: engine.Music,

pub fn initFromFile(fileName: [:0]const u8, volume: f32, loop: bool) !@This() {
    var ret: @This() = .{
        .volume = volume,
        .music = try engine.loadMusicStreamFromFile(fileName),
    };
    ret.looping = loop;
    ret.updateVolume();
    engine.playMusicStream(ret.music);
    return ret;
}

pub fn initFromMemory(fileType: [:0]const u8, data: []const u8, volume: f32, loop: bool) !@This() {
    var ret: @This() = .{
        .volume = volume,
        .music = try engine.loadMusicStreamFromMemory(fileType, data),
    };
    ret.music.looping = loop;
    ret.updateVolume();
    engine.playMusicStream(ret.music);
    return ret;
}

pub fn deinit(self: *@This()) void {
    engine.stopMusicStream(self.music);
    engine.unloadMusicStream(self.music);
}

pub fn deinitGeneric(self: *@This(), _: std.mem.Allocator) void {
    self.deinit();
}

pub fn draw(self: @This()) void {
    engine.updateMusicStream(self.music);
}

pub fn stopLooping(self: *@This()) void {
    self.music.looping = false;
}

pub fn isPlaying(self: @This()) bool {
    engine.isMusicStreamPlaying(self.music);
}

pub fn updateVolume(self: @This()) void {
    engine.setMusicVolume(self.music, self.volume);
}
