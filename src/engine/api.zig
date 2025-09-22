const engine = @import("engine.zig");
pub const TraceLogLevel = engine.TraceLogLevel;

pub const Window = struct {
    real_width: i32,
    real_height: i32,
    inner_width: i32,
    inner_height: i32,
    scale: f32,
    top_padding: i32,
    right_padding: i32,
    bot_padding: i32,
    left_padding: i32,
};

/// Renderer concrete public API.
///
/// (mostly here cuz LSP sucks for duck typing)
pub fn API(Context: type, AccessEnum: type) type {
    return struct {
        /// Log function, guess what it does ...
        ///
        /// IMPORTANT: logs only in .Debug builds!
        log: fn (comptime []const u8, anytype) void,
        /// Details about current renderer setup.
        window: fn () *const Window,
        /// Screen presets length. (its guaranteed static)
        preset_size: usize,
        /// Get index of preset currently in use by renderer.
        activePresetIndex: fn () usize,
        /// Sets log level of backing engine (Raylib currently).
        setLogLevel: fn (TraceLogLevel) void,
        /// Initializes window using provided name and fps cap.
        ///
        /// (null means use monitor refresh rate)
        ///
        /// IMPORTANT: requires deinit() to be called before exiting!
        init: fn ([:0]const u8, ?u32) void,
        /// Deinitializes window and all internal resources.
        ///
        /// IMPORTANT: all other render functions stop working afterwards!
        deinit: fn () void,
        /// Makes first render of provided starting scene, initializes internal scene.
        ///
        /// IMPORTANT: from this point onwards one scene is always loaded in renderer, requires sceneUnload() to be called before exiting!
        initialRender: fn (Context, AccessEnum) error{SceneInitFailed}!void,
        /// Unloads currently loaded scene inside the renderer.
        ///
        /// IMPORTANT: unloading scene twice or before loading it is UB!
        sceneUnload: fn (Context) void,
        /// Renders scene, if new scene is requested loads it first.
        ///
        /// Calls update method as perfectly as it can based on "updates_per_s" regardless of current FPS.
        ///
        /// When new scene is loaded, it resets the update method "sleep" timer, so its not called immediately.
        ///
        /// IMPORTANT: expects loaded scene inside renderer! (see initialRender() for loading it)
        render: fn (Context) error{ SceneInitFailed, SceneUpdateFailed, SceneRenderFailed }!void,
        /// Returns whether window termination was requested.
        ///
        /// (escape key pressed or window close icon clicked)
        shouldWindowClose: fn () bool,
        /// Requests new scene to be loaded on next render() call.
        ///
        /// (safely overwrites previous requests, if they happen before render() call)
        requestNextScene: fn (AccessEnum) void,
        /// Requests window termination programatically so shouldWindowClose() returns true.
        requestTermination: fn () void,
        /// Requests to change current FPS cap.
        ///
        /// (0 means no limit)
        requestFpsCapUpdate: fn (u31) void,
    };
}
