const std = @import("std");
const time = std.time;
const c = @import("clock_popup").c;
const anim = @import("anim.zig");

const time_buf_size = 8;
const title = "clock popup";
const font_path = "/usr/share/fonts/TTF/PressStart-Regular.ttf";
const font_size: f32 = 96;

const bg_color: c.SDL_Color = .{
    .r = 0x22,
    .g = 0x22,
    .b = 0x22,
    .a = 0x88,
};

const fg_color: c.SDL_Color = .{
    .r = 0xdd,
    .g = 0xdd,
    .b = 0xdd,
    .a = 0xff,
};

const text_padding = 40;

const neg_top_offset_rel: f32 = 0;
const neg_left_offset_rel: f32 = 1 / 8;
const neg_bottom_offset_rel: f32 = 1 / 8;
const neg_right_offset_rel: f32 = 1 / 8;

const neg_top_offset: f32 = font_size * neg_top_offset_rel;
const neg_left_offset: f32 = font_size * neg_left_offset_rel;
const neg_bottom_offset: f32 = font_size * neg_bottom_offset_rel;
const neg_right_offset: f32 = font_size * neg_right_offset_rel;

var rndr: ?*c.SDL_Renderer = null;
var win: ?*c.SDL_Window = null;

const anim_y_offset = 300;

