package main;

ZOMBIE_PNG_DATA :: #load("../res/characters/zombie.png");
PLAYER_PNG_DATA :: #load("../res/characters/player.png");
PLAYER_WITH_PISTOL_PNG_DATA :: #load("../res/characters/player_with_pistol.png");
HOSTAGE_RED_PNG_DATA :: #load("../res/characters/hostage_red.png");
HOSTAGE_PURPLE_PNG_DATA :: #load("../res/characters/hostage_purple.png");
HOSTAGE_YELLOW_PNG_DATA :: #load("../res/characters/hostage_yellow.png");

FONT_PIXELTYPE_DATA :: #load("../res/fonts/Pixeltype.ttf");

MAP_TILESET_DATA :: #load("../res/maps/tileset.json");
MAP_TILESET_IMAGE_DATA :: #load("../res/maps/tileset.png");
MAP_OUTSIDE_DATA :: #load("../res/maps/outside.json");
MAP_TOWN_HALL_DATA :: #load("../res/maps/town_hall.json");

PISTOL_BULLET_PNG_DATA :: #load("../res/objects/pistol_bullet.png");
CHEST_PNG_DATA :: #load("../res/objects/chest.png");

INVENTORY_SLOT_BACKGROUND_DATA :: #load("../res/ui/inventory_slot_background.png");
INVENTORY_SLOT_BACKGROUND_SELECTED_DATA :: #load("../res/ui/inventory_slot_background_selected.png");
CHEST_CONTENTS_ICON_BACKGROUND_DATA :: #load("../res/ui/chest_contents_icon_background.png");
PISTOL_ICON_PNG_DATA :: #load("../res/ui/pistol_icon.png");
MED_KIT_ICON_PNG_DATA :: #load("../res/ui/med_kit_icon.png");
HOSTAGE_ICON_PNG_DATA :: #load("../res/ui/hostage_icon.png");

GameData :: struct {
	characterDimensions: Vector2,

	playerWalkAcceleration: f64,
	playerFriction: f64,
	playerRotationSpeed: f64,

	hostageWalkAcceleration: f64,
	hostageFriction: f64,
	hostageFollowMinDistance: f64,
	hostageFollowMaxDistance: f64,
	hostageScareDistance: f64,

	zombieWalkAcceleration: f64,
	zombieFriction: f64,
	zombieAggroDistance: f64,
	zombieMinDamage: f64,
	zombieMaxDamage: f64,
	zombieDamageCooldown: f64,

	medKitHealthBoost: f64,

	pistolShotCooldown: f64,
	pistolShotVelocity: f64,
	pistolShotLifetime: f64,
	pistolMinDamage: f64,
	pistolMaxDamage: f64,
	pistolKnockback: f64,
}

get_game_data :: proc(game: ^Game) -> GameData {
	characterDimensions: Vector2 = { 64, 64 };
	if game.currentTilemap == game.townHallTilemap {
		characterDimensions = { 96, 96 };
	}

	movementScale := OUTSIDE_OUTPUT_TILE_SIZE.x / game.currentOutputTileSize.x;
	
	return {
		characterDimensions = characterDimensions,

		playerWalkAcceleration = 32 * movementScale,
		playerFriction = 0.9,
		playerRotationSpeed = 7,

		hostageWalkAcceleration = 20 * movementScale,
		hostageFriction = 0.9,
		hostageFollowMinDistance = 1.5,
		hostageFollowMaxDistance = 10,
		hostageScareDistance = 10,

		zombieWalkAcceleration = 9.4 * movementScale,
		zombieFriction = 0.9,
		zombieAggroDistance = 15.6,
		zombieMinDamage = 0.1,
		zombieMaxDamage = 0.2,
		zombieDamageCooldown = 0.5,

		medKitHealthBoost = 0.3,

		pistolShotCooldown = 0.4,
		pistolShotVelocity = 25 * movementScale,
		pistolShotLifetime = 1.0,
		pistolMinDamage = 0.2,
		pistolMaxDamage = 0.4,
		pistolKnockback = 0.16 * movementScale,
	};
}
