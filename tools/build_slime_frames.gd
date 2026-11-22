extends SceneTree
func _init():
	var tex: Texture2D = load("res://assets/enemies/slime.png")
	var sf := SpriteFrames.new()
	sf.rename_animation("default", "bounce")
	sf.set_animation_speed("bounce", 3)
	sf.set_animation_loop("bounce", true)
	for i in 2:
		var at := AtlasTexture.new(); at.atlas = tex; at.region = Rect2(i * 16, 0, 16, 16)
		sf.add_frame("bounce", at)
	print(ResourceSaver.save(sf, "res://assets/enemies/slime_frames.tres"))
	quit()
