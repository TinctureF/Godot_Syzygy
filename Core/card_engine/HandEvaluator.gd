# HandEvaluator.gd
# 手牌评估器 - DEMO版本：顺子/刻子Buff效果
extends Node

## Buff效果类型枚举
enum BuffType {
	NONE,
	# 顺子效果
	FIRE_METEOR,      # 红1-2-3: 火流星 - 子弹溅射
	CLUSTER_BOMB,    # 红4-5-6: 集束雷 - 追踪飞弹
	DEATH_RAY,        # 红7-8-9: 死光 - 持续射线
	SLOW_HEAL,        # 绿1-2-3: 缓慢回血
	SHIELD,           # 绿4-5-6: 护盾
	INSTANT_HEAL,     # 绿7-8-9: 瞬间回血
	FREE_DASH,        # 蓝1-2-3: 免费Dash×2
	ENERGY_BOOST,     # 蓝4-5-6: 能量回复+40
	FREEZE_TIME,      # 蓝7-8-9: 免费时控×3
	# 刻子效果
	EXPLOSION,        # 红AAA: 爆裂 - AOE清场
	FATAL_SHIELD,     # 绿AAA: 致命屏障
	FATAL_DASH        # 蓝AAA: 致命Dash
}

## Buff效果数据表（根据GDD）
var buff_data: Dictionary = {
	BuffType.FIRE_METEOR: {
		"name": "火流星",
		"description": "子弹溅射：主伤2.0 + 溅射0.8×3",
		"damage": 2.0,
		"splash_damage": 0.8,
		"splash_count": 3
	},
	BuffType.CLUSTER_BOMB: {
		"name": "集束雷",
		"description": "追踪飞弹：2.5×5，持续5秒",
		"damage": 2.5,
		"missile_count": 5,
		"duration": 5.0
	},
	BuffType.DEATH_RAY: {
		"name": "死光",
		"description": "持续射线：0.5/0.1s，持续10秒，总计50",
		"damage_per_tick": 0.5,
		"tick_rate": 0.1,
		"duration": 10.0
	},
	BuffType.SLOW_HEAL: {
		"name": "缓慢回血",
		"description": "每秒回血+1，持续20秒",
		"heal_per_second": 1.0,
		"duration": 20.0
	},
	BuffType.SHIELD: {
		"name": "护盾",
		"description": "抵挡3发任意攻击",
		"block_count": 3
	},
	BuffType.INSTANT_HEAL: {
		"name": "瞬间回血",
		"description": "立即回血+20 HP",
		"heal_amount": 20.0
	},
	BuffType.FREE_DASH: {
		"name": "免费Dash",
		"description": "免费Dash×2，节省30能量",
		"dash_count": 2,
		"energy_saved": 30
	},
	BuffType.ENERGY_BOOST: {
		"name": "能量回复",
		"description": "立即充能+40点能量",
		"energy_amount": 40
	},
	BuffType.FREEZE_TIME: {
		"name": "免费时控",
		"description": "免费时控×3，节省60点能量",
		"time_warp_count": 3,
		"energy_saved": 60
	},
	BuffType.EXPLOSION: {
		"name": "爆裂",
		"description": "周身200px AOE清场，15.0伤害",
		"damage": 15.0,
		"radius": 200.0
	},
	BuffType.FATAL_SHIELD: {
		"name": "致命屏障",
		"description": "自动抵挡1次致命伤害",
		"blocks": 1
	},
	BuffType.FATAL_DASH: {
		"name": "致命Dash",
		"description": "致命时自动Dash",
		"dashes": 1
	}
}

func _ready():
	# 连接调试信号
	SignalBus.hand_evaluated.connect(_on_hand_evaluated)

## 评估手牌，返回Buff数据
func evaluate_hand(hand: Array) -> Dictionary:
	var buff = _get_default_buff()

	if hand.size() < 3:
		SignalBus.hand_evaluated.emit(buff)
		return buff

	# 查找所有顺子
	var sequences = _find_sequences(hand)
	for seq in sequences:
		var buff_result = _evaluate_sequence(seq)
		if buff_result.has_combo:
			SignalBus.hand_evaluated.emit(buff_result)
			return buff_result

	# 查找所有刻子
	var triplets = _find_triplets(hand)
	for trip in triplets:
		var buff_result = _evaluate_triplet(trip)
		if buff_result.has_combo:
			SignalBus.hand_evaluated.emit(buff_result)
			return buff_result

	# 无组合
	SignalBus.hand_evaluated.emit(buff)
	return buff

