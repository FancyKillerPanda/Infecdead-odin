package main;

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import ttf "vendor:sdl2/ttf"

ButtonGroup :: struct {
	renderer: ^sdl.Renderer,
	font: ^ttf.Font,
	buttonTexts: [dynamic] Text,

	baseColour: sdl.Colour,
	hoverColour: sdl.Colour,
	pressedColour: sdl.Colour,

	active: i32,
}

create_button_group :: proc(renderer: ^sdl.Renderer, font: ^ttf.Font, texts: [] cstring) -> (buttonGroup: ButtonGroup) {
	buttonGroup.renderer = renderer;
	buttonGroup.font = font;

	set_button_group_colours(&buttonGroup);
	
	for text in texts {
		append(&buttonGroup.buttonTexts, create_text(renderer, font, text, buttonGroup.baseColour));
	}

	return;
}

draw_button_group :: proc(using buttonGroup: ^ButtonGroup, position: Vector2, spacing: Vector2, positionIsTopLeft := false) {
	currentPosition: Vector2;
	if positionIsTopLeft {
		currentPosition = position;
	} else {
		currentPosition = position - ((f64(len(buttonTexts) - 1) / 2.0) * spacing);
	}
	
	for text in &buttonTexts {
		if positionIsTopLeft {
			draw_text(&text, currentPosition + Vector2 { f64(text.rect.w) / 2, f64(text.rect.h) / 2 });
		} else {
			draw_text(&text, currentPosition);
		}
		currentPosition += spacing;
	}
}

set_button_group_colours :: proc(buttonGroup: ^ButtonGroup, baseColour: sdl.Colour = { 255, 255, 255, 255 },
								 hoverColour: sdl.Colour = { 255, 0, 0, 255 }, pressedColour: sdl.Colour = { 127, 0, 0, 255 }) {
	buttonGroup.baseColour = baseColour;
	buttonGroup.hoverColour = hoverColour;
	buttonGroup.pressedColour = pressedColour;
}

button_group_handle_event :: proc(using buttonGroup: ^ButtonGroup, event: ^sdl.Event) -> i32 {
	#partial switch event.type {
		case .MOUSEMOTION:
			button_group_handle_mouse_motion(buttonGroup, event);

		case .MOUSEBUTTONDOWN:
			button_group_handle_mouse_down(buttonGroup, event);
			
		case .MOUSEBUTTONUP:
			return button_group_handle_mouse_up(buttonGroup, event);
	}

	return -1;
}

@(private = "file")
button_group_handle_mouse_motion :: proc(using buttonGroup: ^ButtonGroup, event: ^sdl.Event) {
	mouseRect: sdl.Rect = { event.motion.x, event.motion.y, 1, 1 };

	for text, i in &buttonGroup.buttonTexts {
		if sdl.HasIntersection(&mouseRect, &text.rect) {
			if text.colour == buttonGroup.baseColour {
				change_text_colour(&text, buttonGroup.hoverColour);
			}
		} else {
			if active == i32(i) {
				active = -1;
			}

			if text.colour != buttonGroup.baseColour {
				change_text_colour(&text, buttonGroup.baseColour);
			}
		}
	}
}

@(private = "file")
button_group_handle_mouse_down :: proc(using buttonGroup: ^ButtonGroup, event: ^sdl.Event) {
	mouseRect: sdl.Rect = { event.button.x, event.button.y, 1, 1 };

	for text, i in &buttonGroup.buttonTexts {
		if sdl.HasIntersection(&mouseRect, &text.rect) {
			active = i32(i);
			
			if text.colour != buttonGroup.pressedColour {
				change_text_colour(&text, buttonGroup.pressedColour);
			}
		}
	}
}

@(private = "file")
button_group_handle_mouse_up :: proc(using buttonGroup: ^ButtonGroup, event: ^sdl.Event) -> i32 {
	if active == -1 {
		return -1;
	}

	mouseRect: sdl.Rect = { event.button.x, event.button.y, 1, 1 };
	if sdl.HasIntersection(&mouseRect, &buttonGroup.buttonTexts[active].rect) {
		change_text_colour(&buttonGroup.buttonTexts[active], buttonGroup.hoverColour);

		oldActive := active;
		active = -1;
		
		return oldActive;
	}
	
	return -1;
}
