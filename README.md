# Clock-popup

This is a fun little spontaneous project I've originally put together in the span of two days. It is intended to be a popup window that displays the current time in a fancy whip of motion, telling the time for a brief moment.

Currently, it has two flavors: 

- A neat popup window that just tells the time (`main` branch)
- A slightly bigger popup window with the same functionality, with a sleeping derg splayed on top of it (`main-derg` branch - my recommendations here)

I highly suggest you configure your wm and compositor to leave this window out of any open/close animations, shadows, blur etc. Those effects unfortunatelly get in the way of the promised clean look, which the popup window manages on its own.

## Installation

As far as I'm concerned, this will only work on linux for now. It *could* possibly work anywhere if you managed to build and link the SDL libraries yourself, since SDL is cross-platform

Tool prequisities: `zig`, `make`.

The SDL libraries also have a list of their dependencies, which you should install via you package manager. Arch example:

    sudo pacman -S alsa-lib cmake hidapi ibus jack libdecor libgl libpulse libusb libx11 libxcursor libxext libxinerama libxkbcommon libxrandr libxrender libxss libxtst mesa ninja pipewire sndio vulkan-driver vulkan-headers wayland wayland-protocols freetype2 harfbuzz libpng

If you are not sure which dependencies to install, check out SDL wiki on github.

Depending on which flavor you would fancy, have `make` download, build and install SDLs for you as well as build and install the whole thing:

- from this directory, just run one of the following:

        make

    or

        make derg

Either way, the binary should install in `/usr/local/bin`. You might want to add include it in `PATH`.


    