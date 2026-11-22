extends CharacterBody2D
## 플레이어 캐릭터: 입력을 받아 8방향으로 움직이고, 공격 버튼으로 칼을 휘두른다.
## 키보드(방향키/WASD, Space/J)와 모바일(가상 조이스틱, 공격 버튼) 모두 같은 "입력 액션"을 쓰므로
## 이 코드는 어떤 기기에서든 그대로 동작한다.

@export var speed: float = 80.0  ## 1초에 움직이는 픽셀 수
@export var attack_duration: float = 0.25  ## 칼 휘두르기 한 번에 걸리는 시간(초)

var facing: String = "down"  ## 마지막으로 바라본 방향
var is_attacking: bool = false  ## 공격 중에는 움직이지 않는다

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash: Sprite2D = $Slash

## 방향별 칼 휘두르기 효과의 위치와 회전 (발밑이 기준점, 몸 중심은 y = -8)
const SLASH_POSE := {
	"right": [Vector2(10, -8), 0.0],
	"left": [Vector2(-10, -8), PI],
	"down": [Vector2(0, 2), PI / 2],
	"up": [Vector2(0, -18), -PI / 2],
}


func _physics_process(_delta: float) -> void:
	# 공격 버튼을 "막 누른 순간"에만 공격 시작
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_attack()

	var input_dir: Vector2 = Vector2.ZERO
	if not is_attacking:
		# 방향키/WASD/조이스틱 입력을 -1~1 범위의 방향 벡터로 (대각선 자동 처리)
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = input_dir * speed
	move_and_slide()
	_update_animation(input_dir)


func _update_animation(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		sprite.play("idle_" + facing)
		return
	if absf(input_dir.x) > absf(input_dir.y):
		facing = "right" if input_dir.x > 0 else "left"
	else:
		facing = "down" if input_dir.y > 0 else "up"
	sprite.play("walk_" + facing)


func _attack() -> void:
	is_attacking = true

	# 바라보는 방향에 칼 휘두르기 효과를 놓는다
	var pose: Array = SLASH_POSE[facing]
	slash.position = pose[0]
	slash.rotation = pose[1]
	slash.visible = true
	slash.modulate.a = 1.0
	slash.scale = Vector2(0.6, 0.6)

	# Tween: 짧은 시간 동안 커지면서 사라지는 연출
	var tween := create_tween().set_parallel(true)
	tween.tween_property(slash, "scale", Vector2.ONE, attack_duration * 0.5)
	tween.tween_property(slash, "modulate:a", 0.0, attack_duration).set_delay(attack_duration * 0.3)
	await tween.finished

	slash.visible = false
	is_attacking = false
