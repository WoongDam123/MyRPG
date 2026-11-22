extends Area2D
## 바닥에 떨어진 아이템 (하트 또는 코인). 플레이어가 닿으면 주워진다.

enum Kind { HEART, COIN }

@export var kind: Kind = Kind.COIN  ## 아이템 종류
@export var lifetime: float = 12.0  ## 이 시간이 지나면 사라진다 (마지막 3초는 깜빡임)

const TEXTURES := {
	Kind.HEART: preload("res://assets/items/heart_full.png"),
	Kind.COIN: preload("res://assets/items/coin.png"),
}

var _age: float = 0.0
var _collected: bool = false
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("pickups")
	sprite.texture = TEXTURES[kind]
	body_entered.connect(_on_body_entered)
	# 떨어질 때 톡 튀어 오르는 연출
	sprite.position.y = -14
	create_tween().tween_property(sprite, "position:y", -6.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if _collected:
		return
	_age += delta
	if _age > 0.35:
		sprite.position.y = -6.0 + sin(_age * 4.0) * 1.5  # 둥실둥실
	if _age > lifetime - 3.0:
		sprite.visible = fmod(_age, 0.2) < 0.13  # 곧 사라짐을 알리는 깜빡임
	if _age > lifetime:
		queue_free()


func _physics_process(_delta: float) -> void:
	# 체력이 가득 차서 하트를 못 주웠을 때, 그 위에 서 있다가 다치면 바로 줍도록
	if not _collected and kind == Kind.HEART:
		for body in get_overlapping_bodies():
			_on_body_entered(body)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	if not body.collect(kind):
		return  # 못 줍는 경우 (예: 체력이 이미 가득)
	_collected = true
	sprite.visible = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "position:y", -20.0, 0.2)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()
