package main;

import "core:fmt"
import "core:strings"
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

	menu: Menu,
	gameWon: bool,
	gameOverScreen: GameOverScreen,
	
	player: Player,
	tilemap: Tilemap,
	zombies: [dynamic] Zombie,
	chests: [dynamic] Chest,
	
	hostages: [dynamic] Hostage,
	hostagesSaved: u32,
	hostagesLeft: u32,
	hostagesProgressText: Text,

	viewOffset: Vector2,

	inventorySlotBackground: Spritesheet,
	inventorySlotBackgroundSelected: Spritesheet,
	pistolIcon: Spritesheet,
	medKitIcon: Spritesheet,
	hostageIcon: Spritesheet,
}

GameState :: enum {
	Menu,
	Playing,
	Paused,
	GameOver,
}

init_game :: proc(using game: ^Game) -> bool {
	create_window(game) or_return;
	
	tilemap = parse_tilemap(game) or_return;
	game.currentWorldDimensions = tilemap.numberOfTiles;

	menu = create_menu(game);
	gameOverScreen = create_game_over_screen(game);
	
	init_chests(game);
	
	init_spritesheet(&inventorySlotBackground, renderer, INVENTORY_SLOT_BACKGROUND_DATA, { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);
	init_spritesheet(&inventorySlotBackgroundSelected, renderer, INVENTORY_SLOT_BACKGROUND_SELECTED_DATA, { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);
	init_spritesheet(&pistolIcon, renderer, PISTOL_ICON_PNG_DATA, { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);
	init_spritesheet(&medKitIcon, renderer, MED_KIT_ICON_PNG_DATA, { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);
	init_spritesheet(&hostageIcon, renderer, HOSTAGE_ICON_PNG_DATA, { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);

	running = true;
	state = .Menu;
	
	return true;
}

reset_game :: proc(using game: ^Game) {
	player = create_player(game);
	spawn_entities(&tilemap);
	spawn_chests(&tilemap);

	
	hostagesSaved = 0;
	hostagesLeft = u32(len(hostages));
	hostagesProgressText = create_text(renderer, menu.textFont,
									   strings.clone_to_cstring(fmt.tprintf("{} / {}", game.hostagesSaved, game.hostagesSaved + game.hostagesLeft)));
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
					case .ESCAPE:
						switch state {
							case .Menu:
								running = false;

							case .Playing:
								state = .Paused;

							case .Paused:
								state = .Playing;

							case .GameOver:
								state = .Menu;
						}
				}

			case .KEYUP:
				keysPressed[event.key.keysym.scancode] = false;
		}

		#partial switch state {
			case .Menu:
				handle_menu_events(&menu, &event);

			case .Playing:
				handle_player_events(&player, &event);

			case .GameOver:
				handle_game_over_events(&gameOverScreen, &event);
		}
	}
}

update_game :: proc(using game: ^Game, deltaTime: f64) {
	if state == .Playing {
		update_player(&player, deltaTime);

		for zombie in &zombies {
			update_zombie(&zombie, deltaTime);
		}
		
		for i := 0; i < len(hostages); {
			hostage := &hostages[i];
			if update_hostage(hostage, i, deltaTime) {
				i += 1;
			}
		}

		update_chests(game);
		
		// The view offset (basically a camera) tracks the player
		tilesOnScreen := game.screenDimensions / OUTPUT_TILE_SIZE;
		viewOffset = player.worldPosition - (tilesOnScreen / 2.0);

		if viewOffset.x < 0.0 do viewOffset.x = 0.0;
		if viewOffset.y < 0.0 do viewOffset.y = 0.0;

		if viewOffset.x + tilesOnScreen.x > currentWorldDimensions.x {
			viewOffset.x = currentWorldDimensions.x - tilesOnScreen.x;
		}

		if viewOffset.y + tilesOnScreen.y > currentWorldDimensions.y {
			viewOffset.y = currentWorldDimensions.y - tilesOnScreen.y;
		}
	}
}

draw_game :: proc(using game: ^Game) {
	sdl.SetRenderDrawColor(renderer, 192, 192, 192, 255);
	sdl.RenderClear(renderer);
	
	switch state {
		case .Menu:
			draw_menu(&menu);

		case .Playing:
			draw_gameplay(game);

		case .Paused:
			draw_paused(game);

		case .GameOver:
			draw_game_over(&gameOverScreen);
	}
	
	sdl.RenderPresent(renderer);
}

draw_gameplay :: proc(using game: ^Game) {
	draw_tilemap_first_pass(&tilemap, OUTPUT_TILE_SIZE, viewOffset);
	draw_chests(game, viewOffset);
	draw_player(&player, viewOffset);
	
	for zombie in &zombies {
		draw_zombie(&zombie, viewOffset);
	}

	for hostage in &hostages {
		draw_hostage(&hostage, viewOffset);
	}
	
	draw_tilemap_second_pass(&tilemap, OUTPUT_TILE_SIZE, viewOffset);

	draw_minimap(&tilemap);
	draw_inventory_slots(game);
	draw_chests_inventory_slots(game, viewOffset);
	draw_character_health_bar(&player, 0);
	draw_number_of_hostages_left(game);
}

draw_paused :: proc(using game: ^Game) {
	draw_gameplay(game);
	draw_dark_overlay(game);
}

draw_dark_overlay :: proc(using game: ^Game) {
	fillRect := create_sdl_rect(Vector2 { 0, 0 }, screenDimensions);
		
	sdl.SetRenderDrawColor(renderer, 50, 50, 50, 200);
	sdl.RenderFillRect(renderer, &fillRect);
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
				
			case .MedKit:
				draw_spritesheet(&medKitIcon, { x, y });
		}

		if player.inventorySlots[i].currentText.message != "" {
			draw_text(&player.inventorySlots[i].currentText, { x, y + f64(player.inventorySlots[i].currentText.rect.h) });
		}

		x += inventorySlotBackground.outputSize.x;
	}
}

