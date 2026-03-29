# BuffAssembler.gd
# Buff组装器 - 实现具体Buff效果
extends Node

## 当前Buff状态
var current_buff: Dictionary = {
	"multiplier": 1.0,
	"fire_rate": 1.0,
	"has_combo": false,
	"combo_type": ""
}

## 特殊效果状态
var active_effects: Dictionary = {
	"shield": 0,           # 护盾剩余次数
	"fatal_shield": false, # 致命屏障是否激活
	"fatal_dash": false,   # 致命Dash是否激活
	"slow_heal_timer": 0.0,
	"slow_heal_amount": 0.0,
	"cluster_missiles": 0,
	"death_ray_active": false,
	"free_dashes": 0,
	"free_time_warps": 0
}

## 胡牌等级
enum HuType { NONE, DAWN, ASCEND, ANNIHILATION }
var hu_type: HuType = HuType.NONE
var registry_sets: int = 0  # 已打出的面子数

func _ready():
	SignalBus.hand_changed.connect(_on_hand_changed)

## 手牌变化时重新计算Buff
func _on_hand_changed(hand: Array) -> void:
	var evaluator = get_node_or_null("/root/HandEvaluator")
	if not evaluator:
		return

	current_buff = evaluator.evaluate_hand(hand)
	SignalBus.buff_updated.emit(current_buff)

## 应用顺子/刻子效果（打出时调用）
func apply_combo_effect(buff: Dictionary) -> void:
	if not buff.has("buff_type"):
		return

	var effect_data = buff.get("effect_data", {})
	match buff.buff_type:
		# === 顺子效果 ===
		1: # FIRE_METEOR - 火流星
			_apply_fire_meteor(effect_data)
		2: # CLUSTER_BOMB - 集束雷
			_apply_cluster_bomb(effect_data)
		3: # DEATH_RAY - 死光
			_apply_death_ray(effect_data)
		4: # SLOW_HEAL - 缓慢回血
			_apply_slow_heal(effect_data)
		5: # SHIELD - 护盾
			_apply_shield(effect_data)
		6: # INSTANT_HEAL - 瞬间回血
			_apply_instant_heal(effect_data)
		7: # FREE_DASH - 免费Dash
			_apply_free_dash(effect_data)
		8: # ENERGY_BOOST - 能量回复
			_apply_energy_boost(effect_data)
		9: # FREEZE_TIME - 免费时控
			_apply_freeze_time(effect_data)
		# === 刻子效果 ===
		10: # EXPLOSION - 爆裂
			_apply_explosion(effect_data)
		11: # FATAL_SHIELD - 致命屏障
			active_effects.fatal_shield = true
		12: # FATAL_DASH - 致命Dash
			active_effects.fatal_dash = true

	print("[BuffAssembler] 应用效果: ", buff.get("name", ""))

## 火流星 - 子弹溅射
func _apply_fire_meteor(data: Dictionary) -> void:
	# 效果在WeaponSystem中实现：发射时带溅射
	current_buff.splash_damage = data.get("splash_damage", 0.8)
	current_buff.splash_count = data.get("splash_count", 3)

## 集束雷 - 追踪飞弹
func _apply_cluster_bomb(data: Dictionary) -> void:
	active_effects.cluster_missiles = data.get("missile_count", 5)
	current_buff.cluster_missiles = active_effects.cluster_missiles

## 死光 - 持续射线
func _apply_death_ray(data: Dictionary) -> void:
	active_effects.death_ray_active = true
	active_effects.death_ray_damage = data.get("damage_per_tick", 0.5)
	active_effects.death_ray_duration = data.get("duration", 10.0)

## 缓慢回血
func _apply_slow_heal(data: Dictionary) -> void:
	active_effects.slow_heal_timer = data.get("duration", 20.0)
	active_effects.slow_heal_amount = data.get("heal_per_second", 1.0)

## 护盾
func _apply_shield(data: Dictionary) -> void:
	active_effects.shield = data.get("block_count", 3)
	SignalBus.buff_updated.emit({"shield": active_effects.shield})

## 瞬间回血
func _apply_instant_heal(data: Dictionary) -> void:
	var heal_amount = data.get("heal_amount", 20.0)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("heal"):
		player.heal(heal_amount)

## 免费Dash
func _apply_free_dash(data: Dictionary) -> void:
	active_effects.free_dashes += data.get("dash_count", 2)

