package main;

import "core:slice"

DialogueBox :: struct {
	isActive: bool,

	game: ^Game,
	background: Spritesheet,
	items: [] DialogueItem,
	currentItemIndex: u32,
}

DialogueItem :: struct {
	mainText: Text,
	options: ButtonGroup,
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
	item.options = create_button_group(game.renderer, game.menu.textFont, options);
	set_button_group_colours(&item.options, { 0, 0, 0, 255}, { 255, 255, 255, 255 }, { 127, 127, 127, 255 });

	return;
}

draw_dialogue_box :: proc(using box: ^DialogueBox) {
	currentItem := items[currentItemIndex];
	
	backgroundCentre: Vector2 = { game.screenDimensions.x / 2, game.screenDimensions.y * 75 / 100 };
	backgroundLeft: Vector2 = backgroundCentre - (background.outputSize / 2);

	draw_spritesheet(&background, backgroundCentre);
	draw_text(&currentItem.mainText, backgroundLeft + (game.screenDimensions * 3 / 100) + Vector2 { f64(currentItem.mainText.rect.w) / 2, f64(currentItem.mainText.rect.h) / 2 });
	draw_button_group(&currentItem.options, backgroundLeft + (game.screenDimensions * 7 / 100), { 0, game.screenDimensions.y * 4 / 100 }, true);
}
