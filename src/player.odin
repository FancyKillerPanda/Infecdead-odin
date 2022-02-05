package main;

import "core:fmt"
import "core:math"
import "core:strings"

import sdl "vendor:sdl2"

PLAYER_WALK_ACC :: 1000;
PLAYER_FRICTION :: 0.92;
PLAYER_ROTATION_SPEED :: 7;

PLAYER_DIRECTIONS: [8] string : { "east", "north_east", "north", "north_west", "west", "south_west", "south", "south_east" };

Vector2 :: [2] f64;

Player :: struct {
	game: ^Game,
	
	position: Vector2,
	dimensions: Vector2,
	rotation: f64,

	velocity: Vector2,
	acceleration: Vector2,

	currentSpritesheet: ^Spritesheet,
	directionalSpritesheets: [8] ^Spritesheet,
}

create_player :: proc(game: ^Game) -> (player: Player) {
	player.game = game;
	
	player.position = { f64(game.width / 2), f64(game.height / 2) };
	// player.dimensions = { 64, 64 };
	player.dimensions = { 128, 128 }; // For testing

	// player.idleSpritesheet = new(Spritesheet);
	// init_spritesheet(player.idleSpritesheet, game.renderer, "res/player/idle_spritesheet.png", player.dimensions, { 16, 16 }, 8, { 0, 1, 2, 3, 4, 5, 6, 7 }, 0);

	for direction, i in PLAYER_DIRECTIONS {
		player.directionalSpritesheets[i] = new(Spritesheet);
		init_spritesheet(player.directionalSpritesheets[i], game.renderer, strings.clone_to_cstring(fmt.tprintf("res/player/{}_facing.png", direction), context.temp_allocator),
						 player.dimensions, { 16, 16 }, 4, { 0, 1, 2, 3 }, 200);
	}
	
	player.currentSpritesheet = player.directionalSpritesheets[0];

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

	if abs(velocity.x) < 5.0 do velocity.x = 0;
	if abs(velocity.y) < 5.0 do velocity.y = 0;
	
	position += velocity * deltaTime;
	
	// Texturing
	currentSpritesheet = directionalSpritesheets[u32(math.mod_f64(rotation + 22.5, 360.0) / 45.0)];
	update_spritesheet(player.currentSpritesheet, deltaTime);

	if velocity == { 0, 0 } {
		spritesheet_set_frame(currentSpritesheet, 0);
	}
}

draw_player :: proc(using player: ^Player) {
	draw_spritesheet(player.currentSpritesheet, player.position);
}
