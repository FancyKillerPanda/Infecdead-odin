package main

import "core:fmt"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import ttf "vendor:sdl2/ttf"

printf :: fmt.printf;

main :: proc() {
	infecdead();
}

infecdead :: proc() -> bool {
	init_dependencies() or_return;
	defer quit_dependencies();
	
	game: Game;
	init_game(&game) or_return;
	run_game(&game);
	
	return true;
}

init_dependencies :: proc() -> bool {
	if sdl.Init(sdl.INIT_EVERYTHING) < 0 {
		printf("Error: Failed to initialise SDL2. Message: '{}'\n", sdl.GetError());
		return false;
	}

	if img.Init(img.INIT_PNG) != img.INIT_PNG {
		printf("Error: Failed to initialise SDL_image. Message: '{}'\n", sdl.GetError());
		return false;
	}

	if ttf.Init() < 0 {
		printf("Error: Failed to initialise SDL_ttf. Message: '{}'\n", sdl.GetError());
		return false;
	}

	return true;
}

quit_dependencies :: proc() {
	ttf.Quit();
	img.Quit();
	sdl.Quit();
}
