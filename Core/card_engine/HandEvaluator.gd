# HandEvaluator.gd
# 手牌评估器 - MVP版本：只判断一种牌型
extends Node

func _ready():
    # --- 调试代码开始 ---
    # 这里的 lambda 函数 (func(res): ...) 会在每次 SignalBus 发出 hand_evaluated 信号时执行
    SignalBus.hand_evaluated.connect(func(res):
        if res.has_combo:
            print("【调试信息】判定成功！牌型：", res.combo_type, " | 倍率：", res.multiplier)
        else:
            print("【调试信息】当前手牌未成型，倍率回归 1.0")
    )
    # --- 调试代码结束 ---
## 评估手牌，返回Buff数据
func evaluate_hand(hand: Array[CardObject]) -> Dictionary:
	var buff = {
		"multiplier": 1.0,
		"fire_rate": 1.0,
		"has_combo": false,
		"combo_type": ""
	    "cards_used": [] # 建议增加：记录是哪些牌组成了Combo，方便后期做动画
    }
	
	if hand.size() < 3:
        # 手牌不足3张也广播一次，用于重置倍率为1.0
        SignalBus.hand_evaluated.emit(buff)
        return buff
	
# 查找顺子
    var sequences = _find_sequences(hand)
    if sequences.size() > 0:
        buff.multiplier = 2.0
        buff.has_combo = true
        buff.combo_type = "sequence"
        buff.cards_used = sequences[0]
        # 【关键：广播信号】
        SignalBus.hand_evaluated.emit(buff)
        return buff
	
# 查找刻子
    var triplets = _find_triplets(hand)
    if triplets.size() > 0:
        buff.multiplier = 2.5
        buff.has_combo = true
        buff.combo_type = "triplet"
        buff.cards_used = triplets[0]
        # 【关键：广播信号】
        SignalBus.hand_evaluated.emit(buff)
        return buff
	
# 如果什么都没搜到，也广播一次基础状态
    SignalBus.hand_evaluated.emit(buff)
    return buff

## 查找顺子（3张同花色连续）
func _find_sequences(hand: Array[CardObject]) -> Array:
	var sequences = []
	
	# 按花色分组
	var suits_dict = {}
	for card in hand:
		if card.suit not in suits_dict:
			suits_dict[card.suit] = []
		suits_dict[card.suit].append(card)
	
	# 在每个花色中查找顺子
	for suit in suits_dict:
		var cards = suits_dict[suit]
		if cards.size() < 3:
			continue
		
		# 排序
		cards.sort_custom(func(a, b): return a.value < b.value)
		
		# 查找连续
		for i in range(cards.size() - 2):
			if cards[i].value + 1 == cards[i+1].value and cards[i+1].value + 1 == cards[i+2].value:
				sequences.append([cards[i], cards[i+1], cards[i+2]])
				break  # MVP：只找一个
	
	return sequences

## 查找刻子（3张同花色同数字）
func _find_triplets(hand: Array[CardObject]) -> Array:
	var triplets = []
	
	# 按花色和数字分组
	var groups = {}
	for card in hand:
		var key = str(card.suit) + "_" + str(card.value)
		if key not in groups:
			groups[key] = []
		groups[key].append(card)
	
	# 查找3张或以上的组
	for key in groups:
		if groups[key].size() >= 3:
			triplets.append([groups[key][0], groups[key][1], groups[key][2]])
			break  # MVP：只找一个
	
	return triplets

## 获取可打出的牌组（MVP：返回第一个找到的）
func get_playable_combo(hand: Array[CardObject]) -> Array:
	# 先找顺子
	var sequences = _find_sequences(hand)
	if sequences.size() > 0:
		return sequences[0]
	
	# 再找刻子
	var triplets = _find_triplets(hand)
	if triplets.size() > 0:
		return triplets[0]
	
	return []
