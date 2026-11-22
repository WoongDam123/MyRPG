extends SceneTree
# 맵의 옛 나무·바위·덤불 타일(source 0)을 2.5D 자연물(source 1)로 바꾼다.
const MAPS := ["house", "village", "barn", "shop", "rock_forest", "mine", "mine_boss", "altar"]

static func convert_layer(obs: TileMapLayer) -> int:
	var n := 0
	for c in obs.get_used_cells():
		if obs.get_cell_source_id(c) != 0:
			continue
		var a := obs.get_cell_atlas_coords(c)
		if a == Vector2i(5, 0):
			var pick := Vector2i(0, 0) if (c.x * 7 + c.y * 13) % 3 != 0 else Vector2i(2, 0)
			obs.set_cell(c, 1, pick)
			n += 1
		elif a == Vector2i(6, 0):
			obs.set_cell(c, 1, Vector2i(4, 2)); n += 1
		elif a == Vector2i(7, 0):
			obs.set_cell(c, 1, Vector2i(5, 2)); n += 1
	return n

func _init():
	await process_frame
	for m in MAPS:
		var path := "res://scenes/maps/%s.tscn" % m
		var root: Node = load(path).instantiate()
		var obs: TileMapLayer = root.get_node("World/Obstacles")
		var n := convert_layer(obs)
		if n > 0:
			var ps := PackedScene.new()
			ps.pack(root)
			ResourceSaver.save(ps, path)
		print(m, ": ", n, " converted")
		root.free()
	quit()
