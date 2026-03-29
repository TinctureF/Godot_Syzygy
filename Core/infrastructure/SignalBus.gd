# SignalBus.gd
# 全局信号总线 - 所有系统解耦的"神经系统"
extends Node

## 敌人相关信号
signal enemy_died(enemy_data: Dictionary)
signal enemy_killed_for_card  # 敌机死亡，触发抽牌到卡槽

## 卡牌相关信号
signal card_collected(card: Resource)
signal card_expired  # 卡牌过期消失
signal card_played(card_group)  # 打出一组牌
signal hand_changed(hand: Array)
signal hand_evaluated(result: Dictionary)

## Buff相关信号
signal buff_updated(buff: Dictionary)

## 时控相关信号
signal request_time_warp(factor: float)

## 战斗相关信号
signal bullet_hit_enemy(bullet, enemy)
signal player_hit(damage: float)
signal player_hp_changed(current_hp: float, max_hp: float)
signal player_shield_changed(current_shield: float, max_shield: float)

## 游戏流程信号
signal stage_changed(new_stage: String)
signal game_over(victory: bool)
signal game_restarted()  # 游戏重启
signal win_condition_met(level)  # 达成胡牌条件

## VFX信号
signal vfx_requested(vfx_name, position)

## UI信号
signal menu_opened(opened_menu)  # 菜单打开
