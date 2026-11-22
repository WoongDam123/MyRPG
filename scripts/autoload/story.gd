extends Node
## 이야기 진행: NPC가 지금 상황(퀘스트 진행도)에 맞는 대사를 하도록 정해 주고,
## 대사가 끝난 뒤 일어날 일(퀘스트 시작, 보상 등)을 처리한다.
## 전역(Autoload) "Story"로 등록. NPC의 story_id가 여기 함수들과 연결된다.
##
## 서장 퀘스트 순서
##   errand_equip(장비) → errand_shop(물약 사기) → errand_quickslot(퀵슬롯) → coming_of_age(성인식)
##   → main_mine(버려진 광산, 킹슬라임) → job_trial(레벨 10 + 대지의 제단 시련 → 1차 전직)

## 맵끼리 어떤 포탈로 이어져 있는지 (자동 이동 길찾기용). 맵 id = 맵 파일 이름
const MAP_LINKS := {
	"house": {"village": "house_door"},
	"village": {"house": "home_door", "barn": "barn_door", "shop": "shop_door", "rock_forest": "forest_exit"},
	"barn": {"village": "barn_out"},
	"shop": {"village": "shop_out"},
	"rock_forest": {"village": "village_exit", "mine": "mine_entrance", "altar": "altar_path"},
	"mine": {"rock_forest": "mine_out", "mine_boss": "boss_door"},
	"mine_boss": {"mine": "boss_out"},
	"altar": {"rock_forest": "altar_out"},
}


func q(id: String) -> String:
	return GameState.quest_state(id)


func _potions() -> int:
	return GameState.inventory.get("potion", 0)


# =====================================================================
# 현재 목표: text = 화면 표시 / map + target = 자동 이동 목적지
#   map이 ""이면 자동 이동 없음, target이 ""이면 그 맵에 도착하면 끝
# =====================================================================
func current_objective() -> Dictionary:
	# ① 장비
	if q("errand_equip") == "":
		return {"text": "아빠와 이야기하기 (마을 밭)", "map": "village", "target": "Dad"}
	if q("errand_equip") == "active":
		if _equip_done():
			return {"text": "아빠에게 돌아가기", "map": "village", "target": "Dad"}
		if GameState.has_item("wooden_sword") or GameState.has_item("leather_armor"):
			return {"text": "가방을 열고 목검·가죽옷 장착하기", "map": "", "target": "", "open_bag": true}
		return {"text": "창고 상자에서 장비 꺼내기", "map": "barn", "target": "Chest"}
	# ② 물약 사기
	if q("errand_shop") == "":
		return {"text": "엄마와 이야기하기 (우리 집)", "map": "house", "target": "Mom"}
	if q("errand_shop") == "active":
		if _potions() < 2:
			return {"text": "잡화점에서 회복 물약 2개 사기 (%d/2)" % _potions(), "map": "shop", "target": "Shopkeeper"}
		return {"text": "엄마에게 물약 갖다 드리기", "map": "house", "target": "Mom"}
	# ③ 퀵슬롯
	if q("errand_quickslot") == "active":
		if GameState.quickslot != "potion":
			return {"text": "가방에서 물약을 '퀵슬롯 등록'하기", "map": "", "target": "", "open_bag": true}
		return {"text": "엄마에게 알리기", "map": "house", "target": "Mom"}
	# ④ 성인식
	if q("coming_of_age") == "":
		return {"text": "아빠에게 성인식 이야기 듣기", "map": "village", "target": "Dad"}
	if q("coming_of_age") == "active":
		return {"text": "광장의 촌장님 만나기", "map": "village", "target": "Elder"}
	# ⑤ 버려진 광산
	if q("main_mine") == "active":
		if GameState.flags.get("king_slime_defeated", false):
			return {"text": "촌장님께 보고하기", "map": "village", "target": "Elder"}
		if not GameState.has_item("mine_key"):
			return {"text": "버려진 광산에서 열쇠 찾기", "map": "mine", "target": "KeyChest"}
		if GameState.level < GameState.BOSS_LEVEL:
			return {"text": "광산에서 수련하기 (Lv %d 필요, 지금 Lv %d)" % [GameState.BOSS_LEVEL, GameState.level],
				"map": "mine", "target": "", "auto_hunt": true}
		return {"text": "광산 깊은 곳의 주인 쓰러뜨리기", "map": "mine_boss", "target": "KingSlime"}
	# ⑥ 전직의 시련
	if q("job_trial") == "active":
		if GameState.job != "":
			return {"text": "촌장님께 전직 보고하기", "map": "village", "target": "Elder"}
		if GameState.level < GameState.JOB_LEVEL:
			return {"text": "레벨 %d 달성하기 (지금 Lv %d) — 광산에서 수련" % [GameState.JOB_LEVEL, GameState.level],
				"map": "mine", "target": "", "auto_hunt": true}
		return {"text": "대지의 제단에서 시련 받기", "map": "altar", "target": "Spirit"}
	return {"text": "1차 전직 완료! 다음 이야기는 곧 이어집니다", "map": "", "target": ""}


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


