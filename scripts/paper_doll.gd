extends Node2D
## 종이 인형(레이어) 캐릭터: 장비 칸마다 따로 그린 그림을 겹쳐서 하나의 용사를 만든다.
## 장비를 바꾸면 해당 레이어 그림만 바뀐다.  (그림 생성: tools/make_paperdoll.py)
##
## 그림 한 장 = 32x32 칸, 가로 9칸 (대기 0-1 · 걷기 2-5 · 공격 6-8) × 세로 4줄 (아래·왼쪽·오른쪽·위)
## 그리는 순서(뒤 → 앞): 망토(뒤) · 무기(등) · 몸 · 갑옷 · 장신구 · 머리 · 망토(위쪽 볼 때) · 무기(공격·위쪽)

signal animation_finished

const DIRS := ["down", "left", "right", "up"]
const ANIMS := {
	"idle": {"frames": [0, 1], "fps": 2.0, "loop": true},
	"walk": {"frames": [2, 3, 4, 5], "fps": 9.0, "loop": true},
	"attack": {"frames": [6, 7, 8], "fps": 12.0, "loop": false},
}
const PATH := "res://assets/hero/%s.png"

var anim: String = "idle"
var dir: String = "down"
var _t: float = 0.0
var _done: bool = false
var _layers := {}  # 이름 → Sprite2D


func _ready() -> void:
	for name in ["cape_back", "weapon_back", "body", "armor", "acc", "hair", "cape_front", "weapon_front"]:
		var s := Sprite2D.new()
		s.name = name
		s.hframes = 9
		s.vframes = 4
		add_child(s)
		_layers[name] = s
	_layers.body.texture = load(PATH % "body")
	_layers.hair.texture = load(PATH % "hair")
	refresh()
	GameState.inventory_changed.connect(refresh)
	GameState.skills_changed.connect(refresh)


## 지금 장비·직업에 맞게 레이어 그림을 고른다
func refresh() -> void:
	_layers.armor.texture = _tex("armor_" + GameState.equipment.armor)
	var weapon := _tex("weapon_" + GameState.equipment.weapon)
	if weapon == null:
		weapon = _tex("weapon_none")  # 맨손: 공격할 때 팔만
	_layers.weapon_back.texture = weapon
	_layers.weapon_front.texture = weapon
	_layers.acc.texture = _tex("acc_" + GameState.equipment.accessory)
	var cape := _tex("cape_" + GameState.job) if GameState.job != "" else null
	_layers.cape_back.texture = cape
	_layers.cape_front.texture = cape
	_apply()


func _tex(name: String) -> Texture2D:
	if name.ends_with("_") or not ResourceLoader.exists(PATH % name):
		return null
	return load(PATH % name)


## AnimatedSprite2D처럼 "walk_down" 같은 이름으로 재생
func play(full_name: String) -> void:
	var parts := full_name.split("_")
	var a: String = parts[0]
	var d: String = parts[1]
	if a == anim and d == dir and not (a == "attack" and _done):
		return
	anim = a
	dir = d
	_t = 0.0
	_done = false
	_apply()


func _process(delta: float) -> void:
	var info: Dictionary = ANIMS[anim]
	_t += delta
	var n: int = info.frames.size()
	var i := int(_t * info.fps)
	if i >= n:
		if info.loop:
			i = i % n
		else:
			i = n - 1
			if not _done:
				_done = true
				animation_finished.emit()
	_set_frame(dir.length() * 0 + DIRS.find(dir) * 9 + info.frames[i])


func _apply() -> void:
	var attacking := anim == "attack"
	_layers.cape_back.visible = dir != "up"
	_layers.cape_front.visible = dir == "up"
	_layers.weapon_back.visible = not attacking and dir != "up"
	_layers.weapon_front.visible = attacking or dir == "up"


func _set_frame(f: int) -> void:
	for s in _layers.values():
		if s.texture:
			s.frame = f
