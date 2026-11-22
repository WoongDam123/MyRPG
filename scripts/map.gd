extends Node2D
## 모든 맵이 함께 쓰는 공통 스크립트.
## - 포탈을 타고 들어왔다면 그 포탈 앞에 플레이어를 놓는다
## - 카메라가 맵 밖을 비추지 않게 한다 (맵이 화면보다 작으면 가운데 정렬)
## - 플레이어 체력·코인을 HUD에 연결한다
## - 처음 들어왔을 때 한 번만 나오는 대사(이벤트)를 재생한다

@export var map_name: String = ""  ## 들어올 때 화면 위에 잠깐 표시되는 이름
@export var camera_zoom: float = 1.0  ## 실내는 2로 하면 가까이 보인다
@export var enter_event_flag: String = ""  ## 이 이름의 기록이 없을 때만 아래 대사를 재생
@export var enter_event_lines: Array = []  ## [{"name": "엄마", "text": "..."}, ...]

@onready var ground: TileMapLayer = $Ground
@onready var player: CharacterBody2D = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	_place_player()
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
