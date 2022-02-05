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

	currentSpritesheet: ^Spritesheet,
	idleSpritesheet: ^Spritesheet,
	walkSpritesheet: ^Spritesheet,
}

create_player :: proc(game: ^Game) -> (player: Player) {
	player.game = game;
	
	player.position = { f64(game.width / 2), f64(game.height / 2) };
	player.dimensions = { 32, 32 };

	player.idleSpritesheet = new(Spritesheet);
	init_spritesheet(player.idleSpritesheet, game.renderer, "res/player/idle_0.png", { 32, 32 }, 1, { 0 }, 0);
	player.walkSpritesheet = new(Spritesheet);
	init_spritesheet(player.walkSpritesheet, game.renderer, "res/player/walk_spritesheet.png", { 32, 32 }, 2, { 0, 1 }, 50);

	player.currentSpritesheet = player.idleSpritesheet;

	return;
}

update_player :: proc(using player: ^Player, deltaTime: f64) {
	// Gets the mouse position
	x, y: i32;
	sdl.GetMouseState(&x, &y);
	mousePos: Vector2 = { f64(x), f64(y) };
	
	// Rotation tracks the mouse position
	positionDelta := mousePos - position;
	result := math.to_degrees_f64(math.atan2_f64(positionDelta.y, positionDelta.x));
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
	velocity *= PLAYER_FRICTION;
	position += acceleration * deltaTime;

	// Texturing
	update_spritesheet(player.currentSpritesheet, deltaTime);
}

draw_player :: proc(using player: ^Player) {
	draw_spritesheet(player.currentSpritesheet, player.position, rotation);
}
