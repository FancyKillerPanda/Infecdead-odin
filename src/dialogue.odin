package main;

import "core:slice"

DialogueBox :: struct {
	isActive: bool,

	game: ^Game,
	background: Spritesheet,
	items: [] DialogueItem,
}

DialogueItem :: struct {
	mainText: Text,
	options: [dynamic] Text,
}

create_dialogue_box :: proc(game: ^Game, items: [] DialogueItem, isActive := false) -> (box: DialogueBox) {
	box.game = game;
	box.isActive = isActive;
	box.items = slice.clone(items);
	init_spritesheet(&box.background, game.renderer, DIALOGUE_BOX_BACKGROUND_DATA, 0, 0, 1, 1, nil, 0);

	return;
}

create_dialogue_item :: proc(game: ^Game, mainString: cstring, options: [] cstring) -> (item: DialogueItem) {
	item.mainText = create_text(game.renderer, game.menu.textFont, mainString, { 0, 0, 0, 255 });
	for option in options {
		append(&item.options, create_text(game.renderer, game.menu.textFont, option, { 0, 0, 0, 255 }));
	}

	return;
}

draw_dialogue_box :: proc(using box: ^DialogueBox) {
	// TODO(fkp): Be able to switch this
	currentItem := items[0];
	
	backgroundCentre: Vector2 = { game.screenDimensions.x / 2, game.screenDimensions.y * 75 / 100 };
	backgroundLeft: Vector2 = backgroundCentre - (background.outputSize / 2);

	draw_spritesheet(&background, backgroundCentre);
	draw_text(&currentItem.mainText, backgroundLeft + (game.screenDimensions * 3 / 100) + Vector2 { f64(currentItem.mainText.rect.w) / 2, f64(currentItem.mainText.rect.h) / 2 });
	ySpacing := game.screenDimensions.y * 4 / 100;
	
	for option, i in &currentItem.options {
		textLeft := backgroundLeft + Vector2 { game.screenDimensions.x * 6 / 100, (game.screenDimensions.y * 3 / 100) + (ySpacing * f64(i + 1)) };
		draw_text(&option, textLeft + Vector2 { f64(option.rect.w) / 2, f64(option.rect.h) / 2 });
	}
}
