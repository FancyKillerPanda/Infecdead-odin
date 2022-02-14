package main;

import "core:encoding/json"
import "core:fmt"
import "core:os"
import core_filepath "core:path/filepath"
import "core:strings"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

TILEMAP_TILE_SIZE: Vector2 : { 16, 16 };

Tilemap :: struct {
	game: ^Game,
	
	numberOfTiles: Vector2,
	tilesetTexture: ^sdl.Texture,
	tilesetTilesPerRow: u32,

	 // Holds data for each layer
	renderDataFirstPass: [dynamic] [dynamic] i16,
	renderDataSecondPass: [dynamic] [dynamic] i16,
	
	objects: [dynamic] sdl.Rect,
	spawnPoints: [dynamic] SpawnPoint,
	hostageCollectionRect: sdl.Rect,

	// Caches the rendered output
	texturesAreDirty: bool,
	textureFirstPass: ^sdl.Texture,
	textureSecondPass: ^sdl.Texture,
};

SpawnPoint :: struct {
	entityType: EntityType,
	worldPosition: Vector2,
	properties: map[string] string,
}

EntityType :: enum {
	Player,
	Zombie,
	Hostage,
	Chest,
}

parse_tilemap :: proc(game_: ^Game) -> (tilemap: Tilemap, success: bool) {
	using tilemap;
	game = game_;

	document, error := json.parse(MAP_OUTSIDE_DATA, json.DEFAULT_SPECIFICATION, true);
	if error != .None {
		printf("Error: Failed to parse tilemap JSON. Reason: {}\n", error);
		return;
	}

	mainObject := document.(json.Object);
	
	assert(mainObject["infinite"].(json.Boolean) == false, "Tilemap parser does not currently support infinite maps.");
	assert(mainObject["orientation"].(json.String) == "orthogonal", "Tilemap parser currently only supports orthogonal maps.");
	assert(mainObject["tilewidth"].(json.Integer) == i64(TILEMAP_TILE_SIZE.x), "Tilemap parser currently only supports 16x16 tiles.");
	assert(mainObject["tileheight"].(json.Integer) == i64(TILEMAP_TILE_SIZE.y), "Tilemap parser currently only supports 16x16 tiles.");
	assert(len(mainObject["tilesets"].(json.Array)) == 1, "Tilemap parser currently only supports one tileset per map.");
	
	numberOfTiles.x = f64(mainObject["width"].(json.Integer));
	numberOfTiles.y = f64(mainObject["height"].(json.Integer));

	parse_tileset(&tilemap, MAP_TILESET_DATA, MAP_TILESET_IMAGE_DATA) or_return;

	clear(&renderDataFirstPass);
	clear(&renderDataSecondPass);

	for layer, i in mainObject["layers"].(json.Array) { 
		switch layer.(json.Object)["type"].(json.String) {
			case "tilelayer":
				add_tile_layer(&tilemap, layer.(json.Object));

			case "objectgroup":
				switch layer.(json.Object)["name"].(json.String) {
					case "Collisions":
						add_collisions_layer(&tilemap, layer.(json.Object));

					case "Spawn Points":
						add_spawn_points(&tilemap, layer.(json.Object));
				}
		}
	}

	texturesAreDirty = true;
	textureFirstPass = sdl.CreateTexture(game.renderer, u32(sdl.PixelFormatEnum.RGBA8888), sdl.TextureAccess.TARGET,
										 i32(numberOfTiles.x * TILEMAP_TILE_SIZE.x), i32(numberOfTiles.y * TILEMAP_TILE_SIZE.y));
	textureSecondPass = sdl.CreateTexture(game.renderer, u32(sdl.PixelFormatEnum.RGBA8888), sdl.TextureAccess.TARGET,
										  i32(numberOfTiles.x * TILEMAP_TILE_SIZE.x), i32(numberOfTiles.y * TILEMAP_TILE_SIZE.y));

	if textureFirstPass == nil || textureSecondPass == nil {
		printf("Error: Failed to create tilemap cache textures. Reason: {}\n", sdl.GetError());
		return;
	}

	sdl.SetTextureBlendMode(textureFirstPass, sdl.BlendMode.BLEND);
	sdl.SetTextureBlendMode(textureSecondPass, sdl.BlendMode.BLEND);

	success = true;
	return;
}

