# EnemySpawner.gd
# 敌人生成器 - MVP：简单定时刷怪
extends Node2D

## 配置
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0  # 每2秒生成一个
@export var max_enemies: int = 10  # 最多10个敌人

var spawn_timer: float = 0.0
var total_spawned: int = 0
var active_enemies: int = 0

func _ready():
	# 加载敌人场景
	if not enemy_scene:
		enemy_scene = preload("res://Entities/enemy/BaseEnemy.tscn")
	
	# 连接敌人死亡信号
	SignalBus.enemy_died.connect(_on_enemy_died)

func _process(delta: float):
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval:
		if active_enemies < max_enemies:
			_spawn_enemy()
		spawn_timer = 0.0

## 生成敌人
func _spawn_enemy() -> void:
	if not enemy_scene:
		return
	
	var enemy = enemy_scene.instantiate()
	
	# 随机生成位置（屏幕右侧）
	var screen_size = get_viewport_rect().size
	var spawn_pos = Vector2(
		screen_size.x + 50,  # 屏幕右侧外
		randf_range(50, screen_size.y - 50)  # 随机高度
	)
	enemy.position = spawn_pos
	
	# 添加到场景
	get_tree().root.add_child(enemy)
	
	total_spawned += 1
	active_enemies += 1
	
	print("生成敌人 #", total_spawned, " 位置: ", spawn_pos)

## 敌人死亡
func _on_enemy_died(enemy_data: Dictionary) -> void:
	active_enemies -= 1

## 停止生成
func stop_spawning() -> void:
	set_process(false)

## 开始生成
func start_spawning() -> void:
	set_process(true)
