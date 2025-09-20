const rlib = @import("../raylib/proxy.zig");
const builtin = @import("builtin");

pub const Vector2 = rlib.Vector2;
pub const Texture2D = rlib.Texture2D;
pub const Rectangle = rlib.Rectangle;
pub const Color = rlib.Color;
pub const Font = rlib.Font;
pub const MouseButton = rlib.MouseButton;
pub const MouseCursor = rlib.MouseCursor;
pub const KeyboardKey = rlib.KeyboardKey;
pub const Image = rlib.Image;
pub const BlendMode = rlib.BlendMode;
pub const Music = rlib.Music;
pub const Sound = rlib.Sound;

pub const TraceLogLevel = rlib.TraceLogLevel;
pub const ConfigFlags = rlib.ConfigFlags;

// safety check in Debug and ReleaseSafe build modes
var rendering = false;

/// Setup canvas (framebuffer) to start drawing
pub fn beginDrawing() void {
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
        if (rendering) unreachable else rendering = true;
    }
    rlib.beginDrawing();
}

/// End canvas drawing and swap buffers (double buffering)
pub fn endDrawing() void {
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
        if (rendering) rendering = false else unreachable;
    }
    rlib.endDrawing();
}

var loaded: i64 = 0;

pub fn getLoaded() i64 {
    return loaded;
}

/// Set the current threshold (minimum) log level
pub fn setTraceLogLevel(logLevel: TraceLogLevel) void {
    rlib.setTraceLogLevel(logLevel);
}

/// Initialize window and OpenGL context
pub fn initWindow(width: i32, height: i32, title: [*:0]const u8) void {
    loaded += 1;
    rlib.initWindow(width, height, title);
}

/// Get current connected monitor
pub fn getCurrentMonitor() i32 {
    return rlib.getCurrentMonitor();
}

/// Measure string size for Font
pub fn measureTextEx(font: Font, text: [*:0]const u8, fontSize: f32, spacing: f32) Vector2 {
    return rlib.measureTextEx(font, text, fontSize, spacing);
}

/// Get specified monitor refresh rate
pub fn getMonitorRefreshRate(monitor: i32) i32 {
    return rlib.getMonitorRefreshRate(monitor);
}

/// Get specified monitor width (current video mode used by monitor)
pub fn getMonitorWidth(monitor: i32) i32 {
    return rlib.getMonitorWidth(monitor);
}

/// Get specified monitor height (current video mode used by monitor)
pub fn getMonitorHeight(monitor: i32) i32 {
    return rlib.getMonitorHeight(monitor);
}

/// Set window configuration state using flags (only PLATFORM_DESKTOP)
pub fn setWindowState(flags: ConfigFlags) void {
    rlib.setWindowState(flags);
}

/// Set window position on screen (only PLATFORM_DESKTOP)
pub fn setWindowPosition(x: i32, y: i32) void {
    rlib.setWindowPosition(x, y);
}

/// Set window dimensions
pub fn setWindowSize(width: i32, height: i32) void {
    rlib.setWindowSize(width, height);
}

/// Set target FPS (maximum)
pub fn setTargetFPS(fps: i32) void {
    rlib.setTargetFPS(fps);
}

/// Close window and unload OpenGL context
pub fn closeWindow() void {
    loaded -= 1;
    rlib.closeWindow();
}

/// Check if application should close (KEY_ESCAPE pressed or windows close icon clicked)
pub fn windowShouldClose() bool {
    return rlib.windowShouldClose();
}

/// Get mouse position XY
pub fn getMousePosition() Vector2 {
    return rlib.getMousePosition();
}

/// Check if a mouse button is being pressed
pub fn isMouseButtonDown(button: MouseButton) bool {
    return rlib.isMouseButtonDown(button);
}

/// Check if a mouse button has been pressed once
pub fn isMouseButtonPressed(button: MouseButton) bool {
    return rlib.isMouseButtonPressed(button);
}

/// Draw text using font and additional parameters
pub fn drawTextEx(font: Font, text: [*:0]const u8, position: Vector2, fontSize: f32, spacing: f32, tint: Color) void {
    rlib.drawTextEx(font, text, position, fontSize, spacing, tint);
}

/// Load image from memory buffer, fileType refers to extension: i.e. '.png'
pub fn loadImageFromMemory(fileType: [*:0]const u8, fileData: []const u8) !Image {
    loaded += 1;
    return rlib.loadImageFromMemory(fileType, fileData);
}

/// Unload image from CPU memory (RAM)
pub fn unloadImage(self: Image) void {
    loaded -= 1;
    rlib.unloadImage(self);
}

