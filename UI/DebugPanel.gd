# DebugPanel.gd
# MVP调试面板 - 实时显示游戏状态
extends CanvasLayer

@onready var label = $DebugLabel

func _ready():
	# 确保在最上层
	layer = 100

func _process(_delta: float):
	if not is_instance_valid(label):
		return
	
	var text = "=== CporA MVP Debug Panel ===\n"
	
	# 获取玩家信息
	var player = get_tree().get_first_node_in_group("player")
	if player:
		text += "玩家血量: %.0f HP\n" % player.current_hp
		text += "手牌数量: %d/7\n" % player.current_hand.size()
		
		# 显示手牌
		if player.current_hand.size() > 0:
			text += "手牌: "
			for card in player.current_hand:
				text += card.get_display_name() + " "
			text += "\n"
	
	# 获取牌库信息
	var deck = get_node_or_null("/root/DeckLibrary")
	if deck:
		text += "剩余牌数: %d/144\n" % deck.get_remaining_cards()
	
	# 获取DataVault信息
	var vault = get_node_or_null("/root/DataVault")
	if vault:
		text += "击杀数: %d\n" % vault.enemies_killed
		text += "收集卡牌: %d\n" % vault.cards_collected
		text += "当前能量: %.0f\n" % vault.energy
	
	# 获取Buff信息
	var buff_assembler = get_tree().get_first_node_in_group("buff_assembler")
	if not buff_assembler:
		# 尝试在场景中查找
		for node in get_tree().root.get_children():
			if node.has_node("BuffAssembler"):
				buff_assembler = node.get_node("BuffAssembler")
				break
	
	if buff_assembler and buff_assembler.has_method("get_current_buff"):
		var buff = buff_assembler.get_current_buff()
		text += "伤害倍率: %.1fx\n" % buff.multiplier
		if buff.has_combo:
			text += "组合类型: %s\n" % buff.combo_type
	
	text += "\n操作: WASD移动, 自动射击"
	
	label.text = text
