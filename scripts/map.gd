extends Node2D
## 모든 맵이 함께 쓰는 공통 스크립트.
## - 포탈을 타고 들어왔다면 그 포탈 앞에 플레이어를 놓는다
## - 카메라가 맵 밖을 비추지 않게 한다 (맵이 화면보다 작으면 가운데 정렬)
## - 플레이어 체력·코인을 HUD에 연결한다
## - 처음 들어왔을 때 한 번만 나오는 대사(이벤트)를 재생한다

@export var map_name: String = ""  ## 들어올 때 화면 위에 잠깐 표시되는 이름
@export var camera_zoom: float = 1.5  ## 실내는 2로 하면 가까이 보인다
@export_enum("outdoor", "indoor", "cave", "off") var fx_profile: String = "outdoor"  ## 화면 효과 분위기
@export var enter_event_flag: String = ""  ## 이 이름의 기록이 없을 때만 아래 대사를 재생
@export var enter_event_lines: Array = []  ## [{"name": "엄마", "text": "..."}, ...]

@onready var ground: TileMapLayer = $Ground
@onready var player: CharacterBody2D = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var hud: CanvasLayer = $HUD

var map_id: String = ""  ## 맵 파일 이름 (예: "village")
var _astar: AStarGrid2D  ## 자동 이동용 길찾기 격자 (처음 필요할 때 만든다)
var _ready_frame: int = 0


func _ready() -> void:
	add_to_group("map")
	_ready_frame = Engine.get_physics_frames()
	map_id = scene_file_path.get_file().get_basename()
	_place_player()
	PostFX.apply(fx_profile)
	player.get_node("Light").enabled = fx_profile == "cave" and GameState.fx_enabled  # 동굴에서는 용사 주변만 밝게
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	_update_camera_limits()
	get_viewport().size_changed.connect(_update_camera_limits)
	camera.reset_smoothing()

	player.health_changed.connect(hud.set_health)
	player.coins_changed.connect(hud.set_coins)
	hud.set_health(player.hp, player.max_hp)
	hud.set_coins(player.coins)

	if map_name != "":
		hud.show_map_name(map_name)
	if enter_event_flag != "" and not GameState.flags.get(enter_event_flag, false):
		_play_enter_event()
	elif GameState.auto_move:
		# 퀘스트 자동 이동 중에 포탈을 타고 왔다면 계속 이어서 간다
		await get_tree().create_timer(0.9).timeout
		if GameState.auto_move:
			player.autopilot.start_quest_move()


## GameState.next_spawn 이름과 같은 포탈/마커를 찾아 플레이어를 옮긴다
func _place_player() -> void:
	var key := GameState.next_spawn
	if key == "":
		return
	for node in get_tree().get_nodes_in_group("spawn_points"):
		if node.has_method("get_spawn_position") and node.portal_id == key:
			player.global_position = node.get_spawn_position()
			return
		if node is Marker2D and node.name == key:
			player.global_position = node.global_position
			return


func _update_camera_limits() -> void:
	var used: Rect2i = ground.get_used_rect()
	var ts: Vector2 = Vector2(ground.tile_set.tile_size)
	var map_rect := Rect2(Vector2(used.position) * ts, Vector2(used.size) * ts)
	var view: Vector2 = get_viewport_rect().size / camera.zoom
	# 가로
	if map_rect.size.x >= view.x:
		camera.limit_left = int(map_rect.position.x)
		camera.limit_right = int(map_rect.end.x)
	else:
		var cx := map_rect.get_center().x
		camera.limit_left = int(cx - view.x / 2)
		camera.limit_right = int(cx + view.x / 2)
	# 세로
	if map_rect.size.y >= view.y:
		camera.limit_top = int(map_rect.position.y)
		camera.limit_bottom = int(map_rect.end.y)
	else:
		var cy := map_rect.get_center().y
		camera.limit_top = int(cy - view.y / 2)
		camera.limit_bottom = int(cy + view.y / 2)


func _play_enter_event() -> void:
	player.set_controls(false)
	await get_tree().create_timer(1.2).timeout  # 화면이 밝아질 때까지 잠깐 기다림
	await hud.dialogue.play(enter_event_lines)
	GameState.flags[enter_event_flag] = true
	player.set_controls(true)



## 쓰러진 적을 잠시 뒤 같은 자리에 다시 놓는다
func respawn_later(scene_path: String, pos: Vector2, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree():
		return
	var e: Node2D = load(scene_path).instantiate()
	e.position = pos
	e.modulate.a = 0.0
	$World.add_child(e)
	e.create_tween().tween_property(e, "modulate:a", 1.0, 0.6)


# ================= 자동 이동용 길찾기 =================

## from에서 to까지 걸어갈 수 있는 길(점 목록)을 찾는다. 못 찾으면 빈 배열.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if Engine.get_physics_frames() - _ready_frame < 6:
		return PackedVector2Array()  # 나무·벽의 충돌 정보가 아직 준비되지 않았다
	if _astar == null:
		_build_grid()
	var a := _nearest_free(Vector2i((from / 16.0).floor()))
	var b := _nearest_free(Vector2i((to / 16.0).floor()))
	if a == Vector2i(-9999, -9999) or b == Vector2i(-9999, -9999):
		return PackedVector2Array()
	var cells := _astar.get_id_path(a, b)
	var points := PackedVector2Array()
	for c in cells:
		points.append(Vector2(c) * 16.0 + Vector2(8, 10))
	if not points.is_empty():
		points.remove_at(0)  # 첫 칸은 지금 서 있는 곳
	return points


## 칸마다 "벽·나무·건물·NPC가 있는지" 물리 엔진에 물어 막힌 칸을 표시한다
func _build_grid() -> void:
	_astar = AStarGrid2D.new()
	_astar.region = ground.get_used_rect()
	_astar.cell_size = Vector2(16, 16)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	var space := get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = Vector2(11, 9)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.collision_mask = 1  # 지형·건물·NPC
	var r := _astar.region
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			q.transform = Transform2D(0, Vector2(x * 16 + 8, y * 16 + 10))
			if not space.intersect_shape(q, 1).is_empty():
				_astar.set_point_solid(Vector2i(x, y))


func _nearest_free(c: Vector2i) -> Vector2i:
	for radius in 4:
		var best := Vector2i(-9999, -9999)
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var p := c + Vector2i(dx, dy)
				if _astar.is_in_boundsv(p) and not _astar.is_point_solid(p):
					if best == Vector2i(-9999, -9999) or Vector2(p - c).length() < Vector2(best - c).length():
						best = p
		if best != Vector2i(-9999, -9999):
			return best
	return Vector2i(-9999, -9999)


## 이름으로 이 맵의 물건(NPC·상자·포탈) 찾기
func find_target(target_name: String) -> Node2D:
	var n := find_child(target_name, true, false)
	return n as Node2D
