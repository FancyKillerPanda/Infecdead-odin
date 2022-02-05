package main;

import "core:slice"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

Spritesheet :: struct {
	renderer: ^sdl.Renderer,
	texture: ^sdl.Texture,
	textureRect: sdl.Rect,
	outputSize: Vector2,
	
	subrectDimensions: Vector2,
	numberOfSubrects: u32,

	timeSinceLastTextureChange: f64,

	animationOrder: [] u32,
	animationCurrentIndex: u32,
	animationDelayMs: u32,
}

// If the animationDelayMs is 0, the animation will not progress automatically
init_spritesheet :: proc(spritesheet: ^Spritesheet, renderer: ^sdl.Renderer, filepath: cstring,
						 outputSize: Vector2,
						 subrectDimensions: Vector2, numberOfSubrects: u32,
						 animationOrder: [] u32, animationDelayMs: u32) {
	spritesheet.renderer = renderer;
	spritesheet.texture = img.LoadTexture(renderer, filepath);
	if spritesheet.texture == nil {
		printf("Error: Failed to load spritesheet texture (\"%s\").\n", filepath);
		return;
	}

	if sdl.QueryTexture(spritesheet.texture, nil, nil, &spritesheet.textureRect.w, &spritesheet.textureRect.h) < 0 {
		printf("Error: spritesheet texture (\"%s\") is invalid.\n", filepath);
		return;
	}

	spritesheet.outputSize = outputSize;
	
	spritesheet.subrectDimensions = subrectDimensions;
	spritesheet.numberOfSubrects = numberOfSubrects;

	spritesheet.animationOrder = slice.clone(animationOrder);
	spritesheet.animationDelayMs = animationDelayMs;
}

update_spritesheet :: proc(using spritesheet: ^Spritesheet, deltaTime: f64) {
	timeSinceLastTextureChange += deltaTime;

	if animationDelayMs != 0.0 && timeSinceLastTextureChange >= (f64(animationDelayMs) / 1000.0) {
		timeSinceLastTextureChange = 0;
		spritesheet_next_frame(spritesheet);
	}
}

draw_spritesheet :: proc(using spritesheet: ^Spritesheet, position: Vector2, rotation: f64 = 0, horizontalFlip := false, verticalFlip := false) {
	rect: sdl.Rect;
	rect.x = i32(position.x - (outputSize.x / 2));
	rect.y = i32(position.y - (outputSize.y / 2));
	rect.w = i32(outputSize.x);
	rect.h = i32(outputSize.y);
	
	subrect := get_spritesheet_subrect(spritesheet, spritesheet.animationOrder[spritesheet.animationCurrentIndex]);
	
	flip := sdl.RendererFlip.NONE;
	if horizontalFlip do flip = sdl.RendererFlip.HORIZONTAL;
	if verticalFlip do flip = sdl.RendererFlip.VERTICAL;
	
	sdl.RenderCopyEx(renderer, texture, &subrect, &rect, rotation, nil, flip);
}

spritesheet_next_frame :: proc(using spritesheet: ^Spritesheet) {
	animationCurrentIndex += 1;
	animationCurrentIndex %= u32(len(animationOrder));
}

spritesheet_set_frame :: proc(using spritesheet: ^Spritesheet, frameIndex: u32) {
	assert(frameIndex < u32(len(animationOrder)));
	animationCurrentIndex = frameIndex;
}

// TODO(fkp): Allow multiple lines of images
get_spritesheet_subrect :: proc(using spritesheet: ^Spritesheet, subrectIndex: u32) -> sdl.Rect {
	assert(subrectIndex < numberOfSubrects);

	return sdl.Rect {
		i32(subrectIndex * u32(subrectDimensions.x)),
		0,
		i32(subrectDimensions.x),
		i32(subrectDimensions.y),
	};
}
