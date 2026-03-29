shader_type spatial;
// 移除无效的 billboard，保留必要的渲染模式
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 shield_color : source_color = vec4(0.3, 0.5, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;
uniform float intensity : hint_range(0.0, 5.0) = 1.0;

// 手动实现 Billboard 逻辑：让物体的模型矩阵始终对齐相机
void vertex() {
	// 获取模型矩阵的缩放信息
	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);
	float scale_z = length(MODEL_MATRIX[2].xyz);
	
	// 将视图矩阵的转置（即相机的旋转）应用到模型矩阵
	// 这样无论相机在哪，QuadMesh 都会正对着相机面
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(scale_x, 0.0, 0.0, 0.0),
		vec4(0.0, scale_y, 0.0, 0.0),
		vec4(0.0, 0.0, scale_z, 0.0),
		MODEL_MATRIX[3]
	);
}

void fragment() {
    // 保持之前的逻辑：创造圆形发光效果
    vec2 center_uv = UV - vec2(0.5);
    float dist = length(center_uv);
    
    // 圆形遮罩与圆环
    float alpha_mask = smoothstep(0.5, 0.4, dist);
    float pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
    
    // 数字化噪点 
    float noise = fract(sin(dot(UV + TIME * 0.1, vec2(12.9898, 78.233))) * 43758.5453);
    
    ALBEDO = shield_color.rgb * (pulse + noise * 0.1);
    ALPHA = alpha_mask * shield_color.a * intensity * pulse;
}