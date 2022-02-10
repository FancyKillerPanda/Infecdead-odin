package main;

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:strings"

import sdl "vendor:sdl2"

PLAYER_WALK_ACC :: 1000;
PLAYER_FRICTION :: 0.90;
PLAYER_ROTATION_SPEED :: 7;

PISTOL_SHOT_COOLDOWN :: 0.4;
PISTOL_SHOT_VELOCITY :: 800;
PISTOL_SHOT_LIFETIME :: 1.0;
PISTOL_MIN_DAMAGE :: 0.2;
PISTOL_MAX_DAMAGE :: 0.4;
PISTOL_KNOCKBACK :: 5;

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

	health: f64,
}

InventoryItem :: struct {
	type: enum {
		Empty,
		Pistol,
	},

	data: union {
		PistolData,
	},
}

PistolData :: struct {
	bulletsLeft: u32,
}

Bullet :: struct {
	worldPosition: Vector2,
	velocity: Vector2,
	lifeTime: f64,
	damage: f64,

	spritesheet: ^Spritesheet,
}

create_player :: proc(game: ^Game) -> (player: Player) {
	player.game = game;
	
	// player.dimensions = { 96, 96 };
	player.dimensions = { 64, 64 };

	player.walkSpritesheet = new(Spritesheet);
	init_spritesheet(player.walkSpritesheet, game.renderer, "res/player/player.png", player.dimensions, { 16, 16 }, 32, 4, nil, 0);
	player.walkWithPistolSpritesheet = new(Spritesheet);
	init_spritesheet(player.walkWithPistolSpritesheet, game.renderer, "res/player/player_with_pistol.png", player.dimensions, { 16, 16 }, 32, 4, nil, 0);

	player.currentSpritesheet = player.walkWithPistolSpritesheet;

	// TODO(fkp): Make the player pick this up somewhere
	player.inventorySlots[1].type = .Pistol;
	player.inventorySlots[1].data = PistolData { bulletsLeft = 5 };
	player.currentlySelectedInventorySlot = 1;

	player.health = 1.0;

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
	
	// Shooting
	timeSinceLastShot += deltaTime;

	bulletLoop: for bulletIndex := 0; bulletIndex < len(activeBullets); {
		bullet := &activeBullets[bulletIndex];
		bullet.worldPosition += bullet.velocity * deltaTime;

		bullet.lifeTime += deltaTime;
		if bullet.lifeTime >= PISTOL_SHOT_LIFETIME {
			destroy_bullet(player, bulletIndex);
			continue;
		}

		if bullet.worldPosition.x < 0 || bullet.worldPosition.y < 0 ||
		   bullet.worldPosition.x > game.currentWorldDimensions.x || bullet.worldPosition.y > game.currentWorldDimensions.y {
			destroy_bullet(player, bulletIndex);
			continue;
		}

		bulletRect := create_sdl_rect(bullet.worldPosition - bullet.spritesheet.outputSize, bullet.spritesheet.outputSize);

		for zombieIndex := 0; zombieIndex < len(game.zombies); {
			zombie := &game.zombies[zombieIndex];
			zombieRect: sdl.Rect = {
				i32(zombie.worldPosition.x - (zombie.dimensions.x / 2)),
				i32(zombie.worldPosition.y - (zombie.dimensions.y / 2)),
				i32(zombie.dimensions.x),
				i32(zombie.dimensions.y),
			};
			
			if sdl.HasIntersection(&bulletRect, &zombieRect) {
				zombie.health -= bullet.damage;
				if zombie.health <= 0.0 {
					destory_zombie(zombie, zombieIndex);
				} else {
					zombie.worldPosition += vec2_normalise(bullet.velocity) * PISTOL_KNOCKBACK;
				}

				destroy_bullet(player, bulletIndex);

				continue bulletLoop;
			}

			zombieIndex += 1;
		}

		bulletIndex += 1;
	}
	
	// Texturing
	// update_spritesheet(player.currentSpritesheet, deltaTime);
	if inventorySlots[currentlySelectedInventorySlot].type == .Empty {
		currentSpritesheet = walkSpritesheet;
	} else if inventorySlots[currentlySelectedInventorySlot].type == .Pistol {
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

draw_player_on_minimap :: proc(using player: ^Player, minimapPosition: Vector2) {
	minimapPlayerRect: sdl.Rect = {
		// -1 to centre the rect
		i32(minimapPosition.x + (player.worldPosition.x * MINIMAP_TILE_SIZE.x / OUTPUT_TILE_SIZE.x) - 1),
		i32(minimapPosition.y + (player.worldPosition.y * MINIMAP_TILE_SIZE.y / OUTPUT_TILE_SIZE.y) - 1),
		i32(MINIMAP_TILE_SIZE.x * 3),
		i32(MINIMAP_TILE_SIZE.y * 3),
	};
	
	sdl.SetRenderDrawColor(game.renderer, 0, 0, 255, 255);
	sdl.RenderFillRect(game.renderer, &minimapPlayerRect);
}

shoot :: proc(using player: ^Player) {
	if inventorySlots[currentlySelectedInventorySlot].type == .Pistol {
		if inventorySlots[currentlySelectedInventorySlot].data.(PistolData).bulletsLeft > 0 {
			if timeSinceLastShot >= PISTOL_SHOT_COOLDOWN {
				timeSinceLastShot = 0;
				(&inventorySlots[currentlySelectedInventorySlot].data.(PistolData)).bulletsLeft -= 1;

				append(&activeBullets, create_pistol_bullet(player));
			}
		} else {
			printf("Magazine is empty!\n");
		}
	}
}

take_damage :: proc(using player: ^Player, damage: f64) {
	health -= damage;

	if health <= 0 {
		printf("You died.\n");
		return;
	}
}

create_pistol_bullet :: proc(using player: ^Player) -> (bullet: Bullet) {
	rotationRadians := math.to_radians_f64(rotation);
	
	bullet.worldPosition = worldPosition;
	bullet.velocity.x = math.cos_f64(rotationRadians) * PISTOL_SHOT_VELOCITY;
	bullet.velocity.y = -math.sin_f64(rotationRadians) * PISTOL_SHOT_VELOCITY;

	bullet.spritesheet = new(Spritesheet);
	init_spritesheet(bullet.spritesheet, game.renderer, "res/bullets/pistol_bullet.png", { 0, 0 }, { 0, 0 }, 1, 1, nil, 0);

	bullet.damage = rand.float64_range(PISTOL_MIN_DAMAGE, PISTOL_MAX_DAMAGE);
	
	return;
}

destroy_bullet :: proc(player: ^Player, index: int) {
	free(player.activeBullets[index].spritesheet);
	ordered_remove(&player.activeBullets, index);
}
