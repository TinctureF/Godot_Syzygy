# LootDropper.gd
# 掉落管理器 - 敌人死亡掉落 + 自然掉落
extends Node
const CardSlotScene = preload("res://UI/CardSlot.tscn")

@export var loot_card_scene: PackedScene

## 自然掉落配置（可在检查器中修改）
@export var spawn_interval: float = 5.0  # 生成时间间隔（秒）
@export var spawn_max: int = 9  # 同屏最高数量
@export var fade_in_time: float = 1.0
@export var fade_out_time: float = 1.0 # 渐显时间（秒）
@export var lifetime: float = 10.0  # 续存时间（秒）

var natural_spawn_timer: float = 0.0
var current_natural_cards: int = 0

func _ready():
	if not loot_card_scene:
		loot_card_scene = load("res://Entities/card/Lootcard.tscn")
	SignalBus.enemy_died.connect(_on_enemy_died)
	SignalBus.card_expired.connect(_on_card_expired)

func _on_card_expired() -> void:
	current_natural_cards = max(0, current_natural_cards - 1)

func _process(delta: float):
	# 自然掉落
	natural_spawn_timer += delta
	if natural_spawn_timer >= spawn_interval:
		if current_natural_cards < spawn_max:
			natural_spawn_timer = 0.0
			_spawn_natural_card()

## 敌人死亡掉落 - 不再生成 3D 掉落物，抽牌由 BaseEnemy 直接触发
func _on_enemy_died(_enemy_data: Dictionary) -> void:
	# 敌机死亡不再掉落盲牌，卡牌直接由 BaseEnemy 发出 enemy_killed_for_card 信号添加
	pass

## 生成掉落卡牌
func _spawn_loot_card(pos: Vector2, from_enemy: bool) -> void:
	# 【添加这三行防爆开关，让它闭嘴】
	if loot_card_scene == null:
		# print("【战术静默】暂无掉落实体场景，跳过掉落逻辑。")
		return

	var deck_library = get_node_or_null("/root/DeckLibrary")
	# ... 下面的代码保持不变 ...
	if not deck_library:
		return

	var card = deck_library.draw_card()
	if not card:
		return

	var loot_card = loot_card_scene.instantiate()
	loot_card.card_data = card
	loot_card.from_enemy = from_enemy
	loot_card.fade_in_time = fade_in_time
	loot_card.lifetime = lifetime

	get_tree().root.add_child(loot_card)

	# 2D 屏幕坐标 → 3D 世界坐标
	var camera = get_viewport().get_camera_3d()
	if camera:
		var origin = camera.project_ray_origin(pos)
		var ray_dir = camera.project_ray_normal(pos)
		var z_depth = 0.0
		var t = (z_depth - origin.z) / ray_dir.z
		var world_pos = origin + ray_dir * t
		loot_card.global_position = world_pos

	if from_enemy:
		current_natural_cards += 1

## 生成掉落卡牌（3D 世界坐标版本 - 用于敌人掉落）
func _spawn_loot_card_3d(world_pos: Vector3, from_enemy: bool) -> void:
	if loot_card_scene == null:
		return

	var deck_library = get_node_or_null("/root/DeckLibrary")
	if not deck_library:
		return

	var card = deck_library.draw_card()
	if not card:
		return

	var loot_card = loot_card_scene.instantiate()
	loot_card.card_data = card
	loot_card.from_enemy = from_enemy
	loot_card.fade_in_time = fade_in_time
	loot_card.lifetime = lifetime

	get_tree().root.add_child(loot_card)

	# 直接使用 3D 世界坐标
	loot_card.global_position = world_pos

	if from_enemy:
		current_natural_cards += 1

## 自然掉落（使用区域排除逻辑）
func _spawn_natural_card() -> void:
	var screen_size = get_tree().root.get_visible_rect().size
	print("[DEBUG] screen_size: ", screen_size)  # 排查 screen_size 是否准确

	var margin = 200.0  # 基础边缘边距

	# 1. 定义左上角的"禁区" (根据你截图红圈的大小调整)
	# 假设红圈范围是左上角 400x400 的区域
	var forbidden_zone = Rect2(Vector2(0, 0), Vector2(400, 400))

	# 2. 在屏幕安全范围内随机取一个点
	var pos = Vector2(
		randf_range(margin, screen_size.x - margin),
		randf_range(margin, screen_size.y - margin)
	)
	print("[DEBUG] 原始生成位置: ", pos)  # 排查原始坐标

	# 3. 核心逻辑：如果随机点落在禁区内，进行"重定向"
	if forbidden_zone.has_point(pos):
		# 方案 A：直接把点推到禁区边缘之外（最省事）
		# 我们把点往右或者往下推，哪边近推哪边
		if pos.x < pos.y:
			pos.y = forbidden_zone.end.y + 50 # 推到禁区下方 50 像素
		else:
			pos.x = forbidden_zone.end.x + 50 # 推到禁区右侧 50 像素
		print("[DEBUG] 禁区重定向后: ", pos)  # 排查重定向后的坐标

	_spawn_loot_card(pos, false)
	current_natural_cards += 1

## 卡牌被收集后回调
func on_card_collected() -> void:
	current_natural_cards = max(0, current_natural_cards - 1)
