package main;

import "core:math"

import sdl "vendor:sdl2"

PLAYER_WALK_ACC :: 1000;
PLAYER_FRICTION :: 0.92;
PLAYER_ROTATION_SPEED :: 7;

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
	player.dimensions = { 64, 64 };

	player.idleSpritesheet = new(Spritesheet);
	init_spritesheet(player.idleSpritesheet, game.renderer, "res/player/idle_spritesheet.png", player.dimensions, { 16, 16 }, 8, { 0, 1, 2, 3, 4, 5, 6, 7 }, 0);
	// player.walkSpritesheet = new(Spritesheet);
	// init_spritesheet(player.walkSpritesheet, game.renderer, "res/player/walk_spritesheet.png", player.dimensions, { 16, 16 }, 3, { 0, 1, 2 }, 250);

	player.currentSpritesheet = player.idleSpritesheet;

	return;
}

update_player :: proc(using player: ^Player, deltaTime: f64) {
	rotationRadians := math.to_radians_f64(rotation);
	sinRotation := math.sin_f64(rotationRadians);
	cosRotation := math.cos_f64(rotationRadians);
	
	// Movement
	acceleration = { 0, 0 };
	if game.keysPressed[sdl.Scancode.W] {
		acceleration.x = cosRotation * PLAYER_WALK_ACC;
		acceleration.y = -sinRotation * PLAYER_WALK_ACC;
	}
	if game.keysPressed[sdl.Scancode.S] {
		acceleration.x = cosRotation * -PLAYER_WALK_ACC * 0.5;
		acceleration.y = -sinRotation * -PLAYER_WALK_ACC * 0.5;
	}
	if game.keysPressed[sdl.Scancode.A] {
		rotation += PLAYER_ROTATION_SPEED;
		rotation = math.mod_f64(rotation, 360.0);
	}
	if game.keysPressed[sdl.Scancode.D] {
		rotation += 360.0;
		rotation -= PLAYER_ROTATION_SPEED;
		rotation = math.mod_f64(rotation, 360.0);
	}

	velocity += acceleration * deltaTime;
	velocity *= PLAYER_FRICTION;

	if abs(velocity.x) < 1.0 do velocity.x = 0;
	if abs(velocity.y) < 1.0 do velocity.y = 0;
	
	position += velocity * deltaTime;
	
	// Texturing
	if velocity != { 0, 0 } {
		// currentSpritesheet = walkSpritesheet;
	} else {
		currentSpritesheet = idleSpritesheet;
	}

	spritesheet_set_frame(currentSpritesheet, u32(rotation / 45.0));
	update_spritesheet(player.currentSpritesheet, deltaTime);
}

draw_player :: proc(using player: ^Player) {
	draw_spritesheet(player.currentSpritesheet, player.position);
}
