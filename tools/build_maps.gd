extends SceneTree
# 맵 생성기: 우리 집, 자갈 마을, 창고, 잡화점, 버려진 광산, 광산 깊은 곳, 대지의 제단
# ⚠️ 다시 실행하면 두 맵 파일을 덮어쓴다. 에디터에서 직접 고친 뒤에는 실행하지 말 것.
enum { GRASS, GRASS2, FLOWER, PATH, WATER, TREE, ROCK, BUSH, FENCE_H, FLOOR, WALL_TOP, WALL, SOIL, GRAVEL, FENCE_V, CAVE_FLOOR, CAVE_WALL }
var TS: TileSet
var rng := RandomNumberGenerator.new()

func _init():
	await process_frame  # 전역(Autoload)이 준비될 때까지 기다린다
	TS = load("res://assets/tiles/tileset.tres")
	rng.seed = 777
	build_house()
	build_village()
	build_barn()
	build_shop()
	build_mine()
	build_mine_boss()
	build_altar()
	quit()

# ---------- 공통 도우미 ----------
func new_map(map_name: String, zoom: float, fx := "outdoor") -> Dictionary:
	var root := Node2D.new(); root.name = "Map"
	root.set_script(load("res://scripts/map.gd"))
	root.map_name = map_name
	root.camera_zoom = zoom
	root.fx_profile = fx
	var ground := TileMapLayer.new(); ground.name = "Ground"; ground.tile_set = TS
	root.add_child(ground); ground.owner = root
	var world := Node2D.new(); world.name = "World"; world.y_sort_enabled = true
	root.add_child(world); world.owner = root
	var obs := TileMapLayer.new(); obs.name = "Obstacles"; obs.tile_set = TS; obs.y_sort_enabled = true
	world.add_child(obs); obs.owner = root
	var spawns := Node2D.new(); spawns.name = "Spawns"
	root.add_child(spawns); spawns.owner = root
	return {"root": root, "ground": ground, "world": world, "obs": obs, "spawns": spawns}

func add(parent: Node, node: Node, owner: Node) -> Node:
	parent.add_child(node); node.owner = owner; return node

## 그림 + 충돌 상자를 가진 물건 (기준점 = 그림의 바닥 가운데)
func prop(m: Dictionary, pname: String, tex: String, pos: Vector2, col: Vector2) -> void:
	var body := StaticBody2D.new(); body.name = pname; body.position = pos
	add(m.world, body, m.root)
	var t: Texture2D = load(tex)
	var sh := Sprite2D.new(); sh.name = "Shadow"
	sh.texture = load("res://assets/effects/shadow_xl.png" if col.x > 40 else ("res://assets/effects/shadow_l.png" if col.x > 18 else "res://assets/effects/shadow_m.png"))
	sh.scale = Vector2(col.x / 52.0, 1.0) if col.x > 40 else Vector2.ONE
	sh.position = Vector2(0, -1)
	add(body, sh, m.root)
	var spr := Sprite2D.new(); spr.name = "Sprite2D"; spr.texture = t
	spr.offset = Vector2(0, -t.get_height() / 2.0)
	add(body, spr, m.root)
	var cs := CollisionShape2D.new(); cs.name = "CollisionShape2D"
	var shape := RectangleShape2D.new(); shape.size = col
	cs.shape = shape; cs.position = Vector2(0, -col.y / 2.0)
	add(body, cs, m.root)

func npc(m: Dictionary, pname: String, display: String, tex: String, pos: Vector2, facing: String, lines: Array[String], story_id := "") -> void:
	var n: Node2D = load("res://scenes/npc.tscn").instantiate()
	n.name = pname; n.position = pos
	n.npc_name = display; n.texture = load(tex); n.facing = facing; n.lines = lines; n.story_id = story_id
	add(m.world, n, m.root)

func portal(m: Dictionary, id: String, pos: Vector2, target_map: String, target_portal: String, label: String, offset: Vector2, lock := {}) -> void:
	var p: Node2D = load("res://scenes/portal.tscn").instantiate()
	p.name = "Portal_" + id; p.position = pos
	p.portal_id = id; p.target_map = target_map; p.target_portal = target_portal
	p.label_text = label; p.spawn_offset = offset
	p.required_flag = lock.get("flag", ""); p.required_item = lock.get("item", ""); p.required_level = lock.get("level", 0)
	if lock.has("text"): p.locked_text = lock.text
	add(m.world, p, m.root)

func enemy(m: Dictionary, scene: String, pos: Vector2, pname := "") -> void:
	var e: Node2D = load(scene).instantiate()
	if pname != "": e.name = pname
	e.position = pos
	add(m.world, e, m.root)

