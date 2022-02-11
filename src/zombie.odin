package main;

import "core:math"
import "core:math/rand"

import sdl "vendor:sdl2"

ZOMBIE_WALK_ACC :: 300;
ZOMBIE_FRICTION :: 0.90;
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
	
	zombie.walkSpritesheet = new(Spritesheet);
	init_spritesheet(zombie.walkSpritesheet, game.renderer, "res/enemies/zombie.png", zombie.dimensions, { 16, 16 }, 64, 8, nil, 0);
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
	update_character_position(zombie, deltaTime);
	
	// Checks for collision with player
	timeSinceLastDamageDealt += deltaTime;
	worldPositionRect := get_character_world_rect(zombie);
	playerRect := get_character_world_rect(&game.player);

	if timeSinceLastDamageDealt >= ZOMBIE_DAMAGE_COOLDOWN && sdl.HasIntersection(&worldPositionRect, &playerRect) {
		timeSinceLastDamageDealt = 0;
		take_damage(&game.player, rand.float64_range(ZOMBIE_MIN_DAMAGE, ZOMBIE_MAX_DAMAGE));
	}

	// Texturing
	update_character_texture(zombie, deltaTime);
}

draw_zombie :: proc(using zombie: ^Zombie, viewOffset: Vector2) {
	draw_spritesheet(currentSpritesheet, worldPosition - viewOffset);

	if health < 1.0 {
		fullHealthBarRect: sdl.Rect = {
			i32(worldPosition.x - viewOffset.x - (dimensions.x / 2)),
			i32((worldPosition.y - viewOffset.y - (dimensions.y / 2)) - (ZOMBIE_HEALTH_BAR_HEIGHT * 2)),
			i32(dimensions.x),
			i32(ZOMBIE_HEALTH_BAR_HEIGHT),
		}

		healthBarRect: sdl.Rect = {
			fullHealthBarRect.x,
			fullHealthBarRect.y,
			i32(f64(fullHealthBarRect.w) * health),
			fullHealthBarRect.h,
		};

		
		sdl.SetRenderDrawColor(game.renderer, 0, 255, 0, 255);
		sdl.RenderFillRect(game.renderer, &healthBarRect);
		sdl.SetRenderDrawColor(game.renderer, 0, 0, 0, 255);
		sdl.RenderDrawRect(game.renderer, &fullHealthBarRect);
	}
}
