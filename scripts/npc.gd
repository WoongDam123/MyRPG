extends StaticBody2D
## 마을 사람(NPC): 가까이 가서 공격 버튼(Space/J)을 누르면 대화한다.
## 그림은 4칸(아래·왼쪽·오른쪽·위) 가로 한 줄 이미지.

@export var npc_name: String = "마을 사람"
@export var texture: Texture2D
@export_multiline var lines: Array[String] = ["안녕!"]  ## 대화 내용 (한 칸이 한 장면)
@export_enum("down", "left", "right", "up") var facing: String = "down"

const FRAME := {"down": 0, "left": 1, "right": 2, "up": 3}

var _player: Node2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var bubble: Label = $Bubble


func _ready() -> void:
	add_to_group("interactable")
	sprite.texture = texture
	sprite.frame = FRAME[facing]
	_player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	# 플레이어가 가까이 오면 말풍선 표시
	var near := _player != null and global_position.distance_to(_player.global_position) < 30.0
	bubble.visible = near
	if near:
		bubble.position.y = -34.0 + sin(Time.get_ticks_msec() / 200.0) * 1.5


func interact(player: Node2D) -> void:
	# 플레이어 쪽을 바라본다
	var d := player.global_position - global_position
	if absf(d.x) > absf(d.y):
		sprite.frame = FRAME["right"] if d.x > 0 else FRAME["left"]
	else:
		sprite.frame = FRAME["down"] if d.y > 0 else FRAME["up"]
	player.set_controls(false)
	var dialogue = get_tree().get_first_node_in_group("dialogue_box")
	var script_lines: Array = []
	for text in lines:
		script_lines.append({"name": npc_name, "text": text})
	await dialogue.play(script_lines)
	sprite.frame = FRAME[facing]
	player.set_controls(true)
