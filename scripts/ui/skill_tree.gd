extends Control
## 스킬 창: 레벨업으로 얻은 스킬 포인트로 스킬을 배운다. 직업이 생기면 직업 스킬도 표시.

signal closed

var _info: Label
var _list: VBoxContainer


func _ready() -> void:
	hide()
	var root := UIKit.window(self, Vector2(400, 260), "스킬", close_menu)
	_info = UIKit.label("", 11, Color(1, 0.88, 0.55))
	root.add_child(_info)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 190)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)
	GameState.skills_changed.connect(func(): if visible: _refresh())


func open_menu() -> void:
	_refresh()
	show()


func close_menu() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("skills_menu")):
		get_viewport().set_input_as_handled()
		close_menu()


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var job_name: String = GameState.JOBS[GameState.job].name if GameState.job != "" else "견습 용사"
	_info.text = "Lv %d %s   ·   스킬 포인트 %d" % [GameState.level, job_name, GameState.skill_points]
	_list.add_child(UIKit.label("견습 용사 스킬", 10, Color(0.8, 0.75, 0.65)))
	for id in ["dash", "earth_blade", "stone_body"]:
		_row(id)
	_list.add_child(UIKit.label("직업 스킬", 10, Color(0.8, 0.75, 0.65)))
	if GameState.job == "":
		_list.add_child(UIKit.label("레벨 %d에 1차 전직을 하면 직업 스킬이 생겨요." % GameState.JOB_LEVEL, 10, Color(0.6, 0.6, 0.6)))
	else:
		_row(GameState.JOBS[GameState.job].skill)


func _row(id: String) -> void:
	var sk: Dictionary = GameState.SKILLS[id]
	var lv: int = GameState.skill_level(id)
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UIKit.box(Color(0.18, 0.14, 0.1), Color(0.4, 0.32, 0.22), 4))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	row.add_child(h)
	var icon := UIKit.icon_rect(UIKit.skill_icon(id), 28)
	if lv == 0:
		icon.modulate = Color(0.5, 0.5, 0.5)
	h.add_child(icon)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = SIZE_EXPAND_FILL
	var kind := "버튼 스킬" if sk.kind == "active" else "항상 적용"
	v.add_child(UIKit.label("%s  %d/%d  (%s)" % [sk.name, lv, sk.max, kind], 11, Color(1, 0.92, 0.7)))
	var d := UIKit.label(sk.desc, 9, Color(0.78, 0.78, 0.78))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 240
	v.add_child(d)
	h.add_child(v)
	if sk.job == "":
		var b := UIKit.button("배우기" if lv < sk.max else "완료")
		b.disabled = not GameState.can_learn(id)
		b.pressed.connect(func(): GameState.learn_skill(id))
		h.add_child(b)
	_list.add_child(row)
