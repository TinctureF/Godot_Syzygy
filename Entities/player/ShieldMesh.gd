extends MeshInstance3D

func _ready():
	SignalBus.player_shield_changed.connect(_on_shield_changed)
	visible = false  # 初始隐藏

func _on_shield_changed(current_shield: float, max_shield: float):
	if current_shield <= 0:
		visible = false
	else:
		visible = true
		var mat = get_active_material(0) as ShaderMaterial
		if mat:
			var ratio = current_shield / max_shield
			mat.set_shader_parameter("intensity", ratio * 2.0)
			if ratio < 0.3:
				mat.set_shader_parameter("pulse_speed", 4.0)
			else:
				mat.set_shader_parameter("pulse_speed", 1.0)
