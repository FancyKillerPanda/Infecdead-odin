package main;

import "core:math"
import "core:math/rand"

import sdl "vendor:sdl2"

HOSTAGE_WALK_ACC :: 700;
HOSTAGE_FRICTION :: 0.9;

HOSTAGE_HEALTH_BAR_HEIGHT :: ZOMBIE_HEALTH_BAR_HEIGHT;

Hostage :: struct {
	using character: Character,
}

create_hostage :: proc(game: ^Game, position: Vector2) -> (hostage: Hostage) {
	init_character(game, &hostage, position);
	hostage.type = .Hostage;
	
	hostage.walkSpritesheet = new(Spritesheet);
	// TODO(fkp): A sprite for the hostages
	init_spritesheet(hostage.walkSpritesheet, game.renderer, "res/player/player.png", hostage.dimensions, { 16, 16 }, 32, 4, nil, 0);
	hostage.currentSpritesheet = hostage.walkSpritesheet;

	return;
}

destory_hostage :: proc(using hostage: ^Hostage, hostageIndex: int) {
	free(walkSpritesheet);
	ordered_remove(&game.hostages, hostageIndex);
}

update_hostage :: proc(using hostage: ^Hostage, deltaTime: f64) {
	// Rotation tracks the player
	deltaToPlayer := game.player.worldPosition - worldPosition;
	rotationRadians := math.atan2_f64(-deltaToPlayer.y, deltaToPlayer.x);
	rotation = math.mod_f64(3600.0 + math.to_degrees_f64(rotationRadians), 360.0);
	rotationVector: Vector2 = { math.cos_f64(rotationRadians), -math.sin_f64(rotationRadians) };
	
	// Movement
	acceleration = rotationVector * ZOMBIE_WALK_ACC;
	velocity += acceleration * deltaTime;
	velocity *= ZOMBIE_FRICTION;

	if abs(velocity.x) < 5.0 do velocity.x = 0;
	if abs(velocity.y) < 5.0 do velocity.y = 0;
	
	// Updates position and does collision checking
	update_character_position(hostage, deltaTime);

	// Texturing
	update_character_texture(hostage, deltaTime);
}

draw_hostage :: proc(using hostage: ^Hostage, viewOffset: Vector2) {
	draw_spritesheet(currentSpritesheet, worldPosition - viewOffset);
	draw_character_health_bar(hostage, viewOffset);
}
