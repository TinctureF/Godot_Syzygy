extends WorldEnvironment

# 闪烁频率（数字化压迫感建议设为较慢的频率）
@export var blink_speed : float = 1.5 
# 闪烁幅度
@export var amplitude : float = 0.01

func _process(delta):
	# 使用 sin 函数制造循环
	var time = Time.get_ticks_msec() * 0.001
	var pulse = (sin(time * blink_speed) + 0.8) / 2.0 
	
	# 动态修改 Glow 的 Intensity（强度）
	# 这样亮的星星会随着脉冲产生“发光->收敛”的循环
	environment.glow_intensity = 0.02 + pulse * amplitude
	
	# 如果你想增加一点“数字化不稳定感”，可以加微小的随机噪点
	if randf() > 0.98:
		environment.glow_intensity += 0.2
