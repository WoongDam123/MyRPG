extends Node
## 이야기 진행: NPC가 지금 상황(퀘스트 진행도)에 맞는 대사를 하도록 정해 주고,
## 대사가 끝난 뒤 일어날 일(퀘스트 시작, 보상 등)을 처리한다.
## 전역(Autoload) "Story"로 등록. NPC의 story_id가 여기 함수 이름과 연결된다.

## 맵끼리 어떤 포탈로 이어져 있는지 (자동 이동 길찾기용)
## 맵 id = 맵 파일 이름 (예: village.tscn → "village")
const MAP_LINKS := {
	"house": {"village": "house_door"},
	"village": {"house": "home_door", "barn": "barn_door", "rock_forest": "forest_exit"},
	"barn": {"village": "barn_out"},
	"rock_forest": {"village": "village_exit"},
}


## 지금 해야 할 일. text = 화면 표시, map + target = 자동 이동 목적지 (map이 비면 자동 이동 없음)
func current_objective() -> Dictionary:
	var q := GameState.quest_state("errand_equip")
	if q == "":
		return {"text": "아빠와 이야기하기 (마을 밭)", "map": "village", "target": "Dad"}
	if q == "active":
		if _equip_done():
			return {"text": "아빠에게 돌아가기", "map": "village", "target": "Dad"}
		if GameState.has_item("wooden_sword") or GameState.has_item("leather_armor"):
			return {"text": "가방을 열고 목검·가죽옷 장착하기", "map": "", "target": "", "open_bag": true}
		return {"text": "창고 상자에서 장비 꺼내기", "map": "barn", "target": "Chest"}
	return {"text": "엄마와 이야기하기 (우리 집)", "map": "house", "target": "Mom"}


## from 맵에서 to 맵으로 가려면 이 맵의 어느 포탈로 가야 하는지 (넓이 우선 탐색)
func next_portal(from_map: String, to_map: String) -> String:
	if from_map == to_map:
		return ""
	var queue: Array = [[from_map, ""]]
	var seen := {from_map: true}
	while not queue.is_empty():
		var cur: Array = queue.pop_front()
		var links: Dictionary = MAP_LINKS.get(cur[0], {})
		for nxt in links:
			if seen.has(nxt):
				continue
			var first: String = cur[1] if cur[1] != "" else links[nxt]
			if nxt == to_map:
				return first
			seen[nxt] = true
			queue.append([nxt, first])
	return ""


## NPC가 말을 걸었을 때 부른다. 반환: 대사 배열. 대사가 끝난 뒤 실행할 일은 after_talk()에서.
func get_lines(story_id: String) -> Array:
	match story_id:
		"dad":
			return _dad_lines()
		"mom":
			return _mom_lines()
	return []


func after_talk(story_id: String) -> void:
	match story_id:
		"dad":
			_dad_after()


# ---------------- 아빠 ----------------
func _dad_lines() -> Array:
	var q := GameState.quest_state("errand_equip")
	if q == "":
		return [
			"오, 우리 집 잠꾸러기 왔구나!",
			"내일이면 너도 어엿한 그라니아의 성인이지. 시간 참 빠르구나.",
			"성인식 전에, 어른으로서 알아 둬야 할 걸 몇 가지 가르쳐 주마.",
			"먼저 우리 집 옆 창고에 가 보렴. 아빠가 젊을 때 쓰던 낡은 목검과 가죽옷이 상자에 들어 있을 거다.",
			"꺼내서 직접 입어 보거라. 장비는 오른쪽 위의 가방을 열어서 장착할 수 있단다.",
		]
	if q == "active":
		if _equip_done():
			return [
				"허허, 제법 용사 티가 나는구나!",
				"목검이라도 맨손보다는 훨씬 낫지. 가죽옷은 한 대쯤 더 버티게 해 줄 게다.",
				"자, 이건 심부름 값이다. 코인 10개!",
				"엄마도 부탁할 게 있다더구나. 집에 가 보렴.",
			]
		if GameState.has_item("wooden_sword") or GameState.has_item("leather_armor"):
			return ["상자는 찾았구나! 이제 오른쪽 위 가방을 열고, 목검과 가죽옷을 눌러 '장착'해 보렴."]
		return ["창고는 우리 집 바로 오른쪽이란다. 안쪽 상자를 살펴보렴."]
	return ["성인식 준비는 잘 돼 가니? 내일이 기대되는구나."]


func _dad_after() -> void:
	var q := GameState.quest_state("errand_equip")
	if q == "":
		GameState.start_quest("errand_equip")
	elif q == "active" and _equip_done():
		GameState.complete_quest("errand_equip")
		GameState.coins += 10
		GameState.item_obtained.emit("coin", 10)
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.coins = GameState.coins
			player.coins_changed.emit(GameState.coins)


func _equip_done() -> bool:
	return GameState.equipment.weapon == "wooden_sword" and GameState.equipment.armor == "leather_armor"


# ---------------- 엄마 ----------------
func _mom_lines() -> Array:
	if GameState.quest_state("errand_equip") == "done":
		return [
			"어머, 아빠 장비를 입으니 제법 어른 같구나.",
			"엄마도 부탁할 게 있는데… 조금만 기다려 주렴. (다음 심부름은 곧 이어집니다)",
		]
	return [
		"아빠는 집 앞 밭에 계셔. 문 앞의 빛나는 곳으로 나가면 된단다.",
		"내일이면 성인식이라니… 엄마는 아직도 네가 아기 같은데.",
	]
