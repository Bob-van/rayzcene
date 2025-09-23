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

pub fn FnTable(Renderer: type) type {
    return struct {
        log: fn (comptime []const u8, anytype) void,
        window: fn () *const Window,
        preset_size: usize,
        activePresetIndex: fn () usize,
        setLogLevel: fn (TraceLogLevel) void,
        init: fn ([:0]const u8, ?u31) void,
        deinit: fn () void,
        initialRender: fn (Renderer.Context, Renderer.AccessEnum) error{SceneInitFailed}!void,
        sceneUnload: fn (Renderer.Context) void,
        render: fn (Renderer.Context) error{ SceneInitFailed, SceneUpdateFailed, SceneRenderFailed }!void,
        shouldWindowClose: fn () bool,
        requestNextScene: fn (Renderer.AccessEnum) void,
        requestTermination: fn () void,
        requestFpsCapUpdate: fn (u31) void,
    };
}

/// Renderer concrete public API.
///
/// (mostly here cuz LSP sucks for duck typing)
pub fn API(Renderer: type) type {
    return struct {
        /// Internal fn table of Renderer implementation
        pub const table: FnTable(Renderer) = Renderer.table;
        /// Log function, guess what it does ...
        ///
        /// IMPORTANT: logs only in .Debug builds!
        pub fn log(comptime fmt: []const u8, args: anytype) void {
            table.log(fmt, args);
        }
        /// Details about current renderer setup.
        pub fn window() *const Window {
            return table.window();
        }
        /// Screen presets length. (its guaranteed static)
        pub const preset_size: usize = table.preset_size;
        /// Get index of preset currently in use by renderer.
        pub fn activePresetIndex() usize {
            return table.activePresetIndex();
        }
        /// Sets log level of backing engine (Raylib currently).
        pub fn setLogLevel(level: TraceLogLevel) void {
            table.setLogLevel(level);
        }
        /// Initializes window using provided title and fps cap.
        ///
        /// (null means use monitor refresh rate)
        ///
        /// IMPORTANT: requires deinit() to be called before exiting!
        pub fn init(title: [:0]const u8, fps_cap: ?u31) void {
            table.init(title, fps_cap);
        }
        /// Deinitializes window and all internal resources.
        ///
        /// IMPORTANT: all other render functions stop working afterwards!
        pub fn deinit() void {
            table.deinit();
        }
        /// Makes first render of provided starting scene, initializes internal scene.
        ///
        /// IMPORTANT: from this point onwards one scene is always loaded in renderer, requires sceneUnload() to be called before exiting!
        pub fn initialRender(ctx: Renderer.Context, scene: Renderer.AccessEnum) error{SceneInitFailed}!void {
            return table.initialRender(ctx, scene);
        }
        /// Unloads currently loaded scene inside the renderer.
        ///
        /// IMPORTANT: unloading scene twice or before loading it is UB!
        pub fn sceneUnload(ctx: Renderer.Context) void {
            table.sceneUnload(ctx);
        }
        /// Renders scene, if new scene is requested loads it first.
        ///
        /// Calls update method as perfectly as it can based on "updates_per_s" regardless of current FPS.
        ///
        /// When new scene is loaded, it resets the update method "sleep" timer, so its not called immediately.
        ///
        /// IMPORTANT: expects loaded scene inside renderer! (see initialRender() for loading it)
        pub fn render(ctx: Renderer.Context) error{ SceneInitFailed, SceneUpdateFailed, SceneRenderFailed }!void {
            return table.render(ctx);
        }
        /// Returns whether window termination was requested.
        ///
        /// (escape key pressed or window close icon clicked)
        pub fn shouldWindowClose() bool {
            return table.shouldWindowClose();
        }
        /// Requests new scene to be loaded on next render() call.
        ///
        /// (safely overwrites previous requests, if they happen before render() call)
        pub fn requestNextScene(scene: Renderer.AccessEnum) void {
            table.requestNextScene(scene);
        }
        /// Requests window termination programatically so shouldWindowClose() returns true.
        pub fn requestTermination() void {
            table.requestTermination();
        }
        /// Requests to change current FPS cap.
        ///
        /// (0 means no limit)
        pub fn requestFpsCapUpdate(fps: u31) void {
            table.requestFpsCapUpdate(fps);
        }
    };
}
