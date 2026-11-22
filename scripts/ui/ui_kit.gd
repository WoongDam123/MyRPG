class_name UIKit
## 창(가방·상점·스킬·전직)들이 함께 쓰는 꾸미기 도우미

static func label(text: String, size: int, color: Color = Color(0.92, 0.9, 0.85)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func box(bg: Color, border: Color, margin: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(margin)
	return s


static func button(text: String, size: int = 11, min_size: Vector2 = Vector2(64, 26)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	return b


## 화면 가운데 패널 + 반투명 배경을 만들어 parent에 붙이고, 내용을 넣을 VBox를 돌려준다
static func window(parent: Control, size: Vector2, title: String, on_close: Callable) -> VBoxContainer:
	parent.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box(Color(0.1, 0.08, 0.06, 0.96), Color(0.8, 0.62, 0.38), 8))
	panel.anchor_left = 0.5; panel.anchor_top = 0.5; panel.anchor_right = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -size.x / 2; panel.offset_top = -size.y / 2
	panel.offset_right = size.x / 2; panel.offset_bottom = size.y / 2
	parent.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	panel.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var t := label(title, 14, Color(1, 0.88, 0.6))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	if on_close.is_valid():
		var close := button("닫기 ✕", 11, Vector2(60, 24))
		close.pressed.connect(on_close)
		top.add_child(close)
	return root


static func icon_rect(tex: Texture2D, size: float = 24) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return r


static func skill_icon(id: String) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = preload("res://assets/ui/skill_icons.png")
	at.region = Rect2(GameState.SKILLS[id].icon * 16, 0, 16, 16)
	return at