## 能量回复
func _apply_energy_boost(data: Dictionary) -> void:
	var energy = data.get("energy_amount", 40)
	if has_node("/root/DataVault"):
		get_node("/root/DataVault").record_energy(energy)

## 免费时控
func _apply_freeze_time(data: Dictionary) -> void:
	active_effects.free_time_warps += data.get("time_warp_count", 3)

## 爆裂 - AOE清场
func _apply_explosion(data: Dictionary) -> void:
	var damage = data.get("damage", 15.0)
	var radius = data.get("radius", 200.0)
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# 查找范围内的敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy is Node2D:
			var dist = player.position.distance_to(enemy.position)
			if dist <= radius:
				enemy.take_damage(damage)

	print("[BuffAssembler] 爆裂AOE造成", damage, "伤害，半径", radius)

## 处理持续效果（每帧调用）
func _process_effects(delta: float, player) -> void:
	# 缓慢回血
	if active_effects.slow_heal_timer > 0:
		active_effects.slow_heal_timer -= delta
		if player and player.has_method("heal"):
			player.heal(active_effects.slow_heal_amount * delta)

## 检查并消耗护盾
func consume_shield() -> bool:
	if active_effects.shield > 0:
		active_effects.shield -= 1
		SignalBus.buff_updated.emit({"shield": active_effects.shield})
		return true
	return false

## 检查致命屏障
func check_fatal_shield() -> bool:
	if active_effects.fatal_shield:
		active_effects.fatal_shield = false
		return true
	return false

## 检查致命Dash
func check_fatal_dash() -> bool:
	if active_effects.fatal_dash:
		active_effects.fatal_dash = false
		return true
	return false

## 胡牌处理
func on_hu(sets: int) -> void:
	registry_sets += sets

	# 根据面子数确定胡牌等级
	if registry_sets >= 5:
		hu_type = HuType.ANNIHILATION
		_apply_annihilation()
	elif registry_sets >= 4:
		hu_type = HuType.ASCEND
		_apply_ascend()
	elif registry_sets >= 3:
		hu_type = HuType.DAWN
		_apply_dawn()

	print("[BuffAssembler] 胡牌！等级:", HuType.keys()[hu_type], " 面子数:", registry_sets)

## 破晓（3组）
func _apply_dawn() -> void:
	current_buff.multiplier = 1.5
	current_buff.fire_rate_multiplier = 1.5
	SignalBus.buff_updated.emit(current_buff)

	# 15秒后效果结束
	await get_tree().create_timer(15.0).timeout
	if hu_type == HuType.DAWN:
		_reset_combat_buff()

## 凌霄（4组）
func _apply_ascend() -> void:
	current_buff.multiplier = 2.5
	current_buff.piercing = true  # 子弹穿透
	SignalBus.buff_updated.emit(current_buff)

	# 30秒后效果结束
	await get_tree().create_timer(30.0).timeout
	if hu_type == HuType.ASCEND:
		_reset_combat_buff()

## 湮灭（5组）
func _apply_annihilation() -> void:
	current_buff.multiplier = 4.5
	current_buff.global_bonus = true
	SignalBus.buff_updated.emit(current_buff)

	# 时空凝滞3秒
	SignalBus.request_time_warp.emit(0.1)

	# 20秒后效果结束
	await get_tree().create_timer(20.0).timeout
	if hu_type == HuType.ANNIHILATION:
		_reset_combat_buff()

## 重置战斗Buff
func _reset_combat_buff() -> void:
	hu_type = HuType.NONE
	current_buff.multiplier = 1.0
	current_buff.fire_rate_multiplier = 1.0
	current_buff.piercing = false
	current_buff.global_bonus = false
	SignalBus.buff_updated.emit(current_buff)

## 获取当前Buff
func get_current_buff() -> Dictionary:
	return current_buff

## 获取有效效果
func get_active_effects() -> Dictionary:
	return active_effects

## 重置
func reset() -> void:
	current_buff = {
		"multiplier": 1.0,
		"fire_rate": 1.0,
		"has_combo": false,
		"combo_type": ""
	}
	active_effects = {
		"shield": 0,
		"fatal_shield": false,
		"fatal_dash": false,
		"slow_heal_timer": 0.0,
		"slow_heal_amount": 0.0,
		"cluster_missiles": 0,
		"death_ray_active": false,
		"free_dashes": 0,
		"free_time_warps": 0
	}
	hu_type = HuType.NONE
	registry_sets = 0
	SignalBus.buff_updated.emit(current_buff)
