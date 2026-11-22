extends Control
## 가방(인벤토리) + 장비창. 화면을 코드로 만든다.
## 왼쪽: 장비 3칸과 능력치 / 오른쪽: 가방 칸 / 아래: 고른 아이템 설명과 버튼(장착·해제·사용)

signal closed

const SLOT_SIZE := Vector2(34, 34)
const BAG_SLOTS := 18

var _selected: Dictionary = {}  # {"from": "bag"/"equip", "id": ..., "slot": ...}
var _equip_buttons := {}
var _bag_grid: GridContainer
var _stats: Label
var _detail_name: Label
var _detail_desc: Label
var _action: Button


func _ready() -> void:
	hide()
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(0.1, 0.08, 0.06, 0.96), Color(0.8, 0.62, 0.38)))
	panel.set_anchors_preset(PRESET_CENTER)
	panel.custom_minimum_size = Vector2(470, 270)
	panel.position = -panel.custom_minimum_size / 2
	panel.anchor_left = 0.5; panel.anchor_top = 0.5; panel.anchor_right = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -235; panel.offset_top = -138; panel.offset_right = 235; panel.offset_bottom = 132
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	panel.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var title := _label("가방", 14, Color(1, 0.88, 0.6))
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(title)
	var close := Button.new()
	close.text = "닫기 ✕"
	close.add_theme_font_size_override("font_size", 11)
	close.pressed.connect(close_inventory)
	top.add_child(close)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)

	# 왼쪽: 장비
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 150
	left.add_theme_constant_override("separation", 4)
	body.add_child(left)
	left.add_child(_label("장비", 11, Color(0.85, 0.8, 0.7)))
	for slot in ["weapon", "armor", "accessory"]:
		var row := HBoxContainer.new()
		var b := _slot_button()
		b.pressed.connect(_select.bind({"from": "equip", "slot": slot}))
		row.add_child(b)
		var l := _label("", 10, Color(0.9, 0.9, 0.9))
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(l)
		left.add_child(row)
		_equip_buttons[slot] = [b, l]
	_stats = _label("", 11, Color(1, 0.85, 0.55))
	left.add_child(_stats)

	# 오른쪽: 가방
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	body.add_child(right)
	right.add_child(_label("소지품", 11, Color(0.85, 0.8, 0.7)))
	_bag_grid = GridContainer.new()
	_bag_grid.columns = 6
	_bag_grid.add_theme_constant_override("h_separation", 4)
	_bag_grid.add_theme_constant_override("v_separation", 4)
	right.add_child(_bag_grid)
	for i in BAG_SLOTS:
		var b := _slot_button()
		b.pressed.connect(_select_bag_index.bind(i))
		_bag_grid.add_child(b)

	# 아래: 설명
	var detail := HBoxContainer.new()
	detail.add_theme_constant_override("separation", 8)
	root.add_child(detail)
	var dv := VBoxContainer.new()
	dv.size_flags_horizontal = SIZE_EXPAND_FILL
	detail.add_child(dv)
	_detail_name = _label("", 12, Color(1, 0.9, 0.6))
	_detail_desc = _label("아이템을 눌러 보세요.", 10, Color(0.85, 0.85, 0.85))
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.custom_minimum_size = Vector2(300, 30)
	dv.add_child(_detail_name)
	dv.add_child(_detail_desc)
	_action = Button.new()
	_action.custom_minimum_size = Vector2(90, 30)
	_action.add_theme_font_size_override("font_size", 12)
	_action.visible = false
	_action.pressed.connect(_on_action)
	detail.add_child(_action)

	GameState.inventory_changed.connect(_refresh)


func open_inventory() -> void:
	_selected = {}
	_refresh()
	show()


func close_inventory() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("inventory") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		close_inventory()


func _bag_ids() -> Array:
	return GameState.inventory.keys()


