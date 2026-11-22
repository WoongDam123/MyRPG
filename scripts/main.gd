extends Node2D
## 메인 장면: 시작할 때 카메라가 맵 밖을 비추지 않도록 맵 크기에 맞춰 카메라 경계를 정한다.

@onready var ground: TileMapLayer = $Ground
@onready var camera: Camera2D = $World/Player/Camera2D


func _ready() -> void:
	var used: Rect2i = ground.get_used_rect()  # 타일이 깔린 범위 (타일 단위)
	var tile_size: Vector2i = ground.tile_set.tile_size
	camera.limit_left = used.position.x * tile_size.x
	camera.limit_top = used.position.y * tile_size.y
	camera.limit_right = used.end.x * tile_size.x
	camera.limit_bottom = used.end.y * tile_size.y
