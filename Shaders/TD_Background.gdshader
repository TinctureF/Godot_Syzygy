
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled; 

// 🚨 核心修复：加入 repeat_enable，告诉显卡这张图可以像地砖一样无限循环拼接！
uniform sampler2D static_bg_tex : source_color, repeat_enable; 
uniform sampler2D td_stream_tex : source_color; // TD 画面不需要循环，保持原样

uniform vec2 static_uv_scale = vec2(1.0, 1.0); 
uniform vec2 static_uv_offset = vec2(0.0, 0.0); 
uniform vec2 scroll_speed = vec2(0.05, 0.0); 

void fragment() {
    // 缩放 -> 偏移 -> 滚动
    vec2 scaled_uv = UV * static_uv_scale;
    vec2 adjusted_uv = scaled_uv + static_uv_offset;
    vec2 scrolling_uv = adjusted_uv + (TIME * scroll_speed);
    
    vec4 bg = texture(static_bg_tex, scrolling_uv);
    vec4 td = texture(td_stream_tex, UV); 
    
    // 混合
    ALBEDO = max(bg.rgb, td.rgb);
    ALPHA = max(bg.a, td.a); 
}