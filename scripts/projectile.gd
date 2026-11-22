extends Area2D
## 수정 탄환: 날아가다가 적에게 맞으면 피해를 주고 사라진다. 벽·나무에 닿아도 사라진다.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 220.0
var damage: int = 1
var _life: float = 0.8


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(damage, global_position - direction * 8.0)
	elif body.is_in_group("player"):
		return
	queue_free()
