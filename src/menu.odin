package main;

import sdl "vendor:sdl2"

Menu :: struct {
	game: ^Game,
}

create_menu :: proc(game: ^Game) -> (menu: Menu) {
	menu.game = game;

	return;
}

handle_menu_events :: proc(using menu: ^Menu, event: ^sdl.Event) {
	
}

draw_menu :: proc(using menu: ^Menu) {
	viewOffset := Vector2 { game.currentWorldDimensions.x / 5, game.currentWorldDimensions.y / 4 };
	draw_tilemap_first_pass(&game.tilemap, viewOffset);
	draw_tilemap_second_pass(&game.tilemap, viewOffset);

	draw_dark_overlay(game);
}
