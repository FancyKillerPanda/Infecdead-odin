package main;

import "core:time"

import sdl "vendor:sdl2"

OUTPUT_TILE_SIZE: Vector2 : { 32, 32 };

Game :: struct {
	running: bool,
	state: GameState,

	screenDimensions: Vector2,
	currentWorldDimensions: Vector2,

	window: ^sdl.Window,
	renderer: ^sdl.Renderer,
	keysPressed: [sdl.Scancode.NUM_SCANCODES] bool,

	player: Player,
	tilemap: Tilemap,

	viewOffset: Vector2,

	inventorySlotBackground: Spritesheet,
	inventorySlotBackgroundSelected: Spritesheet,
}

GameState :: enum {
	Playing,
}

init_game :: proc(using game: ^Game) -> bool {
	create_window(game) or_return;
	
	player = create_player(game);
	tilemap = parse_tilemap(game, "res/map/outside.json") or_return;
	game.currentWorldDimensions = tilemap.dimensions;
	
	init_spritesheet(&inventorySlotBackground, renderer, "res/ui/inventory_slot_background.png", { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);
	init_spritesheet(&inventorySlotBackgroundSelected, renderer, "res/ui/inventory_slot_background_selected.png", { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);
	
	running = true;
	state = .Playing;
	
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

			case sdl.EventType.KEYDOWN:
				keysPressed[event.key.keysym.scancode] = true;

			case sdl.EventType.KEYUP:
				keysPressed[event.key.keysym.scancode] = false;
		}
	}
}

update_game :: proc(using game: ^Game, deltaTime: f64) {
	if state == .Playing {
		update_player(&player, deltaTime);

		// The view offset (basically a camera) tracks the player
		viewOffset = player.worldPosition - (game.screenDimensions / 2.0);

		if viewOffset.x < 0.0 do viewOffset.x = 0.0;
		if viewOffset.y < 0.0 do viewOffset.y = 0.0;

		if viewOffset.x + game.screenDimensions.x > OUTPUT_TILE_SIZE.x * currentWorldDimensions.x {
			viewOffset.x = (OUTPUT_TILE_SIZE.x * currentWorldDimensions.x) - game.screenDimensions.x;
		}

		if viewOffset.y + game.screenDimensions.y > OUTPUT_TILE_SIZE.y * currentWorldDimensions.y {
			viewOffset.y = (OUTPUT_TILE_SIZE.y * currentWorldDimensions.y) - game.screenDimensions.y;
		}
	}
}

draw_game :: proc(using game: ^Game) {
	sdl.SetRenderDrawColor(renderer, 192, 192, 192, 255);
	sdl.RenderClear(renderer);

	draw_tilemap(&tilemap, OUTPUT_TILE_SIZE, viewOffset);
	draw_player(&player, viewOffset);
	draw_inventory_slots(game);
	
	sdl.RenderPresent(renderer);
}

draw_inventory_slots :: proc(using game: ^Game) {
	x := (game.screenDimensions.x / 2) - (inventorySlotBackground.outputSize.x * 1.5);
	y := game.screenDimensions.y * 19 / 20;
	
	for i in 0..<4 {
		if u32(i) == player.currentlySelectedInventorySlot {
			draw_spritesheet(&inventorySlotBackgroundSelected, { x, y });
		} else {
			draw_spritesheet(&inventorySlotBackground, { x, y });
		}

		x += inventorySlotBackground.outputSize.x;
	}
}

create_window :: proc(game: ^Game) -> (success: bool) {
	// TODO(fkp): Determine this based on monitor size
	// TODO(fkp): Allow toggling between fullscreen and windowed
	game.screenDimensions = { 1920, 1080 };
	
	game.window = sdl.CreateWindow("Infecdead", 0, 0, i32(game.screenDimensions.x), i32(game.screenDimensions.y), nil);
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
