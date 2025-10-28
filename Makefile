.PHONY: install
install: /usr/local/lib/libSDL3.so /usr/local/lib/libSDL3_ttf.so /usr/share/fonts/TTF/PressStart-Regular.ttf
	sudo zig build --release=safe install --prefix /usr/local

.PHONY: clean-sdls
clean-sdls:
	rm -rf SDL SDL_ttf SDL_image

.PHONY: clean
clean:
	rm -rf SDL/build SDL_ttf/build SDL_image/build
	rm -rf .zig-cache

.PHONY: derg
derg: checkout-derg /usr/local/lib/libSDL3_image.so /usr/local/share/clock-popup/derg-frames install

.PHONY: checkout-derg
checkout-derg:
	git checkout main-derg

SDL:
	mkdir -p SDL
	git clone https://github.com/libsdl-org/SDL.git SDL
	cd SDL && git checkout release-3.2.6

/usr/local/lib/libSDL3.so: SDL
	cd SDL && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release 
	cmake --build SDL/build 
	sudo cmake --install SDL/build --prefix /usr/local

SDL_ttf:
	mkdir -p SDL_ttf
	git clone https://github.com/libsdl-org/SDL_ttf.git SDL_ttf
	cd SDL_ttf && git checkout release-3.2.2

/usr/local/lib/libSDL3_ttf.so: SDL_ttf /usr/local/lib/libSDL3.so
	cd SDL_ttf && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
	cmake --build SDL_ttf/build
	sudo cmake --install SDL_ttf/build --prefix /usr/local

SDL_image:
	mkdir -p SDL_image
	git clone https://github.com/libsdl-org/SDL_image.git SDL_image
	cd SDL_image && git checkout release-3.2.4

/usr/local/lib/libSDL3_image.so: SDL_image /usr/local/lib/libSDL3.so
	cd SDL_image && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
	cmake --build SDL_image/build
	sudo cmake --install SDL_image/build --prefix /usr/local

/usr/share/fonts/TTF/PressStart-Regular.ttf:
	sudo mkdir -p /usr/share/fonts/TTF
	sudo cp assets/PressStart-Regular.ttf /usr/share/fonts/TTF/PressStart-Regular.ttf

/usr/local/share/clock-popup/derg-frames:
	sudo mkdir -p /usr/local/share/clock-popup/derg-frames
	sudo cp assets/derg-frames/* /usr/local/share/clock-popup/derg-frames/