func chest_at(m: Dictionary, pname: String, pos: Vector2, id: String, items: Array[String], quest := "", locked := "", after: Array[String] = []) -> void:
	var c: Node2D = load("res://scenes/chest.tscn").instantiate()
	c.name = pname; c.position = pos
	c.chest_id = id; c.items = items; c.required_quest = quest
	if locked != "": c.locked_text = locked
	c.after_text = after
	add(m.world, c, m.root)

func tint(m: Dictionary, color: Color) -> void:
	var cm := CanvasModulate.new(); cm.name = "Darkness"; cm.color = color
	add(m.root, cm, m.root)

func marker(m: Dictionary, mname: String, pos: Vector2) -> void:
	var mk := Marker2D.new(); mk.name = mname; mk.position = pos
	add(m.spawns, mk, m.root)
	mk.add_to_group("spawn_points", true)

func finish(m: Dictionary, player_pos: Vector2, path: String) -> void:
	load("res://tools/convert_nature.gd").convert_layer(m.obs)  # 나무·바위·덤불 → 2.5D 자연물
	var player: Node2D = load("res://scenes/player.tscn").instantiate()
	player.position = player_pos
	add(m.world, player, m.root)
	var hud: Node = load("res://scenes/hud.tscn").instantiate()
	add(m.root, hud, m.root)
	var ps := PackedScene.new()
	print(path, " pack=", ps.pack(m.root), " save=", ResourceSaver.save(ps, path))

func cell(layer: TileMapLayer, x: int, y: int, t: int) -> void:
	layer.set_cell(Vector2i(x, y), 0, Vector2i(t, 0))

# ---------- 우리 집 (실내, 20 x 12 타일) ----------
func build_house() -> void:
	var m := new_map("우리 집", 2.0, "indoor")
	for y in 12:
		for x in 20:
			var t := FLOOR
			if y == 0 or x == 0 or x == 19 or (y == 11 and not x in [9, 10]):
				t = WALL_TOP
			elif y in [1, 2]:
				t = WALL
			cell(m.ground, x, y, t)
	prop(m, "Bed", "res://assets/props/bed.png", Vector2(40, 76), Vector2(16, 22))
	prop(m, "Table", "res://assets/props/table.png", Vector2(160, 124), Vector2(32, 10))
	prop(m, "Shelf", "res://assets/props/shelf.png", Vector2(232, 70), Vector2(20, 10))
	prop(m, "Stove", "res://assets/props/stove.png", Vector2(288, 70), Vector2(24, 12))
	prop(m, "Plant", "res://assets/props/plant.png", Vector2(24, 172), Vector2(10, 6))
	prop(m, "Plant2", "res://assets/props/plant.png", Vector2(296, 172), Vector2(10, 6))
	npc(m, "Mom", "엄마", "res://assets/npcs/mom.png", Vector2(266, 92), "right", [
		"아빠는 집 앞 밭에 계셔. 문 앞의 빛나는 곳으로 나가면 된단다.",
		"내일이면 성인식이라니… 엄마는 아직도 네가 아기 같은데.",
	], "mom")
	portal(m, "house_door", Vector2(160, 186), "res://scenes/maps/village.tscn", "home_door", "", Vector2(0, -24))
	marker(m, "bed", Vector2(40, 92))
	m.root.enter_event_flag = "intro_done"
	m.root.enter_event_lines = [
		{"name": "엄마", "text": "어머, 이제야 일어났니? 잠꾸러기 같으니라고."},
		{"name": "엄마", "text": "벌써 해가 중천이야. 내일이 네 성인식인 거 잊지 않았지?"},
		{"name": "엄마", "text": "아빠가 밭에서 너를 찾으시더라. 나가서 인사드리렴."},
		{"name": "", "text": "(…이상한 꿈을 꾼 것 같다. 별이 가득한 곳에서, 누군가 나에게 말을 걸던…)"},
	]
	finish(m, Vector2(40, 92), "res://scenes/maps/house.tscn")

