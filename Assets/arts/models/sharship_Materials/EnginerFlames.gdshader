shader_type spatial;
render_mode blend_add, unshaded; // 对应 Blender 的“混合着色器”和“自发光”

uniform sampler2D color_ramp; // 在检查器里给它分配一个 GradientTexture1D
uniform float speed = 2.0;
uniform float scale_y = 3.0;
uniform float emission_value = 25.0;

void fragment() {
    // 1. 对应 Blender 的 Mapping 节点：让 UV 随时间滚动实现动态喷射
    vec2 moving_uv = UV;
    moving_uv.x -= TIME * speed; 
    
    // 2. 对应 Blender 的渐变纹理 (Gradient Texture)
    // 我们利用 UV 的 X 轴产生水平渐变，利用 Y 轴产生上下向中心的收缩渐变
    float gradient = (1.0 - UV.x) * (1.0 - abs(UV.y - 0.5) * 2.0);
    
    // 3. 对应 Blender 的颜色渐变 (ColorRamp)：采样我们定义的渐变色
    vec4 final_color = texture(color_ramp, vec2(gradient, 0.5));
    
    // 4. 对应 Blender 的透明 BSDF 混合：通过采样 Alpha 来控制透明度
    ALBEDO = final_color.rgb;
    ALPHA = final_color.a * gradient;
    
    // 增加自发光强度，符合你文档中的“双环灯带”视觉
    EMISSION = ALBEDO * emission_value;
}