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
	subrectsPerRow: u32,

	timeSinceLastTextureChange: f64,

	animationOrder: [] u32,
	animationCurrentIndex: u32,
	animationDelayMs: u32,
}

// If the animationDelayMs is 0, the animation will not progress automatically
init_spritesheet :: proc(spritesheet: ^Spritesheet, renderer: ^sdl.Renderer, data: [] u8,
						 outputSize: Vector2,
						 subrectDimensions: Vector2, numberOfSubrects: u32, subrectsPerRow: u32,
						 animationOrder: [] u32, animationDelayMs: u32) {
	spritesheet.renderer = renderer;

	textureData := sdl.RWFromConstMem(raw_data(data), i32(len(data)));
	if textureData == nil {
		printf("Error: Failed to read texture data. Reason: {}\n", sdl.GetError());
		return;
	}
	
	spritesheet.texture = img.LoadTexture_RW(renderer, textureData, true);
	if spritesheet.texture == nil {
		printf("Error: Failed to load spritesheet texture.\n");
		return;
	}

	if sdl.QueryTexture(spritesheet.texture, nil, nil, &spritesheet.textureRect.w, &spritesheet.textureRect.h) < 0 {
		printf("Error: spritesheet texture is invalid.\n");
		return;
	}

	if outputSize != { 0, 0 } {
		spritesheet.outputSize = outputSize;
	} else {
		spritesheet.outputSize = { f64(spritesheet.textureRect.w), f64(spritesheet.textureRect.h) };
	}

	if subrectDimensions != { 0, 0 } {
		spritesheet.subrectDimensions = subrectDimensions;
	} else {
		spritesheet.subrectDimensions = { f64(spritesheet.textureRect.w), f64(spritesheet.textureRect.h) };
	}

	spritesheet.numberOfSubrects = numberOfSubrects;
	spritesheet.subrectsPerRow = subrectsPerRow;

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
	rect := create_sdl_rect(position - (outputSize / 2), outputSize);
	subrect: sdl.Rect;

	if animationOrder == nil {
		subrect = get_spritesheet_subrect(spritesheet, animationCurrentIndex);
	} else {
		subrect = get_spritesheet_subrect(spritesheet, animationOrder[animationCurrentIndex]);
	}
	
	flip := sdl.RendererFlip.NONE;
	if horizontalFlip do flip = sdl.RendererFlip.HORIZONTAL;
	if verticalFlip do flip = sdl.RendererFlip.VERTICAL;
	
	sdl.RenderCopyEx(renderer, texture, &subrect, &rect, rotation, nil, flip);
}

spritesheet_next_frame :: proc(using spritesheet: ^Spritesheet) {
	animationCurrentIndex += 1;
	
	if animationOrder == nil {
		animationCurrentIndex %= numberOfSubrects;
	} else {
		animationCurrentIndex %= u32(len(animationOrder));
	}
}

spritesheet_set_frame :: proc(using spritesheet: ^Spritesheet, frameIndex: u32) {
	if animationOrder == nil {
		assert(frameIndex < numberOfSubrects);
	} else {
		assert(frameIndex < u32(len(animationOrder)));
	}

	animationCurrentIndex = frameIndex;
}

get_spritesheet_subrect :: proc(using spritesheet: ^Spritesheet, subrectIndex: u32) -> sdl.Rect {
	assert(subrectIndex < numberOfSubrects);

	subrectRow := subrectIndex / subrectsPerRow;
	subrectCol := subrectIndex % subrectsPerRow;
	
	return create_sdl_rect(Vector2 { f64(subrectCol), f64(subrectRow) } * subrectDimensions, subrectDimensions);
}
