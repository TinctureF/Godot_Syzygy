extends Node3D

# 旋转速度：数值越小越显得巨大、沉重
# 0.02 约为每秒旋转 1 度左右，适合这种宏大的视觉背景
@export var rotation_speed : float = 0.02 

func _process(delta):
	# rotate_y 是绕垂直轴旋转
	# delta 是帧间隔时间，乘以它能确保无论电脑卡不卡，转速都是匀速的
	rotate_y(rotation_speed * delta)
	
	# 如果你还想要文档中提到的“巨大城市废墟缓缓移动”的微弱漂浮感 
	# 可以取消下面两行的注释：
	# var hover = sin(Time.get_ticks_msec() * 0.001) * 0.005
	# position.y += hover
