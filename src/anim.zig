const std = @import("std");

pub fn FrameIterator(comptime EasingT: type) type {
    if (!std.meta.hasMethod(EasingT, "countSteps") or !std.meta.hasMethod(EasingT, "calcFrame"))
        @compileError("easing struct type must have countSteps and calcFrame methods");

    return struct {
        easing: EasingT,
        step: u32 = 0,
        total_steps: u32,

        pub fn init(easing: EasingT) @This() {
            return .{
                .easing = easing,
                .step = 0,
                .total_steps = easing.countSteps(),
            };
        }

        pub fn next(self: *@This()) ?f32 {
            if (self.step >= self.total_steps)
                return null;

            const frame = self.easing.calcFrame(self.step);
            self.step += 1;
            return frame;
        }
    };
}

pub const ExpoEasing = struct {
    anim_frame_rate: f32 = 36,
    anim_dur_s: f32,
    scale_px: f32,
    exp_base: f32 = 10,
    graph_width: f32 = 5,

    pub fn countSteps(self: ExpoEasing) u32 {
        return @as(u32, @intFromFloat(self.anim_frame_rate * self.anim_dur_s)) + 1;
    }

    pub fn calcFrame(self: ExpoEasing, step: u32) f32 {
        const steps = self.anim_frame_rate * self.anim_dur_s;
        if (step > @as(u32, @intFromFloat(steps)))
            return 0;

        return self.scale_px * std.math.pow(f32, 1 / self.exp_base, self.graph_width / (steps - 1) * @as(f32, @floatFromInt(step)));
    }
};
