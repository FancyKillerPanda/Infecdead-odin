package main;

import sdl "vendor:sdl2"

Vector2 :: [2] f64;

Player :: struct {
	game: ^Game,
	
	position: Vector2,
	dimensions: Vector2,
}

create_player :: proc(game: ^Game) -> (player: Player) {
	player.game = game;
	
	player.position = { f64(game.width / 2), f64(game.height / 2) };
	player.dimensions = { 32, 32 };

	return;
}

update_player :: proc(using player: ^Player, deltaTime: f64) {
}

draw_player :: proc(using player: ^Player) {
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
