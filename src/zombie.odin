package main;

import "core:math"
import "core:math/rand"

import sdl "vendor:sdl2"

ZOMBIE_WALK_ACC :: 9.4;
ZOMBIE_FRICTION :: 0.9;
ZOMBIE_AGGRO_DISTANCE :: 15.6;

ZOMBIE_MIN_DAMAGE :: 0.1;
ZOMBIE_MAX_DAMAGE :: 0.2;
ZOMBIE_DAMAGE_COOLDOWN :: 0.5;

ZOMBIE_HEALTH_BAR_HEIGHT :: 10;

Zombie :: struct {
	using character: Character,
	timeSinceLastDamageDealt: f64,
}

create_zombie :: proc(game: ^Game, position: Vector2) -> (zombie: Zombie) {
	init_character(game, &zombie, position);
	zombie.type = .Zombie;
	
	zombie.walkSpritesheet = new(Spritesheet);
	init_spritesheet(zombie.walkSpritesheet, game.renderer, ZOMBIE_PNG_DATA, zombie.dimensions * OUTPUT_TILE_SIZE, { 16, 16 }, 64, 8, nil, 0);
	zombie.currentSpritesheet = zombie.walkSpritesheet;

	return;
}

destory_zombie :: proc(using zombie: ^Zombie, zombieIndex: int) {
	free(walkSpritesheet);
	ordered_remove(&game.zombies, zombieIndex);
}

update_zombie :: proc(using zombie: ^Zombie, deltaTime: f64) {
	// Rotation tracks the player
	deltaToPlayer := game.player.worldPosition - worldPosition;
	totalDelta := deltaToPlayer;

	for zombie in game.zombies {
		deltaToZombie := zombie.worldPosition - worldPosition;
		distance := vec2_length(deltaToZombie);

		if distance != 0 && distance <= HOSTAGE_SCARE_DISTANCE {
			totalDelta -= vec2_normalise(deltaToZombie) * 20;
		}
	}

	rotationRadians := math.atan2_f64(-totalDelta.y, totalDelta.x);
	rotation = math.mod_f64(3600.0 + math.to_degrees_f64(rotationRadians), 360.0);
	rotationVector: Vector2 = vec2_normalise({ math.cos_f64(rotationRadians), -math.sin_f64(rotationRadians) });
	
	// Movement
	if vec2_length(deltaToPlayer) <= ZOMBIE_AGGRO_DISTANCE {
		acceleration = rotationVector * ZOMBIE_WALK_ACC;
	} else {
		acceleration = 0;
	}

	velocity += acceleration * deltaTime;
	velocity *= ZOMBIE_FRICTION;

	if abs(velocity.x) < 0.15 do velocity.x = 0;
	if abs(velocity.y) < 0.15 do velocity.y = 0;
	
	// Updates position and does collision checking
	update_character_position(zombie, deltaTime);
	
	// Checks for collision with player
	timeSinceLastDamageDealt += deltaTime;
	worldPositionRect := multiply_sdl_rect(get_character_world_rect(zombie), OUTPUT_TILE_SIZE);
	playerRect := multiply_sdl_rect(get_character_world_rect(&game.player), OUTPUT_TILE_SIZE);

	if timeSinceLastDamageDealt >= ZOMBIE_DAMAGE_COOLDOWN && sdl.HasIntersection(&worldPositionRect, &playerRect) {
		timeSinceLastDamageDealt = 0;
		take_damage(&game.player, rand.float64_range(ZOMBIE_MIN_DAMAGE, ZOMBIE_MAX_DAMAGE));
	}

	// Texturing
	update_character_texture(zombie, deltaTime);
}

draw_zombie :: proc(using zombie: ^Zombie, viewOffset: Vector2) {
	draw_spritesheet(currentSpritesheet, (worldPosition - viewOffset) * OUTPUT_TILE_SIZE);
	draw_character_health_bar(zombie, viewOffset);
}


