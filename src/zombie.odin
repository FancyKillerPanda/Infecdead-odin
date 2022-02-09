package main;

import "core:math"
import "core:math/rand"

import sdl "vendor:sdl2"

ZOMBIE_WALK_ACC :: 600;
ZOMBIE_FRICTION :: 0.90;
ZOMBIE_MIN_DAMAGE :: 0.1;
ZOMBIE_MAX_DAMAGE :: 0.2;
ZOMBIE_DAMAGE_COOLDOWN :: 0.5;

HEALTH_BAR_HEIGHT :: 10;

Zombie :: struct {
	game: ^Game,

	worldPosition: Vector2,
	dimensions: Vector2,
	rotation: f64,

	velocity: Vector2,
	acceleration: Vector2,

	currentSpritesheet: ^Spritesheet,
	walkSpritesheet: ^Spritesheet,

	currentAnimationFrame: u32,
	timeSinceLastFrameChange: f64,

	health: f64,
	timeSinceLastDamageDealt: f64,
}

create_zombie :: proc(game: ^Game, position: Vector2) -> (zombie: Zombie) {
	zombie.game = game;
	
	// TODO(fkp): Load this from the tilemap
	zombie.worldPosition = position;
	zombie.dimensions = { 64, 64 };

	zombie.walkSpritesheet = new(Spritesheet);
	init_spritesheet(zombie.walkSpritesheet, game.renderer, "res/enemies/zombie.png", zombie.dimensions, { 16, 16 }, 64, 8, nil, 0);

	zombie.currentSpritesheet = zombie.walkSpritesheet;
	zombie.health = 1.0;

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
	sinRotation := math.sin_f64(rotationRadians);
	cosRotation := math.cos_f64(rotationRadians);
	
	// Movement
	acceleration = { cosRotation * ZOMBIE_WALK_ACC, -sinRotation * ZOMBIE_WALK_ACC };
	velocity += acceleration * deltaTime;
	velocity *= ZOMBIE_FRICTION;

	if abs(velocity.x) < 5.0 do velocity.x = 0;
	if abs(velocity.y) < 5.0 do velocity.y = 0;
	
	// Updates position and does collision checking
	worldPosition.x += velocity.x * deltaTime;
	worldPositionRect: sdl.Rect = {
		i32(worldPosition.x - (dimensions.x / 2.0)),
		i32(worldPosition.y - (dimensions.y / 4.0)),
		i32(dimensions.x),
		i32(dimensions.y / 2.0),
	};

	for object in &game.tilemap.objects {
		if sdl.HasIntersection(&worldPositionRect, &object) {
			worldPosition.x -= velocity.x * deltaTime;
			velocity.x = 0;
			break;
		}
	}

	worldPosition.y += velocity.y * deltaTime;
	worldPositionRect.x = i32(worldPosition.x - (dimensions.x / 2.0));
	worldPositionRect.y = i32(worldPosition.y - (dimensions.y / 4.0));

	for object in &game.tilemap.objects {
		if sdl.HasIntersection(&worldPositionRect, &object) {
			worldPosition.y -= velocity.y * deltaTime;
			velocity.y = 0;
			break;
		}
	}

	worldPosition.x = clamp(worldPosition.x, dimensions.x / 2.0, (game.tilemap.dimensions.x * OUTPUT_TILE_SIZE.x) - (dimensions.x / 2.0));
	worldPosition.y = clamp(worldPosition.y, dimensions.y / 2.0, (game.tilemap.dimensions.y * OUTPUT_TILE_SIZE.y) - (dimensions.y / 2.0));
	
	// Checks for collision with player
	timeSinceLastDamageDealt += deltaTime;
	worldPositionRect.x = i32(worldPosition.x - (dimensions.x / 2.0));
	worldPositionRect.y = i32(worldPosition.y - (dimensions.y / 4.0));

	playerRect: sdl.Rect = {
		i32(game.player.worldPosition.x - (game.player.dimensions.x / 2)),
		i32(game.player.worldPosition.y - (game.player.dimensions.y / 2)),
		i32(game.player.dimensions.x / 2),
		i32(game.player.dimensions.y / 2),
	};

	if timeSinceLastDamageDealt >= ZOMBIE_DAMAGE_COOLDOWN && sdl.HasIntersection(&worldPositionRect, &playerRect) {
		timeSinceLastDamageDealt = 0;
		take_damage(&game.player, rand.float64_range(ZOMBIE_MIN_DAMAGE, ZOMBIE_MAX_DAMAGE));
	}

	// Texturing
	timeSinceLastFrameChange += deltaTime;
	if timeSinceLastFrameChange >= 0.15 {
		timeSinceLastFrameChange = 0;

		currentAnimationFrame += 1;
		currentAnimationFrame %= currentSpritesheet.subrectsPerRow;
	}

	if velocity == { 0, 0 } {
		currentAnimationFrame = 0;
	}

	row := u32(math.mod_f64(rotation + 22.5, 360.0) / 45.0);
	spritesheet_set_frame(currentSpritesheet, (row * currentSpritesheet.subrectsPerRow) + currentAnimationFrame);
}

draw_zombie :: proc(using zombie: ^Zombie, viewOffset: Vector2) {
	draw_spritesheet(currentSpritesheet, worldPosition - viewOffset);

	if health < 1.0 {
		fullHealthBarRect: sdl.Rect = {
			i32(worldPosition.x - viewOffset.x - (dimensions.x / 2)),
			i32((worldPosition.y - viewOffset.y - (dimensions.y / 2)) - (HEALTH_BAR_HEIGHT * 2)),
			i32(dimensions.x),
			i32(HEALTH_BAR_HEIGHT),
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
