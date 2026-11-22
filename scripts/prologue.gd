extends Control
## 프롤로그: 미지의 존재가 나를 불러내고, 세 근원 에너지 중 하나를 고르게 한다.

const NEXT_SCENE := "res://scenes/maps/house.tscn"  # 자갈 마을의 우리 집에서 눈을 뜬다
const BEING := "???"

const INTRO := [
	{"name": BEING, "text": "……들리는가."},
	{"name": BEING, "text": "놀라지 마라. 너의 원래 세계는, 잠시 뒤에 두고 왔을 뿐이다."},
	{"name": BEING, "text": "여기는 별과 대지 사이. 어디에도 속하지 않는 곳."},
	{"name": BEING, "text": "내가 너를 이곳으로 불렀다. 저 아래의 세계, '가이아'를 위해서."},
	{"name": BEING, "text": "가이아에는 세 개의 근원 에너지가 흐른다."},
	{"name": BEING, "text": "단단한 대지의 힘, Solid.\n흐르는 생명의 힘, Liquid.\n아득한 별의 힘, Cosmo."},
	{"name": BEING, "text": "그중 하나를 받아들여라. 그 힘이 네가 살아갈 곳을 정할 것이다."},
]

const AFTER := {
	"solid": [
		{"name": BEING, "text": "……대지를 택했구나."},
		{"name": BEING, "text": "단단함은 쉽게 부서지지 않는다. 그러나 무겁기에, 멈춰 서기도 쉽지."},
		{"name": BEING, "text": "너는 대지의 왕국 그라니아, 산자락의 작은 마을에서 새로운 삶을 얻게 될 것이다."},
		{"name": BEING, "text": "그곳에서 자라며… 언젠가 오늘을 떠올리게 되겠지."},
		{"name": BEING, "text": "가라. 코스모 가이아의 균형이, 너에게 달려 있다."},
	],
}

const ORB_COLORS := {
	"solid": Color(1.0, 0.75, 0.4),
	"liquid": Color(0.45, 0.75, 1.0),
	"cosmo": Color(0.75, 0.55, 1.0),
}

var selected: String = ""

@onready var being: TextureRect = %Being
@onready var dialogue = %DialogueBox
@onready var choice_panel: Control = %ChoicePanel
@onready var desc_title: Label = %DescTitle
@onready var desc_label: Label = %DescLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var orb_buttons := {"solid": %OrbSolid, "liquid": %OrbLiquid, "cosmo": %OrbCosmo}


func _ready() -> void:
	choice_panel.hide()
	confirm_button.disabled = true
	confirm_button.pressed.connect(_on_confirm)
	for key in orb_buttons:
		orb_buttons[key].pressed.connect(_on_orb_pressed.bind(key))
		orb_buttons[key].pivot_offset = orb_buttons[key].custom_minimum_size / 2
		if not GameState.ATTRIBUTES[key].unlocked:
			orb_buttons[key].self_modulate = Color(0.6, 0.6, 0.7)  # 잠긴 힘은 살짝 어둡게

	# 미지의 존재가 천천히 나타난다
	being.modulate.a = 0.0
	await get_tree().create_timer(0.8).timeout
	await create_tween().tween_property(being, "modulate:a", 1.0, 2.0).finished

	await dialogue.play(INTRO)
	_show_choice()


func _process(_delta: float) -> void:
	# 미지의 존재가 둥실둥실 떠 있고, 고른 구슬이 맥박치듯 빛난다
	var t := Time.get_ticks_msec() / 1000.0
	being.position.y = sin(t * 1.5) * 3.0  # BeingHolder 안에서 위아래로
	for key in orb_buttons:
		var b: TextureButton = orb_buttons[key]
		var target := 1.25 + 0.05 * sin(t * 4.0) if key == selected else 1.0
		b.scale = b.scale.lerp(Vector2(target, target), 0.2)


func _show_choice() -> void:
	desc_title.text = "구슬을 눌러 힘을 살펴보아라"
	desc_label.text = ""
	choice_panel.modulate.a = 0.0
	choice_panel.show()
	create_tween().tween_property(choice_panel, "modulate:a", 1.0, 0.6)


func _on_orb_pressed(key: String) -> void:
	selected = key
	var info: Dictionary = GameState.ATTRIBUTES[key]
	desc_title.text = "%s — %s" % [info.name, info.title]
	desc_title.add_theme_color_override("font_color", ORB_COLORS[key])
	if info.unlocked:
		desc_label.text = info.desc
		confirm_button.disabled = false
		confirm_button.text = "이 힘을 받아들인다"
	else:
		desc_label.text = info.desc + "\n(이 힘은 아직 잠들어 있다 — 추후 업데이트)"
		confirm_button.disabled = true
		confirm_button.text = "아직 받아들일 수 없다"


func _on_confirm() -> void:
	if selected == "" or not GameState.ATTRIBUTES[selected].unlocked:
		return
	GameState.attribute = selected
	confirm_button.disabled = true
	await create_tween().tween_property(choice_panel, "modulate:a", 0.0, 0.5).finished
	choice_panel.hide()
	await dialogue.play(AFTER[selected])
	GameState.next_spawn = "bed"  # 침대 옆에서 시작
	Transition.change_scene(NEXT_SCENE, "그라니아 변방, 자갈 마을\n\n— 성인식을 앞둔 어느 날 —", Color.WHITE)
