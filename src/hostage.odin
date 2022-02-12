package main;

import "core:math"
import "core:math/rand"

import sdl "vendor:sdl2"

HOSTAGE_WALK_ACC :: 650;
HOSTAGE_FRICTION :: 0.9;
HOSTAGE_FOLLOW_DISTANCE :: 300;
HOSTAGE_SCARE_DISTANCE :: 300;

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

update_hostage :: proc(using hostage: ^Hostage, hostageIndex: int, deltaTime: f64) -> bool{
	// Rotation tracks the player, but stays away from zombies
	deltaToPlayer := game.player.worldPosition - worldPosition;
	if vec2_length(deltaToPlayer) > HOSTAGE_FOLLOW_DISTANCE {
		deltaToPlayer = 0;
	}
	
	totalDelta := deltaToPlayer;

	for hostage in game.hostages {
		deltaToHostage := hostage.worldPosition - worldPosition;
		distance := vec2_length(deltaToHostage);

		if distance != 0 && distance <= HOSTAGE_FOLLOW_DISTANCE {
			totalDelta -= vec2_normalise(deltaToHostage) * 20;
		}
	}
	
	for zombie in game.zombies {
		deltaToZombie := zombie.worldPosition - worldPosition;
		if vec2_length(deltaToZombie) <= HOSTAGE_SCARE_DISTANCE {
			totalDelta -= vec2_normalise(deltaToZombie) * 25;
		}
	}

	rotationRadians := math.atan2_f64(-totalDelta.y, totalDelta.x);
	rotation = math.mod_f64(3600.0 + math.to_degrees_f64(rotationRadians), 360.0);
	rotationVector := vec2_normalise({ math.cos_f64(rotationRadians), -math.sin_f64(rotationRadians) });
	
	// Movement
	if totalDelta == 0 {
		acceleration = 0;
	} else {
		acceleration = rotationVector * HOSTAGE_WALK_ACC;
	}
	velocity += acceleration * deltaTime;
	velocity *= HOSTAGE_FRICTION;

	if abs(velocity.x) < 5.0 do velocity.x = 0;
	if abs(velocity.y) < 5.0 do velocity.y = 0;
	
	// Updates position and does collision checking
	update_character_position(hostage, deltaTime);

	worldRect := get_character_world_rect(hostage);
	if sdl.HasIntersection(&worldRect, &game.tilemap.hostageCollectionRect) {
		game.hostagesSaved += 1;
		game.hostagesLeft -= 1;

		destory_hostage(hostage, hostageIndex);
		return false;
	}

	// Texturing
	update_character_texture(hostage, deltaTime);

	return true;
}

draw_hostage :: proc(using hostage: ^Hostage, viewOffset: Vector2) {
	draw_spritesheet(currentSpritesheet, worldPosition - viewOffset);
	draw_character_health_bar(hostage, viewOffset);
}
