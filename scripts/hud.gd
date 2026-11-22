extends CanvasLayer
## 화면 위 정보: 하트 체력, 코인 개수.
## HUD는 플레이어를 직접 모르고, main.gd가 플레이어 시그널을 이 함수들에 연결해 준다.

const HEART_FULL := preload("res://assets/items/heart_full.png")
const HEART_EMPTY := preload("res://assets/items/heart_empty.png")

@onready var hearts: HBoxContainer = $TopLeft/Hearts
@onready var coin_label: Label = $TopLeft/Coins/Label
@onready var map_name_label: Label = $MapName
@onready var dialogue = $DialogueBox


func set_health(current: int, maximum: int) -> void:
	# 최대 체력 수만큼 하트 칸을 맞춘다
	while hearts.get_child_count() < maximum:
		var heart := TextureRect.new()
		heart.stretch_mode = TextureRect.STRETCH_KEEP
		hearts.add_child(heart)
	while hearts.get_child_count() > maximum:
		var last := hearts.get_child(hearts.get_child_count() - 1)
		hearts.remove_child(last)
		last.queue_free()
	for i in maximum:
		var heart: TextureRect = hearts.get_child(i)
		var was_full := heart.texture == HEART_FULL
		heart.texture = HEART_FULL if i < current else HEART_EMPTY
		if was_full and i >= current:
			_pop(heart)  # 방금 잃은 하트는 통통 튀는 연출


func set_coins(total: int) -> void:
	coin_label.text = "× %d" % total
	_pop(coin_label)


func _pop(node: Control) -> void:
	node.pivot_offset = node.size / 2
	node.scale = Vector2(1.5, 1.5)
	create_tween().tween_property(node, "scale", Vector2.ONE, 0.2)


## 맵에 들어올 때 이름을 화면 위에 잠깐 보여 준다
func show_map_name(text: String) -> void:
	map_name_label.text = text
	map_name_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(map_name_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.8)
	tween.tween_property(map_name_label, "modulate:a", 0.0, 0.8)
