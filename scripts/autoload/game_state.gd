extends Node
## 게임 전체에서 공유하는 정보 (장면이 바뀌어도 유지된다).
## 프로젝트 설정 → 전역(Autoload)에 "GameState"로 등록되어 있어서 어디서든 GameState.attribute 처럼 쓸 수 있다.

## 세 가지 근원 에너지(속성) 정보
const ATTRIBUTES := {
	"solid": {
		"name": "Solid",
		"title": "대지의 힘",
		"desc": "대지·광물·강철의 힘.\n높은 체력과 방어, 묵직한 근접 공격.\n시작 왕국: 그라니아",
		"kingdom": "그라니아",
		"unlocked": true,
	},
	"liquid": {
		"name": "Liquid",
		"title": "흐름의 힘",
		"desc": "물·흐름·생명의 힘.\n빠른 연속 공격과 회복.\n시작 왕국: 아쿠아리스",
		"kingdom": "아쿠아리스",
		"unlocked": false,
	},
	"cosmo": {
		"name": "Cosmo",
		"title": "별의 힘",
		"desc": "별·중력·우주 에너지의 힘.\n멀리서 쏘는 에너지 공격, 낮은 체력.\n시작 왕국: 아스트라",
		"kingdom": "아스트라",
		"unlocked": false,
	},
}

signal inventory_changed  ## 가방·장비가 바뀌었을 때
signal stats_changed  ## 공격력·최대 체력이 바뀌었을 때
signal item_obtained(item_id: String, count: int)  ## 아이템을 얻었을 때 (화면 알림용)
signal quest_changed  ## 퀘스트가 시작·완료됐을 때

## 아이템 목록. icon = item_icons.png의 몇 번째 칸인지
## type: weapon(무기) / armor(방어구) / accessory(장신구) / consumable(소모품) / material(재료)
const ITEMS := {
	"wooden_sword": {"name": "낡은 목검", "type": "weapon", "icon": 0, "atk": 1,
		"desc": "아빠가 젊은 시절 쓰던 목검. 낡았지만 손에 잘 맞는다.\n공격력 +1"},
	"leather_armor": {"name": "가죽옷", "type": "armor", "icon": 1, "hp": 1,
		"desc": "튼튼하게 무두질한 가죽옷. 한 대쯤은 더 버틸 수 있을 것 같다.\n최대 체력 +1"},
	"potion": {"name": "회복 물약", "type": "consumable", "icon": 2, "heal": 2,
		"desc": "마시면 체력을 2 회복한다."},
	"herb": {"name": "약초", "type": "material", "icon": 3,
		"desc": "자갈 마을 근처에서 자라는 약초. 물약의 재료가 된다."},
}

const SLOT_NAMES := {"weapon": "무기", "armor": "방어구", "accessory": "장신구"}

## 퀘스트(심부름) 목록
const QUESTS := {
	"errand_equip": {"title": "아빠의 부탁 ① 장비 갖추기",
		"goal": "창고 상자에서 장비를 꺼내 장착하고 아빠에게 돌아가기"},
}

const BASE_ATTACK := 1  ## 맨손 공격력
const BASE_MAX_HP := 5

var attribute: String = ""  ## 플레이어가 고른 속성 ("solid" / "liquid" / "cosmo")
var player_name: String = "용사"

# --- 플레이어 상태 (맵을 옮겨 다녀도 유지) ---
var player_hp: int = -1  ## -1이면 "가득 찬 상태로 시작"
var coins: int = 0
var inventory: Dictionary = {}  ## 아이템 id → 개수
var equipment: Dictionary = {"weapon": "", "armor": "", "accessory": ""}  ## 장착 중인 아이템 id
var quests: Dictionary = {}  ## 퀘스트 id → "active" / "done"

# --- 맵 이동 ---
var next_spawn: String = ""  ## 다음 맵에서 플레이어가 나타날 위치 이름 (포탈 id 또는 Spawns의 Marker2D 이름)

# --- 자동 기능 ---
var auto_hunt: bool = false  ## 자동 사냥 켜짐
var auto_move: bool = false  ## 퀘스트 자동 이동 중 (맵을 넘어가도 이어짐)

# --- 이야기 진행 기록 (예: "intro_done": true) ---
var flags: Dictionary = {}


# ================= 아이템·장비 =================

func add_item(id: String, count: int = 1) -> void:
	inventory[id] = inventory.get(id, 0) + count
	inventory_changed.emit()
	item_obtained.emit(id, count)


func remove_item(id: String, count: int = 1) -> void:
	inventory[id] = inventory.get(id, 0) - count
	if inventory[id] <= 0:
		inventory.erase(id)
	inventory_changed.emit()


func has_item(id: String) -> bool:
	return inventory.get(id, 0) > 0 or equipment.values().has(id)


## 가방에 있는 장비를 장착한다 (원래 끼고 있던 건 가방으로)
func equip(id: String) -> void:
	var slot: String = ITEMS[id].type
	if not equipment.has(slot) or inventory.get(id, 0) <= 0:
		return
	if equipment[slot] != "":
		inventory[equipment[slot]] = inventory.get(equipment[slot], 0) + 1
	remove_item(id)
	equipment[slot] = id
	_after_equipment_change()


func unequip(slot: String) -> void:
	if equipment.get(slot, "") == "":
		return
	inventory[equipment[slot]] = inventory.get(equipment[slot], 0) + 1
	equipment[slot] = ""
	_after_equipment_change()


func _after_equipment_change() -> void:
	if player_hp > get_max_hp():
		player_hp = get_max_hp()
	inventory_changed.emit()
	stats_changed.emit()


func get_attack() -> int:
	var atk := BASE_ATTACK
	for slot in equipment:
		if equipment[slot] != "":
			atk += ITEMS[equipment[slot]].get("atk", 0)
	return atk


func get_max_hp() -> int:
	var hp := BASE_MAX_HP
	for slot in equipment:
		if equipment[slot] != "":
			hp += ITEMS[equipment[slot]].get("hp", 0)
	return hp


## item_icons.png에서 아이콘 한 칸을 잘라 준다
func get_icon(id: String) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = preload("res://assets/items/item_icons.png")
	at.region = Rect2(ITEMS[id].icon * 16, 0, 16, 16)
	return at


# ================= 퀘스트 =================

func start_quest(id: String) -> void:
	quests[id] = "active"
	quest_changed.emit()


func complete_quest(id: String) -> void:
	quests[id] = "done"
	quest_changed.emit()


func quest_state(id: String) -> String:
	return quests.get(id, "")  # "" = 아직 안 받음


## 지금 진행 중인 퀘스트 하나 (HUD 표시용)
func active_quest() -> String:
	for id in quests:
		if quests[id] == "active":
			return id
	return ""


# ================= 한국어 조사 =================

## 받침이 있으면 a("을"), 없으면 b("를")
func josa(word: String, a: String, b: String) -> String:
	if word.is_empty():
		return word + a
	var code := word.unicode_at(word.length() - 1)
	if code < 0xAC00 or code > 0xD7A3:
		return word + a
	return word + (a if (code - 0xAC00) % 28 != 0 else b)
