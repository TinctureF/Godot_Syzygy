# DeckLibrary.gd - 牌库大总管 (位于 Core/card_engine/)
extends Node

var full_deck: Array[CardObject] = [] # 完整的108张牌堆

# 游戏开始时调用，生成并洗牌
func initialize_deck():
	full_deck.clear()
	
	# 定义我们刚才建立的文件夹和命名前缀
	var suits_data = [
		{"enum_val": CardObject.Suit.POINT, "prefix": "point"},
		{"enum_val": CardObject.Suit.LINE, "prefix": "line"},
		{"enum_val": CardObject.Suit.PLANE, "prefix": "plane"}
	]
	
	# 双重循环：3个花色 x 9个数字
	for suit_info in suits_data:
		for i in range(1, 10):
			# 按照刚才的命名规范拼出文件路径
			var res_path = "res://Resources/card/instances/%s/%s_%d.tres" % [suit_info.prefix, suit_info.prefix, i]
			
			# 读取资源
			var card_res = load(res_path) as CardObject
			if card_res != null:
				# 每种牌放 4 张进去，凑齐 108 张
				for copy in range(4):
					full_deck.append(card_res)
			else:
				push_error("找不到卡牌资源，请检查路径: " + res_path)
	
	# 使用 Godot 内置算法完美洗牌
	full_deck.shuffle()
	print(">> BOTANICAL.SYS: 108张牌库已生成并洗乱。")

# 抽牌函数
func draw_card() -> CardObject:
	if full_deck.size() > 0:
		return full_deck.pop_back() # 从牌堆尾部抽出一张
	else:
		print(">> 警告：牌库已耗尽！")
		return null
