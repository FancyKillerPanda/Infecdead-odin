package main;

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
	ttf.SizeUTF8(font, message, &text.rect.w, &text.rect.h);

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
