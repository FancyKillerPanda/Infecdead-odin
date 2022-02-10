package main;

import "core:time"

import sdl "vendor:sdl2"

OUTPUT_TILE_SIZE: Vector2 : { 32, 32 };
MINIMAP_TILE_SIZE: Vector2 : { 2, 2 };

Game :: struct {
	running: bool,
	state: GameState,

	screenDimensions: Vector2,
	currentWorldDimensions: Vector2,

	window: ^sdl.Window,
	renderer: ^sdl.Renderer,
	keysPressed: [sdl.Scancode.NUM_SCANCODES] bool,

	player: Player,
	zombies: [dynamic] Zombie,
	tilemap: Tilemap,

	viewOffset: Vector2,

	inventorySlotBackground: Spritesheet,
	inventorySlotBackgroundSelected: Spritesheet,
	pistolIcon: Spritesheet,
}

GameState :: enum {
	Playing,
	Paused,
}

init_game :: proc(using game: ^Game) -> bool {
	create_window(game) or_return;
	
	tilemap = parse_tilemap(game, "res/map/outside.json", OUTPUT_TILE_SIZE) or_return;
	game.currentWorldDimensions = tilemap.dimensions * OUTPUT_TILE_SIZE;
	player = create_player(game);
	
	init_spritesheet(&inventorySlotBackground, renderer, "res/ui/inventory_slot_background.png", { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);
	init_spritesheet(&inventorySlotBackgroundSelected, renderer, "res/ui/inventory_slot_background_selected.png", { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);
	init_spritesheet(&pistolIcon, renderer, "res/ui/pistol_icon.png", { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);
	
	spawn_entities(&tilemap);
	
	running = true;
	state = .Playing;
	
	return true;
}

run_game :: proc(using game: ^Game) {
	lastTime := time.now();
	frameTimeAverageStart := time.now();
	frameTimeAverageCount := 0;
	
	for running {
		handle_events(game);

		now := time.now();
		deltaTime := f64(time.diff(lastTime, now)) / f64(time.Second);
		
		if deltaTime >= 0.016 {
			lastTime = now;
			update_game(game, deltaTime);
		}
		
		draw_game(game);
		
		frameTimeAverageCount += 1;
		if frameTimeAverageCount == 60 {
			frameTimeAverage := (f64(time.diff(frameTimeAverageStart, time.now())) / f64(time.Millisecond)) / f64(frameTimeAverageCount);
			printf("Frame: %d ms (%d FPS)\n", i64(frameTimeAverage), i64(1000.0 / frameTimeAverage));

			frameTimeAverageStart = time.now();
			frameTimeAverageCount = 0;
		}
	}
}

handle_events :: proc(using game: ^Game) {
	event: sdl.Event;

	for sdl.PollEvent(&event) != 0 {
		#partial switch event.type {
			case .QUIT:
				running = false;

			case .KEYDOWN:
				keysPressed[event.key.keysym.scancode] = true;

				#partial switch event.key.keysym.scancode {
					case .P:
						if state == .Playing {
							state = .Paused;
						} else if state == .Paused {
							state = .Playing;
						}

					case .ESCAPE:
						if state == .Paused {
							state = .Playing;
						}
				}

			case .KEYUP:
				keysPressed[event.key.keysym.scancode] = false;
		}

		handle_player_events(&player, &event);
	}
}

update_game :: proc(using game: ^Game, deltaTime: f64) {
	if state == .Playing {
		update_player(&player, deltaTime);

		for zombie in &zombies {
			update_zombie(&zombie, deltaTime);
		}
		
		// The view offset (basically a camera) tracks the player
		viewOffset = player.worldPosition - (game.screenDimensions / 2.0);

		if viewOffset.x < 0.0 do viewOffset.x = 0.0;
		if viewOffset.y < 0.0 do viewOffset.y = 0.0;

		if viewOffset.x + game.screenDimensions.x > currentWorldDimensions.x {
			viewOffset.x = currentWorldDimensions.x - game.screenDimensions.x;
		}

		if viewOffset.y + game.screenDimensions.y > currentWorldDimensions.y {
			viewOffset.y = currentWorldDimensions.y - game.screenDimensions.y;
		}
	}
}

draw_game :: proc(using game: ^Game) {
	sdl.SetRenderDrawColor(renderer, 192, 192, 192, 255);
	sdl.RenderClear(renderer);

	draw_tilemap_first_pass(&tilemap, viewOffset);
	draw_player(&player, viewOffset);
	
	for zombie in &zombies {
		draw_zombie(&zombie, viewOffset);
	}
	
	draw_tilemap_second_pass(&tilemap, viewOffset);
	draw_minimap(&tilemap);
	draw_inventory_slots(game);
	
	// Draws a dark overlay
	if state == .Paused {
		fillRect: sdl.Rect = { 0, 0, i32(screenDimensions.x), i32(screenDimensions.y) }
		
		sdl.SetRenderDrawColor(renderer, 50, 50, 50, 200);
		sdl.RenderFillRect(renderer, &fillRect);
	}
	
	sdl.RenderPresent(renderer);
}

draw_inventory_slots :: proc(using game: ^Game) {
	x := (game.screenDimensions.x / 2) - (inventorySlotBackground.outputSize.x * 1.5);
	y := game.screenDimensions.y * 19 / 20;
	
	for i in 0..<len(player.inventorySlots) {
		if u32(i) == player.currentlySelectedInventorySlot {
			draw_spritesheet(&inventorySlotBackgroundSelected, { x, y });
		} else {
			draw_spritesheet(&inventorySlotBackground, { x, y });
		}

		switch player.inventorySlots[i].type {
			case .Empty:
				// Do nothing

			case .Pistol:
				draw_spritesheet(&pistolIcon, { x, y });
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