# ---------- 자갈 마을 (48 x 30 타일) ----------
func build_village() -> void:
	var m := new_map("자갈 마을", 1.5)
	const W := 48
	const H := 30
	var road := {}
	var reserved := {}
	var mark := func(dict: Dictionary, r: Rect2i):
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				dict[Vector2i(x, y)] = true
	# 길(자갈): 큰길, 광장, 집으로 가는 길
	mark.call(road, Rect2i(8, 15, 40, 2))     # 동쪽 출구까지 큰길
	mark.call(road, Rect2i(18, 11, 11, 9))    # 광장
	mark.call(road, Rect2i(13, 8, 2, 8))      # 우리 집 → 큰길
	mark.call(road, Rect2i(33, 8, 2, 8))      # 잡화점 → 큰길
	mark.call(road, Rect2i(9, 16, 2, 6))      # 이웃집 → 큰길
	mark.call(road, Rect2i(19, 8, 2, 4))      # 창고 → 광장
	# 건물·밭 자리 (나무가 자라지 않게)
	mark.call(reserved, Rect2i(8, 2, 13, 7))  # 우리 집
	mark.call(reserved, Rect2i(28, 2, 13, 7)) # 잡화점
	mark.call(reserved, Rect2i(17, 2, 7, 7))  # 창고
	mark.call(reserved, Rect2i(4, 16, 13, 7)) # 이웃집
	mark.call(reserved, Rect2i(28, 18, 14, 10)) # 밭 + 울타리
	mark.call(reserved, Rect2i(44, 13, 4, 6)) # 동쪽 출구
	for y in H:
		for x in W:
			var p := Vector2i(x, y)
			var t := GRASS
			if road.has(p): t = GRAVEL
			elif Rect2i(30, 20, 10, 6).has_point(p): t = SOIL
			else:
				var r := rng.randf()
				t = FLOWER if r < 0.06 else (GRASS2 if r < 0.25 else GRASS)
			cell(m.ground, x, y, t)
	# 밭 울타리 (위쪽 가운데는 출입구)
	for x in range(29, 41):
		if not x in [34, 35]: cell(m.obs, x, 19, FENCE_H)
		cell(m.obs, x, 26, FENCE_H)
	for y in range(20, 26):
		cell(m.obs, 29, y, FENCE_V)
		cell(m.obs, 40, y, FENCE_V)
	# 테두리 숲 + 드문드문 나무·덤불
	for y in H:
		for x in W:
			var p := Vector2i(x, y)
			if road.has(p) or reserved.has(p) or m.obs.get_cell_source_id(p) != -1: continue
			var edge: int = mini(mini(x, y), mini(W - 1 - x, H - 1 - y))
			if edge < 2 or (edge == 2 and rng.randf() < 0.45):
				cell(m.obs, x, y, TREE)
			elif _far_from(road, p, 2):
				var r := rng.randf()
				if r < 0.05: cell(m.obs, x, y, TREE)
				elif r < 0.08: cell(m.obs, x, y, BUSH)
	# 건물·물건
	prop(m, "HousePlayer", "res://assets/props/house_player.png", Vector2(224, 128), Vector2(64, 30))
	prop(m, "HouseShop", "res://assets/props/house_shop.png", Vector2(544, 128), Vector2(64, 30))
	prop(m, "HouseNeighbor", "res://assets/props/house_neighbor.png", Vector2(160, 352), Vector2(64, 30))
	prop(m, "Barn", "res://assets/props/barn.png", Vector2(320, 128), Vector2(52, 26))
	prop(m, "Well", "res://assets/props/well.png", Vector2(392, 200), Vector2(20, 10))
	# 사람들
	npc(m, "Dad", "아빠", "res://assets/npcs/dad.png", Vector2(560, 360), "down", [
		"오, 우리 집 잠꾸러기 왔구나!",
		"내일이면 너도 어엿한 그라니아의 성인이지. 시간 참 빠르구나.",
		"성인식 전에 몇 가지 부탁할 게 있단다. 준비가 되면 다시 이야기하자꾸나.",
	], "dad")
	npc(m, "Bori", "보리", "res://assets/npcs/neighbor.png", Vector2(424, 216), "left", [
		"안녕! 내일 성인식이지? 부럽다~",
		"나도 빨리 어른이 돼서 바위 숲 너머로 가 보고 싶어.",
		"아 참, 바위 숲엔 슬라임이 나오니까 조심해! 동쪽 큰길 끝의 포탈로 가면 돼.",
	])
	npc(m, "Elder", "촌장", "res://assets/npcs/elder.png", Vector2(344, 200), "down", ["허허."], "elder")
	# 포탈
	portal(m, "home_door", Vector2(224, 138), "res://scenes/maps/house.tscn", "house_door", "우리 집", Vector2(0, 22))
	portal(m, "barn_door", Vector2(320, 138), "res://scenes/maps/barn.tscn", "barn_out", "창고", Vector2(0, 22))
	portal(m, "shop_door", Vector2(544, 138), "res://scenes/maps/shop.tscn", "shop_out", "잡화점", Vector2(0, 22))
	portal(m, "forest_exit", Vector2(744, 256), "res://scenes/maps/rock_forest.tscn", "village_exit", "바위 숲", Vector2(-26, 0),
		{"flag": "adult", "text": "(아직 성인식을 치르지 않아서 마을 밖으로 나갈 수 없다.)"})
	finish(m, Vector2(224, 164), "res://scenes/maps/village.tscn")

