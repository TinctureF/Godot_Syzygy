# LootCard.gd
# 掉落卡牌 - 可被玩家捡取
extends Area2D

## 卡牌数据
var card_data: CardObject = null

## 移动参数
var drift_speed: float = -50.0  # 向左飘移
var lifetime: float = 5.0
var current_lifetime: float = 0.0

func _ready():
	# 连接碰撞检测
	body_entered.connect(_on_body_entered)
	
	# 设置碰撞层
	collision_layer = 8  # 掉落物层
	collision_mask = 1   # 玩家层
	
	# 显示卡牌信息（简化：在Sprite上显示）
	if card_data and has_node("Label"):
		$Label.text = card_data.get_display_name()

func _physics_process(delta: float):
	# 向左飘移
	position.x += drift_speed * delta
	
	# 生命周期
	current_lifetime += delta
	if current_lifetime >= lifetime:
		_expire()

## 被玩家捡到
func _on_body_entered(body: Node2D):
	if body.has_method("get_faction") and body.get_faction() == "player":
		_collect(body)

## 收集卡牌
func _collect(player: Node2D) -> void:
	if not card_data:
		queue_free()
		return
	
	# 尝试添加到手牌
	if player.has_method("add_card_to_hand"):
		var success = player.add_card_to_hand(card_data)
		if success:
			# 发送信号
			SignalBus.card_collected.emit(card_data)
			print("收集卡牌: ", card_data.get_display_name())
	
	# 销毁
	queue_free()

## 过期销毁
func _expire() -> void:
	print("卡牌过期流失: ", card_data.get_display_name() if card_data else "unknown")
	queue_free()
