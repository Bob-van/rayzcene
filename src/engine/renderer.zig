const std = @import("std");
const builtin = @import("builtin");
const engine = @import("engine.zig");
const api = @import("api.zig");
const ScreenPreset = @import("../root.zig").ScreenPreset;
const RenderableScene = @import("../root.zig").RenderableScene;

/// updates_per_s = 0 -> never update
pub fn Renderer(comptime presets: []const ScreenPreset, comptime scenes: []const RenderableScene, comptime SceneContext: type) type {
    var prev = std.math.floatMax(f32);
    for (presets) |screenPreset| {
        if (prev < screenPreset.ratio) @compileError("\"comptime presets: []const ScreenPreset\" need to be ordered in descending way based on \"ratio: f32\"");
        prev = screenPreset.ratio;
    }

    const enum_fields: [scenes.len]std.builtin.Type.EnumField = blk: {
        var fields: [scenes.len]std.builtin.Type.EnumField = undefined;
        for (scenes, 0..) |renderableScene, i| {
            fields[i] = .{ .name = renderableScene.name, .value = i };
        }
        break :blk fields;
    };

    const update_interval_micro: [scenes.len]comptime_int = blk: {
        var intervals: [scenes.len]comptime_int = undefined;
        for (scenes, 0..) |renderableScene, i| {
            intervals[i] = if (renderableScene.updates_per_s == 0) 0 else 1000000 / renderableScene.updates_per_s;
        }
        break :blk intervals;
    };
    const does_it_ever_update: bool = blk: {
        for (scenes) |renderableScene| {
            if (renderableScene.updates_per_s != 0) break :blk true;
        }
        break :blk false;
    };

    return struct {
        /// Context type that functions take and gets passed to the scenes
        pub const Context = SceneContext;

        /// Enum of exposed scenes
        pub const AccessEnum = @Type(.{ .@"enum" = .{
            .tag_type = usize,
            .fields = &enum_fields,
            .decls = &.{},
            .is_exhaustive = true,
        } });

        /// Use API, not this, this is internal exposure that API uses!
        pub const table: api.FnTable(@This()) = .{
            .log = log,
            .window = getWindow,
            .preset_size = presets.len,
            .activePresetIndex = getCurrentPresetIndex,
            .setLogLevel = setLogLevel,
            .init = init,
            .deinit = deinit,
            .initialRender = initialRender,
            .sceneUnload = sceneUnload,
            .render = render,
            .shouldWindowClose = wasWindowClosed,
            .requestNextScene = requestNextScene,
            .requestTermination = requestTermination,
            .requestFpsCapUpdate = requestFpsCapUpdate,
        };

        /// Exposed Renderer API (constructed like this mainly for LSP reasons)
        pub const API = api.API(@This());

        const Types = blk: {
            var types: [scenes.len]type = undefined;
            for (scenes, 0..) |renderableScene, i| {
                types[i] = renderableScene.SceneTypeGenerator(@This());
            }
            break :blk types;
        };

        const StorageUnion = blk: {
            var union_fields: [scenes.len]std.builtin.Type.UnionField = undefined;
            for (scenes, 0..) |renderableScene, i| {
                union_fields[i] = .{
                    .name = renderableScene.name,
                    .type = Types[i],
                    .alignment = @alignOf(Types[i]),
                };
            }
            break :blk @Type(.{ .@"union" = .{
                .layout = .auto,
                .tag_type = null,
                .fields = &union_fields,
                .decls = &.{},
            } });
        };

        var window_opened = false;

        var current_scene: AccessEnum = undefined;

        var next_scene: AccessEnum = undefined;

        var scene: StorageUnion = undefined;

        var current_preset_id: usize = undefined;

        var window: api.Window = undefined;

        var fps_cap: u31 = undefined;

        var last_update_micro: if (does_it_ever_update) i64 else void = undefined;

        fn log(comptime fmt: []const u8, args: anytype) void {
            if (builtin.mode == .Debug) {
                std.debug.print(fmt, args);
            }
        }

        fn getWindow() *const api.Window {
            return &window;
        }

        fn getCurrentPresetIndex() usize {
            return current_preset_id;
        }

        fn setLogLevel(logLevel: engine.TraceLogLevel) void {
            engine.setTraceLogLevel(logLevel);
        }

        fn init(window_title: [:0]const u8, fps: ?u31) void {
            // open minimalized game window
            engine.initWindow(1, 1, window_title);
            // remember that window was opened
            window_opened = true;
            // get ID of monitor currently in use
            const monitor_id = engine.getCurrentMonitor();

            // get monitor scale
            const screen_width = engine.getMonitorWidth(monitor_id);
            const screen_height = engine.getMonitorHeight(monitor_id);
            log("Device screen params recieved: {d} x {d}\n", .{ screen_width, screen_height });

            const cap: u31 = fps orelse blk: {
                // compute param for removal of repeating non 0 cost calls
                const refresh_rate = engine.getMonitorRefreshRate(monitor_id);
                log("Monitor supports up to: {} FPS\n", .{refresh_rate});
                break :blk if (refresh_rate < 60) 60 else @intCast(refresh_rate);
            };
            log("Renderer targetting {} FPS\n", .{cap});
            // allow resizeability
            engine.setWindowState(.{ .window_resizable = true, .window_always_run = true });
            // compute param for removal of repeating non 0 cost calls
            const window_width = @divFloor(screen_width, 4);
            // compute param for removal of repeating non 0 cost calls
            const window_height = @divFloor(screen_height, 4);
            // move window
            engine.setWindowPosition(window_width, window_height);
            // rescale window
            engine.setWindowSize(
                window_width * 2,
                window_height * 2,
            );
            // set prefered gameloop speed
            requestFpsCapUpdate(cap);
            // open audio device
            engine.initAudioDevice();
        }

        fn deinit() void {
            // close audio device
            engine.closeAudioDevice();
            // close the real window
            engine.closeWindow();
            // remember that window was closed
            window_opened = false;

            if (engine.getLoaded() != 0) {
                log("Renderer was left with {} loaded assets on exit!", .{engine.getLoaded()});
                if (builtin.mode == .Debug) unreachable;
            }
        }

        fn wasWindowClosed() bool {
            // TO DO: make ignore ESC at specific requests
            // specidies whether was the real window closed or program thinks it was closed
            return engine.windowShouldClose() or !window_opened;
        }

        fn initialRender(context: Context, starting_scene: AccessEnum) error{SceneInitFailed}!void {
            next_scene = starting_scene;
            if (!try update(context, false)) @panic("TO DO: determine behavior on init when window is minimalized.");
        }

        fn sceneUnload(context: Context) void {
            switch (current_scene) {
                inline else => |tag| {
                    @field(scene, scenes[@intFromEnum(tag)].name).deinit(context);
                },
            }
        }

        fn requestNextScene(next: AccessEnum) void {
            next_scene = next;
        }

        fn requestTermination() void {
            window_opened = false;
        }

        fn requestFpsCapUpdate(new_cap: u31) void {
            fps_cap = new_cap;
            engine.setTargetFPS(@intCast(fps_cap));
        }

        fn render(context: Context) error{ SceneInitFailed, SceneUpdateFailed, SceneRenderFailed }!void {
            switch (current_scene) {
                inline else => |tag| {
                    const interval = update_interval_micro[@intFromEnum(tag)];
                    if (comptime interval != 0) {
                        const now: i64 = std.time.microTimestamp();
                        while (last_update_micro + interval < now) {
                            @field(scene, scenes[@intFromEnum(tag)].name).update(context, last_update_micro + interval) catch return error.SceneUpdateFailed;
                            last_update_micro += interval;
                        }
                    }
                },
            }
            const should_render = try update(context, true);
            // begin single frame render
            engine.beginDrawing();
            // reports end of single frame render
            defer engine.endDrawing();
            if (should_render) {
                switch (current_scene) {
                    inline else => |tag| {
                        @field(scene, scenes[@intFromEnum(tag)].name).render(context) catch return error.SceneRenderFailed;
                    },
                }
            }
        }

        fn inferPreset(ratio: f32) usize {
            var new_preset_id: usize = 0;
            while (new_preset_id < presets.len and ratio < presets[new_preset_id].ratio) : (new_preset_id += 1) {}
            if (new_preset_id == 0) return 0;
            if (new_preset_id == presets.len) return new_preset_id - 1;

            const diff_large: f32 = @abs(ratio - presets[new_preset_id - 1].ratio);
            const diff_small: f32 = @abs(ratio - presets[new_preset_id].ratio);
            if (diff_large < diff_small) {
                new_preset_id -= 1;
            }
            return new_preset_id;
        }

        fn calculateInnerWindow() void {
            const f_window_width: f32 = @floatFromInt(window.real_width);
            const f_window_height: f32 = @floatFromInt(window.real_height);
            const ratio: f32 = f_window_width / f_window_height;

            log("Window size: {d} x {d}\n", .{ window.real_width, window.real_height });

            current_preset_id = inferPreset(ratio);
            const curr_preset = presets[current_preset_id];

            log("Ratio: {}, Preset: {} -> {} x {}\n", .{
                ratio,
                curr_preset.ratio,
                curr_preset.width,
                curr_preset.height,
            });

            const width_valid: bool = ratio < curr_preset.ratio;
            const single_unit: f32 = if (width_valid) f_window_width / curr_preset.width else f_window_height / curr_preset.height;
            const inner_window_width: i32 = if (width_valid) window.real_width else @intFromFloat(single_unit * curr_preset.width);
            const inner_window_height: i32 = if (width_valid) @intFromFloat(single_unit * curr_preset.height) else window.real_height;
            const width_diff: i32 = window.real_width - inner_window_width;
            const height_diff: i32 = window.real_height - inner_window_height;

            window = .{
                .real_width = window.real_width,
                .real_height = window.real_height,
                .inner_width = inner_window_width,
                .inner_height = inner_window_height,
                .scale = if (width_valid) f_window_width / curr_preset.width else f_window_height / curr_preset.height,
                .top_padding = @divFloor(height_diff, 2),
                .right_padding = @divFloor(width_diff, 2),
                .bot_padding = @divFloor(height_diff, 2) + @mod(height_diff, 2),
                .left_padding = @divFloor(width_diff, 2) + @mod(width_diff, 2),
            };

            log("{} x {} -> x{} -> {}, {}, {}, {}\n", .{
                window.inner_width,
                window.inner_height,
                window.scale,
                window.top_padding,
                window.right_padding,
                window.bot_padding,
                window.left_padding,
            });
        }

        fn update(context: Context, comptime scene_exists: bool) error{SceneInitFailed}!bool {
            const curr_width = engine.getScreenWidth();
            const curr_height = engine.getScreenHeight();
            if (curr_width <= 0 or curr_height <= 0) return false;
            if (comptime scene_exists) {
                if (curr_width == window.real_width and curr_height == window.real_height and current_scene == next_scene) return true;
            }
            if ((comptime !scene_exists) or curr_width != window.real_width or curr_height != window.real_height) {
                window.real_width = curr_width;
                window.real_height = curr_height;
                calculateInnerWindow();
            }
            if (comptime scene_exists) {
                sceneUnload(context);
            }
            try sceneUpdate(context);
            return true;
        }

        fn sceneUpdate(context: Context) error{SceneInitFailed}!void {
            switch (next_scene) {
                inline else => |tag| {
                    // set scene union to next_scene_type.empty
                    scene = @unionInit(StorageUnion, scenes[@intFromEnum(tag)].name, .empty);
                    // initialize new scene in the union (in place, so self referencial pointers stay valid)
                    @field(scene, scenes[@intFromEnum(tag)].name).init(context) catch return error.SceneInitFailed;
                    if (comptime update_interval_micro[@intFromEnum(tag)] != 0) {
                        last_update_micro = std.time.microTimestamp();
                    }
                    if (next_scene == current_scene) {
                        log("Scene \"{s}\" rescaled\n", .{scenes[@intFromEnum(tag)].name});
                    } else {
                        log("Scene \"{s}\" loaded\n", .{scenes[@intFromEnum(tag)].name});
                    }
                },
            }
            current_scene = next_scene;
        }
    };
}
