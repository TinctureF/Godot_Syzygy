# CardObject.gd
# 卡牌资源定义 (DEMO 精简版)
extends Resource
class_name CardObject

## 卡牌花色枚举 (DEMO 仅保留点、线、面)
enum Suit {
	POINT,  # 点- 攻击强化
	LINE,   # 线 - 防御强化
	PLANE   # 面 - 能量机动
}

## 基础属性
@export var suit: Suit = Suit.POINT
@export var value: int = 1  # 1-9
@export var card_id: String = ""
@export var card_texture: Texture2D # 用于存放那 27 张具体的卡面贴图

# 初始化函数
func _init(p_suit: Suit = Suit.POINT, p_value: int = 1):
	suit = p_suit
	value = p_value
	card_id = _generate_id()

# 自动生成唯一 ID (例如: POINT_5)
func _generate_id() -> String:
	var suit_name = Suit.keys()[suit]
	return suit_name + "_" + str(value)

## 获取卡牌显示名称 (用于后台测试或UI提示)
func get_display_name() -> String:
	var suit_names = {
		Suit.POINT: "点",
		Suit.LINE: "线",
		Suit.PLANE: "面"
	}
	return suit_names.get(suit, "") + str(value)

## 规则辅助：判断是否可以与另外两张牌组成顺子
func can_form_sequence_with(card2: CardObject, card3: CardObject) -> bool:
	if suit != card2.suit or suit != card3.suit:
		return false
	var values = [value, card2.value, card3.value]
	values.sort()
	return values[1] == values[0] + 1 and values[2] == values[1] + 1

## 规则辅助：判断是否可以与另外两张牌组成刻子
func can_form_triplet_with(card2: CardObject, card3: CardObject) -> bool:
	return suit == card2.suit and suit == card3.suit and value == card2.value and value == card3.value
