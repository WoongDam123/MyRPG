extends Node2D
## 전직의 시련: 바위 슬라임 무리 → 단단한 슬라임 무리 → 대지의 수호자를 차례로 물리치면
## 직업 고르기 창이 열린다. (쓰러지면 처음부터 다시)

const WAVES := [
	["res://scenes/enemies/rock_slime.tscn", 4, "시련 1/3 — 바위의 무리"],
	["res://scenes/enemies/hard_slime.tscn", 3, "시련 2/3 — 단단한 바위의 무리"],
	["res://scenes/enemies/golem.tscn", 1, "시련 3/3 — 대지의 수호자"],
]

var running: bool = false


func _ready() -> void:
	add_to_group("trial")


func _hud() -> Node:
	return get_tree().get_first_node_in_group("hud")


func start() -> void:
	if running:
		return
	running = true
	var player = get_tree().get_first_node_in_group("player")
	for wave in WAVES:
		_hud().show_toast(wave[2])
		await get_tree().create_timer(1.2).timeout
		var alive: Array = []
		var markers := get_children().filter(func(c): return c is Marker2D)
		for i in wave[1]:
			var e: Node2D = load(wave[0]).instantiate()
			e.respawn_time = 0.0
			e.chase_range = 500.0
			e.coin_chance = 0.3
			e.position = markers[i % markers.size()].position if wave[1] > 1 else Vector2(192, 150)
			get_parent().add_child(e)
			alive.append(e)
		while alive.any(func(e): return is_instance_valid(e) and not e.is_dead):
			await get_tree().create_timer(0.3).timeout
		await get_tree().create_timer(0.8).timeout
	_hud().show_toast("시련을 이겨 냈다!")
	await get_tree().create_timer(1.0).timeout
	var dialogue = get_tree().get_first_node_in_group("dialogue_box")
	player.set_controls(false)
	await dialogue.play([
		{"name": "대지의 정령", "text": "……훌륭하다. 대지가 그대를 인정했다."},
		{"name": "대지의 정령", "text": "이제 걸어갈 길을 고르라. 굳건히 지키는 자, 모든 것을 부수는 자, 결정을 다루는 자."},
	])
	var job: String = await _hud().choose_job()
	GameState.set_job(job)
	player.set_controls(false)
	await dialogue.play([
		{"name": "대지의 정령", "text": "그대는 이제 「%s」. 대지의 이름을 칭호로 받은 자." % GameState.JOBS[job].name},
		{"name": "대지의 정령", "text": "새로운 힘 「%s」이(가) 깨어났다. 오른쪽 아래 버튼(키보드 L)으로 써 보라." % GameState.SKILLS[GameState.JOBS[job].skill].name},
		{"name": "대지의 정령", "text": "…그리고 기억하라. 별에서 온 자여. 그대를 이곳에 보낸 존재가, 그대를 지켜보고 있다."},
	])
	player.set_controls(true)
	_hud().show_toast("1차 전직 완료! %s" % GameState.JOBS[job].name)
	GameState.quest_changed.emit()
	running = false
