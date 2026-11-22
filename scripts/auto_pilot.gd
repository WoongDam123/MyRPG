extends Node
## 자동 조종: 플레이어 대신 "어디로 갈지, 언제 공격할지"를 정한다.
## 1) 퀘스트 자동 이동: 목표(NPC·상자)까지 길을 찾아 걸어가고, 다른 맵이면 포탈을 거쳐 간다. 도착하면 말을 건다.
## 2) 자동 사냥: 가까운 적에게 다가가 공격하고, 떨어진 아이템을 줍는다.
## 조이스틱·키보드로 직접 움직이면 자동 이동은 멈추고, 자동 사냥은 잠깐 쉰다.

@export var hunt_range: float = 260.0  ## 이 거리 안의 적을 우선 노린다 (없으면 맵 전체)
@export var attack_reach: float = 17.0  ## 이만큼 가까우면 공격

var player: CharacterBody2D
var _path: PackedVector2Array = PackedVector2Array()
var _goal: Vector2 = Vector2.INF
var _repath_timer: float = 0.0
var _manual_pause: float = 0.0  ## 직접 조작한 뒤 자동 사냥을 잠깐 쉬는 시간
var _quest_target: Node2D = null
var _attack_dir: Vector2 = Vector2.ZERO
var _last_pos: Vector2
var _stuck_time: float = 0.0
var _stuck_count: int = 0  ## 연속으로 막힌 횟수
var _hunt_target: Node2D = null
var _swings: int = 0
var _ignore: Dictionary = {}  ## 닿을 수 없는 대상 → 남은 무시 시간


func _ready() -> void:
	player = get_parent()


func _map() -> Node:
	return get_tree().get_first_node_in_group("map")


# ---------------- 퀘스트 자동 이동 ----------------

func start_quest_move() -> void:
	var obj: Dictionary = Story.current_objective()
	var map = _map()
	if obj.get("map", "") == "" or map == null:
		stop_quest_move()
		return
	GameState.auto_move = true
	if obj.map != map.map_id:
		# 다른 맵이면 그쪽으로 이어지는 포탈로 간다
		var portal_id := Story.next_portal(map.map_id, obj.map)
		_quest_target = null
		for p in get_tree().get_nodes_in_group("spawn_points"):
			if p.get("portal_id") == portal_id:
				_quest_target = p
		if _quest_target == null:
			stop_quest_move()
			return
	else:
		_quest_target = map.find_target(obj.target)
		if _quest_target == null:
			stop_quest_move()
			return
	_set_goal(_quest_target.global_position)


func stop_quest_move() -> void:
	GameState.auto_move = false
	_quest_target = null
	_path = PackedVector2Array()
	_goal = Vector2.INF


func is_quest_moving() -> bool:
	return GameState.auto_move and _quest_target != null


# ---------------- 매 프레임 판단 ----------------

## 직접 조작이 들어왔을 때 player가 부른다
func on_manual_input() -> void:
	if GameState.auto_move:
		stop_quest_move()
	_manual_pause = 1.0


## 이번 프레임에 움직일 방향 (없으면 ZERO)
func get_move_dir(delta: float) -> Vector2:
	_attack_dir = Vector2.ZERO
	_manual_pause = maxf(_manual_pause - delta, 0.0)

	if is_quest_moving():
		return _quest_step(delta)

	if GameState.auto_hunt and _manual_pause <= 0.0:
		return _hunt_step(delta)
	return Vector2.ZERO


## 공격해야 하면 공격 방향, 아니면 ZERO
func get_attack_dir() -> Vector2:
	return _attack_dir


func _quest_step(delta: float) -> Vector2:
	if not is_instance_valid(_quest_target):
		stop_quest_move()
		return Vector2.ZERO
	var target_pos := _quest_target.global_position
	var is_portal := _quest_target.has_method("get_spawn_position")
	if not is_portal and player.global_position.distance_to(target_pos) < 22.0:
		# 도착! 바라보고 말 걸기 (상자·NPC)
		var t := _quest_target
		stop_quest_move()
		player.face_toward(t.global_position)
		if t.has_method("interact"):
			t.interact(player)
		return Vector2.ZERO
	_repath_timer -= delta
	if _repath_timer <= 0.0 or _goal.distance_to(target_pos) > 12.0:
		_set_goal(target_pos)
	return _follow_path(delta, target_pos)


