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
	mapData: [dynamic] [dynamic] i16, // Holds data for each layer
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

	clear(&mapData);

	for layer, i in mainObject["layers"].(json.Array) { 
		append(&mapData, [dynamic] i16 {});
		reserve(&mapData[i], int(dimensions.x * dimensions.y * size_of(mapData[i][0])));
		
		for tile in layer.(json.Object)["data"].(json.Array) {
			value := cast(type_of(mapData[i][0])) tile.(json.Integer);
			if value <= 0 {
				append(&mapData[i], -1);
			} else {
				append(&mapData[i], value - 1);
			}
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

	// assert(i32(dimensions.x) == width && i32(dimensions.y) == height, "Tileset image dimensions do not match.");
	
	success = true;
	return;
}

draw_tilemap :: proc(using tilemap: ^Tilemap, outputTileDimensions: Vector2, offset: Vector2) {
	rect: sdl.Rect = { 0, 0, i32(outputTileDimensions.x), i32(outputTileDimensions.y) };
	subrect: sdl.Rect = { 0, 0, i32(tileset.tileDimensions.x), i32(tileset.tileDimensions.y) };

	for layer in mapData {
		currentRow: i32;
		currentColumn: i32;
		
		for value in layer {
			if value == -1 {
				advance_position(&currentRow, &currentColumn, tilemap);
				continue;
			}

			rect.x = (currentColumn * i32(outputTileDimensions.x)) - i32(offset.x);
			rect.y = (currentRow * i32(outputTileDimensions.y)) - i32(offset.y);
			subrect.x = i32((value % i16(tileset.tilesPerRow)) * i16(tileset.tileDimensions.x));
			subrect.y = i32((value / i16(tileset.tilesPerRow)) * i16(tileset.tileDimensions.y));
			
			// TODO(fkp): Don't draw off the screen
			sdl.RenderCopy(tileset.game.renderer, tileset.texture, &subrect, &rect);
			advance_position(&currentRow, &currentColumn, tilemap);
		}
	}
}

advance_position :: proc(currentRow: ^i32, currentColumn: ^i32, tilemap: ^Tilemap) {
	currentColumn^ += 1;

	if currentColumn^ == i32(tilemap.dimensions.x) {
		currentColumn^ = 0;
		currentRow^ += 1;
	}
}
