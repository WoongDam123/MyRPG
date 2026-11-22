extends SceneTree
# 타일셋(.tres) 생성기: 타일 17종과 충돌 모양
enum { GRASS, GRASS2, FLOWER, PATH, WATER, TREE, ROCK, BUSH, FENCE_H, FLOOR, WALL_TOP, WALL, SOIL, GRAVEL, FENCE_V, CAVE_FLOOR, CAVE_WALL }
func _init():
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tiles/tiles.png")
	src.texture_region_size = Vector2i(16, 16)
	ts.add_source(src, 0)
	for i in 17:
		src.create_tile(Vector2i(i, 0))
	var full := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	var shapes := {
		WATER: full, WALL_TOP: full, WALL: full, CAVE_WALL: full,
		TREE: PackedVector2Array([Vector2(-4, 1), Vector2(4, 1), Vector2(4, 8), Vector2(-4, 8)]),
		ROCK: PackedVector2Array([Vector2(-6, -2), Vector2(6, -2), Vector2(6, 6), Vector2(-6, 6)]),
		BUSH: PackedVector2Array([Vector2(-6, -1), Vector2(6, -1), Vector2(6, 6), Vector2(-6, 6)]),
		FENCE_H: PackedVector2Array([Vector2(-8, -2), Vector2(8, -2), Vector2(8, 6), Vector2(-8, 6)]),
		FENCE_V: PackedVector2Array([Vector2(-3, -8), Vector2(3, -8), Vector2(3, 8), Vector2(-3, 8)]),
	}
	for id in shapes:
		var data: TileData = src.get_tile_data(Vector2i(id, 0), 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, shapes[id])
	for id in [TREE, ROCK, BUSH, FENCE_H, FENCE_V]:
		src.get_tile_data(Vector2i(id, 0), 0).y_sort_origin = 6
	print(ResourceSaver.save(ts, "res://assets/tiles/tileset.tres"))
	quit()
