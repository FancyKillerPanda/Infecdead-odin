package main;

import "core:math"
import "core:math/rand"

import sdl "vendor:sdl2"

ZOMBIE_HEALTH_BAR_HEIGHT :: 10;

Zombie :: struct {
	using character: Character,
	timeSinceLastDamageDealt: f64,
}

create_zombie :: proc(game: ^Game, position: Vector2) -> (zombie: Zombie) {
	init_character(game, &zombie, position);
	zombie.type = .Zombie;
	
	zombie.walkSpritesheet = new(Spritesheet);
	init_spritesheet(zombie.walkSpritesheet, game.renderer, ZOMBIE_PNG_DATA, zombie.dimensions * game.currentOutputTileSize, { 16, 16 }, 64, 8, nil, 0);
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

		if distance != 0 && distance <= get_game_data(game).hostageScareDistance {
			totalDelta -= vec2_normalise(deltaToZombie) * 20;
		}
	}

	rotationRadians := math.atan2_f64(-totalDelta.y, totalDelta.x);
	rotation = math.mod_f64(3600.0 + math.to_degrees_f64(rotationRadians), 360.0);
	rotationVector: Vector2 = vec2_normalise({ math.cos_f64(rotationRadians), -math.sin_f64(rotationRadians) });
	
	// Movement
	if vec2_length(deltaToPlayer) <= get_game_data(game).zombieAggroDistance {
		acceleration = rotationVector * get_game_data(game).zombieWalkAcceleration;
	} else {
		acceleration = 0;
	}

	velocity += acceleration * deltaTime;
	velocity *= get_game_data(game).zombieFriction;

	if abs(velocity.x) < 0.15 do velocity.x = 0;
	if abs(velocity.y) < 0.15 do velocity.y = 0;
	
	// Updates position and does collision checking
	update_character_position(zombie, deltaTime);
	
	// Checks for collision with player
	timeSinceLastDamageDealt += deltaTime;
	worldPositionRect := multiply_sdl_rect(get_character_world_rect(zombie), game.currentOutputTileSize);
	playerRect := multiply_sdl_rect(get_character_world_rect(&game.player), game.currentOutputTileSize);

	if timeSinceLastDamageDealt >= get_game_data(game).zombieDamageCooldown && sdl.HasIntersection(&worldPositionRect, &playerRect) {
		timeSinceLastDamageDealt = 0;
		take_damage(&game.player, rand.float64_range(get_game_data(game).zombieMinDamage, get_game_data(game).zombieMaxDamage));
	}

	// Texturing
	update_character_texture(zombie, deltaTime);
}

draw_zombie :: proc(using zombie: ^Zombie, viewOffset: Vector2) {
	draw_spritesheet(currentSpritesheet, game.currentTilemapOutputPosition + ((worldPosition - viewOffset) * game.currentOutputTileSize));
	draw_character_health_bar(zombie, viewOffset);
}
