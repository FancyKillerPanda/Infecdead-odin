package main;

import sdl "vendor:sdl2"

Chest :: struct {
	isOpen: bool,
	contents: InventoryItem,
	worldPosition: Vector2,
}

chestSpritesheet: Spritesheet;
chestContentsIconBackground: Spritesheet;

init_chests :: proc(game: ^Game) {
	init_spritesheet(&chestSpritesheet, game.renderer, CHEST_PNG_DATA, OUTPUT_TILE_SIZE, { 16, 16 }, 2, 2, nil, 0);
	init_spritesheet(&chestContentsIconBackground, game.renderer, CHEST_CONTENTS_ICON_BACKGROUND_DATA, { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);
	spawn_chests(&game.tilemap);
}

update_chests :: proc(using game: ^Game) {
	playerWorldPositionRect := get_character_world_rect(&player);
	
	// Since the player won't actually be touching the chest, this expands the player hit box
	// slightly to check if they are near enough to it.
	playerWorldPositionRect.x -= 10;
	playerWorldPositionRect.y -= 10;
	playerWorldPositionRect.w += 20;
	playerWorldPositionRect.h += 20;
	
	for chest in &chests {
		chestRect := create_sdl_rect(chest.worldPosition, OUTPUT_TILE_SIZE);

		if sdl.HasIntersection(&playerWorldPositionRect, &chestRect) {
			chest.isOpen = true;
		} else {
			chest.isOpen = false;
		}
	}
}

draw_chests :: proc(game: ^Game, viewOffset: Vector2) {
	for chest in &game.chests {
		spritesheet_set_frame(&chestSpritesheet, u32(chest.isOpen));
		draw_spritesheet(&chestSpritesheet, chest.worldPosition - viewOffset);
	}
}

draw_chests_inventory_slots :: proc(game: ^Game, viewOffset: Vector2) {
	for chest in &game.chests {
		if chest.isOpen {
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

			if chest.contents.currentText.message != "" {
				draw_text(&chest.contents.currentText, { iconPosition.x, iconPosition.y + f64(chest.contents.currentText.rect.h)});
			}
		}
	}
}