# ---------- 창고 (실내, 12 x 8 타일) ----------
func build_barn() -> void:
	var m := new_map("창고", 2.0, "indoor")
	for y in 8:
		for x in 12:
			var t := FLOOR
			if y == 0 or x == 0 or x == 11 or (y == 7 and not x in [5, 6]):
				t = WALL_TOP
			elif y == 1:
				t = WALL
			cell(m.ground, x, y, t)
	for pos in [Vector2(24, 48), Vector2(40, 48), Vector2(24, 64), Vector2(168, 104)]:
		prop(m, "Crate", "res://assets/props/crate.png", pos, Vector2(14, 10))
	prop(m, "Hay", "res://assets/props/hay.png", Vector2(160, 52), Vector2(18, 10))
	prop(m, "Hay2", "res://assets/props/hay.png", Vector2(140, 52), Vector2(18, 10))
	var chest: Node2D = load("res://scenes/chest.tscn").instantiate()
	chest.name = "Chest"; chest.position = Vector2(96, 50)
	chest.chest_id = "dad_gear"
	chest.items = ["wooden_sword", "leather_armor"] as Array[String]
	chest.required_quest = "errand_equip"
	chest.locked_text = "(아빠의 물건이 든 상자다. 허락 없이 열면 혼날 것 같다.)"
	chest.after_text = ["(오른쪽 위의 가방 버튼을 눌러 장착해 보자.)"] as Array[String]
	add(m.world, chest, m.root)
	portal(m, "barn_out", Vector2(96, 122), "res://scenes/maps/village.tscn", "barn_door", "", Vector2(0, -22))
	finish(m, Vector2(96, 100), "res://scenes/maps/barn.tscn")


# ---------- 잡화점 (실내, 14 x 9 타일) ----------
func build_shop() -> void:
	var m := new_map("잡화점", 2.0, "indoor")
	for y in 9:
		for x in 14:
			var t := FLOOR
			if y == 0 or x == 0 or x == 13 or (y == 8 and not x in [6, 7]):
				t = WALL_TOP
			elif y == 1:
				t = WALL
			cell(m.ground, x, y, t)
	prop(m, "Counter", "res://assets/props/counter.png", Vector2(112, 78), Vector2(48, 10))
	prop(m, "Shelf", "res://assets/props/shelf.png", Vector2(36, 58), Vector2(20, 10))
	prop(m, "Shelf2", "res://assets/props/shelf.png", Vector2(188, 58), Vector2(20, 10))
	prop(m, "Crate", "res://assets/props/crate.png", Vector2(30, 120), Vector2(14, 10))
	prop(m, "Plant", "res://assets/props/plant.png", Vector2(196, 122), Vector2(10, 6))
	npc(m, "Shopkeeper", "잡화점 주인", "res://assets/npcs/shopkeeper.png", Vector2(112, 56), "down", ["어서 오게!"], "shopkeeper")
	portal(m, "shop_out", Vector2(112, 136), "res://scenes/maps/village.tscn", "shop_door", "", Vector2(0, -24))
	finish(m, Vector2(112, 110), "res://scenes/maps/shop.tscn")

