# MainUI.gd
extends CanvasLayer

@onready var grid_container = $TacticalOverlay/CardSlotGrid

var current_combo_cards = []  # 当前成组的卡牌
var last_double_click_time: float = 0.0
var double_click_threshold: float = 0.4

# MainUI.gd 扩容版
func _ready():
	DeckLibrary.initialize_deck()

	# 监听敌机死亡，触发抽牌
	SignalBus.enemy_killed_for_card.connect(_draw_to_slot)

	# 监听卡牌拾取，触发抽牌到槽位
	SignalBus.card_collected.connect(_on_card_collected)

	# 连接卡牌槽的点击信号
	var slots = grid_container.get_children()
	for i in range(slots.size()):
		var slot = slots[i]
		slot.slot_index = i
		if not slot.slot_pressed.is_connected(_on_slot_clicked):
			slot.slot_pressed.connect(_on_slot_clicked)

func _input(event):
	# 键盘 1-9 映射
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var index = event.keycode - KEY_1
			_play_card(index)

	# 全局双击发射成组卡牌
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_double_click_time < double_click_threshold:
				# 双击：发射成组的卡牌
				_play_combo_cards()
			last_double_click_time = current_time

# 其他函数（_draw_to_slot, _play_card, _sort_hand）保持不变
# 因为它们使用的是 grid_container.get_children()，会自动识别 9 个槽位！

# 响应鼠标点击信号 
func _on_slot_clicked(index: int):
	_play_card(index)

# MainUI.gd 内部

# 1. 抽牌函数：抽完立即排序
func _draw_to_slot():
	_draw_card_to_slot(null)

# 拾取卡牌时调用
func _on_card_collected(card: CardObject):
	_draw_card_to_slot(card)

# 通用抽牌函数
func _draw_card_to_slot(card: CardObject):
	if card == null:
		card = DeckLibrary.draw_card()
	if card == null: return

	# 找第一个空位暂时放下
	var slots = grid_container.get_children()
	for slot in slots:
		if slot.is_empty():
			slot.set_card_data(card)
			# 【关键】放下后立即全员重新排队
			_sort_hand()
			return

# 2. 排序核心函数,--- 全自动手牌整理算法 ---
func _sort_hand():
	var slots = grid_container.get_children()
	var active_cards: Array[CardObject] = []
	
	# 第一步：把所有卡牌数据“没收”上来
	for slot in slots:
		if not slot.is_empty():
			active_cards.append(slot.current_card)
			slot.set_card_data(null) # 暂时清空所有槽位的显示
	
	# 第二步：执行排序算法 (P->L->A, 然后 1->9)
	active_cards.sort_custom(func(a, b):
		if a.suit != b.suit:
			return a.suit < b.suit
		return a.value < b.value
	)
	
	# 第三步：按新顺序重新填入前几个槽位
	for i in range(active_cards.size()):
		slots[i].set_card_data(active_cards[i])
	
	# 第四步：【核心】排序完成后，立即进行高亮判定
	_request_battle_evaluation()

# 3. 打牌函数：打完也要重新排序对齐
func _play_card(index: int):
	var slots = grid_container.get_children()
	if index >= 0 and index < slots.size():
		var slot = slots[index]
		if not slot.is_empty():
			# 获取打出的卡牌并应用效果
			var card = slot.current_card
			_apply_single_card_effect(card)
			slot.set_card_data(null)
			# 打掉一张，剩下的牌自动向左靠拢并排序
			_sort_hand()

## 应用单张卡牌效果
func _apply_single_card_effect(card):
	if card == null:
		return

	# 找出玩家节点
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# 如果是PLANE卡牌，增加护盾
	if card is CardObject and card.suit == CardObject.Suit.PLANE:
		player.add_shield(5.0)
		print("[UI] 打出PLANE卡牌, 护盾 +5")

	# 如果是LINE卡牌，回血5点
	if card is CardObject and card.suit == CardObject.Suit.LINE:
		player.heal(5.0)
		print("[UI] 打出LINE卡牌, 回血 +5")

	# 如果是POINT卡牌，子弹变大，伤害翻倍，持续10秒
	if card is CardObject and card.suit == CardObject.Suit.POINT:
		if player.has_node("WeaponSystem"):
			var weapon = player.get_node("WeaponSystem")
			if weapon.has_method("apply_point_buff"):
				weapon.apply_point_buff(1)  # 1 = 单张Point
				print("[UI] 打出POINT卡牌, 子弹变大，伤害翻倍，10秒")

