# PlayerController.gd
# 玩家控制器 - 移动和射击
extends CharacterBody2D

## 基础属性
@export var move_speed: float = 300.0
@export var max_hp: float = 100.0

var current_hp: float = 100.0
var faction: String = "player"

## 手牌系统
var current_hand: Array[CardObject] = []
const MAX_HAND_SIZE: int = 7

## 子节点引用
@onready var weapon_system = $WeaponSystem

func _ready():
	current_hp = max_hp
	# 设置碰撞层
	collision_layer = 1  # 玩家层
	collision_mask = 4   # 敌人层

func _physics_process(delta: float):
	# 移动输入
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")
	
	velocity = input_dir.normalized() * move_speed
	move_and_slide()
	
	# 限制在屏幕范围内
	var screen_size = get_viewport_rect().size
	position.x = clampf(position.x, 20, screen_size.x - 20)
	position.y = clampf(position.y, 20, screen_size.y - 20)
	
	# 自动射击
	if weapon_system:
		weapon_system.try_fire()

## 受到伤害
func take_damage(damage: float) -> void:
	current_hp -= damage
	
	# 发送信号
	SignalBus.player_hit.emit(damage)
	
	# 闪烁效果
	_flash_red()
	
	if current_hp <= 0:
		_die()

## 死亡
func _die() -> void:
	SignalBus.game_over.emit(false)
	queue_free()

## 闪红效果
func _flash_red() -> void:
	if has_node("Sprite2D"):
		var sprite = get_node("Sprite2D")
		sprite.modulate = Color(2, 0.5, 0.5, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color(1, 1, 1, 1)

## 获取阵营
func get_faction() -> String:
	return faction

## 添加卡牌到手牌
func add_card_to_hand(card: CardObject) -> bool:
	if current_hand.size() >= MAX_HAND_SIZE:
		# 满手牌时的处理（MVP简化：直接丢弃）
		return false
	
	current_hand.append(card)
	SignalBus.hand_changed.emit(current_hand)
	return true

## 从手牌移除卡牌
func remove_cards_from_hand(cards: Array[CardObject]) -> void:
	for card in cards:
		current_hand.erase(card)
	SignalBus.hand_changed.emit(current_hand)