# =====================================================================
# NPC 대사
# =====================================================================
func get_lines(story_id: String) -> Array:
	match story_id:
		"dad": return _dad_lines()
		"mom": return _mom_lines()
		"shopkeeper": return _shopkeeper_lines()
		"elder": return _elder_lines()
		"spirit": return _spirit_lines()
	return []


func after_talk(story_id: String) -> void:
	match story_id:
		"dad": _dad_after()
		"mom": _mom_after()
		"shopkeeper": _hud().open_shop()
		"elder": _elder_after()
		"spirit": _spirit_after()


func _hud() -> Node:
	return get_tree().get_first_node_in_group("hud")


func _give_coins(n: int) -> void:
	GameState.coins += n
	GameState.item_obtained.emit("coin", n)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.coins = GameState.coins
		player.coins_changed.emit(GameState.coins)


# ---------------- 아빠 ----------------
func _dad_lines() -> Array:
	var e := q("errand_equip")
	if e == "":
		return [
			"오, 우리 집 잠꾸러기 왔구나!",
			"내일이면 너도 어엿한 그라니아의 성인이지. 시간 참 빠르구나.",
			"성인식 전에, 어른으로서 알아 둬야 할 걸 몇 가지 가르쳐 주마.",
			"먼저 우리 집 옆 창고에 가 보렴. 아빠가 젊을 때 쓰던 낡은 목검과 가죽옷이 상자에 들어 있을 거다.",
			"꺼내서 직접 입어 보거라. 장비는 오른쪽 위의 가방을 열어서 장착할 수 있단다.",
		]
	if e == "active":
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
	if q("errand_quickslot") == "done" and q("coming_of_age") == "":
		return [
			"엄마 심부름까지 다 했구나. 이제 정말 준비가 끝났어.",
			"자, 광장의 촌장님께 가 보거라. 성인식은 촌장님이 직접 해 주신단다.",
			"…아빠도 젊을 땐 그 목검 하나 들고 바위 숲을 누볐지. 너도 잘 해낼 게다.",
		]
	if q("coming_of_age") == "done":
		return ["우리 아들이 벌써 용사라니… 몸조심하거라. 힘들면 언제든 돌아오고."]
	return ["엄마 심부름은 했니? 엄마는 집에 계신단다."]


func _dad_after() -> void:
	var e := q("errand_equip")
	if e == "":
		GameState.start_quest("errand_equip")
	elif e == "active" and _equip_done():
		GameState.complete_quest("errand_equip")
		_give_coins(10)
	elif q("errand_quickslot") == "done" and q("coming_of_age") == "":
		GameState.start_quest("coming_of_age")


func _equip_done() -> bool:
	return GameState.equipment.weapon == "wooden_sword" and GameState.equipment.armor == "leather_armor"


