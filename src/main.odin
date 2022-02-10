package main

import "core:fmt"
import "core:math"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import ttf "vendor:sdl2/ttf"

Vector2 :: [2] f64;

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

vec2_normalise :: proc(vec: Vector2) -> Vector2 {
	return vec / vec2_length(vec);
}

vec2_length :: proc(vec: Vector2) -> f64 {
	return math.sqrt_f64((vec.x * vec.x) + (vec.y * vec.y));
}

create_sdl_rect :: proc(position: Vector2, dimensions: Vector2) -> (rect: sdl.Rect) {
	rect.x = i32(position.x);
	rect.y = i32(position.y);
	rect.w = i32(dimensions.x);
	rect.h = i32(dimensions.y);

	return;
}
