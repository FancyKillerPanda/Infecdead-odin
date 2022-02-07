package main;

import "core:encoding/json"
import "core:os"
import core_filepath "core:path/filepath"
import "core:strings"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

Tilemap :: struct {
	dimensions: Vector2,
	tileset: Tileset,
	mapData: [dynamic] i16,
};

Tileset :: struct {
	game: ^Game,
	texture: ^sdl.Texture,

	dimensions: Vector2,
	tileDimensions: Vector2,
	tilesPerRow: u32,
}

parse_tilemap :: proc(game: ^Game, filepath: string) -> (tilemap: Tilemap, success: bool) {
	using tilemap;

	data, readSuccess := os.read_entire_file(filepath);
	if !readSuccess {
		printf("Error: Failed to read tilemap file '%s'\n", filepath);
		return;
	}

	document, error := json.parse(data, json.DEFAULT_SPECIFICATION, true);
	if error != .None {
		printf("Error: Failed to parse tilemap JSON. Reason: {}\n", error);
		return;
	}

	mainObject := document.(json.Object);
	
	assert(mainObject["infinite"].(json.Boolean) == false, "Tilemap parser does not currently support infinite maps.");
	assert(mainObject["orientation"].(json.String) == "orthogonal", "Tilemap parser currently only supports orthogonal maps.");
	assert(mainObject["tilewidth"].(json.Integer) == 16, "Tilemap parser currently only supports 16x16 tiles.");
	assert(mainObject["tileheight"].(json.Integer) == 16, "Tilemap parser currently only supports 16x16 tiles.");
	assert(len(mainObject["tilesets"].(json.Array)) == 1, "Tilemap parser currently only supports one tileset per map.");
	
	dimensions.x = f64(mainObject["width"].(json.Integer));
	dimensions.y = f64(mainObject["height"].(json.Integer));

	tilesetFilepath := core_filepath.join(core_filepath.dir(filepath), mainObject["tilesets"].(json.Array)[0].(json.Object)["source"].(json.String));
	tileset = parse_tileset(game, tilesetFilepath) or_return;

	reserve(&mapData, int(dimensions.x * dimensions.y * size_of(mapData[0])));
	clear(&mapData);
	for i in mainObject["layers"].(json.Array)[0].(json.Object)["data"].(json.Array) {
		value := cast(type_of(mapData[0])) i.(json.Integer);
		if value <= 0 {
			append(&mapData, -1);
		} else {
			append(&mapData, value - 1);
		}
	}
	
	success = true;
	return;
}

parse_tileset :: proc(game_: ^Game, filepath: string) -> (tileset: Tileset, success: bool) {
	using tileset;

	data, readSuccess := os.read_entire_file(filepath);
	if !readSuccess {
		printf("Error: Failed to read tileset file '%s'\n", filepath);
		return;
	}

	document, error := json.parse(data, json.DEFAULT_SPECIFICATION, true);
	if error != .None {
		printf("Error: Failed to parse tileset JSON. Reason: {}\n", error);
		return;
	}

	mainObject := document.(json.Object);

	assert(mainObject["tilewidth"].(json.Integer) == 16, "Tileset parser currently only supports 16x16 tiles.");
	assert(mainObject["tileheight"].(json.Integer) == 16, "Tileset parser currently only supports 16x16 tiles.");
	assert(mainObject["margin"].(json.Integer) == 0, "Tileset parser currently only supports having 0 margin.");
	assert(mainObject["spacing"].(json.Integer) == 0, "Tileset parser currently only supports having 0 spacing.");

	game = game_;
	dimensions.x = f64(mainObject["imagewidth"].(json.Integer));
	dimensions.y = f64(mainObject["imageheight"].(json.Integer));
	tileDimensions.x = f64(mainObject["tilewidth"].(json.Integer));
	tileDimensions.y = f64(mainObject["tileheight"].(json.Integer));
	tilesPerRow = u32(mainObject["columns"].(json.Integer));

	imageFilepath := core_filepath.join(core_filepath.dir(filepath), mainObject["image"].(json.String));
	texture = img.LoadTexture(game.renderer, strings.clone_to_cstring(imageFilepath, context.temp_allocator));
	if texture == nil {
		printf("Error: Failed to load tileset image. Reason: '%s'\n", sdl.GetError());
		return;
	}

	width, height: i32;
	if sdl.QueryTexture(texture, nil, nil, &width, &height) < 0 {
		printf("Error: Tileset image is invalid. Reason: '%s'\n", sdl.GetError());
		return;
	}

	assert(i32(dimensions.x) == width && i32(dimensions.y) == height, "Tileset image dimensions do not match.");
	
	success = true;
	return;
}

draw_tilemap :: proc(using tilemap: ^Tilemap, outputTileDimensions: Vector2, offset: Vector2) {
	rect: sdl.Rect = { 0, 0, i32(outputTileDimensions.x), i32(outputTileDimensions.y) };
	subrect: sdl.Rect = { 0, 0, i32(tileset.tileDimensions.x), i32(tileset.tileDimensions.y) };

	currentRow: i32;
	currentColumn: i32;
	
	for value in mapData {
		if value == -1 {
			continue;
		}

		rect.x = (currentColumn * i32(outputTileDimensions.x)) - i32(offset.x);
		rect.y = (currentRow * i32(outputTileDimensions.y)) - i32(offset.y);
		subrect.x = i32((value % i16(tileset.tilesPerRow)) * i16(tileset.tileDimensions.x));
		subrect.y = i32((value / i16(tileset.tilesPerRow)) * i16(tileset.tileDimensions.y));
		
		// TODO(fkp): Don't draw off the screen
		sdl.RenderCopy(tileset.game.renderer, tileset.texture, &subrect, &rect);

		currentColumn += 1;
		if currentColumn == i32(tilemap.dimensions.x) {
			currentColumn = 0;
			currentRow += 1;
		}
	}
}
