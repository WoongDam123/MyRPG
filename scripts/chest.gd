extends StaticBody2D
## 보물 상자: 공격 버튼으로 연다. 한 번 열면 GameState에 기록되어 다시 열리지 않는다.

@export var chest_id: String = ""  ## 상자마다 다른 이름 (열었는지 기록용)
@export var items: Array[String] = []  ## 들어 있는 아이템 id
@export var required_quest: String = ""  ## 이 퀘스트를 받은 뒤에만 열 수 있음 (비우면 언제나)
@export_multiline var locked_text: String = "(아직 열면 안 될 것 같다.)"
@export_multiline var after_text: Array[String] = []  ## 열고 난 뒤 나오는 안내

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("interactable")
	sprite.frame = 1 if _is_opened() else 0


func _is_opened() -> bool:
	return GameState.flags.get("chest_" + chest_id, false)


func interact(player: Node2D) -> void:
	var dialogue = get_tree().get_first_node_in_group("dialogue_box")
	player.set_controls(false)
	if _is_opened():
		await dialogue.play(["(빈 상자다.)"])
	elif required_quest != "" and GameState.quest_state(required_quest) != "active":
		await dialogue.play([locked_text])
	else:
		GameState.flags["chest_" + chest_id] = true
		sprite.frame = 1
		var lines: Array = []
		for id in items:
			GameState.add_item(id)
			lines.append("(%s 얻었다!)" % GameState.josa(GameState.ITEMS[id].name, "을", "를"))
		lines.append_array(after_text)
		await dialogue.play(lines)
	player.set_controls(true)
