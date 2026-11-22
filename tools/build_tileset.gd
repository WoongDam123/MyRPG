extends SceneTree
# 타일셋(.tres) 생성기
#  source 0: 16x16 기본 타일 17종 (바닥·물·벽·울타리 등)
#  source 1: 2.5D 자연물 (큰 나무 2종 32x48, 바위, 덤불) — 앞뒤 가리기(y-sort)와 충돌 포함
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

	# ---- 2.5D 자연물 ----
	var nat := TileSetAtlasSource.new()
	nat.texture = load("res://assets/nature/nature.png")
	nat.texture_region_size = Vector2i(16, 16)
	ts.add_source(nat, 1)
	for spec in [[Vector2i(0, 0), Vector2i(2, 3)], [Vector2i(2, 0), Vector2i(2, 3)], [Vector2i(4, 2), Vector2i(1, 1)], [Vector2i(5, 2), Vector2i(1, 1)]]:
		nat.create_tile(spec[0], spec[1])
	var trunk := PackedVector2Array([Vector2(-4, 1), Vector2(4, 1), Vector2(4, 8), Vector2(-4, 8)])
	for c in [Vector2i(0, 0), Vector2i(2, 0)]:
		var td: TileData = nat.get_tile_data(c, 0)
		td.texture_origin = Vector2i(0, 16)  # 큰 그림의 밑동이 칸 아래쪽에 오도록
		td.y_sort_origin = 6
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, trunk)
	var rock_td: TileData = nat.get_tile_data(Vector2i(4, 2), 0)
	rock_td.y_sort_origin = 5
	rock_td.add_collision_polygon(0)
	rock_td.set_collision_polygon_points(0, 0, shapes[ROCK])
	var bush_td: TileData = nat.get_tile_data(Vector2i(5, 2), 0)
	bush_td.y_sort_origin = 5
	bush_td.add_collision_polygon(0)
	bush_td.set_collision_polygon_points(0, 0, shapes[BUSH])
	print(ResourceSaver.save(ts, "res://assets/tiles/tileset.tres"))
	quit()