/// Resize image (Nearest-Neighbor scaling algorithm)
pub fn imageResizeNN(image: *Image, newWidth: i32, newHeight: i32) void {
    rlib.imageResizeNN(image, newWidth, newHeight);
}

/// Load texture from image data
pub fn loadTextureFromImage(image: Image) !Texture2D {
    loaded += 1;
    return rlib.loadTextureFromImage(image);
}

/// Unload texture from GPU memory (VRAM)
pub fn unloadTexture(texture: Texture2D) void {
    loaded -= 1;
    rlib.unloadTexture(texture);
}

/// Draw a Texture2D with position defined as Vector2
pub fn drawTextureV(texture: Texture2D, position: Vector2, tint: Color) void {
    rlib.drawTextureV(texture, position, tint);
}

/// Begin blending mode (alpha, additive, multiplied, subtract, custom)
pub fn beginBlendMode(mode: BlendMode) void {
    rlib.beginBlendMode(mode);
}

/// End blending mode (reset to default: alpha blending)
pub fn endBlendMode() void {
    rlib.endBlendMode();
}

/// Check if point is inside rectangle
pub fn checkCollisionPointRec(point: Vector2, rec: Rectangle) bool {
    return rlib.checkCollisionPointRec(point, rec);
}

/// Draw a color-filled rectangle
pub fn drawRectangle(posX: i32, posY: i32, width: i32, height: i32, color: Color) void {
    rlib.drawRectangle(posX, posY, width, height, color);
}

/// Draw a color-filled rectangle (Vector version)
pub fn drawRectangleV(position: Vector2, size: Vector2, color: Color) void {
    rlib.drawRectangleV(position, size, color);
}

/// Set background color (framebuffer clear color)
pub fn clearBackground(color: Color) void {
    rlib.clearBackground(color);
}

/// Get current screen width
pub fn getScreenWidth() i32 {
    return rlib.getScreenWidth();
}

/// Get current screen height
pub fn getScreenHeight() i32 {
    return rlib.getScreenHeight();
}

/// Load font from memory buffer, fileType refers to extension: i.e. '.ttf'
pub fn loadFontFromMemory(fileType: [*:0]const u8, fileData: ?[]const u8, fontSize: i32, fontChars: ?[]i32) !Font {
    loaded += 1;
    return Font.fromMemory(fileType, fileData, fontSize, fontChars);
}

/// Unload font from GPU memory (VRAM)
pub fn unloadFont(font: Font) void {
    loaded -= 1;
    rlib.unloadFont(font);
}

/// Initialize audio device and context
pub fn initAudioDevice() void {
    rlib.initAudioDevice();
}

/// Close the audio device and context
pub fn closeAudioDevice() void {
    rlib.closeAudioDevice();
}

/// Check if music is playing
pub fn isMusicStreamPlaying(music: Music) bool {
    return rlib.isMusicStreamPlaying(music);
}

/// Load music stream from data
pub fn loadMusicStreamFromMemory(fileType: [*:0]const u8, data: []const u8) !Music {
    loaded += 1;
    return rlib.loadMusicStreamFromMemory(fileType, data);
}

/// Load music stream from file
pub fn loadMusicStreamFromFile(fileName: [*:0]const u8) !Music {
    loaded += 1;
    return rlib.loadMusicStream(fileName);
}

/// Unload music stream
pub fn unloadMusicStream(music: Music) void {
    loaded -= 1;
    rlib.unloadMusicStream(music);
}

/// Start music playing
pub fn playMusicStream(music: Music) void {
    rlib.playMusicStream(music);
}

// stop music playing
pub fn stopMusicStream(music: Music) void {
    rlib.stopMusicStream(music);
}

/// Updates buffers for music streaming
pub fn updateMusicStream(music: Music) void {
    rlib.updateMusicStream(music);
}

/// Set volume for music (1.0 is max level)
pub fn setMusicVolume(music: Music, volume: f32) void {
    rlib.setMusicVolume(music, volume);
}

pub fn setMouseCursor(cursor: MouseCursor) void {
    rlib.setMouseCursor(cursor);
}

pub fn getCharPressed() i32 {
    return rlib.getCharPressed();
}

pub fn isKeyPressed(key: KeyboardKey) bool {
    return rlib.isKeyPressed(key);
}

pub fn isKeyDown(key: KeyboardKey) bool {
    return rlib.isKeyDown(key);
}

pub fn getClipboardText() [*:0]const u8 {
    return rlib.getClipboardText();
}

pub fn setClipboardText(text: [*:0]const u8) void {
    rlib.setClipboardText(text);
}

pub fn getFps() i32 {
    return rlib.getFPS();
}