# ---------- 버려진 광산 (40 x 26 타일, 방 6개를 통로로 연결) ----------
func build_mine() -> void:
	var m := new_map("버려진 광산", 1.75, "cave")
	var open := {}
	var carve := func(r: Rect2i):
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				open[Vector2i(x, y)] = true
	for r in [Rect2i(2, 17, 9, 7), Rect2i(14, 16, 9, 8), Rect2i(3, 3, 8, 7), Rect2i(14, 3, 11, 8), Rect2i(28, 3, 10, 10), Rect2i(28, 16, 10, 8),
			Rect2i(10, 20, 5, 2), Rect2i(17, 10, 2, 7), Rect2i(10, 6, 5, 2), Rect2i(24, 6, 5, 2), Rect2i(22, 19, 7, 2), Rect2i(32, 12, 2, 5)]:
		carve.call(r)
	for y in 26:
		for x in 40:
			cell(m.ground, x, y, CAVE_FLOOR if open.has(Vector2i(x, y)) else CAVE_WALL)
	for pos in [Vector2(56, 300), Vector2(150, 300), Vector2(400, 60)]:
		prop(m, "Crate", "res://assets/props/crate.png", pos, Vector2(14, 10))
	chest_at(m, "KeyChest", Vector2(104, 84), "mine_key", ["mine_key"] as Array[String], "main_mine", "(굳게 닫혀 있다.)",
		["(광산 깊은 곳의 문을 여는 열쇠인 것 같다.)"] as Array[String])
	chest_at(m, "PotionChest", Vector2(568, 364), "mine_potions", ["potion", "potion"] as Array[String])
	var rs := "res://scenes/enemies/rock_slime.tscn"
	var hs := "res://scenes/enemies/hard_slime.tscn"
	for p in [Vector2(260, 300), Vector2(320, 340), Vector2(280, 100), Vector2(360, 140), Vector2(120, 130), Vector2(500, 300), Vector2(560, 290)]:
		enemy(m, rs, p)
	for p in [Vector2(500, 100), Vector2(560, 160), Vector2(520, 360), Vector2(330, 80)]:
		enemy(m, hs, p)
	portal(m, "mine_out", Vector2(40, 336), "res://scenes/maps/rock_forest.tscn", "mine_entrance", "바위 숲", Vector2(26, 0))
	portal(m, "boss_door", Vector2(568, 58), "res://scenes/maps/mine_boss.tscn", "boss_out", "깊은 곳", Vector2(0, 26),
		{"item": "mine_key", "level": 5, "text": "(녹슨 자물쇠로 잠긴 문이다. 열쇠가 필요하다.)"})
	tint(m, Color(0.42, 0.4, 0.5))
	finish(m, Vector2(70, 336), "res://scenes/maps/mine.tscn")

# ---------- 광산 깊은 곳 (보스 방, 22 x 16 타일) ----------
func build_mine_boss() -> void:
	var m := new_map("광산 깊은 곳", 1.75, "cave")
	for y in 16:
		for x in 22:
			var wall := y < 2 or x < 2 or x > 19 or y > 14
			if (x in [2, 19] and y in [2, 3, 13, 14]) or (y == 2 and x in [3, 18]): wall = true
			cell(m.ground, x, y, CAVE_WALL if wall else CAVE_FLOOR)
	enemy(m, "res://scenes/enemies/king_slime.tscn", Vector2(176, 100), "KingSlime")
	portal(m, "boss_out", Vector2(176, 226), "res://scenes/maps/mine.tscn", "boss_door", "광산", Vector2(0, -26))
	tint(m, Color(0.5, 0.46, 0.56))
	finish(m, Vector2(176, 200), "res://scenes/maps/mine_boss.tscn")

# ---------- 대지의 제단 (24 x 18 타일) ----------
func build_altar() -> void:
	var m := new_map("대지의 제단", 1.5)
	for y in 18:
		for x in 24:
			var t := GRASS2 if rng.randf() < 0.3 else GRASS
			if Vector2(x - 11.5, (y - 8.5) * 1.3).length() < 7.5: t = GRAVEL
			if x in [11, 12] and y >= 14: t = GRAVEL
			cell(m.ground, x, y, t)
			var edge: int = mini(mini(x, y), mini(23 - x, 17 - y))
			if (edge < 2 and not (x in [11, 12] and y > 9)) or (edge == 2 and rng.randf() < 0.4 and not x in [11, 12]):
				cell(m.obs, x, y, TREE)
	for p in [Vector2(96, 72), Vector2(288, 72), Vector2(96, 216), Vector2(288, 216)]:
		cell(m.obs, int(p.x / 16), int(p.y / 16), ROCK)
	prop(m, "Altar", "res://assets/props/altar.png", Vector2(192, 92), Vector2(28, 12))
	npc(m, "Spirit", "대지의 정령", "res://assets/npcs/spirit.png", Vector2(224, 100), "down", ["……"], "spirit")
	var trial := Node2D.new(); trial.name = "Trial"
	trial.set_script(load("res://scripts/trial.gd"))
	add(m.world, trial, m.root)
	for i in 6:
		var mk := Marker2D.new(); mk.name = "Spawn%d" % i
		mk.position = Vector2(192, 148) + Vector2.RIGHT.rotated(i * TAU / 6.0) * Vector2(90, 55)
		add(trial, mk, m.root)
	portal(m, "altar_out", Vector2(192, 262), "res://scenes/maps/rock_forest.tscn", "altar_path", "바위 숲", Vector2(0, -26))
	finish(m, Vector2(192, 230), "res://scenes/maps/altar.tscn")


func _far_from(dict: Dictionary, p: Vector2i, dist: int) -> bool:
	for dy in range(-dist, dist + 1):
		for dx in range(-dist, dist + 1):
			if dict.has(p + Vector2i(dx, dy)): return false
	return true
