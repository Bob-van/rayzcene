const std = @import("std");

pub const SceneComponent = struct {
    name: [:0]const u8,
    ComponentType: type,

    pub fn init(name: [:0]const u8, ComponentType: type) @This() {
        return .{
            .name = name,
            .ComponentType = ComponentType,
        };
    }
};

pub fn Scene(comptime componentList: []const SceneComponent) type {
    comptime var Types: [componentList.len]type = undefined;
    comptime var enum_fields: [componentList.len]std.builtin.Type.EnumField = undefined;
    comptime var struct_fields: [componentList.len]std.builtin.Type.StructField = undefined;
    for (componentList, 0..) |sceneComponent, i| {
        Types[i] = sceneComponent.ComponentType;
        enum_fields[i] = .{ .name = sceneComponent.name, .value = i };
        struct_fields[i] = .{
            .name = sceneComponent.name,
            .type = sceneComponent.ComponentType,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(sceneComponent.ComponentType),
        };
    }
    const AccessEnum = @Type(.{ .@"enum" = .{ .tag_type = usize, .fields = &enum_fields, .decls = &.{}, .is_exhaustive = true } });
    const StorageStruct = @Type(.{ .@"struct" = .{ .layout = .auto, .backing_integer = null, .fields = &struct_fields, .decls = &.{}, .is_tuple = false } });
    return struct {
        items: StorageStruct,

        pub const ComponentAccessEnum = AccessEnum;
        pub const ComponentStorageStruct = StorageStruct;

        pub fn init() @This() {
            return .{
                .items = undefined,
            };
        }

        pub fn get(self: *@This(), comptime element: AccessEnum) *Types[@intFromEnum(element)] {
            return &@field(self.items, componentList[@intFromEnum(element)].name);
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            inline for (0..componentList.len) |i| {
                @field(self.items, componentList[i].name).deinitGeneric(allocator);
            }
        }

        pub fn draw(self: *@This()) void {
            inline for (0..componentList.len) |i| {
                @field(self.items, componentList[i].name).draw();
            }
        }
    };
}