add_tile_layer :: proc(using tilemap: ^Tilemap, layer: json.Object) {
	// Determines whether this layer should be drawn before or after characters and such
	pass := &renderDataFirstPass;
	if layer["properties"] != nil {
		properties := layer["properties"].(json.Array);

		for property in properties {
			if property.(json.Object)["name"].(json.String) == "renderedAbove" && property.(json.Object)["value"].(json.Boolean) == true {
				pass = &renderDataSecondPass;
			}
		}
	}
	
	append(pass, [dynamic] i16 {});
	// reserve(&pass[len(pass^) - 1], int(dimensions.x * dimensions.y));
	numberToSkip: i16;
	
	for tile in layer["data"].(json.Array) {
		value := cast(i16) tile.(json.Integer);
		if value <= 0 {
			// append(&pass[len(pass^) - 1], -1);
			numberToSkip += 1;
		} else {
			if numberToSkip > 0 {
				append(&pass[len(pass^) - 1], -numberToSkip);
				numberToSkip = 0;
			}
			
			append(&pass[len(pass^) - 1], value - 1);
		}
	}

	if numberToSkip > 0 {
		append(&pass[len(pass^) - 1], -numberToSkip);
	}
}

add_collisions_layer :: proc(using tilemap: ^Tilemap, layer: json.Object) {
	objectValues := layer["objects"].(json.Array);
	reserve(&objects, len(objects) + len(objectValues));
	
	for value in objectValues {
		objectRect: sdl.Rect = {
			cast(i32) value.(json.Object)["x"].(json.Integer),
			cast(i32) value.(json.Object)["y"].(json.Integer),
			cast(i32) value.(json.Object)["width"].(json.Integer),
			cast(i32) value.(json.Object)["height"].(json.Integer),
		};
		
		if value.(json.Object)["name"].(json.String) == "Hostage Collection" {
			hostageCollectionRect = objectRect;
		} else {
			append(&objects, objectRect);
		}
	}
}

add_spawn_points :: proc(using tilemap: ^Tilemap, layer: json.Object) {
	objectValues := layer["objects"].(json.Array);
	reserve(&spawnPoints, len(spawnPoints) + len(objectValues));

	for value in objectValues {
		worldPosition := Vector2 { f64(value.(json.Object)["x"].(json.Integer)), f64(value.(json.Object)["y"].(json.Integer)) } + (TILEMAP_TILE_SIZE / 2);
		entityType: EntityType;
		properties: map[string] string;
		
		switch value.(json.Object)["name"].(json.String) {
			case "Player":entityType = .Player;
			case "Zombie": entityType = .Zombie;
			case "Hostage": entityType = .Hostage;
			
			case "Chest":
				entityType = .Chest;
				
				for property in value.(json.Object)["properties"].(json.Array) {
					for key in property.(json.Object) {
						properties[key] = property.(json.Object)[key].(json.String);
					}
				}
		}
		
		append(&spawnPoints, SpawnPoint { entityType, worldPosition, properties });
	}
}

parse_tileset :: proc(tilemap: ^Tilemap, data: [] u8, imageData: [] u8) -> (success: bool) {
	using tilemap;

	document, error := json.parse(data, json.DEFAULT_SPECIFICATION, true);
	if error != .None {
		printf("Error: Failed to parse tileset JSON. Reason: {}\n", error);
		return;
	}

	mainObject := document.(json.Object);

	assert(mainObject["tilewidth"].(json.Integer) == i64(TILEMAP_TILE_SIZE.x), "Tileset parser currently only supports 16x16 tiles.");
	assert(mainObject["tileheight"].(json.Integer) == i64(TILEMAP_TILE_SIZE.y), "Tileset parser currently only supports 16x16 tiles.");
	assert(mainObject["margin"].(json.Integer) == 0, "Tileset parser currently only supports having 0 margin.");
	assert(mainObject["spacing"].(json.Integer) == 0, "Tileset parser currently only supports having 0 spacing.");

	tilesetTilesPerRow = u32(mainObject["columns"].(json.Integer));

	imageDataMemory := sdl.RWFromConstMem(raw_data(imageData), i32(len(imageData)));
	if imageDataMemory == nil {
		printf("Error: Failed to read tileset image data. Reason: {}\n", sdl.GetError());
		return;
	}
	
	tilesetTexture = img.LoadTexture_RW(game.renderer, imageDataMemory, true);
	if tilesetTexture == nil {
		printf("Error: Failed to load tileset image. Reason: '%s'\n", sdl.GetError());
		return;
	}

	success = true;
	return;
}

draw_tilemap_first_pass :: proc(using tilemap: ^Tilemap, tileSize: Vector2, viewOffset: Vector2) {
	draw_tilemap(tilemap, 0, 0, tileSize, viewOffset, false);
}

draw_tilemap_second_pass :: proc(using tilemap: ^Tilemap, tileSize: Vector2, viewOffset: Vector2) {
	draw_tilemap(tilemap, 1, 0, tileSize, viewOffset, false);
}

draw_minimap :: proc(using tilemap: ^Tilemap) {
	minimapPosition: Vector2 = { game.screenDimensions.x * 89 / 100, game.screenDimensions.y * 1 / 100 };
	minimapRect := create_sdl_rect(minimapPosition, MINIMAP_TILE_SIZE * numberOfTiles);

	draw_tilemap(tilemap, 0, minimapPosition, MINIMAP_TILE_SIZE, 0, true);
	draw_tilemap(tilemap, 1, minimapPosition, MINIMAP_TILE_SIZE, 0, true);
	
	draw_player_on_minimap(&game.player, minimapPosition);
	
	sdl.SetRenderDrawColor(game.renderer, 0, 0, 0, 255);
	sdl.RenderDrawRect(game.renderer, &minimapRect);
}

