extends CharacterBody2D
## 적 공통 스크립트 (슬라임·바위 슬라임·킹슬라임·대지의 수호자).
## 평소엔 어슬렁거리다가 플레이어가 가까이 오면 쫓아온다. 칼에 맞으면 번쩍이며 밀려나고,
## 체력이 0이 되면 경험치를 주고 사라진다. (보스는 몸통 박치기 돌진을 한다)

@export var display_name: String = "슬라임"
@export var max_hp: int = 3  ## 몇 번 맞으면 죽는지
@export var speed: float = 32.0  ## 쫓아올 때 속도
@export var chase_range: float = 90.0  ## 이 거리(픽셀) 안에 플레이어가 오면 쫓아온다
@export var damage: int = 1  ## 플레이어에게 닿았을 때 주는 피해
@export var exp_reward: int = 4  ## 처치하면 얻는 경험치
@export_range(0.0, 1.0) var coin_chance: float = 0.6  ## 죽을 때 코인을 떨어뜨릴 확률
@export_range(0.0, 1.0) var heart_chance: float = 0.25  ## 코인 대신 하트를 떨어뜨릴 확률
@export var respawn_time: float = 15.0  ## 죽은 뒤 이 시간이 지나면 같은 자리에 다시 나타남 (0 = 안 나타남)
@export_group("보스")
@export var is_boss: bool = false  ## 화면 위에 체력 막대 표시
@export var dash_interval: float = 0.0  ## 몇 초마다 돌진하는지 (0 = 돌진 안 함)
@export var dash_speed: float = 170.0
@export var drop_item: String = ""  ## 죽으면 반드시 주는 아이템
@export var defeat_flag: String = ""  ## 죽으면 기록되는 이름 (이미 기록돼 있으면 처음부터 나타나지 않음)

const PICKUP_SCENE := preload("res://scenes/pickup.tscn")

var hp: int
var knockback: Vector2 = Vector2.ZERO  ## 맞았을 때 밀려나는 속도 (점점 줄어든다)
var wander_dir: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var is_dead: bool = false
var home: Vector2
var _dash_timer: float = 0.0
var _dash_state: int = 0  # 0 보통, 1 준비(부르르), 2 돌진 중
var _dash_t: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var player: Node2D


func _ready() -> void:
	if defeat_flag != "" and GameState.flags.get(defeat_flag, false):
		queue_free()  # 이미 쓰러뜨린 보스
		return
	hp = max_hp
	home = position
	add_to_group("enemies")
	if is_boss:
		add_to_group("bosses")
	player = get_tree().get_first_node_in_group("player")
	sprite.play("bounce")
	sprite.frame = randi() % 2
	_dash_timer = dash_interval


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if knockback.length() > 5.0:
		velocity = knockback
		knockback = knockback.lerp(Vector2.ZERO, (4.0 if is_boss else 10.0) * delta)
	elif _dash_state > 0:
		_update_dash(delta)
	elif player and global_position.distance_to(player.global_position) < chase_range:
		velocity = global_position.direction_to(player.global_position) * speed
		if dash_interval > 0.0:
			_dash_timer -= delta
			if _dash_timer <= 0.0:
				_dash_state = 1
				_dash_t = 0.5
				_dash_dir = global_position.direction_to(player.global_position)
	else:
		wander_timer -= delta
		if wander_timer <= 0.0:
			wander_timer = randf_range(1.5, 3.0)
			wander_dir = Vector2.ZERO if randf() < 0.4 else Vector2.RIGHT.rotated(randf() * TAU)
		velocity = wander_dir * speed * 0.4
	if velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0
	move_and_slide()


## 보스 돌진: 0.5초 부르르 떨며 준비 → 0.35초 빠르게 돌진
func _update_dash(delta: float) -> void:
	_dash_t -= delta
	if _dash_state == 1:
		velocity = Vector2.ZERO
		sprite.position.x = sin(_dash_t * 60.0) * 1.5
		sprite.modulate = Color(1.4, 1.0, 1.0)
		if _dash_t <= 0.0:
			_dash_state = 2
			_dash_t = 0.35
			sprite.position.x = 0.0
			sprite.modulate = Color.WHITE
	else:
		velocity = _dash_dir * dash_speed
		if _dash_t <= 0.0:
			_dash_state = 0
			_dash_timer = dash_interval


## 플레이어의 공격에 맞았을 때 호출된다
func take_damage(amount: int, from_position: Vector2) -> void:
	if is_dead:
		return
	hp -= amount
	knockback = (global_position - from_position).normalized() * (60.0 if is_boss else 160.0)
	sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	_float_text(str(amount), Color(1, 1, 0.8))
	if hp <= 0:
		_die()


func _die() -> void:
	is_dead = true
	remove_from_group("enemies")
	remove_from_group("bosses")
	$CollisionShape2D.set_deferred("disabled", true)
	GameState.add_exp(exp_reward)
	_float_text("+%d EXP" % exp_reward, Color(0.6, 0.9, 1.0))
	if defeat_flag != "":
		GameState.flags[defeat_flag] = true
	if drop_item != "":
		GameState.add_item(drop_item)
	_drop_item()
	if respawn_time > 0.0 and defeat_flag == "":
		var map = get_tree().get_first_node_in_group("map")
		if map:
			map.respawn_later(scene_file_path, home, respawn_time)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.6, 0.3), 0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free()


## 머리 위로 떠오르는 글자 (피해 숫자, 경험치)
func _float_text(text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	l.position = global_position + Vector2(-20, -30)
	l.size = Vector2(40, 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 10
	get_parent().add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 14, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


## 확률에 따라 하트나 코인을 떨어뜨린다
func _drop_item() -> void:
	var roll := randf()
	var kind: int
	if roll < heart_chance:
		kind = 0  # 하트
	elif roll < heart_chance + coin_chance:
		kind = 1  # 코인
	else:
		return
	var item := PICKUP_SCENE.instantiate()
	item.kind = kind
	item.position = position
	get_parent().add_child.call_deferred(item)
