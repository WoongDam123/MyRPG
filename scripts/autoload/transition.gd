extends CanvasLayer
## 화면 전환 효과 (어둡게 → 장면 바꾸기 → 밝게). 전역(Autoload) "Transition"으로 등록.
## 사용 예: Transition.change_scene("res://scenes/main.tscn", "볕돌 마을")

var _rect: ColorRect
var _caption: Label


func _ready() -> void:
	layer = 100  # 다른 모든 화면보다 위에
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 14)
	_caption.modulate.a = 0.0
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)


## 장면을 바꾼다. caption을 주면 검은 화면에 글자를 잠시 보여 준다.
func change_scene(path: String, caption: String = "", color: Color = Color.BLACK) -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # 전환 중에는 터치 막기
	_rect.color = Color(color, 0.0)
	await create_tween().tween_property(_rect, "color:a", 1.0, 0.6).finished
	if color != Color.BLACK:
		await create_tween().tween_property(_rect, "color", Color.BLACK, 0.8).finished
	if caption != "":
		_caption.text = caption
		await create_tween().tween_property(_caption, "modulate:a", 1.0, 0.8).finished
		await get_tree().create_timer(1.6).timeout
		await create_tween().tween_property(_caption, "modulate:a", 0.0, 0.6).finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await create_tween().tween_property(_rect, "color:a", 0.0, 0.6).finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
