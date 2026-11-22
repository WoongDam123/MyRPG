extends CharacterBody2D
## 슬라임: 평소엔 어슬렁거리다가 플레이어가 가까이 오면 쫓아온다.
## 칼에 맞으면 깜빡이며 뒤로 밀려나고, 체력이 0이 되면 사라진다.

@export var max_hp: int = 3  ## 몇 번 맞으면 죽는지
@export var speed: float = 32.0  ## 쫓아올 때 속도
@export var chase_range: float = 90.0  ## 이 거리(픽셀) 안에 플레이어가 오면 쫓아온다
@export var damage: int = 1  ## 플레이어에게 닿았을 때 주는 피해
@export_range(0.0, 1.0) var coin_chance: float = 0.6  ## 죽을 때 코인을 떨어뜨릴 확률
@export_range(0.0, 1.0) var heart_chance: float = 0.25  ## 코인 대신 하트를 떨어뜨릴 확률

const PICKUP_SCENE := preload("res://scenes/pickup.tscn")

var hp: int
var knockback: Vector2 = Vector2.ZERO  ## 맞았을 때 밀려나는 속도 (점점 줄어든다)
var wander_dir: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var is_dead: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var player: Node2D


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	sprite.play("bounce")
	sprite.frame = randi() % 2  # 슬라임마다 박자를 다르게


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if knockback.length() > 5.0:
		# 맞은 직후: 밀려나는 중
		velocity = knockback
		knockback = knockback.lerp(Vector2.ZERO, 10.0 * delta)
	elif player and global_position.distance_to(player.global_position) < chase_range:
		# 쫓아가기
		velocity = global_position.direction_to(player.global_position) * speed
	else:
		# 어슬렁거리기: 1.5~3초마다 방향을 바꾸거나 잠깐 쉰다
		wander_timer -= delta
		if wander_timer <= 0.0:
			wander_timer = randf_range(1.5, 3.0)
			wander_dir = Vector2.ZERO if randf() < 0.4 else Vector2.RIGHT.rotated(randf() * TAU)
		velocity = wander_dir * speed * 0.4

	if velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0
	move_and_slide()


## 플레이어의 칼에 맞았을 때 호출된다
func take_damage(amount: int, from_position: Vector2) -> void:
	if is_dead:
		return
	hp -= amount
	knockback = (global_position - from_position).normalized() * 160.0

	# 하얗게 번쩍
	sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)

	if hp <= 0:
		_die()


func _die() -> void:
	is_dead = true
	remove_from_group("enemies")
	$CollisionShape2D.set_deferred("disabled", true)
	_drop_item()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.6, 0.3), 0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free()


## 확률에 따라 하트나 코인을 떨어뜨린다
func _drop_item() -> void:
	var roll := randf()
	var kind: int
	if roll < heart_chance:
		kind = 0  # Pickup.Kind.HEART
	elif roll < heart_chance + coin_chance:
		kind = 1  # Pickup.Kind.COIN
	else:
		return  # 아무것도 안 떨어뜨림
	var item := PICKUP_SCENE.instantiate()
	item.kind = kind
	item.position = position
	get_parent().add_child.call_deferred(item)  # 물리 계산 중이라 한 박자 늦게 추가
