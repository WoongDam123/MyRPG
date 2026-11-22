extends Node2D
## 메인 장면: 카메라 경계를 맵 크기에 맞추고, 플레이어 체력을 HUD에 연결한다.

@onready var ground: TileMapLayer = $Ground
@onready var player: CharacterBody2D = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var hp_label: Label = $HUD/HPLabel


func _ready() -> void:
	# 1) 카메라가 맵 밖을 비추지 않도록 경계 설정
	var used: Rect2i = ground.get_used_rect()  # 타일이 깔린 범위 (타일 단위)
	var tile_size: Vector2i = ground.tile_set.tile_size
	camera.limit_left = used.position.x * tile_size.x
	camera.limit_top = used.position.y * tile_size.y
	camera.limit_right = used.end.x * tile_size.x
	camera.limit_bottom = used.end.y * tile_size.y

	# 2) 플레이어 체력이 바뀌면 HUD 글자를 바꾼다 (시그널 연결)
	player.health_changed.connect(_on_player_health_changed)
	_on_player_health_changed(player.hp, player.max_hp)


func _on_player_health_changed(current: int, maximum: int) -> void:
	hp_label.text = "HP %d / %d" % [current, maximum]
