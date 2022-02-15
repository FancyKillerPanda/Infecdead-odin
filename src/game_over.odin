package main;

import sdl "vendor:sdl2"

GAME_OVER_WON_TEXT :: \
`Congrats! You have successfully thwarted the zombie invasion,
and have earned the respect of every member in your village.

Enjoy your new-found fame, you deserve it!`;

GAME_OVER_LOST_TEXT :: \
`Yikes! The zombies have converted you, the last hope of the
village. Without you, the village fell in minutes.

This is your fault.`;

GameOverScreen :: struct {
	game: ^Game,
	
	gameWonText: Text,
	gameWonExtraText: Text,
	gameLostText: Text,
	gameLostExtraText: Text,
	gameOverWonMenu: ButtonGroup,
	gameOverLostMenu: ButtonGroup,
}

create_game_over_screen :: proc(game: ^Game) -> (gameOverScreen: GameOverScreen) {
	gameOverScreen.game = game;
	
	using gameOverScreen;
	gameWonText = create_text(game.renderer, game.menu.titleFont, "What zombie invasion?", { 0, 255, 0, 255 });
	gameWonExtraText = create_text(game.renderer, game.menu.textFont, GAME_OVER_WON_TEXT);
	gameOverWonMenu = create_button_group(game.renderer, game.menu.textFont, { "Play Again", "Menu" });
	set_button_group_colours(&gameOverWonMenu, { 255, 255, 255, 255 }, { 0, 255, 0, 255 }, { 0, 127, 0, 255 });
	
	gameLostText = create_text(game.renderer, game.menu.titleFont, "You Lost!", { 255, 0, 0, 255 });
	gameLostExtraText = create_text(game.renderer, game.menu.textFont, GAME_OVER_LOST_TEXT);
	gameOverLostMenu = create_button_group(game.renderer, game.menu.textFont, { "Retry", "Menu" });
	set_button_group_colours(&gameOverLostMenu, { 255, 255, 255, 255 }, { 255, 0, 0, 255 }, { 127, 0, 0, 255 });

	return;
}

handle_game_over_events :: proc(using gameOverScreen: ^GameOverScreen, event: ^sdl.Event) {
	menu: ^ButtonGroup;
	if game.gameWon {
		menu = &gameOverWonMenu;
	} else {
		menu = &gameOverLostMenu;
	}
	
	#partial switch event.type {
		case .MOUSEMOTION:
			button_group_handle_mouse_motion(menu, event);
		
		case.MOUSEBUTTONDOWN:
			button_group_handle_mouse_down(menu, event);

		case .MOUSEBUTTONUP:
			result := button_group_handle_mouse_up(menu, event);
			if result == 0 {
				reset_game(game);
				game.state = .Playing;
			} else if result == 1 {
				game.state = .Menu;
			}
	}
}

draw_game_over :: proc(using gameOverScreen: ^GameOverScreen) {
	draw_tilemap_first_pass(game.currentTilemap, game.currentOutputTileSize, game.viewOffset);
	draw_chests(game, game.viewOffset);
	draw_tilemap_second_pass(game.currentTilemap, game.currentOutputTileSize, game.viewOffset);

	draw_dark_overlay(game);
	
	screenWidth := game.screenDimensions.x;
	screenHeight := game.screenDimensions.y;
	
	if game.gameWon {
		draw_text(&gameWonText, { screenWidth / 2, screenHeight / 4 });
		draw_text(&gameWonExtraText, { screenWidth / 2, screenHeight / 2 });
		draw_button_group(&gameOverWonMenu, { screenWidth / 2, screenHeight * 7 / 10 }, { screenWidth / 4, 0 });
	} else {
		draw_text(&gameLostText, { screenWidth / 2, screenHeight / 4 });
		draw_text(&gameLostExtraText, { screenWidth / 2, screenHeight / 2 });
		draw_button_group(&gameOverLostMenu, { screenWidth / 2, screenHeight * 7 / 10 }, { screenWidth / 4, 0 });
	}
}
