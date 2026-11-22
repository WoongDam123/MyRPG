extends Control
## 반짝이는 별이 흩뿌려진 우주 배경 (그림 파일 없이 코드로 그린다).

@export var star_count: int = 140
@export var bg_color: Color = Color(0.03, 0.02, 0.08)

var _stars: Array = []  # [위치(0~1 비율), 크기, 반짝이는 속도, 시작 위상, 색]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var colors := [Color(1, 1, 1), Color(0.8, 0.85, 1), Color(1, 0.9, 0.75), Color(0.85, 0.75, 1)]
	for i in star_count:
		_stars.append([Vector2(rng.randf(), rng.randf()), 1 if rng.randf() < 0.85 else 2,
				rng.randf_range(1.0, 3.5), rng.randf() * TAU, colors[rng.randi() % colors.size()]])


func _process(_delta: float) -> void:
	queue_redraw()  # 매 프레임 다시 그려서 반짝이게


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	var t := Time.get_ticks_msec() / 1000.0
	for s in _stars:
		var a: float = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * s[2] + s[3]))
		var c: Color = s[4]
		c.a = a
		var p: Vector2 = (s[0] * size).floor()
		draw_rect(Rect2(p, Vector2(s[1], s[1])), c)
