package main;

import "core:fmt"
import "core:math"
import "core:strings"

import sdl "vendor:sdl2"

PLAYER_WALK_ACC :: 1000;
PLAYER_FRICTION :: 0.90;
PLAYER_ROTATION_SPEED :: 7;

PISTOL_SHOT_COOLDOWN :: 0.4;
PISTOL_SHOT_VELOCITY :: 800;
PISTOL_SHOT_LIFETIME :: 1.0;

Vector2 :: [2] f64;

Player :: struct {
	game: ^Game,
	
	worldPosition: Vector2,
	dimensions: Vector2,
	rotation: f64,

	velocity: Vector2,
	acceleration: Vector2,

	currentSpritesheet: ^Spritesheet,
	walkSpritesheet: ^Spritesheet,
	walkWithPistolSpritesheet: ^Spritesheet,
	
	currentAnimationFrame: u32,
	timeSinceLastFrameChange: f64,

	inventorySlots: [4] InventoryItem,
	currentlySelectedInventorySlot: u32,

	activeBullets: [dynamic] Bullet,
	timeSinceLastShot: f64,
}

InventoryItem :: enum {
	Empty,
	Pistol,
}

Bullet :: struct {
	worldPosition: Vector2,
	velocity: Vector2,
	lifeTime: f64,

	spritesheet: ^Spritesheet,
}

create_player :: proc(game: ^Game) -> (player: Player) {
	player.game = game;
	
	player.worldPosition = { 100, 100 }; // This is temporary, until we have a proper starting spot
	player.dimensions = { 96, 96 };

	player.walkSpritesheet = new(Spritesheet);
	init_spritesheet(player.walkSpritesheet, game.renderer, "res/player/player.png", player.dimensions, { 16, 16 }, 32, 4, nil, 0);
	player.walkWithPistolSpritesheet = new(Spritesheet);
	init_spritesheet(player.walkWithPistolSpritesheet, game.renderer, "res/player/player_with_pistol.png", player.dimensions, { 16, 16 }, 32, 4, nil, 0);

	player.currentSpritesheet = player.walkWithPistolSpritesheet;

	// TODO(fkp): Make the player pick this up somewhere
	player.inventorySlots[1] = .Pistol;
	player.currentlySelectedInventorySlot = 1;

	return;
}

handle_player_events :: proc(using player: ^Player, event: ^sdl.Event) {
	#partial switch event.type {
		case .KEYDOWN:
			#partial switch event.key.keysym.scancode {
				case .NUM1: fallthrough;
				case .NUM2: fallthrough;
				case .NUM3: fallthrough;
				case .NUM4:
					player.currentlySelectedInventorySlot = u32(event.key.keysym.scancode - sdl.Scancode.NUM1);
			}

		case .MOUSEWHEEL:
			if event.wheel.y > 0 {
				currentlySelectedInventorySlot += len(inventorySlots);
				currentlySelectedInventorySlot -= 1;
			} else if event.wheel.y < 0 {
				currentlySelectedInventorySlot += 1;
			}

			currentlySelectedInventorySlot %= len(inventorySlots);

		case .MOUSEBUTTONDOWN:
			if event.button.button == sdl.BUTTON_LEFT {
				shoot(player);
			}
	}
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
	
	worldPosition += velocity * deltaTime;

	// Position bounds checking
	worldPosition.x = clamp(worldPosition.x, dimensions.x / 2.0, (game.tilemap.dimensions.x * OUTPUT_TILE_SIZE.x) - (dimensions.x / 2.0));
	worldPosition.y = clamp(worldPosition.y, dimensions.y / 2.0, (game.tilemap.dimensions.y * OUTPUT_TILE_SIZE.y) - (dimensions.y / 2.0));

	// Shooting
	timeSinceLastShot += deltaTime;

	for i := 0; i < len(activeBullets); {
		bullet := &activeBullets[i];
		bullet.worldPosition += bullet.velocity * deltaTime;

		bullet.lifeTime += deltaTime;
		if bullet.lifeTime >= PISTOL_SHOT_LIFETIME {
			destroy_bullet(player, i);
			continue;
		}

		if bullet.worldPosition.x < 0 || bullet.worldPosition.y < 0 ||
		   bullet.worldPosition.x > game.currentWorldDimensions.x || bullet.worldPosition.y > game.currentWorldDimensions.y {
			destroy_bullet(player, i);
			continue;
		}

		i += 1;
	}
	
	// Texturing
	// update_spritesheet(player.currentSpritesheet, deltaTime);
	if inventorySlots[currentlySelectedInventorySlot] == .Empty {
		currentSpritesheet = walkSpritesheet;
	} else if inventorySlots[currentlySelectedInventorySlot] == .Pistol {
		currentSpritesheet = walkWithPistolSpritesheet;
	}
	
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

draw_player :: proc(using player: ^Player, viewOffset: Vector2) {
	draw_spritesheet(player.currentSpritesheet, player.worldPosition - viewOffset);

	for bullet in activeBullets {
		draw_spritesheet(bullet.spritesheet, bullet.worldPosition - viewOffset);
	}
}

shoot :: proc(using player: ^Player) {
	if inventorySlots[currentlySelectedInventorySlot] == .Pistol {
		if timeSinceLastShot >= PISTOL_SHOT_COOLDOWN {
			timeSinceLastShot = 0;
			append(&activeBullets, create_pistol_bullet(player));
		}
	}
}

create_pistol_bullet :: proc(using player: ^Player) -> (bullet: Bullet) {
	rotationRadians := math.to_radians_f64(rotation);
	
	bullet.worldPosition = worldPosition;
	bullet.velocity.x = math.cos_f64(rotationRadians) * PISTOL_SHOT_VELOCITY;
	bullet.velocity.y = -math.sin_f64(rotationRadians) * PISTOL_SHOT_VELOCITY;

	bullet.spritesheet = new(Spritesheet);
	init_spritesheet(bullet.spritesheet, game.renderer, "res/bullets/pistol_bullet.png", { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);

	return;
}

destroy_bullet :: proc(player: ^Player, index: int) {
	free(player.activeBullets[index].spritesheet);
	ordered_remove(&player.activeBullets, index);
}
