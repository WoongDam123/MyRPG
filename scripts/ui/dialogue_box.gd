extends Control
## 대화창: 글자가 한 글자씩 나타나고, 화면을 터치(클릭)하거나 Space/J를 누르면 다음 줄로 넘어간다.
## 사용 예:
##   await $DialogueBox.play([{"name": "엄마", "text": "일어났니?"}, "이름 없이 글만 쓸 수도 있어요."])

signal finished

@export var chars_per_second: float = 30.0  ## 글자가 나타나는 속도

var _lines: Array = []
var _index: int = 0
var _typing: bool = false
var _tween: Tween

@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %TextLabel
@onready var next_mark: Label = %NextMark


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func play(lines: Array) -> void:
	_lines = lines
	_index = 0
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP  # 대화 중에는 뒤쪽 터치를 막는다
	_show_line()
	await finished


func _show_line() -> void:
	var line = _lines[_index]
	var speaker := ""
	var text := ""
	if line is Dictionary:
		speaker = line.get("name", "")
		text = line.get("text", "")
	else:
		text = str(line)
	name_label.text = speaker
	name_label.get_parent().visible = speaker != ""
	text_label.text = text
	text_label.visible_ratio = 0.0
	next_mark.hide()
	_typing = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(text_label, "visible_ratio", 1.0, max(text.length() / chars_per_second, 0.05))
	_tween.finished.connect(_on_typed)


func _on_typed() -> void:
	_typing = false
	next_mark.show()


func _advance() -> void:
	if not visible:
		return
	if _typing:
		# 글자가 나오는 중에 누르면 한 번에 다 보여 준다
		_tween.kill()
		text_label.visible_ratio = 1.0
		_on_typed()
		return
	_index += 1
	if _index >= _lines.size():
		hide()
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		finished.emit()
	else:
		_show_line()


func _gui_input(event: InputEvent) -> void:
	# 휴대폰 터치도 마우스 클릭으로 바뀌어 들어오므로 클릭만 처리하면 된다
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_accept") or event.is_action_pressed("attack")):
		get_viewport().set_input_as_handled()
		_advance()


func _process(_delta: float) -> void:
	if next_mark.visible:
		next_mark.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
