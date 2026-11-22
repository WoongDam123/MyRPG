extends Area2D
## 포탈: 플레이어가 들어오면 다른 맵의 같은 짝 포탈 앞으로 이동시킨다.
## 예) 자갈 마을의 "forest_exit" 포탈 → 바위 숲 맵의 "village_exit" 포탈

@export var portal_id: String = ""  ## 이 포탈의 이름 (다른 맵에서 이 이름으로 찾아온다)
@export_file("*.tscn") var target_map: String = ""  ## 이동할 맵 파일
@export var target_portal: String = ""  ## 이동할 맵에서 나타날 포탈 이름
@export var label_text: String = ""  ## 포탈 위에 표시할 글자 (예: "바위 숲")
@export var spawn_offset: Vector2 = Vector2(0, 24)  ## 이 포탈로 "도착"했을 때 나타날 위치 (포탈 기준)
@export var required_flag: String = ""  ## 이 기록이 있어야 지나갈 수 있음 (예: "adult")
@export var required_item: String = ""  ## 이 아이템이 있어야 지나갈 수 있음 (예: "mine_key")
@export var required_level: int = 0  ## 이 레벨 이상이어야 지나갈 수 있음
@export_multiline var locked_text: String = "(아직 지나갈 수 없을 것 같다.)"

var _armed: bool = false  ## 도착 직후 바로 다시 빨려 들어가지 않도록 잠깐 꺼 둔다
var _t: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label


func _ready() -> void:
	add_to_group("spawn_points")
	body_entered.connect(_on_body_entered)
	label.text = label_text
	label.visible = label_text != ""
	if _is_locked():
		sprite.modulate = Color(0.55, 0.55, 0.6, 0.8)  # 잠긴 포탈은 어둡게
	await get_tree().create_timer(0.8).timeout
	_armed = true


func _process(delta: float) -> void:
	_t += delta
	sprite.frame = int(_t * 8.0) % 4  # 소용돌이 애니메이션
	sprite.scale = Vector2.ONE * (1.0 + 0.04 * sin(_t * 3.0))


func get_spawn_position() -> Vector2:
	return global_position + spawn_offset


func _on_body_entered(body: Node2D) -> void:
	if not _armed or not body.is_in_group("player") or target_map == "":
		return
	if _is_locked():
		_armed = false
		body.knockback = (body.global_position - global_position).normalized() * 160.0
		if body.autopilot:
			body.autopilot.stop_quest_move()
		body.set_controls(false)
		var msg := locked_text
		if required_level > 0 and GameState.level < required_level and (required_item == "" or GameState.has_item(required_item)):
			msg = "(문 너머에서 엄청난 기운이 느껴진다… 레벨 %d 이상이 되어 다시 오자. 지금 Lv %d)" % [required_level, GameState.level]
		await get_tree().get_first_node_in_group("dialogue_box").play([msg])
		body.set_controls(true)
		await get_tree().create_timer(0.6).timeout
		_armed = true
		return
	_armed = false
	body.set_controls(false)
	GameState.next_spawn = target_portal
	Transition.change_scene(target_map)


func _is_locked() -> bool:
	if required_flag != "" and not GameState.flags.get(required_flag, false):
		return true
	if required_item != "" and not GameState.has_item(required_item):
		return true
	if GameState.level < required_level:
		return true
	return false
