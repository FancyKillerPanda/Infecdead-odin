package main;

import "core:math"

import sdl "vendor:sdl2"

PLAYER_WALK_ACC :: 500;
PLAYER_STRAFE_ACC :: 250;
PLAYER_FRICTION :: 0.92;

Vector2 :: [2] f64;

Player :: struct {
	game: ^Game,
	
	position: Vector2,
	dimensions: Vector2,
	rotation: f64,

	velocity: Vector2,
	acceleration: Vector2,
}

create_player :: proc(game: ^Game) -> (player: Player) {
	player.game = game;
	
	player.position = { f64(game.width / 2), f64(game.height / 2) };
	player.dimensions = { 32, 32 };

	return;
}

update_player :: proc(using player: ^Player, deltaTime: f64) {
	// Gets the mouse position
	x, y: i32;
	sdl.GetMouseState(&x, &y);
	mousePos: Vector2 = { f64(x), f64(y) };
	
	// Rotation tracks the mouse position
	delta := mousePos - position;
	result := math.to_degrees_f64(math.atan2_f64(-delta.y, delta.x));
	rotation = math.mod_f64(result + 360.0, 360.0);

	rotationRadians := math.to_radians_f64(rotation);
	sinRotation := math.sin_f64(rotationRadians);
	cosRotation := math.cos_f64(rotationRadians);
	
	// Movement
	acceleration = { 0, 0 };
	if game.keysPressed[sdl.Scancode.W] {
		acceleration.x = cosRotation * PLAYER_WALK_ACC;
		acceleration.y = sinRotation * PLAYER_WALK_ACC;
	}
	if game.keysPressed[sdl.Scancode.S] {
		acceleration.x = cosRotation * -PLAYER_STRAFE_ACC;
		acceleration.y = sinRotation * -PLAYER_STRAFE_ACC;
	}
	if game.keysPressed[sdl.Scancode.A] {
		acceleration.x = sinRotation * -PLAYER_STRAFE_ACC;
		acceleration.y = cosRotation * -PLAYER_STRAFE_ACC;
	}
	if game.keysPressed[sdl.Scancode.D] {
		acceleration.x = sinRotation * PLAYER_STRAFE_ACC;
		acceleration.y = cosRotation * PLAYER_STRAFE_ACC;
	}

	velocity += acceleration * deltaTime;
	velocity.x *= PLAYER_FRICTION;
	position += acceleration * deltaTime;
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
