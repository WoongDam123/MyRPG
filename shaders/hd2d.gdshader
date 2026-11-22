// 2.5D(HD-2D 느낌) 화면 효과
// - 틸트시프트: 화면 위·아래를 흐리게 해서 미니어처를 내려다보는 느낌
// - 블룸: 밝은 곳이 은은하게 번짐
// - 비네트: 가장자리를 살짝 어둡게
// - 색감: 채도·따뜻함·대비
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float blur_strength = 2.2;     // 흐림 정도 (기준 해상도 픽셀)
uniform float focus_center = 0.55;     // 또렷한 띠의 세로 위치 (0 위 ~ 1 아래)
uniform float focus_width = 0.22;      // 또렷한 띠의 두께
uniform float bloom = 0.22;
uniform float bloom_threshold = 0.72;
uniform float vignette = 0.32;
uniform float saturation = 1.08;
uniform float contrast = 1.04;
uniform vec3 tint = vec3(1.03, 1.0, 0.95);  // 따뜻한 색감

const vec2 TAPS[12] = vec2[](
	vec2(-0.326, -0.406), vec2(-0.840, -0.074), vec2(-0.696, 0.457), vec2(-0.203, 0.621),
	vec2(0.962, -0.195), vec2(0.473, -0.480), vec2(0.519, 0.767), vec2(0.185, -0.893),
	vec2(0.507, 0.064), vec2(0.896, 0.412), vec2(-0.322, -0.933), vec2(-0.792, -0.598)
);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE * (1.0 / max(SCREEN_PIXEL_SIZE.y * 360.0, 0.0001));  // 기준 해상도 1픽셀
	vec3 sharp = texture(screen_tex, uv).rgb;

	float d = abs(uv.y - focus_center);
	float amount = smoothstep(focus_width, focus_width + 0.3, d) * blur_strength;

	vec3 blur = sharp;
	vec3 glow = vec3(0.0);
	if (amount > 0.01 || bloom > 0.0) {
		vec3 acc = sharp;
		for (int i = 0; i < 12; i++) {
			vec3 c = texture(screen_tex, uv + TAPS[i] * px * max(amount, 0.0) * 1.6).rgb;
			acc += c;
			vec3 g = texture(screen_tex, uv + TAPS[i] * px * 5.0).rgb;
			glow += max(g - vec3(bloom_threshold), vec3(0.0));
		}
		blur = acc / 13.0;
		glow /= 12.0;
	}
	vec3 col = (amount > 0.01) ? blur : sharp;
	col += glow * bloom * 2.5;

	// 색감
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);
	col = (col - 0.5) * contrast + 0.5;
	col *= tint;

	// 비네트
	vec2 v = uv - 0.5;
	v.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float vig = smoothstep(0.35, 0.95, length(v) * 0.9);
	col *= 1.0 - vig * vignette;

	COLOR = vec4(col, 1.0);
}
