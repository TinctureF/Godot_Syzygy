extends Node3D

# 将你保存的 Enemy.tscn 拖到这个槽位
@export var enemy_scene: PackedScene
@export var spawn_x: float = 25.0 # 屏幕右侧外
@export var spawn_spacing: float = 1.5 # 阵列间距

# 自动生成参数（可在检查器中调整）
@export var auto_spawn_enabled: bool = true
@export_range(1, 20) var spawn_interval: float = 5.0  # 生成间隔（秒）
@export_range(1, 20) var move_speed: float = 5.0  # 移动速度（约200px/s）

var spawn_timer: float = 0.0
var formation_counter: int = 0

enum FormationType {
	V_SHAPE,     # V字编队 3只
	LINE,        # 一字编队 4只
	DIAMOND,     # 菱形编队 5只
	DOUBLE_V     # 双V编队 6只
}

func _process(delta: float):
	# 按下键盘 T 键触发测试生成
	if Input.is_key_pressed(KEY_T):
		spawn_swarm(6)

	# 自动生成
	if auto_spawn_enabled:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			spawn_random_formation()

func spawn_random_formation():
	var formation_type = randi() % 4
	match formation_type:
		0: spawn_formation(FormationType.V_SHAPE)
		1: spawn_formation(FormationType.LINE)
		2: spawn_formation(FormationType.DIAMOND)
		3: spawn_formation(FormationType.DOUBLE_V)

func spawn_formation(type: FormationType):
	formation_counter += 1
	var positions = _get_formation_positions(type)
	var base_x = spawn_x
	var base_y = randf_range(-3, 3)  # 随机Y轴位置

	for i in range(positions.size()):
		var enemy = enemy_scene.instantiate()
		get_tree().root.add_child(enemy)

		var offset = positions[i]
		enemy.global_position = Vector3(base_x + offset.x, base_y + offset.y, 0)

		# 设置为组长
		if i == 0:
			enemy.set_leader(true, formation_counter)
		else:
			enemy.set_leader(false, formation_counter)

		# 设置移动速度
		enemy.set_move_speed(move_speed)

func _get_formation_positions(type: FormationType) -> Array[Vector2]:
	var positions: Array[Vector2] = []

	match type:
		FormationType.V_SHAPE:  # V字编队 3只
			positions.append(Vector2(0, 0))       # 组长在前
			positions.append(Vector2(-1.5, 1.0))  # 左后
			positions.append(Vector2(-1.5, -1.0)) # 右后

		FormationType.LINE:  # 一字编队 4只
			positions.append(Vector2(0, 0))
			positions.append(Vector2(-1.5, 0))
			positions.append(Vector2(-3.0, 0))
			positions.append(Vector2(-4.5, 0))

		FormationType.DIAMOND:  # 菱形编队 5只
			positions.append(Vector2(0, 0))       # 组长在中央
			positions.append(Vector2(-1.5, 1.0))  # 上
			positions.append(Vector2(-1.5, -1.0)) # 下
			positions.append(Vector2(-3.0, 0))    # 后
			positions.append(Vector2(-1.5, 0))    # 前

		FormationType.DOUBLE_V:  # 双V编队 6只
			positions.append(Vector2(0, 0.8))     # 前V组长
			positions.append(Vector2(-1.2, 1.5))
			positions.append(Vector2(-1.2, 0.1))
			positions.append(Vector2(-2.5, -0.5)) # 后V组长
			positions.append(Vector2(-3.7, -1.2))
			positions.append(Vector2(-3.7, 0.2))

	return positions

func spawn_swarm(count: int):
	print("生成病毒编队...")
	for i in range(count):
		var enemy = enemy_scene.instantiate()
		# 在主场景（Root）生成，防止敌机跟随生成器移动
		get_tree().root.add_child(enemy)

		# 阵列排布：在 X 轴附近错开生成
		var pos = Vector3(spawn_x + (i * spawn_spacing), randf_range(-5, 5), 0)
		enemy.global_position = pos