func _select_bag_index(i: int) -> void:
	var ids := _bag_ids()
	if i < ids.size():
		_select({"from": "bag", "id": ids[i]})


func _select(sel: Dictionary) -> void:
	if sel.from == "equip":
		sel["id"] = GameState.equipment[sel.slot]
		if sel.id == "":
			return
	_selected = sel
	_refresh()


func _on_action() -> void:
	if _selected.is_empty():
		return
	var id: String = _selected.id
	var type: String = GameState.ITEMS[id].type
	if _selected.from == "equip":
		GameState.unequip(_selected.slot)
		_selected = {"from": "bag", "id": id}
	elif type in ["weapon", "armor", "accessory"]:
		GameState.equip(id)
		_selected = {"from": "equip", "slot": type, "id": id}
	elif type == "consumable":
		var player = get_tree().get_first_node_in_group("player")
		if player and player.use_item(id):
			if GameState.inventory.get(id, 0) <= 0:
				_selected = {}
	_refresh()


func _refresh() -> void:
	# 장비 칸
	for slot in _equip_buttons:
		var id: String = GameState.equipment[slot]
		var b: Button = _equip_buttons[slot][0]
		var l: Label = _equip_buttons[slot][1]
		b.icon = GameState.get_icon(id) if id != "" else null
		l.text = "%s\n%s" % [GameState.SLOT_NAMES[slot], GameState.ITEMS[id].name if id != "" else "(비어 있음)"]
		b.modulate = Color(1.3, 1.2, 0.8) if (not _selected.is_empty() and _selected.from == "equip" and _selected.slot == slot) else Color.WHITE
	_stats.text = "공격력  %d\n최대 체력  %d" % [GameState.get_attack(), GameState.get_max_hp()]
	# 가방 칸
	var ids := _bag_ids()
	for i in BAG_SLOTS:
		var b: Button = _bag_grid.get_child(i)
		var cnt: Label = b.get_child(0)
		if i < ids.size():
			b.icon = GameState.get_icon(ids[i])
			var n: int = GameState.inventory[ids[i]]
			cnt.text = str(n) if n > 1 else ""
			b.modulate = Color(1.3, 1.2, 0.8) if (not _selected.is_empty() and _selected.from == "bag" and _selected.id == ids[i]) else Color.WHITE
		else:
			b.icon = null
			cnt.text = ""
			b.modulate = Color.WHITE
	# 설명과 버튼
	if _selected.is_empty() or not GameState.ITEMS.has(_selected.get("id", "")):
		_detail_name.text = ""
		_detail_desc.text = "아이템을 눌러 보세요."
		_action.visible = false
		return
	var item: Dictionary = GameState.ITEMS[_selected.id]
	_detail_name.text = item.name
	_detail_desc.text = item.desc
	_action.visible = true
	if _selected.from == "equip":
		_action.text = "해제"
	elif item.type in ["weapon", "armor", "accessory"]:
		_action.text = "장착"
	elif item.type == "consumable":
		_action.text = "사용"
	else:
		_action.visible = false


func _slot_button() -> Button:
	var b := Button.new()
	b.custom_minimum_size = SLOT_SIZE
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_stylebox_override("normal", _box(Color(0.2, 0.16, 0.12), Color(0.45, 0.36, 0.26)))
	b.add_theme_stylebox_override("hover", _box(Color(0.26, 0.2, 0.15), Color(0.7, 0.56, 0.38)))
	b.add_theme_stylebox_override("pressed", _box(Color(0.3, 0.24, 0.16), Color(0.9, 0.72, 0.45)))
	var cnt := _label("", 9, Color.WHITE)
	cnt.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	cnt.offset_left = -14; cnt.offset_top = -13; cnt.offset_right = -2; cnt.offset_bottom = 0
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cnt.add_theme_color_override("font_outline_color", Color.BLACK)
	cnt.add_theme_constant_override("outline_size", 3)
	b.add_child(cnt)
	return b


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(6)
	return s
