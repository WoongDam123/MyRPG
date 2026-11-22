extends SceneTree
# 2.5D 캐릭터·적 애니메이션(SpriteFrames) 생성
# 캐릭터 그림: 32x32 칸, 줄 = 아래·왼쪽·오른쪽·위, 칸 = 대기 0-1 / 걷기 2-5 / 공격 6-8

func char_frames(png: String, out: String) -> void:
	var tex: Texture2D = load(png)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var dirs := ["down", "left", "right", "up"]
	for row in 4:
		for anim in [["idle", [0, 1], 2.0, true], ["walk", [2, 3, 4, 5], 9.0, true], ["attack", [6, 7, 8], 12.0, false]]:
			var name: String = anim[0] + "_" + dirs[row]
			sf.add_animation(name)
			sf.set_animation_speed(name, anim[2])
			sf.set_animation_loop(name, anim[3])
			for col in anim[1]:
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(col * 32, row * 32, 32, 32)
				sf.add_frame(name, at)
	print(out, " ", ResourceSaver.save(sf, out))


func enemy_frames(png: String, w: int, h: int, out: String, fps: float) -> void:
	var tex: Texture2D = load(png)
	var sf := SpriteFrames.new()
	sf.rename_animation("default", "bounce")
	sf.set_animation_speed("bounce", fps)
	for i in tex.get_width() / w:
		var at := AtlasTexture.new(); at.atlas = tex; at.region = Rect2(i * w, 0, w, h)
		sf.add_frame("bounce", at)
	print(out, " ", ResourceSaver.save(sf, out))


func _init():
	for look in ["hero", "granite_knight", "steel_fighter", "quartz_mage"]:
		char_frames("res://assets/characters/%s.png" % look, "res://assets/characters/%s_frames.tres" % look)
	enemy_frames("res://assets/enemies/slime.png", 24, 22, "res://assets/enemies/slime_frames.tres", 6)
	enemy_frames("res://assets/enemies/rock_slime.png", 24, 22, "res://assets/enemies/rock_slime_frames.tres", 5)
	enemy_frames("res://assets/enemies/hard_slime.png", 24, 22, "res://assets/enemies/hard_slime_frames.tres", 4)
	enemy_frames("res://assets/enemies/king_slime.png", 44, 44, "res://assets/enemies/king_slime_frames.tres", 4)
	enemy_frames("res://assets/enemies/golem.png", 36, 40, "res://assets/enemies/golem_frames.tres", 4)
	quit()
