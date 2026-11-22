extends CanvasLayer
## 화면 위 정보: 하트 체력, 코인 개수.
## HUD는 플레이어를 직접 모르고, main.gd가 플레이어 시그널을 이 함수들에 연결해 준다.

const HEART_FULL := preload("res://assets/items/heart_full.png")
const HEART_EMPTY := preload("res://assets/items/heart_empty.png")

@onready var hearts: HBoxContainer = $TopLeft/Hearts
@onready var coin_label: Label = $TopLeft/Coins/Label
@onready var map_name_label: Label = $MapName
@onready var dialogue = $DialogueBox
@onready var quest_button: Button = $TopRight/QuestButton
@onready var bag_button: TextureButton = $TopRight/BagButton
@onready var auto_button: Button = $AutoButton
@onready var toast: Label = $Toast
@onready var inventory: Control = $Inventory

var _toast_queue: Array = []
var _toast_busy: bool = false


func _ready() -> void:
	bag_button.pressed.connect(open_inventory)
	quest_button.pressed.connect(_on_quest_pressed)
	auto_button.button_pressed = GameState.auto_hunt
	auto_button.toggled.connect(_on_auto_toggled)
	_style_auto_button()
	inventory.closed.connect(_on_inventory_closed)
	GameState.item_obtained.connect(_on_item_obtained)
	GameState.quest_changed.connect(refresh_objective)
	GameState.inventory_changed.connect(refresh_objective)
	refresh_objective()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not inventory.visible and not dialogue.visible:
		get_viewport().set_input_as_handled()
		open_inventory()


# ---------- 가방 ----------
func open_inventory() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_controls(false)
	inventory.open_inventory()


func _on_inventory_closed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_controls(true)
	refresh_objective()


# ---------- 목표(퀘스트) ----------
func refresh_objective() -> void:
	var obj: Dictionary = Story.current_objective()
	var moving := GameState.auto_move
	quest_button.text = ("▶ 이동 중… " if moving else "목표: ") + obj.text
	quest_button.tooltip_text = "누르면 목표까지 자동으로 이동해요"


func _on_quest_pressed() -> void:
	var obj: Dictionary = Story.current_objective()
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if obj.get("open_bag", false):
		open_inventory()
		return
	if GameState.auto_move:
		player.autopilot.stop_quest_move()  # 한 번 더 누르면 멈춤
	else:
		player.autopilot.start_quest_move()
	refresh_objective()


# ---------- 자동 사냥 ----------
func _on_auto_toggled(on: bool) -> void:
	GameState.auto_hunt = on
	_style_auto_button()
	_show_toast("자동 사냥 켜짐" if on else "자동 사냥 꺼짐")


func _style_auto_button() -> void:
	auto_button.text = "자동\nON" if GameState.auto_hunt else "자동\nOFF"
	auto_button.modulate = Color(1.2, 1.1, 0.6) if GameState.auto_hunt else Color(1, 1, 1, 0.85)


# ---------- 알림 ----------
func _on_item_obtained(id: String, count: int) -> void:
	if id == "coin":
		_show_toast("코인 %d개를 받았다!" % count)
	elif GameState.ITEMS.has(id):
		_show_toast("%s 얻었다!" % GameState.josa(GameState.ITEMS[id].name, "을", "를"))


func _show_toast(text: String) -> void:
	_toast_queue.append(text)
	if _toast_busy:
		return
	_toast_busy = true
	while not _toast_queue.is_empty():
		toast.text = _toast_queue.pop_front()
		var tw := create_tween()
		tw.tween_property(toast, "modulate:a", 1.0, 0.2)
		tw.tween_interval(1.3)
		tw.tween_property(toast, "modulate:a", 0.0, 0.3)
		await tw.finished
	_toast_busy = false


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



func _process(_delta: float) -> void:
	# 자동 이동이 끝나면 표시를 원래대로
	if quest_button.text.begins_with("▶") != GameState.auto_move:
		refresh_objective()