func _hunt_step(delta: float) -> Vector2:
	var me := player.global_position
	for k in _ignore.keys():
		_ignore[k] -= delta
		if _ignore[k] <= 0.0 or not is_instance_valid(k):
			_ignore.erase(k)
	# 1) 근처에 떨어진 아이템이 있으면 먼저 줍는다
	var pickup := _nearest(get_tree().get_nodes_in_group("pickups").filter(_can_pick), me, 110.0)
	if pickup:
		_hunt_target = pickup
		_retarget(pickup.global_position, delta, 0.3)
		return _follow_path(delta, pickup.global_position)
	# 2) 가장 가까운 적 (근처에 없으면 맵 전체에서)
	var enemies := get_tree().get_nodes_in_group("enemies").filter(func(e): return not _ignore.has(e))
	var enemy := _nearest(enemies, me, hunt_range)
	if enemy == null:
		enemy = _nearest(enemies, me, INF)
	if enemy == null:
		return Vector2.ZERO
	if enemy != _hunt_target:
		_swings = 0
	_hunt_target = enemy
	var to_enemy: Vector2 = enemy.global_position - me
	if to_enemy.length() < attack_reach + 6.0:
		# 칼은 상하좌우로만 휘두르므로, 적과 한 줄로 맞춘 뒤 공격한다
		if absf(to_enemy.x) >= absf(to_enemy.y):
			if absf(to_enemy.y) > 7.0:
				return Vector2(0, signf(to_enemy.y))
			_attack_dir = Vector2(signf(to_enemy.x), 0)
		else:
			if absf(to_enemy.x) > 7.0:
				return Vector2(signf(to_enemy.x), 0)
			_attack_dir = Vector2(0, signf(to_enemy.y))
		if not player.is_attacking:
			_swings += 1
			if _swings > 8:  # 여러 번 휘둘러도 안 맞으면 잠시 다른 적을 노린다
				_ignore[enemy] = 4.0
				_swings = 0
		return Vector2.ZERO
	_retarget(enemy.global_position, delta, 0.35)
	return _follow_path(delta, enemy.global_position)


func _can_pick(p: Node) -> bool:
	if _ignore.has(p):
		return false
	if p.get("kind") == 0 and player.hp >= player.max_hp:
		return false  # 체력이 가득이면 하트는 못 줍는다
	return not p.get("_collected")


func _nearest(nodes: Array, from: Vector2, max_dist: float) -> Node2D:
	var best: Node2D = null
	var best_d := max_dist
	for n in nodes:
		var d: float = from.distance_to(n.global_position)
		if d < best_d:
			best = n
			best_d = d
	return best


# ---------------- 길 따라가기 ----------------

func _retarget(pos: Vector2, delta: float, interval: float) -> void:
	_repath_timer -= delta
	if _repath_timer <= 0.0 or _goal.distance_to(pos) > 24.0:
		_set_goal(pos)
		_repath_timer = interval


func _set_goal(pos: Vector2) -> void:
	_goal = pos
	_repath_timer = 1.0
	var map = _map()
	_path = map.find_path(player.global_position, pos) if map else PackedVector2Array()


func _follow_path(delta: float, final_pos: Vector2) -> Vector2:
	var me := player.global_position
	# 막혀서 못 움직이면 길을 다시 찾는다
	if me.distance_to(_last_pos) < 0.3:
		_stuck_time += delta
		if _stuck_time > 0.6:
			_stuck_time = 0.0
			_stuck_count += 1
			if _stuck_count >= 3 and is_instance_valid(_hunt_target) and not is_quest_moving():
				# 몇 번을 다시 찾아도 못 가면, 그 대상은 잠시 포기하고 다른 걸 노린다
				_ignore[_hunt_target] = 6.0
				_stuck_count = 0
			_set_goal(final_pos)
	else:
		_stuck_time = 0.0
		_stuck_count = 0
	_last_pos = me
	while not _path.is_empty() and me.distance_to(_path[0]) < 4.0:
		_path.remove_at(0)
	if _path.is_empty():
		var d := final_pos - me
		return d.normalized() if d.length() > 3.0 else Vector2.ZERO
	return (_path[0] - me).normalized()