pub fn main() !void {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.log.err("failed to initialize SDL: {s}\n", .{c.SDL_GetError()});
        return error.SDLInitFailed;
    }
    defer c.SDL_Quit();

    if (!c.TTF_Init()) {
        std.log.err("failed to initialize SDL_ttf: {s}\n", .{c.SDL_GetError()});
        return error.TTFInitFailed;
    }
    defer c.TTF_Quit();

    const cur_time = c.time(null);
    const tm = c.localtime(&cur_time);
    var time_buf: [time_buf_size]u8 = undefined;

    const w_len = c.strftime(&time_buf[0], time_buf_size, "%H:%M", tm);
    const time_str = time_buf[0..w_len];

    const font = c.TTF_OpenFont(font_path, font_size);
    if (font == null) {
        std.log.err("failed to load font: {s}\n", .{c.SDL_GetError()});
        return error.FontLoadFailed;
    }
    defer c.TTF_CloseFont(font);

    var text_surf = c.TTF_RenderText_Blended(
        font,
        time_str.ptr,
        time_str.len,
        fg_color,
    );
    if (text_surf == null) {
        std.log.err("failed to render text: {s}\n", .{c.SDL_GetError()});
        return error.TextRenderFailed;
    }

    var disp_count: c_int = undefined;
    const disps = c.SDL_GetDisplays(&disp_count);
    if (disps == null or disp_count < 1) {
        std.log.err("failed to get displays: {s}\n", .{c.SDL_GetError()});
        return error.DisplayGetFailed;
    }

    std.log.debug("{d} displays found", .{disp_count});

    var i: usize = 0;
    while (i < disp_count) : (i += 1) {
        std.log.debug("{d}", .{disps[i]});
    }

    std.log.debug("using display {d}", .{disps[0]});

    const disp_mode = c.SDL_GetCurrentDisplayMode(disps[0]);
    if (disp_mode == null) {
        std.log.err("failed to get display mode: {s}\n", .{c.SDL_GetError()});
        return error.DisplayModeGetFailed;
    }

    const win_w = text_surf.*.w + 2 * text_padding - @as(c_int, @intFromFloat(neg_left_offset + neg_right_offset));
    const win_h = text_surf.*.h + 2 * text_padding - @as(c_int, @intFromFloat(neg_top_offset + neg_bottom_offset));

    c.SDL_DestroySurface(text_surf);

    if (!c.SDL_CreateWindowAndRenderer(
        title,
        win_w,
        win_h,
        c.SDL_WINDOW_BORDERLESS | c.SDL_WINDOW_TRANSPARENT | c.SDL_WINDOW_NOT_FOCUSABLE | c.SDL_WINDOW_ALWAYS_ON_TOP | c.SDL_WINDOW_UTILITY,
        &win,
        &rndr,
    )) {
        std.log.err("failed to create window and renderer: {s}\n", .{c.SDL_GetError()});
        return error.WindowCreateFailed;
    }
    defer {
        c.SDL_DestroyRenderer(rndr);
        c.SDL_DestroyWindow(win);
    }

    const center_x = @divTrunc(disp_mode.*.w - win_w, 2);
    const center_y = @divTrunc(disp_mode.*.h - win_h, 2);

    _ = c.SDL_SetWindowPosition(win, center_x, center_y);

    const easing: anim.ExpoEasing = .{ .anim_dur_s = 1, .scale_px = 1 };
    var frame_iter: anim.FrameIterator(anim.ExpoEasing) = .init(easing);
    var anim_end = false;
    var anim_first_part = true;

    const ival = std.time.us_per_s / @as(u64, @intFromFloat(easing.anim_frame_rate));
    const th = std.Thread.spawn(.{}, timerInterrupt, .{ival}) catch {
        std.log.err("failed to create timer thread\n", .{});
        return error.ThreadCreateFailed;
    };
    th.detach();

    var event: c.SDL_Event = undefined;
    var running = true;

    while (running and !anim_end) {
        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_QUIT => running = false,
                else => {},
            }
        }

        if (anim_int.load(.acquire)) {
            anim_int.store(false, .release);

            if (!anim_first_part and frame_iter.step > frame_iter.total_steps / 3)
                anim_end = true;

            if (frame_iter.next()) |frame| {
                const anim_dir: c_int = if (anim_first_part) 1 else -1;
                const frame_dir = if (anim_first_part) (1 - frame) else frame;

                const y_frame = anim_dir * @as(c_int, @intFromFloat(anim_y_offset * (1 - frame_dir)));
                _ = c.SDL_SetWindowPosition(win, center_x, center_y + y_frame);

                _ = c.SDL_SetRenderDrawColor(
                    rndr,
                    @intFromFloat(frame_dir * bg_color.r),
                    @intFromFloat(frame_dir * bg_color.g),
                    @intFromFloat(frame_dir * bg_color.b),
                    @intFromFloat(frame_dir * bg_color.a),
                );
                _ = c.SDL_RenderClear(rndr);

                const fg_color_frame: c.SDL_Color = .{
                    .r = @intFromFloat(frame_dir * fg_color.r),
                    .g = @intFromFloat(frame_dir * fg_color.g),
                    .b = @intFromFloat(frame_dir * fg_color.b),
                    .a = @intFromFloat(frame_dir * fg_color.a),
                };

                text_surf = c.TTF_RenderText_Blended(
                    font,
                    time_str.ptr,
                    time_str.len,
                    fg_color_frame,
                );
                if (text_surf == null) {
                    std.log.err("failed to render text: {s}\n", .{c.SDL_GetError()});
                    return error.TextRenderFailed;
                }

                const text_tex = c.SDL_CreateTextureFromSurface(rndr, text_surf);
                if (text_tex == null) {
                    std.log.err("failed to create texture from surface: {s}\n", .{c.SDL_GetError()});
                    return error.TextureCreateFailed;
                }
                defer c.SDL_DestroyTexture(text_tex);
                c.SDL_DestroySurface(text_surf);

                var src_rect: c.SDL_FRect = .{
                    .x = neg_left_offset,
                    .y = neg_top_offset,
                    .w = @as(f32, @floatFromInt(text_tex.*.w)) - (neg_left_offset + neg_right_offset),
                    .h = @as(f32, @floatFromInt(text_tex.*.h)) - (neg_top_offset + neg_bottom_offset),
                };

                var dst_rect: c.SDL_FRect = .{
                    .x = text_padding,
                    .y = text_padding,
                    .w = @as(f32, @floatFromInt(text_tex.*.w)) - (neg_left_offset + neg_right_offset),
                    .h = @as(f32, @floatFromInt(text_tex.*.h)) - (neg_top_offset + neg_bottom_offset),
                };

                _ = c.SDL_RenderTexture(rndr, text_tex, &src_rect, &dst_rect);
                _ = c.SDL_RenderPresent(rndr);
            } else if (anim_first_part) {
                anim_first_part = false;
                anim_pause.store(true, .release);
                frame_iter.step = 0;
            } else anim_end = true;
        }
    }
}

var anim_int: std.atomic.Value(bool) = .init(true);
var anim_pause: std.atomic.Value(bool) = .init(false);

fn timerInterrupt(interval_us: u64) void {
    while (true) {
        std.Thread.sleep(std.time.ns_per_us * interval_us);

        if (anim_pause.load(.acquire)) {
            std.Thread.sleep(std.time.ns_per_ms * 200);
            anim_pause.store(false, .release);
        }

        anim_int.store(true, .release);
    }
}
