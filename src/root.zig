const scene = @import("engine/scene.zig");
const api = @import("engine/api.zig");

const renderer = @import("engine/renderer.zig");

/// EXPOSED ONLY BECAUSE YOU MIGHT WANT TO IMPLEMENT YOUR OWN STUFF
///
/// (for now used to expose some internal data types)
pub const BackingEngine = @import("engine/engine.zig");

pub const ScreenPreset = struct {
    width: f32,
    height: f32,
    ratio: f32,

    pub fn init(width: f32, height: f32) @This() {
        return .{
            .width = width,
            .height = height,
            .ratio = width / height,
        };
    }
};

pub const RenderableScene = struct {
    name: [:0]const u8,
    SceneTypeGenerator: fn (type) type,

    pub fn init(name: [:0]const u8, SceneTypeGenerator: fn (type) type) @This() {
        return .{
            .name = name,
            .SceneTypeGenerator = SceneTypeGenerator,
        };
    }
};

pub fn Init(comptime presets: []const ScreenPreset, comptime scenes: []const RenderableScene, comptime SceneContext: type, updates_per_s: comptime_int) type {
    return struct {
        pub const Renderer = renderer.Renderer(presets, scenes, SceneContext, updates_per_s);

        pub const Scene = scene.Scene;
        pub const SceneComponent = scene.SceneComponent;

        pub const ui = struct {
            pub const Background = @import("gui-components/UiBackground.zig").UiBackground(Renderer);
            pub const Padding = @import("gui-components/UiPadding.zig").UiPadding(Renderer);
            pub const Rectangle = @import("gui-components/UiRectangle.zig").UiRectangle(Renderer);
            pub const Border = @import("gui-components/UiBorder.zig").UiBorder(Renderer);
            pub const Text = @import("gui-components/UiText.zig").UiText(Renderer);
            pub const Image = @import("gui-components/UiImage.zig").UiImage(Renderer);
            pub const Button = @import("gui-components/UiButton.zig").UiButton(Renderer);
            pub const SliderHandle = @import("gui-components/UiSliderHandle.zig").UiSliderHandle(Renderer);
            pub const Slider = @import("gui-components/UiSlider.zig").UiSlider(Renderer);
            pub const TextInputField = @import("gui-components/UiTextInputField.zig").UiTextInputField(Renderer);
            pub const TextValue = @import("gui-components/UiTextValue.zig").UiTextValue(Renderer);
        };

        pub const audio = struct {
            pub const Music = @import("sound-components/Music.zig");
            pub const Sound = @import("sound-components/Sound.zig");
        };
    };
}
