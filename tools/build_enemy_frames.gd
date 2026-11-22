extends SceneTree
# 적 애니메이션(SpriteFrames) 생성: 가로로 2프레임이 있는 그림 → "bounce" 애니메이션
func make(png: String, size: int, out: String, fps: float) -> void:
	var tex: Texture2D = load(png)
	var sf := SpriteFrames.new()
	sf.rename_animation("default", "bounce")
	sf.set_animation_speed("bounce", fps)
	for i in 2:
		var at := AtlasTexture.new(); at.atlas = tex; at.region = Rect2(i * size, 0, size, size)
		sf.add_frame("bounce", at)
	print(out, " ", ResourceSaver.save(sf, out))
func _init():
	make("res://assets/enemies/rock_slime.png", 16, "res://assets/enemies/rock_slime_frames.tres", 3)
	make("res://assets/enemies/hard_slime.png", 16, "res://assets/enemies/hard_slime_frames.tres", 2)
	make("res://assets/enemies/king_slime.png", 32, "res://assets/enemies/king_slime_frames.tres", 2)
	make("res://assets/enemies/golem.png", 24, "res://assets/enemies/golem_frames.tres", 2)
	quit()
