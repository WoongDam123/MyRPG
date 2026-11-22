extends CanvasLayer
## 2.5D 화면 효과 (전역 "PostFX"): 틸트시프트·블룸·비네트·색감 + 떠다니는 입자.
## 맵마다 분위기(profile)를 고른다: "outdoor"(들판) / "indoor"(실내) / "cave"(동굴) / "off"(끔)
## 그래픽이 버거운 휴대폰에서는 GameState.fx_enabled = false 로 끌 수 있다.

const PROFILES := {
	"outdoor": {"blur_strength": 2.2, "focus_center": 0.56, "focus_width": 0.2, "bloom": 0.22, "vignette": 0.3,
		"saturation": 1.1, "contrast": 1.04, "tint": Vector3(1.03, 1.0, 0.94), "particles": "pollen"},
	"indoor": {"blur_strength": 1.2, "focus_center": 0.55, "focus_width": 0.24, "bloom": 0.18, "vignette": 0.42,
		"saturation": 1.04, "contrast": 1.03, "tint": Vector3(1.06, 0.99, 0.9), "particles": "dust"},
	"cave": {"blur_strength": 1.8, "focus_center": 0.55, "focus_width": 0.2, "bloom": 0.35, "vignette": 0.55,
		"saturation": 1.0, "contrast": 1.08, "tint": Vector3(0.94, 0.97, 1.06), "particles": "dust"},
}

var _rect: ColorRect
var _mat: ShaderMaterial
var _particles: CPUParticles2D


func _ready() -> void:
	layer = 5  # 게임 화면(0) 위, HUD(10) 아래
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/hd2d.gdshader")
	_rect.material = _mat
	add_child(_rect)
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	add_child(_particles)
	apply("off")
	get_viewport().size_changed.connect(_fit_particles)


func apply(profile: String) -> void:
	if profile == "off" or not GameState.fx_enabled or not PROFILES.has(profile):
		_rect.visible = false
		_particles.emitting = false
		_particles.visible = false
		return
	var p: Dictionary = PROFILES[profile]
	for k in p:
		if k != "particles":
			_mat.set_shader_parameter(k, p[k])
	_rect.visible = true
	_setup_particles(p.particles)


func _setup_particles(kind: String) -> void:
	var pt := _particles
	pt.visible = true
	pt.amount = 26 if kind == "pollen" else 18
	pt.lifetime = 7.0
	pt.preprocess = 7.0
	pt.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pt.direction = Vector2(1, -0.3) if kind == "pollen" else Vector2(0.2, -1)
	pt.spread = 40.0
	pt.gravity = Vector2.ZERO
	pt.initial_velocity_min = 4.0
	pt.initial_velocity_max = 12.0
	pt.scale_amount_min = 1.0
	pt.scale_amount_max = 2.0
	var grad := Gradient.new()
	var c := Color(1.0, 0.95, 0.7) if kind == "pollen" else Color(0.85, 0.85, 0.95)
	grad.set_color(0, Color(c, 0.0))
	grad.add_point(0.2, Color(c, 0.75))
	grad.add_point(0.8, Color(c, 0.6))
	grad.set_color(grad.get_point_count() - 1, Color(c, 0.0))
	pt.color_ramp = grad
	_fit_particles()
	pt.emitting = true


func _fit_particles() -> void:
	var size := get_viewport().get_visible_rect().size
	_particles.position = size / 2
	_particles.emission_rect_extents = size / 2
