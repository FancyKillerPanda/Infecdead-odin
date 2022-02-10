package main;

import sdl "vendor:sdl2"

Chest :: struct {
	open: bool,
	contents: InventoryItem,
	worldPosition: Vector2,
}

chestSpritesheet: Spritesheet;
chestContentsIconBackground: Spritesheet;

init_chests :: proc(game: ^Game) {
	init_spritesheet(&chestSpritesheet, game.renderer, "res/objects/chest.png", OUTPUT_TILE_SIZE, { 16, 16 }, 2, 2, nil, 0);
	init_spritesheet(&chestContentsIconBackground, game.renderer, "res/ui/chest_contents_icon_background.png", { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);
	spawn_chests(&game.tilemap);
}

update_chests :: proc(using game: ^Game) {
	playerWorldPositionRect := get_player_world_rect(&player);
	
	// Since the player won't actually be touching the chest, this expands the player hit box
	// slightly to check if they are near enough to it.
	playerWorldPositionRect.x -= 10;
	playerWorldPositionRect.y -= 10;
	playerWorldPositionRect.w += 20;
	playerWorldPositionRect.h += 20;
	
	for chest in &chests {
		chestRect := create_sdl_rect(chest.worldPosition, OUTPUT_TILE_SIZE);

		if sdl.HasIntersection(&playerWorldPositionRect, &chestRect) {
			chest.open = true;
		} else {
			chest.open = false;
		}
	}
}

draw_chests :: proc(game: ^Game, viewOffset: Vector2) {
	for chest in game.chests {
		if chest.open {
			spritesheet_set_frame(&chestSpritesheet, 1);

			iconPosition := chest.worldPosition - viewOffset;
			iconPosition.y -= chestContentsIconBackground.outputSize.y * 2 / 3; // For some spacing

			draw_spritesheet(&chestContentsIconBackground, iconPosition);
			
			switch chest.contents.type {
				case .Empty:
					// Do nothing

				case .Pistol:
					draw_spritesheet(&game.pistolIcon, iconPosition);
				
				case .MedKit:
					draw_spritesheet(&game.medKitIcon, iconPosition);
				}
		} else {
			spritesheet_set_frame(&chestSpritesheet, 0);
		}

		draw_spritesheet(&chestSpritesheet, chest.worldPosition - viewOffset);
	}
}