draw_tilemap :: proc(using tilemap: ^Tilemap, pass: u32, outputPosition: Vector2, outputTileDimensions: Vector2, viewOffset: Vector2, renderFullMap: bool) {
	if texturesAreDirty {
		draw_tilemap_to_textures(tilemap);
	}
	
	textures: [2] ^sdl.Texture = { textureFirstPass, textureSecondPass };
	textureRect: sdl.Rect;
	outputRect: sdl.Rect;
	
	if renderFullMap {
		textureRect = create_sdl_rect(0, numberOfTiles * TILEMAP_TILE_SIZE);
		outputRect = create_sdl_rect(outputPosition, numberOfTiles * outputTileDimensions); 
	} else {
		textureRect = create_sdl_rect(viewOffset, (game.screenDimensions / outputTileDimensions) * TILEMAP_TILE_SIZE);
		outputRect = create_sdl_rect(outputPosition, game.screenDimensions); // TODO(fkp): This is probably wrong
	}

	sdl.RenderCopy(game.renderer, textures[pass], &textureRect, &outputRect);
}

draw_tilemap_to_textures :: proc(using tilemap: ^Tilemap) {
	passes: [2] [dynamic] [dynamic] i16 = { renderDataFirstPass, renderDataSecondPass };
	textures: [2] ^sdl.Texture = { textureFirstPass, textureSecondPass };

	rect := create_sdl_rect(0, TILEMAP_TILE_SIZE);
	subrect := create_sdl_rect(0, TILEMAP_TILE_SIZE);

	for pass, i in passes {
		sdl.SetRenderTarget(game.renderer, textures[i]);
		
		for layer in pass {
			currentRow: i32;
			currentColumn: i32;
			
			for value in layer {
				rect.x = currentColumn * i32(TILEMAP_TILE_SIZE.x);
				rect.y = currentRow * i32(TILEMAP_TILE_SIZE.y);
				
				if value < 0 {
					advance_position(&currentRow, &currentColumn, tilemap, -value);
					continue;
				}
	
				subrect.x = i32((value % i16(tilesetTilesPerRow)) * i16(TILEMAP_TILE_SIZE.x));
				subrect.y = i32((value / i16(tilesetTilesPerRow)) * i16(TILEMAP_TILE_SIZE.y));
				
				sdl.RenderCopy(game.renderer, tilesetTexture, &subrect, &rect);
				advance_position(&currentRow, &currentColumn, tilemap);
			}
	
		}
	}

	texturesAreDirty = false;
	sdl.SetRenderTarget(game.renderer, nil);
}

advance_position :: proc(currentRow: ^i32, currentColumn: ^i32, tilemap: ^Tilemap, amount: i16 = 1) {
	currentColumn^ += i32(amount);

	for currentColumn^ >= i32(tilemap.numberOfTiles.x) {
		currentColumn^ -= i32(tilemap.numberOfTiles.x);
		currentRow^ += 1;
	}
}

// This function will spawn zombies and other characters, but only set the location
// of the player (it assumes the player has already been initialised).
spawn_entities :: proc(using tilemap: ^Tilemap) {
	clear(&game.zombies);
	clear(&game.hostages);
	
	for spawnPoint in spawnPoints {
		switch spawnPoint.entityType {
			case .Chest:
				// Do nothing
			
			case .Player:
				game.player.worldPosition = spawnPoint.worldPosition;

			case .Zombie:
				append(&game.zombies, create_zombie(game, spawnPoint.worldPosition));
				
			case .Hostage:
				append(&game.hostages, create_hostage(game, spawnPoint.worldPosition));
		}
	}
}

spawn_chests :: proc(using tilemap: ^Tilemap) {
	clear(&game.chests);
	
	for spawnPoint in spawnPoints {
		#partial switch spawnPoint.entityType {
			case .Chest:
				contents: InventoryItem;
				if spawnPoint.properties["name"] == "contents" {
					switch spawnPoint.properties["value"] {
						case "pistol":
							contents.type = .Pistol;
							contents.data = PistolData { bulletsLeft = 16, maxBullets = 16, };

							text := fmt.tprintf("{}/{}", contents.data.(PistolData).bulletsLeft, contents.data.(PistolData).maxBullets);
							contents.currentText = create_text(game.renderer, game.menu.textFont, strings.clone_to_cstring(text));
						
						case "med_kit":
							contents.type = .MedKit;

						case:
							assert(false, "Tilemap chest has unknown item.");
					}
				}
			
				append(&game.chests, Chest { isOpen = false, contents = contents, worldPosition = spawnPoint.worldPosition });
		}
	}
}