# ---------------- 엄마 ----------------
func _mom_lines() -> Array:
	if q("errand_equip") != "done":
		return [
			"아빠는 집 앞 밭에 계셔. 문 앞의 빛나는 곳으로 나가면 된단다.",
			"내일이면 성인식이라니… 엄마는 아직도 네가 아기 같은데.",
		]
	if q("errand_shop") == "":
		return [
			"어머, 아빠 장비를 입으니 제법 어른 같구나.",
			"엄마도 부탁 하나 하자. 잡화점에 가서 회복 물약 2개만 사다 주렴.",
			"여기 코인 20개. 잡화점은 마을 오른쪽 위, 파란 지붕 집이야.",
			"가게에서는 물건을 사기도 하고, 필요 없는 물건을 팔 수도 있단다.",
		]
	if q("errand_shop") == "active":
		if _potions() >= 2:
			return [
				"고마워라! 하나는 엄마가 쓰고, 하나는 네가 가지렴.",
				"모험하다 다치면 바로 마실 수 있게 '퀵슬롯'에 넣어 두렴.",
				"가방에서 물약을 누르고 '퀵슬롯 등록'을 누르면 돼.",
				"그러면 오른쪽 아래 물약 버튼(키보드 Q)으로 언제든 바로 마실 수 있단다.",
			]
		return ["회복 물약 2개야. 잡화점은 마을 오른쪽 위 파란 지붕 집이란다."]
	if q("errand_quickslot") == "active":
		if GameState.quickslot == "potion":
			return [
				"잘했어! 이제 위험할 때 바로 마실 수 있겠구나.",
				"이건 엄마가 몰래 챙겨 둔 물약이야. 2개 더 가져가렴.",
				"이제 아빠한테 가 보렴. 성인식 이야기를 해 주실 거야.",
			]
		return ["가방을 열고 물약을 누른 다음 '퀵슬롯 등록'을 눌러 보렴."]
	if q("coming_of_age") == "done":
		return ["밥은 꼭 챙겨 먹고 다니렴. 물약도 넉넉히 사 두고!"]
	return ["아빠가 성인식 이야기를 해 주실 거야. 밭에 계신단다."]


func _mom_after() -> void:
	if q("errand_equip") != "done":
		return
	if q("errand_shop") == "":
		GameState.start_quest("errand_shop")
		_give_coins(20)
	elif q("errand_shop") == "active" and _potions() >= 2:
		GameState.remove_item("potion")
		GameState.complete_quest("errand_shop")
		GameState.start_quest("errand_quickslot")
	elif q("errand_quickslot") == "active" and GameState.quickslot == "potion":
		GameState.complete_quest("errand_quickslot")
		GameState.add_item("potion", 2)


# ---------------- 잡화점 주인 ----------------
func _shopkeeper_lines() -> Array:
	if q("errand_shop") == "active" and _potions() < 2:
		return ["어서 오게! 회복 물약을 사러 왔구먼. '구매' 목록에서 물약을 눌러 보게나."]
	return ["어서 오게, 자갈 마을 잡화점일세! 천천히 둘러보게."]


