# Clock-popup

This is a fun little spontaneous project I've put together in the span of two days. It is intended to be a popup window that displays the current time in a fancy whip of motion, telling the time for a brief moment.

I highly suggest you configure your wm and compositor to leave this window out of any open/close animations, shadows, blur etc. Those effects unfortunatelly get in the way of the promised clean look, which the popup window manages on its own.

## Installation

As far as I'm concerned, this will only work on linux for now. It *could* possibly work anywhere if you managed to build and link the SDL libraries yourself, since SDL is cross-platform

- If you have the SDL libs (namely `libSDL3.so` and `libSDL3_ttf.so`) installed system-wide:
    
    1) make sure to copy the font from `assets/` to `/usr/share/fonts/TTF/` or point the path in `src/main.zig` to any font you wish to use (optionally, adjust the offsets accordingly, so that the displayed text is properly centered)

    2) from this directory, run:
        
            sudo zig build --release=safe install --prefix /usr/local

- Have `make` download, build and install SDLs for you as well as build and install the whole thing:

    1) from this directory, just run:
    
            make

Either way, the binary should now be installed in `/usr/local/bin`. You might want to add include it in `PATH`, along with `/usr/local/lib` to help dynamic loader find the shared libs.


    