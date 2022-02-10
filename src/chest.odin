package main;

Chest :: struct {
	open: bool,
	contents: InventoryItem,
	worldPosition: Vector2,
}

chestSpritesheet: Spritesheet;

init_chests :: proc(game: ^Game) {
	init_spritesheet(&chestSpritesheet, game.renderer, "res/objects/chest.png", OUTPUT_TILE_SIZE, { 16, 16 }, 2, 2, nil, 0);
	spawn_chests(&game.tilemap);
}

draw_chests :: proc(game: ^Game, viewOffset: Vector2) {
	for chest in game.chests {
		if chest.open {
			spritesheet_set_frame(&chestSpritesheet, 1);
		} else {
			spritesheet_set_frame(&chestSpritesheet, 0);
		}

		draw_spritesheet(&chestSpritesheet, chest.worldPosition - viewOffset);
	}
}
