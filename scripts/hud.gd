extends CanvasLayer
## 화면 위 정보와 버튼들.
## 왼쪽 위: 하트·코인·레벨/경험치 / 오른쪽 위: 목표(누르면 자동 이동)·스킬·가방
## 오른쪽 아래: 공격, 스킬 1·2, 퀵슬롯, 자동 사냥 / 가운데: 맵 이름, 알림, 보스 체력
## HUD는 플레이어를 직접 모르고, map.gd가 플레이어 시그널을 이 함수들에 연결해 준다.

const HEART_FULL := preload("res://assets/items/heart_full.png")
const HEART_EMPTY := preload("res://assets/items/heart_empty.png")
const BTN_TEX := preload("res://assets/ui/attack_button.png")
const BTN_TEX_P := preload("res://assets/ui/attack_button_pressed.png")

@onready var hearts: HBoxContainer = $TopLeft/Hearts
@onready var coin_label: Label = $TopLeft/Coins/Label
@onready var level_label: Label = $TopLeft/Level/Label
@onready var exp_bar: ProgressBar = $TopLeft/Level/ExpBar
@onready var map_name_label: Label = $MapName
@onready var dialogue = $DialogueBox
@onready var quest_button: Button = $TopRight/QuestButton
@onready var skill_button: Button = $TopRight/SkillButton
@onready var bag_button: TextureButton = $TopRight/BagButton
@onready var auto_button: Button = $AutoButton
@onready var toast: Label = $Toast
@onready var inventory: Control = $Inventory
@onready var shop: Control = $Shop
@onready var skill_tree: Control = $SkillTree
@onready var job_choice: Control = $JobChoice
@onready var boss_bar: Control = $BossBar
@onready var actions: Control = $Actions

var _toast_queue: Array = []
var _toast_busy: bool = false
var _action_buttons := {}  # "skill_1" / "skill_2" / "quickslot" → [버튼, 아이콘, 글자]


func _ready() -> void:
	bag_button.pressed.connect(open_inventory)
	skill_button.pressed.connect(open_skill_tree)
	quest_button.pressed.connect(_on_quest_pressed)
	auto_button.button_pressed = GameState.auto_hunt
	auto_button.toggled.connect(_on_auto_toggled)
	sync_auto_button()
	for panel in [inventory, shop, skill_tree]:
		panel.closed.connect(_on_panel_closed)
	GameState.item_obtained.connect(_on_item_obtained)
	GameState.quest_changed.connect(refresh_objective)
	GameState.inventory_changed.connect(refresh_objective)
	GameState.inventory_changed.connect(_refresh_actions)
	GameState.exp_changed.connect(_refresh_level)
	GameState.leveled_up.connect(_on_level_up)
	GameState.skills_changed.connect(_refresh_actions)
	GameState.quickslot_changed.connect(_refresh_actions)
	_make_action_button("skill_2", Vector2(118, 46))
	_make_action_button("skill_1", Vector2(64, 96))
	_make_action_button("quickslot", Vector2(160, 40))
	_refresh_actions()
	_refresh_level()
	refresh_objective()
	_style_bar(exp_bar, Color(0.45, 0.8, 1.0))
	_style_bar(boss_bar.get_node("Bar"), Color(0.9, 0.3, 0.3))
	# 조작 안내는 첫 심부름을 마칠 때까지만 보여 준다
	$Hint.visible = GameState.quest_state("errand_equip") != "done"


func _unhandled_input(event: InputEvent) -> void:
	if _any_panel_open() or dialogue.visible:
		return
	if event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		open_inventory()
	elif event.is_action_pressed("skills_menu"):
		get_viewport().set_input_as_handled()
		open_skill_tree()


func _process(_delta: float) -> void:
	# 자동 이동이 끝나면 목표 표시를 원래대로
	if quest_button.text.begins_with("▶") != GameState.auto_move:
		refresh_objective()
	_update_cooldowns()
	_update_boss_bar()


# ---------- 창 열기/닫기 (열려 있는 동안 플레이어 조작 멈춤) ----------
func _any_panel_open() -> bool:
	return inventory.visible or shop.visible or skill_tree.visible or job_choice.visible


