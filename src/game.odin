package main;

import "core:time"

import sdl "vendor:sdl2"

Game :: struct {
	running: bool,

	width: u32,
	height: u32,

	window: ^sdl.Window,
	renderer: ^sdl.Renderer,

	player: Player,
}

init_game :: proc(using game: ^Game) -> bool {
	create_window(game) or_return;
	
	init_entity(game, &player, { f64(width / 2), f64(height / 2) }, { 32, 32 });
	
	running = true;
	return true;
}

run_game :: proc(using game: ^Game) {
	lastTime := time.now();
	
	for running {
		handle_events(game);

		now := time.now();
		deltaTime := f64(time.diff(lastTime, now)) / f64(time.Second);
		
		if deltaTime >= 0.016 {
			lastTime = now;
			update_game(game, deltaTime);
		}
		
		draw_game(game);
	}
}

handle_events :: proc(using game: ^Game) {
	event: sdl.Event;

	for sdl.PollEvent(&event) != 0 {
		#partial switch event.type {
			case sdl.EventType.QUIT:
				running = false;
		}
	}
}

update_game :: proc(using game: ^Game, deltaTime: f64) {
}

draw_game :: proc(using game: ^Game) {
	sdl.SetRenderDrawColor(renderer, 192, 192, 192, 255);
	sdl.RenderClear(renderer);

	draw_entity(&player);
	
	sdl.RenderPresent(renderer);
}

create_window :: proc(game: ^Game) -> (success: bool) {
	// TODO(fkp): Determine this based on monitor size
	// TODO(fkp): Allow toggling between fullscreen and windowed
	game.width = 1920;
	game.height = 1080;
	
	game.window = sdl.CreateWindow("Infecdead", 0, 0, i32(game.width), i32(game.height), nil);
	if game.window == nil {
		printf("Error: Failed to create window. Message: '{}'\n", sdl.GetError());
		return false;
	}
	
	game.renderer = sdl.CreateRenderer(game.window, -1, sdl.RENDERER_PRESENTVSYNC | sdl.RENDERER_ACCELERATED);
	if game.renderer == nil {
		printf("Error: Failed to create renderer. Message: '{}'\n", sdl.GetError());
		return false;
	}

	sdl.SetRenderDrawBlendMode(game.renderer, sdl.BlendMode.BLEND);
	return true;
}
