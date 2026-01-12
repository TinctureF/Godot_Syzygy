# SignalBus.gd
# 全局信号总线 - 所有系统解耦的"神经系统"
extends Node

## 敌人相关信号
signal enemy_died(enemy_data: Dictionary)

## 卡牌相关信号
signal card_collected(card: Resource)
signal hand_changed(hand: Array)

## Buff相关信号
signal buff_updated(buff: Dictionary)

## 时控相关信号
signal request_time_warp(factor: float)

## 战斗相关信号
signal bullet_hit_enemy(bullet, enemy)
signal player_hit(damage: float)

## 游戏流程信号
signal stage_changed(new_stage: String)
signal game_over(victory: bool)
