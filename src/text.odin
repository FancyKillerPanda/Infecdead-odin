package main;

import "core:strings"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import ttf "vendor:sdl2/ttf"

Text :: struct {
	message: cstring,

	renderer: ^sdl.Renderer,
	font: ^ttf.Font,
	texture: ^sdl.Texture,
	rect: sdl.Rect,

	colour: sdl.Colour,
}

create_text :: proc(renderer: ^sdl.Renderer, font: ^ttf.Font, message: cstring, colour: sdl.Colour = { 255, 255, 255, 255 }) -> (text: Text) {
	text.renderer = renderer;
	text.font = font;
	text.message = message;
	
	change_text_colour(&text, colour);
	SizeUTF8_Wrapped(font, message, &text.rect.w, &text.rect.h);

	return;
}

free_text :: proc(using text: ^Text) {
	sdl.DestroyTexture(texture);
	texture = nil;
}

draw_text :: proc(using text: ^Text, position: Vector2) {
	rect.x = i32(position.x) - (rect.w / 2);
	rect.y = i32(position.y) - (rect.h / 2);

	sdl.RenderCopy(renderer, texture, nil, &rect);
}

change_text_colour :: proc(using text: ^Text, colour_: sdl.Colour) {
	colour = colour_;
	
	surface := ttf.RenderUTF8_Solid_Wrapped(font, message, colour, 0);
	texture = sdl.CreateTextureFromSurface(renderer, surface);
	sdl.FreeSurface(surface);
}

SizeUTF8_Wrapped :: proc(font: ^ttf.Font, messageCString: cstring, width: ^i32, height: ^i32) {
	message := string(messageCString);
	
	lineStart: i32;
	lineCurrent: i32;
	longestLineWidth: i32;
	numberOfLines: i32 = 1;

	for char in message {
		lineCurrent += 1;
		if char == '\n' {
			line := message[lineStart : lineCurrent];
			numberOfLines += 1;
			lineStart = lineCurrent;
			
			ttf.SizeUTF8(font, strings.clone_to_cstring(line, context.temp_allocator), width, height);
			if width^ > longestLineWidth do longestLineWidth = width^;
		}
	}

	if numberOfLines == 1 {
		ttf.SizeUTF8(font, messageCString, &longestLineWidth, height);
	}

	width^ = longestLineWidth;
	height^ = numberOfLines * ttf.FontLineSkip(font);
}
