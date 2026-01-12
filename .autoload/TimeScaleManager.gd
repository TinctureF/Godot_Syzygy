# TimeScaleManager.gd
# 时间缩放管理器 - MVP：占位脚本
extends Node

## 全局战斗时间因子
var global_combat_factor: float = 1.0

func _ready():
	# 连接时控请求信号
	SignalBus.request_time_warp.connect(_on_request_time_warp)

## 处理时控请求
func _on_request_time_warp(factor: float) -> void:
	global_combat_factor = factor
	Engine.time_scale = factor
	print("时间缩放: ", factor)

## 恢复正常时间
func reset_time_scale() -> void:
	global_combat_factor = 1.0
	Engine.time_scale = 1.0

## 获取当前时间因子
func get_time_factor() -> float:
	return global_combat_factor
