extends CharacterBody2D
## 플레이어 캐릭터: 입력을 받아 8방향으로 움직이고, 방향에 맞는 애니메이션을 재생한다.

@export var speed: float = 80.0  ## 1초에 움직이는 픽셀 수 (인스펙터에서 조절 가능)

var facing: String = "down"  ## 마지막으로 바라본 방향 (멈췄을 때 그 방향을 유지)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(_delta: float) -> void:
	# 1) 입력 읽기: 방향키/WASD를 -1~1 범위의 방향 벡터로 바꿔 준다 (대각선도 자동 처리)
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# 2) 이동: 방향 × 속도 → 벽에 부딪히면 미끄러지듯 멈춘다
	velocity = input_dir * speed
	move_and_slide()

	# 3) 애니메이션 갱신
	_update_animation(input_dir)


func _update_animation(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		sprite.play("idle_" + facing)
		return

	# 가로 입력이 더 크면 좌/우, 세로 입력이 더 크면 위/아래를 바라본다
	if absf(input_dir.x) > absf(input_dir.y):
		facing = "right" if input_dir.x > 0 else "left"
	else:
		facing = "down" if input_dir.y > 0 else "up"
	sprite.play("walk_" + facing)
