shader_type spatial;
// blend_mix 启用混合模式，cull_disabled 确保正反都能看到，unshaded 禁用引擎光照
render_mode blend_mix, cull_disabled, unshaded;

uniform vec4 body_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform float speed = 2.0;
uniform sampler2D noise_tex; // 必须在检查器里给它赋值！
uniform float fade_alpha : hint_range(0.0, 1.0) = 1.0; // 渐显透明度

float smooth_union(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

void fragment() {
    // 3D 中使用 UV，映射到 -1 到 1
    vec2 uv = (UV - 0.5) * 2.0;
    float t = TIME * speed;

    // 律动逻辑
    vec2 p1 = vec2(sin(t * 0.7), cos(t * 1.2)) * 0.3;
    vec2 p2 = vec2(cos(t * 1.5), sin(t * 0.8)) * 0.4;

    // 纹理扰动：如果没有 noise_tex，这里会出错
    float noise = texture(noise_tex, uv + t * 0.1).r * 0.15;

    float d1 = length(uv - p1) - (0.2 + noise);
    float d2 = length(uv - p2) - (0.15 + noise);

    float field = smooth_union(d1, d2, 0.2);
    float mask = smoothstep(0.02, 0.0, field);

    // 在 3D 中，输出颜色用 ALBEDO，透明度用 ALPHA
    ALBEDO = body_color.rgb;
    ALPHA = mask * fade_alpha; // 这里决定了它是”病毒形”还是”方形”
}