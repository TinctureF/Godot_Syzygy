shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled;

// --- 颜色调节 ---
uniform vec4 color_mercury : source_color = vec4(0.9, 0.9, 0.95, 1.0); // 头部水银
uniform vec4 color_red_core : source_color = vec4(1.0, 0.1, 0.0, 1.0); // 红色能量核心
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;            // 红色发光强度
uniform float fresnel_power : hint_range(1.0, 8.0) = 4.0;

// --- 动态参数 ---
uniform float tail_speed = 4.0;
uniform float tail_amplitude = 0.18;
uniform sampler2D noise_tex;

// 平滑融合
float smooth_union(float d1, float d2, float k) {
	float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
	return mix(d2, d1, h) - k * h * (1.0 - h);
}

// 钝头三角形
float sdf_rounded_triangle(vec2 p, float r, float h) {
	const float k = sqrt(3.0);
	p.x = abs(p.x) - 1.0;
	p.y = p.y + k / 3.0;
	if (p.x + k * p.y > 0.0) p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
	p.x -= clamp(p.x, -2.0, 0.0);
	return -length(p) * sign(p.y) - r * h;
}

// 获取场景总距离场
float get_scene_dist(vec2 uv, float t) {
	vec2 head_uv = vec2(-uv.x, uv.y); 
	float sdf_head = sdf_rounded_triangle(head_uv / 0.4, 0.15, 0.4);

	vec2 p1 = vec2(0.2, sin(t) * tail_amplitude);
	float sdf_t1 = length(uv - p1) - 0.28;
	vec2 p2 = vec2(0.7, sin(t - 1.2) * tail_amplitude * 1.5);
	float sdf_t2 = length(uv - p2) - 0.22;
	vec2 p3 = vec2(1.2, sin(t - 2.4) * tail_amplitude * 2.0);
	float sdf_t3 = length(uv - p3) - 0.15;

	float tails = smooth_union(sdf_t1, sdf_t2, 0.35);
	tails = smooth_union(tails, sdf_t3, 0.35);
	
	float noise = texture(noise_tex, uv * 0.4 + vec2(t * 0.06, 0.0)).r;
	return smooth_union(sdf_head, tails, 0.45) + noise * 0.04;
}

void fragment() {
	vec2 uv = (UV - 0.5) * 2.8; // 稍微扩大画幅
	float t = TIME * tail_speed;

	float dist = get_scene_dist(uv, t);

	// 1. 重新构建法线（用于金属反射）
	vec2 e = vec2(0.01, 0.0);
	vec3 normal = normalize(vec3(
		get_scene_dist(uv - e.xy, t) - get_scene_dist(uv + e.xy, t),
		get_scene_dist(uv - e.yx, t) - get_scene_dist(uv + e.yx, t),
		0.08
	));

	// 2. 视觉效果：反射与边缘光
	float reflection = smoothstep(-0.3, 0.3, normal.y); 
	float rim = pow(1.0 - max(dot(normal, vec3(0.0, 0.0, 1.0)), 0.0), fresnel_power);

	// 3. --- 红色找回逻辑 ---
	// 调整 mask 范围：让红色从头部后方一点点开始，覆盖整个尾部
	float color_mask = smoothstep(-0.1, 0.8, uv.x); 
	
	// 水银底色
	vec3 mercury_base = color_mercury.rgb + (reflection * 0.15) + (rim * 0.5);
	
	// 红色能量色（添加 glow_intensity 增强视觉冲击力）
	vec3 energy_core = color_red_core.rgb * glow_intensity;

	// 最终颜色：在水银和红色核心之间进行插值
	// 我们使用 color_mask 的平方来让过渡更平滑，且在尾部更倾向于红色
	vec3 final_color = mix(mercury_base, energy_core, color_mask * color_mask);

	// 4. 透明度裁切
	float alpha = smoothstep(0.02, 0.0, dist);

	ALBEDO = final_color;
	ALPHA = alpha;
}