draw_number_of_hostages_left :: proc(using game: ^Game) {
	// Draws the icon (we can't use draw_spritesheet() here because
	// we need to specify the size, not just the position.)
	iconRect := create_sdl_rect({ screenDimensions.x * 1 / 150, screenDimensions.y * 8 / 100 },
								{ PLAYER_HEALTH_BAR_HEIGHT, PLAYER_HEALTH_BAR_HEIGHT });
	sdl.RenderCopy(renderer, hostageIcon.texture, nil, &iconRect);

	draw_text(&hostagesProgressText, { (screenDimensions.x * 4 / 100) + (f64(hostagesProgressText.rect.w) / 2),
									   (screenDimensions.y * 8 / 100) + (f64(hostagesProgressText.rect.h))})
}

create_window :: proc(game: ^Game) -> (success: bool) {
	// TODO(fkp): Allow toggling between fullscreen and windowed
	displayMode: sdl.DisplayMode;
	sdl.GetCurrentDisplayMode(0, &displayMode);

	WINDOW_FLAGS :: sdl.WindowFlags {};
	windowDimensions: Vector2;

	if sdl.WindowFlag.FULLSCREEN in WINDOW_FLAGS {
		windowDimensions = { f64(displayMode.w), f64(displayMode.h) };
	} else {
		size := min(displayMode.w / 16, displayMode.h / 9);
		size -= 10; // Makes the window a bit smaller than the screen size
		windowDimensions = { f64(size * 16), f64(size * 9) };

		if windowDimensions.x > 1920 && windowDimensions.y > 1080 {
			windowDimensions = { 1920, 1080 };
		}
	}
	
	game.window = sdl.CreateWindow("Infecdead", 0, 0, i32(windowDimensions.x), i32(windowDimensions.y), WINDOW_FLAGS);
	if game.window == nil {
		printf("Error: Failed to create window. Message: '{}'\n", sdl.GetError());
		return false;
	}
	
	game.renderer = sdl.CreateRenderer(game.window, -1, sdl.RENDERER_PRESENTVSYNC | sdl.RENDERER_ACCELERATED);
	if game.renderer == nil {
		printf("Error: Failed to create renderer. Message: '{}'\n", sdl.GetError());
		return false;
	}

	game.screenDimensions = { 1920, 1080 };
	sdl.RenderSetLogicalSize(game.renderer, 1920, 1080);
	sdl.SetRenderDrawBlendMode(game.renderer, sdl.BlendMode.BLEND);
	return true;
}
