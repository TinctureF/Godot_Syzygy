extends Node3D

@onready var particles = $GPUParticles3D

func _ready():
	# 确保 One Shot 已开启
	particles.emitting = true
	# 在 Lifetime 结束后自动删除整个场景
	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
