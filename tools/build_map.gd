extends SceneTree
# [옛 도구] 4단계에서 바위 숲(당시 main.tscn)을 처음 만들 때 쓴 생성기. 지금은 실행하지 말 것
# (바위 숲은 scenes/maps/rock_forest.tscn으로 옮겨져 포탈·슬라임 배치가 추가됨)
const W := 60
const H := 40
enum { GRASS, GRASS2, FLOWER, PATH, WATER, TREE, ROCK, BUSH }

func make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tiles/tiles.png")
	src.texture_region_size = Vector2i(16, 16)
	ts.add_source(src, 0)
	for i in 8:
		src.create_tile(Vector2i(i, 0))
	# 충돌 모양 (타일 중심이 0,0 / 타일 범위는 -8~8)
	var shapes := {
		WATER: PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]),
		TREE: PackedVector2Array([Vector2(-4, 1), Vector2(4, 1), Vector2(4, 8), Vector2(-4, 8)]),
		ROCK: PackedVector2Array([Vector2(-6, -2), Vector2(6, -2), Vector2(6, 6), Vector2(-6, 6)]),
		BUSH: PackedVector2Array([Vector2(-6, -1), Vector2(6, -1), Vector2(6, 6), Vector2(-6, 6)]),
	}
	for id in shapes:
		var data: TileData = src.get_tile_data(Vector2i(id, 0), 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, shapes[id])
	# 앞뒤 가리기(y-sort) 기준점: 나무/바위의 "밑동" 위치
	for id in [TREE, ROCK, BUSH]:
		src.get_tile_data(Vector2i(id, 0), 0).y_sort_origin = 6
	ResourceSaver.save(ts, "res://assets/tiles/tileset.tres")
	return load("res://assets/tiles/tileset.tres")

func _init():
	var ts: TileSet = load("res://assets/tiles/tileset.tres")  # 타일셋은 build_tileset.gd가 만든다
	var rng := RandomNumberGenerator.new(); rng.seed = 2026
	var main := Node2D.new(); main.name = "Main"
	main.set_script(load("res://scripts/main.gd"))
	var ground := TileMapLayer.new(); ground.name = "Ground"; ground.tile_set = ts
	main.add_child(ground); ground.owner = main
	var world := Node2D.new(); world.name = "World"; world.y_sort_enabled = true
	main.add_child(world); world.owner = main
	var obs := TileMapLayer.new(); obs.name = "Obstacles"; obs.tile_set = ts; obs.y_sort_enabled = true
	world.add_child(obs); obs.owner = main

	var path := {}
	var water := {}
	var cx := 28; var cy := 20
	for x in range(2, W - 2):
		for dy in [0, 1]: path[Vector2i(x, cy + dy + int(2 * sin(x * 0.25)))] = true
	for y in range(2, H - 2):
		for dx in [0, 1]: path[Vector2i(cx + dx + int(2 * sin(y * 0.3)), y)] = true
	for y in H:
		for x in W:
			var p := Vector2i(x, y)
			if pow((x - 46) / 6.5, 2) + pow((y - 10) / 4.0, 2) <= 1.0 and not path.has(p):
				water[p] = true
			var t := GRASS
			if path.has(p): t = PATH
			elif water.has(p): t = WATER
			else:
				var r := rng.randf()
				t = FLOWER if r < 0.05 else (GRASS2 if r < 0.25 else GRASS)
			ground.set_cell(p, 0, Vector2i(t, 0))
	var spawn := Vector2i(cx, cy + 1)
	for y in H:
		for x in W:
			var p := Vector2i(x, y)
			if path.has(p) or water.has(p): continue
			var edge: int = mini(mini(x, y), mini(W - 1 - x, H - 1 - y))
			var t := -1
			if edge < 2 or (edge == 2 and rng.randf() < 0.5):
				t = TREE
			elif p.distance_to(spawn) > 5:
				var r := rng.randf()
				if r < 0.06: t = TREE
				elif r < 0.08: t = BUSH
				elif r < 0.095: t = ROCK
			if t >= 0: obs.set_cell(p, 0, Vector2i(t, 0))
	# 작은 숲 두 군데
	for c in [Vector2i(12, 9), Vector2i(14, 31)]:
		for y in range(-3, 4):
			for x in range(-4, 5):
				var p: Vector2i = c + Vector2i(x, y)
				if Vector2(x / 4.5, y / 3.5).length() < 1.0 and not path.has(p) and rng.randf() < 0.75:
					obs.set_cell(p, 0, Vector2i(TREE, 0))

	var player: Node2D = load("res://scenes/player.tscn").instantiate()
	player.position = Vector2(spawn * 16) + Vector2(8, 12)
	world.add_child(player); player.owner = main
	var hud: Node = load("res://scenes/hud.tscn").instantiate()
	main.add_child(hud); hud.owner = main

	var ps := PackedScene.new()
	print("pack ", ps.pack(main))
	print("save ", ResourceSaver.save(ps, "res://scenes/main.tscn"))
	quit()