func _lock_player(lock: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_controls(not lock)


func open_inventory() -> void:
	_lock_player(true)
	inventory.open_inventory()


func open_shop() -> void:
	_lock_player(true)
	shop.open_shop()


func open_skill_tree() -> void:
	_lock_player(true)
	skill_tree.open_menu()


## 전직 직업 고르기 창을 열고, 고를 때까지 기다린다
func choose_job() -> String:
	_lock_player(true)
	job_choice.open()
	var id: String = await job_choice.chosen
	_lock_player(false)
	return id


func _on_panel_closed() -> void:
	_lock_player(false)
	refresh_objective()


# ---------- 하트·코인·레벨 ----------
func set_health(current: int, maximum: int) -> void:
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
			_pop(heart)
	_refresh_actions()


func set_coins(total: int) -> void:
	coin_label.text = "× %d" % total
	_pop(coin_label)


func _refresh_level() -> void:
	var job_name: String = GameState.JOBS[GameState.job].name if GameState.job != "" else "견습 용사"
	level_label.text = "Lv %d %s" % [GameState.level, job_name]
	exp_bar.max_value = GameState.exp_to_next()
	exp_bar.value = GameState.exp_points
	skill_button.text = "스킬 ●" if GameState.skill_points > 0 else "스킬"
	refresh_objective()


func _on_level_up(lv: int) -> void:
	_refresh_level()
	_show_toast("레벨 업! Lv %d — 스킬 포인트 +1" % lv)
	_pop(level_label)


# ---------- 목표(퀘스트) ----------
func refresh_objective() -> void:
	var obj: Dictionary = Story.current_objective()
	quest_button.text = ("▶ 이동 중… " if GameState.auto_move else "목표: ") + obj.text


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
	if GameState.auto_hunt == on:
		return
	GameState.auto_hunt = on
	sync_auto_button()
	_show_toast("자동 사냥 켜짐" if on else "자동 사냥 꺼짐")


func sync_auto_button() -> void:
	auto_button.set_pressed_no_signal(GameState.auto_hunt)
	auto_button.text = "자동\nON" if GameState.auto_hunt else "자동\nOFF"
	auto_button.modulate = Color(1.2, 1.1, 0.6) if GameState.auto_hunt else Color(1, 1, 1, 0.85)


# ---------- 스킬·퀵슬롯 버튼 (여러 손가락 동시 터치가 되도록 TouchScreenButton) ----------
func _make_action_button(action: String, pos: Vector2) -> void:
	var b := TouchScreenButton.new()
	b.texture_normal = BTN_TEX
	b.texture_pressed = BTN_TEX_P
	b.scale = Vector2(0.75, 0.75)
	b.position = pos
	b.action = action
	var shape := CircleShape2D.new()
	shape.radius = 24
	b.shape = shape
	b.shape_centered = true
	actions.add_child(b)
	var icon := Sprite2D.new()
	icon.position = Vector2(24, 24)
	icon.scale = Vector2(1.6, 1.6)
	b.add_child(icon)
	var l := Label.new()
	l.position = Vector2(4, 30)
	l.size = Vector2(40, 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	b.add_child(l)
	_action_buttons[action] = [b, icon, l]


func _refresh_actions() -> void:
	if _action_buttons.is_empty():
		return
	var skills: Array = GameState.active_skills()
	for i in 2:
		var parts: Array = _action_buttons["skill_%d" % (i + 1)]
		parts[0].visible = skills[i] != ""
		if skills[i] != "":
			parts[1].texture = UIKit.skill_icon(skills[i])
	var q: Array = _action_buttons["quickslot"]
	q[0].visible = GameState.quickslot != ""
	if GameState.quickslot != "":
		q[1].texture = GameState.get_icon(GameState.quickslot)
		q[2].text = str(GameState.inventory.get(GameState.quickslot, 0))


func _update_cooldowns() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or _action_buttons.is_empty():
		return
	var skills: Array = GameState.active_skills()
	for i in 2:
		var parts: Array = _action_buttons["skill_%d" % (i + 1)]
		var ratio: float = player.get_cooldown_ratio(skills[i])
		parts[1].modulate = Color(0.4, 0.4, 0.4) if ratio > 0.0 else Color.WHITE
		parts[2].text = "%.0f" % ceilf(player.cooldowns.get(skills[i], 0.0)) if ratio > 0.0 else ""


func _update_boss_bar() -> void:
	var boss = get_tree().get_first_node_in_group("bosses")
	boss_bar.visible = boss != null
	if boss:
		boss_bar.get_node("Name").text = boss.display_name
		boss_bar.get_node("Bar").max_value = boss.max_hp
		boss_bar.get_node("Bar").value = boss.hp


# ---------- 알림 ----------
func _on_item_obtained(id: String, count: int) -> void:
	if id == "coin":
		_show_toast("코인 %d개를 받았다!" % count)
	elif GameState.ITEMS.has(id):
		var name: String = GameState.ITEMS[id].name
		_show_toast(("%s %d개를 얻었다!" % [name, count]) if count > 1 else ("%s 얻었다!" % GameState.josa(name, "을", "를")))


func show_toast(text: String) -> void:
	_show_toast(text)


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


## 맵에 들어올 때 이름을 화면 위에 잠깐 보여 준다
func show_map_name(text: String) -> void:
	map_name_label.text = text
	map_name_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(map_name_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.8)
	tween.tween_property(map_name_label, "modulate:a", 0.0, 0.8)


func _pop(node: Control) -> void:
	node.pivot_offset = node.size / 2
	node.scale = Vector2(1.5, 1.5)
	create_tween().tween_property(node, "scale", Vector2.ONE, 0.2)


func _style_bar(bar: ProgressBar, fill: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(2)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
