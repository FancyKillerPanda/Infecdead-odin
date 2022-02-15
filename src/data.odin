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
	return {
		characterDimensions = { 64, 64 },

		playerWalkAcceleration = 32,
		playerFriction = 0.9,
		playerRotationSpeed = 7,

		hostageWalkAcceleration = 20,
		hostageFriction = 0.9,
		hostageFollowMinDistance = 1.5,
		hostageFollowMaxDistance = 10,
		hostageScareDistance = 10,

		zombieWalkAcceleration = 9.4,
		zombieFriction = 0.9,
		zombieAggroDistance = 15.6,
		zombieMinDamage = 0.1,
		zombieMaxDamage = 0.2,
		zombieDamageCooldown = 0.5,

		medKitHealthBoost = 0.3,

		pistolShotCooldown = 0.4,
		pistolShotVelocity = 25,
		pistolShotLifetime = 1.0,
		pistolMinDamage = 0.2,
		pistolMaxDamage = 0.4,
		pistolKnockback = 0.16,
	};
}

/*
CHARACTER_DIMENSIONS: Vector2 : { 64, 64 };

PLAYER_WALK_ACC :: 32;
PLAYER_FRICTION :: 0.9;
PLAYER_ROTATION_SPEED :: 7;

HOSTAGE_WALK_ACC :: 20;
HOSTAGE_FRICTION :: 0.9;
HOSTAGE_FOLLOW_MIN_DISTANCE :: 1.5;
HOSTAGE_FOLLOW_MAX_DISTANCE :: 10;
HOSTAGE_SCARE_DISTANCE :: 10;

ZOMBIE_WALK_ACC :: 9.4;
ZOMBIE_FRICTION :: 0.9;
ZOMBIE_AGGRO_DISTANCE :: 15.6;
ZOMBIE_MIN_DAMAGE :: 0.1;
ZOMBIE_MAX_DAMAGE :: 0.2;
ZOMBIE_DAMAGE_COOLDOWN :: 0.5;

MED_KIT_HEALTH_BOOST :: 0.3;

PISTOL_SHOT_COOLDOWN :: 0.4;
PISTOL_SHOT_VELOCITY :: 25;
PISTOL_SHOT_LIFETIME :: 1.0;
PISTOL_MIN_DAMAGE :: 0.2;
PISTOL_MAX_DAMAGE :: 0.4;
PISTOL_KNOCKBACK :: 0.16;
*/
