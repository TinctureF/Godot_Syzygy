shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// 在面板中调节这些参数
uniform sampler2D ring_texture;    // 之前建立的 1D 噪声纹理
uniform float stripe_density : hint_range(600.0, 2000.0) = 1200.0; // 极高频条纹
uniform float brightness : hint_range(1.0, 10.0) = 3.0;            // 自发光强度
uniform vec3 ring_color : source_color = vec3(0.8, 0.8, 0.9);      // 冷铅灰色
uniform vec3 warm_glow_color : source_color = vec3(1.0, 0.6, 0.3);

void fragment() {
	// 1. 定义 dist（修正之前的错误）：计算当前像素距离中心 (0.5, 0.5) 的距离
	float dist = distance(UV, vec2(0.5));
	
	// 2. 采样 1D 纹理：利用距离作为采样坐标
	// 纹理的高度设为 1，所以这里用 vec2(dist, 0.0) 采样
	vec4 tex_data = texture(ring_texture, vec2(dist, 0.0));
	
	// 3. 生成致密条纹算法：使用高频正弦波叠加噪声
	// stripe_density 设为 1200 左右可以消除稀疏感
	float pattern = sin(dist * stripe_density);
	pattern = smoothstep(0.2, 0.8, pattern * tex_data.r); // 结合噪声产生不均匀破碎感
	// 模拟一个来自侧方的伪暖光反射
    // dot(NORMAL, vec3(1,0,0)) 表示光从 X 轴正方向打过来
    float warm_reflection = pow(max(0.0, dot(NORMAL, vec3(0.7, 0.3, 0.5))), 4.0);
    
    // 将暖光叠加到自发光或反射中
    vec3 final_warmth = warm_glow_color * warm_reflection * 2.0;
	
	// 4. 设置物理属性以增加反光
	ALBEDO = ring_color * tex_data.rgb;
	METALLIC = 1.0;            // 全金属质感
	ROUGHNESS = 0.05;          // 极低粗糙度 = 镜面反射
	SPECULAR = 1.0;            // 增强镜面高光
	
	// 5. 关键：切线方向定义各向异性 (Anisotropy)
	// 这会让光线顺着圆环拉伸，形成丝绸般的反光
	TANGENT = normalize(cross(NORMAL, vec3(UV.x - 0.5, 0.0, UV.y - 0.5)));
	ANISOTROPY = 1.0;          // 开启各向异性
	
	// 6. 数字化自发光：解决“黑”的问题
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 3.0); // 边缘光
	EMISSION = ALBEDO * pattern * brightness + (ring_color * fresnel * 0.5);
	// 更新 EMISSION
    EMISSION += final_warmth * pattern;
	// 7. 透明度控制：让环带自然羽化
	ALPHA = pattern * tex_data.a * (1.0 - smoothstep(0.4, 0.5, dist));
}