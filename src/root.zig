pub const c = @cImport({
    @cInclude("time.h");
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});
