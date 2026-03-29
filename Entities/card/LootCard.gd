# LootCard.gd
# 掉落卡牌 - 可被玩家捡取
extends Area3D

## 卡牌数据
var card_data: CardObject = null
var from_enemy: bool = false  # 是否来自敌人掉落

var current_lifetime: float = 0.0
var fade_timer: float = 0.0
var fade_in_time: float = 1.0  # 由 LootDropper 传入
var fade_out_time: float = 1.0  # 由 LootDropper 传入
var lifetime: float = 10.0  # 由 LootDropper 传入

func _ready():
	body_entered.connect(_on_body_entered)
	collision_layer = 8
	collision_mask = 1
	add_to_group("loot_card")

	# 初始化时将所有材质设为完全透明
	_set_alpha(0.0)

func _physics_process(delta: float):
	# 渐显效果
	fade_timer += delta
	if fade_timer < fade_in_time:
		var alpha = fade_timer / fade_in_time
		_set_alpha(alpha)
	elif fade_timer >= fade_in_time and fade_timer < fade_in_time + 0.1:
		_set_alpha(1.0)  # 确保完全显示

	# 渐隐效果
	var remaining_time = lifetime - current_lifetime
	if remaining_time <= fade_out_time and remaining_time > 0:
		var alpha = remaining_time / fade_out_time
		_set_alpha(alpha)

	current_lifetime += delta
	if current_lifetime >= lifetime:
		_expire()

func _set_alpha(alpha: float):
	# 遍历所有MeshInstance3D设置透明度
	for child in get_children():
		if child is MeshInstance3D:
			var mat = child.get_surface_override_material(0)
			if mat == null:
				mat = child.mesh.surface_get_material(0)
			if mat:
				if mat is ShaderMaterial:
					mat.set_shader_parameter("fade_alpha", alpha)
				elif mat is StandardMaterial3D:
					if mat.transparency == 0:
						mat = mat.duplicate()
						mat.transparency = 1
						child.set_surface_override_material(0, mat)
					mat.albedo_color.a = alpha

func _on_body_entered(body: Node3D):
	if body.has_method("get_faction") and body.get_faction() == "player":
		_collect(body)

func _collect(player: Node3D) -> void:
	if not card_data:
		queue_free()
		return

	if player.has_method("add_card_to_hand"):
		var success = player.add_card_to_hand(card_data)
		if success:
			SignalBus.card_collected.emit(card_data)

			# 回复能量（捕获盲牌+3）
			if has_node("/root/DataVault"):
				get_node("/root/DataVault").record_energy(3.0)

			print("收集卡牌: ", card_data.get_display_name())

	queue_free()

func _expire() -> void:
	print("卡牌过期流失: ", card_data.get_display_name() if card_data else "unknown")
	if not from_enemy:
		SignalBus.card_expired.emit()
	queue_free()
