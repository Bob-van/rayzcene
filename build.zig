const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("rayzcene", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const raylib_dep = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.artifact("raylib");

    //if (target.result.os.tag == .macos) { //TO DO: do i need it? (build.zig in raylib has it now, test using it!)
    //    if (b.lazyDependency("xcode_frameworks", .{})) |dep| {
    //        raylib.addSystemFrameworkPath(dep.path("Frameworks"));
    //        raylib.addSystemIncludePath(dep.path("include"));
    //        raylib.addLibraryPath(dep.path("lib"));
    //    }
    //}

    mod.linkLibrary(raylib);

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}
