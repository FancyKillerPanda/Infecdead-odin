package main;

import sdl "vendor:sdl2"

Vector2 :: [2] f64;

Entity :: struct {
	game: ^Game,
	
	position: Vector2,
	dimensions: Vector2,
}

init_entity :: proc(game: ^Game, entity: ^Entity, position: Vector2, dimensions: Vector2) {
	entity.game = game;
	
	entity.position = position;
	entity.dimensions = dimensions;
}

draw_entity :: proc(using entity: ^Entity) {
	rect: sdl.Rect = {
		i32(position.x - (dimensions.x / 2)),
		i32(position.y - (dimensions.y / 2)),
		i32(dimensions.x),
		i32(dimensions.y),
	};
	
	// TODO(fkp): This is temporary, will be replaced with textures
	sdl.SetRenderDrawColor(game.renderer, 255, 255, 255, 255);
	sdl.RenderFillRect(game.renderer, &rect);
}


Player :: struct {
	using entity: Entity,
}