## 评估顺子效果
func _evaluate_sequence(cards: Array) -> Dictionary:
	if cards.size() != 3:
		return _get_default_buff()

	var suit = cards[0].suit
	var values = [cards[0].value, cards[1].value, cards[2].value]
	values.sort()

	var buff = _get_default_buff()
	buff.cards_used = cards

	# 【修正点】使用新的 POINT, LINE, PLANE 枚举
	match suit:
		CardObject.Suit.POINT: # 原 RED (点)
			if values == [1, 2, 3]:
				buff = _create_buff(BuffType.FIRE_METEOR, cards)
			elif values == [4, 5, 6]:
				buff = _create_buff(BuffType.CLUSTER_BOMB, cards)
			elif values == [7, 8, 9]:
				buff = _create_buff(BuffType.DEATH_RAY, cards)
		CardObject.Suit.LINE: # 原 GREEN (线)
			if values == [1, 2, 3]:
				buff = _create_buff(BuffType.SLOW_HEAL, cards)
			elif values == [4, 5, 6]:
				buff = _create_buff(BuffType.SHIELD, cards)
			elif values == [7, 8, 9]:
				buff = _create_buff(BuffType.INSTANT_HEAL, cards)
		CardObject.Suit.PLANE: # 原 BLUE (面)
			if values == [1, 2, 3]:
				buff = _create_buff(BuffType.FREE_DASH, cards)
			elif values == [4, 5, 6]:
				buff = _create_buff(BuffType.ENERGY_BOOST, cards)
			elif values == [7, 8, 9]:
				buff = _create_buff(BuffType.FREEZE_TIME, cards)

	return buff

## 评估刻子效果
func _evaluate_triplet(cards: Array) -> Dictionary:
	if cards.size() != 3:
		return _get_default_buff()

	var suit = cards[0].suit
	var buff = _get_default_buff()
	buff.cards_used = cards

	# 【修正点】使用新的 POINT, LINE, PLANE 枚举
	match suit:
		CardObject.Suit.POINT: # 原 RED
			buff = _create_buff(BuffType.EXPLOSION, cards)
		CardObject.Suit.LINE: # 原 GREEN
			buff = _create_buff(BuffType.FATAL_SHIELD, cards)
		CardObject.Suit.PLANE: # 原 BLUE
			buff = _create_buff(BuffType.FATAL_DASH, cards)

	return buff

## 创建Buff数据
func _create_buff(buff_type: BuffType, cards: Array) -> Dictionary:
	var data = buff_data.get(buff_type, {})
	return {
		"buff_type": buff_type,
		"name": data.get("name", ""),
		"description": data.get("description", ""),
		"multiplier": 2.0,  # 顺子基础倍率
		"fire_rate": 1.0,
		"has_combo": true,
		"combo_type": "sequence",
		"cards_used": cards,
		"effect_data": data
	}

## 获取默认Buff
func _get_default_buff() -> Dictionary:
	return {
		"buff_type": BuffType.NONE,
		"name": "",
		"description": "",
		"multiplier": 1.0,
		"fire_rate": 1.0,
		"has_combo": false,
		"combo_type": "",
		"cards_used": [],
		"effect_data": {}
	}

## 调试：手牌评估回调
func _on_hand_evaluated(res: Dictionary):
	if res.has_combo:
		print("【调试】判定成功！牌型：", res.combo_type, " | 效果：", res.name, " | 倍率：", res.multiplier)
	else:
		print("【调试】当前手牌未成型，倍率回归1.0")

## 查找所有顺子
func _find_sequences(hand: Array) -> Array:
	var sequences = []
	var suits_dict = {}

	for card in hand:
		if card.suit not in suits_dict:
			suits_dict[card.suit] = []
		suits_dict[card.suit].append(card)

	for suit in suits_dict:
		var cards = suits_dict[suit]
		if cards.size() < 3:
			continue
		cards.sort_custom(func(a, b): return a.value < b.value)

		for i in range(cards.size() - 2):
			if cards[i].value + 1 == cards[i+1].value and cards[i+1].value + 1 == cards[i+2].value:
				sequences.append([cards[i], cards[i+1], cards[i+2]])

	return sequences

## 查找所有刻子
func _find_triplets(hand: Array) -> Array:
	var triplets = []
	var groups = {}

	for card in hand:
		var key = str(card.suit) + "_" + str(card.value)
		if key not in groups:
			groups[key] = []
		groups[key].append(card)

	for key in groups:
		if groups[key].size() >= 3:
			triplets.append([groups[key][0], groups[key][1], groups[key][2]])

	return triplets

## 获取可打出的牌组
func get_playable_combo(hand: Array) -> Array:
	var sequences = _find_sequences(hand)
	if sequences.size() > 0:
		return sequences[0]

	var triplets = _find_triplets(hand)
	if triplets.size() > 0:
		return triplets[0]

	return []

## 获取Buff数据表（供BuffAssembler使用）
func get_buff_data(buff_type: BuffType) -> Dictionary:
	return buff_data.get(buff_type, {})
