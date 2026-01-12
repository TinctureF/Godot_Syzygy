# CporA MVP Prototype - 使用说明

## 项目结构

```
cpor-a/
├── Core/                    # 核心系统
│   ├── SignalBus.gd        # 全局信号总线
│   ├── DataVault.gd        # 数据黑匣子
│   ├── BulletPool.gd       # 子弹对象池
│   ├── TimeScaleManager.gd # 时间缩放管理（占位）
│   └── StageCoordinator.gd # 关卡协调器
├── Scripts/                 # 游戏逻辑脚本
│   ├── Projectile.gd       # 投射物逻辑
│   ├── DeckLibrary.gd      # 144张牌库
│   ├── HandEvaluator.gd    # 手牌评估
│   ├── BuffAssembler.gd    # Buff组装
│   ├── LootDropper.gd      # 掉落管理
│   ├── UIMediator.gd       # UI中介
│   ├── EnemySpawner.gd     # 敌人生成
│   └── CombatResolver.gd   # 战斗裁判
├── Entities/
│   ├── player/
│   │   ├── Player.tscn     # 玩家场景
│   │   ├── PlayerController.gd
│   │   └── WeaponSystem.gd
│   ├── enemy/
│   │   ├── BaseEnemy.tscn  # 敌人场景
│   │   └── BaseEnemy.gd
│   ├── card/
│   │   ├── LootCard.tscn   # 掉落卡牌场景
│   │   └── LootCard.gd
│   └── Projectile.tscn     # 子弹场景
├── Resources/
│   └── CardObject.gd       # 卡牌资源定义
└── Scenes/
    └── MainGame.tscn       # 主游戏场景
```

## MVP完成的功能

### ✅ 已实现（7项核心功能）

1. **玩家移动射击** ✅
   - WASD移动
   - 自动射击（5发/秒）
   
2. **敌人生成与死亡** ✅
   - 每2秒从右侧生成敌人
   - 敌人向左飘移
   - 被击杀后触发掉落

3. **敌人掉落卡牌** ✅
   - 击杀敌人100%掉1张牌
   - 卡牌从爆炸点喷出
   - 向左飘移，5秒后消失

4. **玩家捡牌** ✅
   - 碰撞卡牌自动收集
   - 加入手牌系统
   - 最多7张手牌

5. **手牌评估** ✅
   - 自动检测顺子（3张同色连续）
   - 自动检测刻子（3张同色同数）
   - 实时计算Buff

6. **攻击力提升** ✅
   - 组成顺子：伤害×2
   - 组成刻子：伤害×2.5
   - 实时应用到射击

7. **牌库消耗** ✅
   - 总共144张牌
   - 每次掉落消耗牌库
   - 剩余数量实时记录

## 如何运行

### 方法1：Godot编辑器
1. 用Godot 4.x打开项目
2. 打开 `Scenes/MainGame.tscn`
3. 按F5运行

### 方法2：快速测试
1. 直接按F5（已设置主场景为MainGame）

## 操作说明

### 键盘控制
- **W/A/S/D** 或 **方向键**: 移动
- **自动射击**: 无需按键，自动开火

### 游戏目标
1. 移动躲避敌人
2. 击杀敌人获得卡牌
3. 收集3张相同花色的连续牌（如红1-2-3）
4. 当组成顺子/刻子时，伤害自动提升
5. 观察控制台输出，查看手牌和Buff状态

## MVP验证清单

按照mvp脚本.txt的7项完成标准：

- [x] 玩家能移动射击
- [x] 敌人能生成并被打死
- [x] 敌人死后会掉牌
- [x] 玩家能捡牌
- [x] 捡到第3张牌，攻击明显变强（组成顺子/刻子时）
- [x] 牌库会减少（从144递减）
- [x] 一段时间后能进入Result状态（玩家死亡）

## 调试信息

游戏运行时，控制台会输出：

```
=== 游戏初始化 ===
牌库初始化完成: 144 张牌
=== 战斗开始 ===
生成敌人 #1 位置: (...)
收集卡牌: 红3
手牌[红3 ]
生成敌人 #2 位置: (...)
收集卡牌: 红1
手牌[红3 红1 ]
收集卡牌: 红2
手牌[红3 红1 红2 ]
>>> 可打出组合: 红1 红2 红3
Buff更新: 倍率=2.0 类型=sequence
```

## 已知限制（MVP故意简化）

❌ **不包含的内容**:
- Boss战
- 时控系统（只有占位代码）
- 对消系统
- 完整的UI界面
- 动画效果
- 音效
- 八荒铭文
- 胡牌系统
- 真实的RuleManager

✅ **这是正常的**: MVP只验证核心闭环，以上功能在后续迭代中实现。

## 数值测试

### 基础数值
- 玩家血量: 100 HP
- 玩家移速: 300 px/s
- 基础伤害: 1.0
- 基础射速: 5发/秒
- 基础DPS: 5.0

### 敌人数值
- 敌人血量: 25 HP
- 击杀时间: 约5秒（基础）
- 掉落: 1张卡牌

### Buff效果测试
1. **无Buff状态**: 需要25发子弹击杀（5秒）
2. **顺子Buff**: 需要12-13发子弹（2.5秒）
3. **刻子Buff**: 需要10发子弹（2秒）

## 下一步扩展建议

根据mvp脚本.txt，下一阶段应该：

1. **完善手牌系统**: 手动打出牌组
2. **实现胡牌机制**: Registry_Sets累积
3. **添加更多牌型**: 四象、三元、八荒
4. **真实时控系统**: 能量消耗和时间减速
5. **对消系统**: 子弹碰撞抵消
6. **UI界面**: 手牌显示、能量条、牌库计数
7. **Boss战**: 终局挑战

## 技术架构说明

### 信号驱动架构
所有系统通过SignalBus解耦：
```gdscript
# 系统A发送
SignalBus.enemy_died.emit(data)

# 系统B接收
SignalBus.enemy_died.connect(_on_enemy_died)
```

### Autoload全局节点
- SignalBus: 信号总线
- DataVault: 数据记录
- DeckLibrary: 牌库管理
- BulletPool: 子弹池
- StageCoordinator: 流程控制
- TimeScaleManager: 时间控制
- HandEvaluator: 手牌评估

### 场景组织
- MainGame: 主场景，包含所有运行时管理器
- Player: 玩家实体 + WeaponSystem
- BaseEnemy: 敌人模板
- LootCard: 掉落卡牌
- Projectile: 子弹模板

## 常见问题

**Q: 为什么没有看到UI？**  
A: MVP阶段UI简化为控制台输出，后续会添加完整UI。

**Q: 为什么攻击力没变化？**  
A: 需要收集到3张能组成顺子或刻子的牌才会触发Buff。

**Q: 牌库是如何消耗的？**  
A: 每次敌人死亡掉落卡牌时，从144张牌库中抽取，逐渐消耗。

**Q: 游戏会结束吗？**  
A: 当玩家血量归零时会触发game_over信号，进入Result状态。

## 贡献者

MVP框架基于：
- cpoa_gameplay_doc.md - 玩法设计
- cpoa_numeric_doc.md - 数值设计
- cpoa_enemy_doc.md - 敌人设计
- mvp脚本.txt - MVP清单

**文档版本**: MVP-0  
**完成日期**: 2026-01-12
