package main;

import sdl "vendor:sdl2"
import ttf "vendor:sdl2/ttf"

MENU_BASE_COLOUR: sdl.Colour : { 255, 255, 255, 255 };
MENU_HOVER_COLOUR: sdl.Colour : { 255, 255, 0, 255 };
MENU_PRESSED_COLOUR: sdl.Colour : { 192, 192, 0, 255 };

HELP_TEXT :: \
`Welcome to the town of Infecdead (a fairly apt name for the current situation)!

This town has been overrun by zombies, and it's now up to you to save your people.
Why you, specifically? Because you're the guy the WASD keys control, duh!

Navigate the map and collect items from conveniently placed chests. How nice!
But beware, you can only carry four items before the weight of the situation
you are in brings you crashing down. So what will it be? Weapons? Defence? Med-kits?`;

ABOUT_TEXT :: \
`Infecdead v0.0.1

Created by FancyKillerPanda
https://github.com/FancyKillerPanda/
https://fancykillerpanda.itch.io/


More from me:
https://fancykillerpanda.itch.io/jumper/


Texture assets were inspired by a variety of sources in the public
domain, notably Kenney's work on https://opengameart.org/`;

Menu :: struct {
	game: ^Game,
	state: MenuState,

	titleFont: ^ttf.Font,
	textFont: ^ttf.Font,

	currentButtonGroup: ^ButtonGroup,
	homeButtons: ^ButtonGroup,
	profileSelectionButtons: ^ButtonGroup,
	backButton: ButtonGroup,

	titleText: Text,
	helpText: Text,
	aboutText: Text,
}

MenuState :: enum {
	Home,
	ProfileSelection,
	Help,
	Options,
	About,
}

create_menu :: proc(game: ^Game) -> (menu: Menu) {
	menu.game = game;
	menu.state = .Home;

	fontData := sdl.RWFromConstMem(raw_data(FONT_PIXELTYPE_DATA), i32(len(FONT_PIXELTYPE_DATA)));
	if fontData == nil {
		printf("Error: Failed to read font data. Reason: {}\n", sdl.GetError());
		return;
	}
	
	menu.titleFont = ttf.OpenFontRW(fontData, false, 144);
	sdl.RWseek(fontData, 0, sdl.SEEK_SET);
	menu.textFont = ttf.OpenFontRW(fontData, true, 56);

	if menu.titleFont == nil || menu.textFont == nil {
		printf("Error: Failed to load menu font. Reason: {}\n", sdl.GetError());
		return;
	}

	menu.homeButtons = new(ButtonGroup);
	menu.homeButtons^ = create_button_group(game.renderer, menu.textFont, { "Play", "Help", "Options", "About" });
	set_button_group_colours(menu.homeButtons, MENU_BASE_COLOUR, MENU_HOVER_COLOUR, MENU_PRESSED_COLOUR);
	
	menu.profileSelectionButtons = new(ButtonGroup);
	menu.profileSelectionButtons^ = create_button_group(game.renderer, menu.textFont, { "Profile One", "Profile Two", "Profile Three" });
	set_button_group_colours(menu.profileSelectionButtons, MENU_BASE_COLOUR, MENU_HOVER_COLOUR, MENU_PRESSED_COLOUR);
	
	menu.currentButtonGroup = menu.homeButtons;
	menu.backButton = create_button_group(game.renderer, menu.textFont, { "Back" });
	set_button_group_colours(&menu.backButton, MENU_BASE_COLOUR, MENU_HOVER_COLOUR, MENU_PRESSED_COLOUR);

	menu.titleText = create_text(game.renderer, menu.titleFont, "INFECDEAD");
	menu.helpText = create_text(game.renderer, menu.textFont, HELP_TEXT);
	menu.aboutText = create_text(game.renderer, menu.textFont, ABOUT_TEXT);

	return;
}

handle_menu_events :: proc(using menu: ^Menu, event: ^sdl.Event) {
	#partial switch event.type {
		case .MOUSEMOTION:
			if currentButtonGroup != nil {
				button_group_handle_mouse_motion(currentButtonGroup, event);
			}
		
			if state != .Home {
				button_group_handle_mouse_motion(&backButton, event);
			}

		case .MOUSEBUTTONDOWN:
			if currentButtonGroup != nil {
				button_group_handle_mouse_down(currentButtonGroup, event);
			}

			if state != .Home {
				button_group_handle_mouse_down(&backButton, event);
			}

		case .MOUSEBUTTONUP:
			result: i32 = -1;
			if currentButtonGroup != nil {
				result = button_group_handle_mouse_up(currentButtonGroup, event);
			}

			if result != -1 {
				#partial switch state {
					case .Home:
						switch result {
							case 0:
								state = .ProfileSelection;
								currentButtonGroup = profileSelectionButtons;

							case 1:
								state = .Help;
								currentButtonGroup = nil;

							case 2:
								state = .Options;
								currentButtonGroup = nil;
							
							case 3:
								state = .About;
								currentButtonGroup = nil;
						}
					
					case .ProfileSelection:
						game.state = .Playing;
						reset_game(game);
				}
			}
			
			if state != .Home {
				result = button_group_handle_mouse_up(&backButton, event);
				if result != -1 {
					state = .Home;
					currentButtonGroup = homeButtons;
				}
			}
	}
}

draw_menu :: proc(using menu: ^Menu) {
	viewOffset := Vector2 { game.currentWorldDimensions.x / 5, game.currentWorldDimensions.y * 5 / 12 };
	draw_tilemap_first_pass(&game.tilemap, OUTPUT_TILE_SIZE, viewOffset);
	draw_chests(game, viewOffset);
	draw_tilemap_second_pass(&game.tilemap, OUTPUT_TILE_SIZE, viewOffset);

	draw_dark_overlay(game);

	screenWidth := game.screenDimensions.x;
	screenHeight := game.screenDimensions.y;
	
	switch state {
		case .Home:
			draw_text(&titleText, { screenWidth / 2, screenHeight / 4 });
			draw_button_group(homeButtons, { screenWidth / 2, screenHeight * 55 / 100 }, { 0, screenHeight * 1 / 10 })
		
		case .ProfileSelection:
			draw_button_group(profileSelectionButtons, game.screenDimensions / 2, { screenWidth * 2 / 10, 0 });
			draw_button_group(&backButton, { screenWidth / 2, screenHeight * 4 / 5 }, 0);

		case .Help:
			draw_text(&titleText, { screenWidth / 2, screenHeight / 4 });
			draw_text(&helpText, game.screenDimensions / 2);
			draw_button_group(&backButton, { screenWidth / 2, screenHeight * 4 / 5 }, 0);
			
		case .Options:
			// TODO(fkp): Options
			draw_button_group(&backButton, { screenWidth / 2, screenHeight * 4 / 5 }, 0);
			
		case .About:
			draw_text(&titleText, { screenWidth / 2, screenHeight / 4 });
			draw_text(&aboutText, game.screenDimensions / 2);
			draw_button_group(&backButton, { screenWidth / 2, screenHeight * 4 / 5 }, 0);
	}
}
