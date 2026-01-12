# CardObject.gd
# 卡牌资源定义
extends Resource
class_name CardObject

## 卡牌花色枚举
enum Suit {
	RED,    # 红色 - 攻击
	GREEN,  # 绿色 - 防御
	BLUE,   # 蓝色 - 能量
	WIND,   # 风 - 四象
	FIRE,   # 火 - 四象
	WATER,  # 水 - 四象
	EARTH,  # 土 - 四象
	SUN,    # 日 - 三元
	MOON,   # 月 - 三元
	STAR,   # 星 - 三元
	BAGUA   # 八荒铭文
}

## 基础属性
@export var suit: Suit = Suit.RED
@export var value: int = 1  # 1-9
@export var card_id: String = ""

## 八荒铭文类型
@export var bagua_type: String = ""  # "天", "地", "玄", "黄", "宇", "宙", "洪", "荒"

func _init(p_suit: Suit = Suit.RED, p_value: int = 1):
	suit = p_suit
	value = p_value
	card_id = _generate_id()

func _generate_id() -> String:
	var suit_name = Suit.keys()[suit]
	if suit == Suit.BAGUA:
		return "BAGUA_" + bagua_type
	return suit_name + "_" + str(value)

## 获取卡牌显示名称
func get_display_name() -> String:
	if suit == Suit.BAGUA:
		return "八荒·" + bagua_type
	var suit_names = {
		Suit.RED: "红",
		Suit.GREEN: "绿",
		Suit.BLUE: "蓝",
		Suit.WIND: "风",
		Suit.FIRE: "火",
		Suit.WATER: "水",
		Suit.EARTH: "土",
		Suit.SUN: "日",
		Suit.MOON: "月",
		Suit.STAR: "星"
	}
	return suit_names.get(suit, "") + str(value)

## 判断是否可以组成顺子
func can_form_sequence_with(card2: CardObject, card3: CardObject) -> bool:
	if suit != card2.suit or suit != card3.suit:
		return false
	var values = [value, card2.value, card3.value]
	values.sort()
	return values[1] == values[0] + 1 and values[2] == values[1] + 1

## 判断是否可以组成刻子
func can_form_triplet_with(card2: CardObject, card3: CardObject) -> bool:
	return suit == card2.suit and suit == card3.suit and value == card2.value and value == card3.value