# ---------------- 촌장 ----------------
func _elder_lines() -> Array:
	if q("coming_of_age") == "active":
		return [
			"오, 왔구나. 오늘을 기다리고 있었단다.",
			"그라니아의 아이는 열아홉 번째 해가 되면 대지 앞에 서서 어른이 됨을 고한다네.",
			"…좋은 눈빛이구나. 대지의 기운이 유난히 강하게 느껴지는군.",
			"이제 그대는 자갈 마을의 어엿한 성인이다! 이 증표를 받게. 장신구 칸에 장착하면 힘이 될 걸세.",
			"그리고… 성인이 된 그대에게 첫 임무를 맡기고 싶네.",
			"바위 숲 동쪽 끝, 버려진 광산에 괴물이 들끓고 있다네. 광산 깊은 곳에 그 주인이 있는 모양이야.",
			"이제 마을 동쪽 큰길 끝의 포탈로 바위 숲에 나갈 수 있다네. 부디 조심하게.",
		]
	if q("main_mine") == "active":
		if GameState.flags.get("king_slime_defeated", false):
			return [
				"오오, 광산의 주인을 쓰러뜨렸다고? 정말 장하구나!",
				"그 손에 든 건… 대지의 결정이로군. 그대에게 반응해 빛나고 있어.",
				"결정이 주인을 고른다는 옛이야기가 사실이었나 보군. 그대에게는 '전직'의 자격이 있네.",
				"레벨 10이 되면 바위 숲 북쪽의 '대지의 제단'으로 가게. 대지의 정령이 시련을 내려 줄 걸세.",
				"시련을 이겨 내면 화강 기사, 강철 투사, 석영 술사 중 하나의 길을 걷게 될 게야.",
			]
		return ["버려진 광산은 바위 숲 동쪽 끝일세. 깊은 곳의 문은 열쇠가 있어야 열린다더군."]
	if q("job_trial") == "active":
		if GameState.job != "":
			return [
				"오오… 그 기운! 정말로 시련을 이겨 냈구나.",
				"%s의 길이라… 그대에게 잘 어울리네." % GameState.JOBS[GameState.job].name,
				"그대가 오기 전날 밤, 별이 유난히 밝게 빛났었지. 어쩌면 그대는… 아니, 아직은 때가 아니군.",
				"그라니아에는 그대의 힘이 필요한 곳이 많네. 이야기는 이제 막 시작이야.",
			]
		return ["레벨 10이 되면 바위 숲 북쪽 대지의 제단으로 가게. 지금은 Lv %d이로군." % GameState.level]
	if q("job_trial") == "done":
		return ["%s, 그대의 이름이 마을에 자자하다네!" % GameState.JOBS[GameState.job].name]
	return ["허허, 성인식 준비는 잘 되어 가는가?"]


func _elder_after() -> void:
	if q("coming_of_age") == "active":
		GameState.complete_quest("coming_of_age")
		GameState.flags["adult"] = true
		GameState.add_item("adult_token")
		GameState.start_quest("main_mine")
	elif q("main_mine") == "active" and GameState.flags.get("king_slime_defeated", false):
		GameState.complete_quest("main_mine")
		GameState.start_quest("job_trial")
	elif q("job_trial") == "active" and GameState.job != "":
		GameState.complete_quest("job_trial")
		_give_coins(50)


# ---------------- 대지의 정령 (전직 시련) ----------------
func _spirit_lines() -> Array:
	if GameState.job != "":
		return ["대지가 그대와 함께한다, %s여." % GameState.JOBS[GameState.job].name]
	if q("job_trial") != "active":
		return ["……아직 그대의 때가 아니다."]
	if GameState.level < GameState.JOB_LEVEL:
		return [
			"……대지의 결정을 지닌 자여, 잘 왔다.",
			"그러나 아직 그대의 목소리는 대지에 닿지 않는다. 레벨 %d이 되어 다시 오라. (지금 Lv %d)" % [GameState.JOB_LEVEL, GameState.level],
		]
	return [
		"……대지의 결정을 지닌 자여, 잘 왔다.",
		"그대 안에 흐르는 Solid의 힘… 이 세계의 것이면서, 이 세계의 것이 아니구나.",
		"좋다. 시련을 내리겠다. 몰려오는 바위의 무리를 견디고, 대지의 수호자를 쓰러뜨려라.",
		"그대가 이겨 낸다면, 걸어갈 길을 스스로 고르게 될 것이다.",
	]


func _spirit_after() -> void:
	if q("job_trial") == "active" and GameState.job == "" and GameState.level >= GameState.JOB_LEVEL:
		var trial := get_tree().get_first_node_in_group("trial")
		if trial:
			trial.start()
