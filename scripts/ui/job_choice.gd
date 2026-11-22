extends Control
## 1차 전직: 세 직업 중 하나를 고른다

signal chosen(job_id: String)

var _selected: String = ""
var _cards := {}
var _confirm: Button
var _desc: Label


func _ready() -> void:
	hide()
	var root := UIKit.window(self, Vector2(470, 250), "1차 전직 — 걸어갈 길을 고르세요", Callable())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)
	for id in GameState.JOBS:
		var job: Dictionary = GameState.JOBS[id]
		var card := Button.new()
		card.custom_minimum_size = Vector2(146, 120)
		card.toggle_mode = true
		card.add_theme_stylebox_override("normal", UIKit.box(Color(0.18, 0.14, 0.1), Color(0.45, 0.36, 0.26)))
		card.add_theme_stylebox_override("pressed", UIKit.box(Color(0.32, 0.24, 0.12), Color(1, 0.8, 0.45)))
		card.add_theme_stylebox_override("hover", UIKit.box(Color(0.24, 0.18, 0.12), Color(0.7, 0.56, 0.38)))
		var v := VBoxContainer.new()
		v.set_anchors_preset(PRESET_FULL_RECT)
		v.offset_left = 6; v.offset_top = 6; v.offset_right = -6; v.offset_bottom = -6
		v.mouse_filter = MOUSE_FILTER_IGNORE
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(v)
		var icon := UIKit.icon_rect(UIKit.skill_icon(job.skill), 36)
		icon.mouse_filter = MOUSE_FILTER_IGNORE
		v.add_child(icon)
		for t in [[job.name, 14, Color(1, 0.9, 0.6)], ["%s 계열" % job.line, 10, Color(0.8, 0.75, 0.65)], ["「%s」" % GameState.SKILLS[job.skill].name, 10, Color(0.85, 0.85, 1)]]:
			var l := UIKit.label(t[0], t[1], t[2])
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.mouse_filter = MOUSE_FILTER_IGNORE
			v.add_child(l)
		card.pressed.connect(_select.bind(id))
		row.add_child(card)
		_cards[id] = card
	var bottom := HBoxContainer.new()
	root.add_child(bottom)
	_desc = UIKit.label("직업을 눌러 살펴보세요.", 10)
	_desc.size_flags_horizontal = SIZE_EXPAND_FILL
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(_desc)
	_confirm = UIKit.button("이 길을 택한다", 12, Vector2(110, 32))
	_confirm.disabled = true
	_confirm.pressed.connect(func(): hide(); chosen.emit(_selected))
	bottom.add_child(_confirm)


func open() -> void:
	_selected = ""
	_confirm.disabled = true
	for id in _cards:
		_cards[id].button_pressed = false
	show()


func _select(id: String) -> void:
	_selected = id
	for k in _cards:
		_cards[k].button_pressed = k == id
	_desc.text = GameState.JOBS[id].desc + "\n" + GameState.SKILLS[GameState.JOBS[id].skill].desc
	_confirm.disabled = false
