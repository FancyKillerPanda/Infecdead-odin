package main;

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:strings"

import sdl "vendor:sdl2"

HOSTAGE_WALK_ACC :: 20;
HOSTAGE_FRICTION :: 0.9;
HOSTAGE_FOLLOW_MIN_DISTANCE :: 1.5;
HOSTAGE_FOLLOW_MAX_DISTANCE :: 10;
HOSTAGE_SCARE_DISTANCE :: 10;

HOSTAGE_HEALTH_BAR_HEIGHT :: ZOMBIE_HEALTH_BAR_HEIGHT;

HOSTAGE_TEXTURES: [3] [] u8 = { HOSTAGE_RED_PNG_DATA, HOSTAGE_PURPLE_PNG_DATA, HOSTAGE_YELLOW_PNG_DATA };

Hostage :: struct {
	using character: Character,
}

create_hostage :: proc(game: ^Game, position: Vector2) -> (hostage: Hostage) {
	init_character(game, &hostage, position);
	hostage.type = .Hostage;
	
	hostageTextureIndex := rand.uint32() % 3;
	
	hostage.walkSpritesheet = new(Spritesheet);
	init_spritesheet(hostage.walkSpritesheet, game.renderer, HOSTAGE_TEXTURES[hostageTextureIndex], hostage.dimensions * OUTPUT_TILE_SIZE, { 16, 16 }, 32, 4, nil, 0);
	hostage.currentSpritesheet = hostage.walkSpritesheet;

	return;
}

destory_hostage :: proc(using hostage: ^Hostage, hostageIndex: int) {
	free(walkSpritesheet);
	ordered_remove(&game.hostages, hostageIndex);
}

update_hostage :: proc(using hostage: ^Hostage, hostageIndex: int, deltaTime: f64) -> bool {
	// Rotation tracks the player, but stays away from zombies
	deltaToPlayer := game.player.worldPosition - worldPosition;
	distanceToPlayer := vec2_length(deltaToPlayer);
	totalDelta := deltaToPlayer;

	if distanceToPlayer > HOSTAGE_FOLLOW_MAX_DISTANCE {
		totalDelta = 0;
	}
	
	for hostage in game.hostages {
		deltaToHostage := hostage.worldPosition - worldPosition;
		distance := vec2_length(deltaToHostage);

		if distance != 0 && distance >= HOSTAGE_FOLLOW_MIN_DISTANCE && distance <= HOSTAGE_FOLLOW_MAX_DISTANCE {
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
	if distanceToPlayer < HOSTAGE_FOLLOW_MIN_DISTANCE || distanceToPlayer > HOSTAGE_FOLLOW_MAX_DISTANCE {
		acceleration = 0;
	} else {
		acceleration = rotationVector * HOSTAGE_WALK_ACC;
	}

	velocity += acceleration * deltaTime;
	velocity *= HOSTAGE_FRICTION;

	if abs(velocity.x) < 0.15 do velocity.x = 0;
	if abs(velocity.y) < 0.15 do velocity.y = 0;
	
	// Updates position and does collision checking
	update_character_position(hostage, deltaTime);

	worldRect := multiply_sdl_rect(get_character_world_rect(hostage), OUTPUT_TILE_SIZE);
	collectionRect := multiply_sdl_rect(game.tilemap.hostageCollectionRect, OUTPUT_TILE_SIZE);
	if sdl.HasIntersection(&worldRect, &collectionRect) {
		game.hostagesSaved += 1;
		game.hostagesLeft -= 1;

		if game.hostagesLeft == 0 {
			game.state = .GameOver;
			game.gameWon = true;
		}

		free_text(&game.hostagesProgressText);
		game.hostagesProgressText = create_text(game.renderer, game.menu.textFont,
												strings.clone_to_cstring(fmt.tprintf("{} / {}", game.hostagesSaved, game.hostagesSaved + game.hostagesLeft)));
		
		destory_hostage(hostage, hostageIndex);
		return false;
	}

	// Texturing
	update_character_texture(hostage, deltaTime);

	return true;
}

draw_hostage :: proc(using hostage: ^Hostage, viewOffset: Vector2) {
	draw_spritesheet(currentSpritesheet, (worldPosition - viewOffset) * OUTPUT_TILE_SIZE);
	draw_character_health_bar(hostage, viewOffset);
}
