extends SceneTree
func _init():
	var tex: Texture2D = load("res://assets/sprites/player.png")
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var dirs := ["down", "left", "right", "up"]
	for row in 4:
		var d: String = dirs[row]
		var idle := "idle_" + d
		var walk := "walk_" + d
		sf.add_animation(idle); sf.set_animation_speed(idle, 1); sf.set_animation_loop(idle, true)
		sf.add_animation(walk); sf.set_animation_speed(walk, 8); sf.set_animation_loop(walk, true)
		var frames := []
		for col in 3:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * 16, row * 16, 16, 16)
			frames.append(at)
		sf.add_frame(idle, frames[0])
		for i in [1, 0, 2, 0]:
			sf.add_frame(walk, frames[i])
	print(ResourceSaver.save(sf, "res://assets/sprites/player_frames.tres"))
	quit()