# 4. 发射成组卡牌
func _play_combo_cards():
	if current_combo_cards.is_empty():
		return

	var slots = grid_container.get_children()
	var cards_to_remove = current_combo_cards.duplicate()

	# 检测卡牌效果并增加护盾
	_apply_card_effects(cards_to_remove)

	# 移除成组的卡牌
	for card in cards_to_remove:
		for slot in slots:
			if not slot.is_empty() and slot.current_card and _is_same_card(slot.current_card, card):
				slot.set_card_data(null)
				break

	# 清空成组状态
	current_combo_cards.clear()

	# 重新排序
	_sort_hand()

## 应用卡牌效果(增加护盾)
func _apply_card_effects(cards: Array):
	# 只有3张或以上才可能是成组
	if cards.size() < 3:
		return

	# 找出玩家节点
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# 检测是否是刻子
	var is_triplet = _is_triplet(cards)
	# 检测是否是顺子
	var is_sequence = _is_sequence(cards)

	if is_triplet or is_sequence:
		# 检查是否是 POINT 花色
		var all_point = true
		for card in cards:
			if card is CardObject and card.suit != CardObject.Suit.POINT:
				all_point = false
				break

		if all_point:
			# POINT刻子或顺子: 应用point_buff(2)
			if player.has_node("WeaponSystem"):
				var weapon = player.get_node("WeaponSystem")
				weapon.apply_point_buff(2)  # 2 = 顺子/刻子Point
				print("[UI] 打出POINT刻子/顺子! 子弹变大，伤害翻倍，三排射击，15秒")
		else:
			# 检查是否是 PLANE
			var all_plane = true
			for card in cards:
				if card is CardObject and card.suit != CardObject.Suit.PLANE:
					all_plane = false
					break

			if all_plane:
				# PLANE刻子或顺子: 护盾加满
				player.fill_shield()
				print("[UI] 打出PLANE刻子/顺子! 护盾加满")
			else:
				# LINE刻子或顺子: 无护盾效果
				print("[UI] 打出LINE刻子/顺子, 无护盾效果")

## 检测是否是刻子(3张相同数值)
func _is_triplet(cards: Array) -> bool:
	if cards.size() != 3:
		return false
	var values = []
	for card in cards:
		if card is CardObject:
			values.append(card.value)
	return values[0] == values[1] and values[1] == values[2]

## 检测是否是顺子(3张连续数值,同花色)
func _is_sequence(cards: Array) -> bool:
	if cards.size() != 3:
		return false
	var values = []
	var suits = []
	for card in cards:
		if card is CardObject:
			values.append(card.value)
			suits.append(card.suit)
	values.sort()
	# 检查数值是否连续
	var is_consecutive = (values[1] == values[0] + 1) and (values[2] == values[1] + 1)
	# 检查是否同花色
	var same_suit = suits[0] == suits[1] and suits[1] == suits[2]
	return is_consecutive and same_suit

func _request_battle_evaluation():
	var slots = grid_container.get_children()
	var current_hand: Array[CardObject] = []

	# 全员熄灯，收集手牌
	for slot in slots:
		slot.set_highlight(false)
		if not slot.is_empty():
			current_hand.append(slot.current_card)

	var result = HandEvaluator.evaluate_hand(current_hand)

	# 保存成组卡牌
	if result.has_combo:
		current_combo_cards = result.cards_used.duplicate()
	else:
		current_combo_cards.clear()

	# 如果大脑说成了！
	if result.has_combo:
		# 名单里现在有 3 张卡了
		for combo_card in result.cards_used:
			for slot in slots:
				if slot.current_card and _is_same_card(slot.current_card, combo_card):
					slot.set_highlight(true) # 这张亮了
					break # 找名单里的下一张

# 比较两张卡牌是否相同（使用 suit 和 value 比较，避免引用问题）
func _is_same_card(card1: CardObject, card2: CardObject) -> bool:
	return card1.suit == card2.suit and card1.value == card2.value
