# DeckLibrary.gd
# 牌库管理 - 144张牌系统
extends Node

## 牌库状态
var deck: Array[CardObject] = []
var drawn_count: int = 0
const TOTAL_CARDS: int = 144

func _ready():
	init_deck()

## 初始化牌库
func init_deck() -> void:
	deck.clear()
	drawn_count = 0
	
	# 生成基础牌 RGB各36张 (1-9各4张)
	for suit in [CardObject.Suit.RED, CardObject.Suit.GREEN, CardObject.Suit.BLUE]:
		for value in range(1, 10):  # 1-9
			for _i in range(4):  # 每种4张
				var card = CardObject.new(suit, value)
				deck.append(card)
	
	# 生成四象牌 各8张 (1-9取部分)
	for suit in [CardObject.Suit.WIND, CardObject.Suit.FIRE, CardObject.Suit.WATER, CardObject.Suit.EARTH]:
		for value in [1, 2, 3, 4, 5, 6, 7, 8]:
			var card = CardObject.new(suit, value)
			deck.append(card)
	
	# 生成三元牌 各4张
	for suit in [CardObject.Suit.SUN, CardObject.Suit.MOON, CardObject.Suit.STAR]:
		for _i in range(4):
			var card = CardObject.new(suit, 1)
			deck.append(card)
	
	# 调整到144张
	while deck.size() < TOTAL_CARDS:
		var card = CardObject.new(CardObject.Suit.RED, randi() % 9 + 1)
		deck.append(card)
	
	# 打乱牌库
	deck.shuffle()
	
	print("牌库初始化完成: ", deck.size(), " 张牌")

## 抽一张牌
func draw_card() -> CardObject:
	if drawn_count >= deck.size():
		print("警告：牌库已空！")
		return null
	
	var card = deck[drawn_count]
	drawn_count += 1
	
	# 更新DataVault
	if has_node("/root/DataVault"):
		get_node("/root/DataVault").remaining_cards = deck.size() - drawn_count
	
	return card

## 获取剩余牌数
func get_remaining_cards() -> int:
	return deck.size() - drawn_count

## 重置牌库
func reset() -> void:
	init_deck()
