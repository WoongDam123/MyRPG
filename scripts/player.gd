extends CharacterBody2D
## 플레이어 캐릭터: 8방향 이동, 칼 공격, 체력.
## 키보드(방향키/WASD, Space/J)와 모바일(가상 조이스틱, 공격 버튼) 모두 같은 "입력 액션"을 쓴다.

signal health_changed(current: int, maximum: int)  ## 체력이 바뀔 때 HUD에 알린다
signal died
signal coins_changed(total: int)  ## 코인 개수가 바뀔 때

@export var speed: float = 80.0  ## 1초에 움직이는 픽셀 수
@export var attack_duration: float = 0.25  ## 칼 휘두르기 한 번에 걸리는 시간(초)
@export var attack_damage: int = 1  ## 칼 한 번에 주는 피해
@export var max_hp: int = 5  ## 최대 체력
@export var invincible_time: float = 1.0  ## 맞은 뒤 무적 시간(초)

var facing: String = "down"  ## 마지막으로 바라본 방향
var is_attacking: bool = false  ## 공격 중에는 움직이지 않는다
var hp: int
var invincible: float = 0.0  ## 남은 무적 시간
var knockback: Vector2 = Vector2.ZERO
var is_dead: bool = false
var coins: int = 0
var _hit_this_swing: Array = []  ## 한 번 휘두를 때 같은 적을 두 번 때리지 않도록

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash: Sprite2D = $Slash
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox

## 방향별 칼 휘두르기 위치와 회전 (발밑이 기준점, 몸 중심은 y = -8)
const SLASH_POSE := {
	"right": [Vector2(10, -8), 0.0],
	"left": [Vector2(-10, -8), PI],
	"down": [Vector2(0, 2), PI / 2],
	"up": [Vector2(0, -18), -PI / 2],
}


func _ready() -> void:
	hp = max_hp
	add_to_group("player")
	attack_hitbox.body_entered.connect(_on_attack_hit)
	health_changed.emit(hp, max_hp)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_check_enemy_contact()
	if invincible > 0.0:
		invincible -= delta
		sprite.visible = fmod(invincible, 0.15) > 0.075 or invincible <= 0.0  # 깜빡깜빡

	if Input.is_action_just_pressed("attack") and not is_attacking:
		_attack()

	var input_dir: Vector2 = Vector2.ZERO
	if not is_attacking:
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = input_dir * speed + knockback
	knockback = knockback.lerp(Vector2.ZERO, 12.0 * delta)
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
	_hit_this_swing.clear()

	var pose: Array = SLASH_POSE[facing]
	slash.position = pose[0]
	slash.rotation = pose[1]
	slash.visible = true
	slash.modulate.a = 1.0
	slash.scale = Vector2(0.6, 0.6)

	# 공격 판정 상자를 칼 위치로 옮기고 켠다
	attack_hitbox.position = pose[0]
	attack_shape.set_deferred("disabled", false)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(slash, "scale", Vector2.ONE, attack_duration * 0.5)
	tween.tween_property(slash, "modulate:a", 0.0, attack_duration).set_delay(attack_duration * 0.3)
	await tween.finished

	attack_shape.set_deferred("disabled", true)
	slash.visible = false
	is_attacking = false


## 공격 판정 상자에 적이 들어오면
func _on_attack_hit(body: Node2D) -> void:
	if body.is_in_group("enemies") and body not in _hit_this_swing:
		_hit_this_swing.append(body)
		body.take_damage(attack_damage, global_position)


## 몸(Hurtbox)에 적이 닿아 있으면 피해를 받는다
func _check_enemy_contact() -> void:
	if invincible > 0.0:
		return
	for body in hurtbox.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			take_damage(body.damage, body.global_position)
			return


func take_damage(amount: int, from_position: Vector2) -> void:
	if is_dead or invincible > 0.0:
		return
	hp = max(hp - amount, 0)
	health_changed.emit(hp, max_hp)
	invincible = invincible_time
	knockback = (global_position - from_position).normalized() * 180.0
	if hp == 0:
		_die()


## 아이템을 주웠을 때 Pickup이 호출한다. 주울 수 없으면 false.
func collect(kind: int) -> bool:
	match kind:
		0:  # 하트: 체력이 가득이면 줍지 않는다
			if hp >= max_hp or is_dead:
				return false
			hp += 1
			health_changed.emit(hp, max_hp)
		1:  # 코인
			coins += 1
			coins_changed.emit(coins)
	return true


func _die() -> void:
	is_dead = true
	sprite.visible = true
	died.emit()
	var tween := create_tween()
	tween.tween_property(sprite, "rotation", PI / 2, 0.4)
	tween.parallel().tween_property(sprite, "modulate", Color(1, 0.3, 0.3, 0.0), 1.0)
	await tween.finished
	get_tree().reload_current_scene()  # 처음부터 다시
