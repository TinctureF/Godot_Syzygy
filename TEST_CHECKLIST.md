# CporA MVP - 启动测试清单

## 🎯 测试前准备

### 1. 确认文件完整性
- [ ] 打开Godot项目，确认无红色错误
- [ ] 检查Autoload配置（项目设置 → Autoload）
- [ ] 确认主场景设置为 `res://Scenes/MainGame.tscn`

### 2. 场景资源检查
- [ ] 打开 `Entities/player/Player.tscn` 确认无错误
- [ ] 打开 `Entities/enemy/BaseEnemy.tscn` 确认无错误
- [ ] 打开 `Entities/card/LootCard.tscn` 确认无错误
- [ ] 打开 `Entities/Projectile.tscn` 确认无错误

---

## 🧪 核心功能测试（按顺序）

### Test 1: 游戏启动
**操作**: 按F5运行游戏
**预期结果**:
- [ ] 游戏窗口打开
- [ ] 看到蓝色方块（玩家）在屏幕左侧
- [ ] 控制台输出 "=== 游戏初始化 ==="
- [ ] 控制台输出 "牌库初始化完成: 144 张牌"
- [ ] 控制台输出 "=== 战斗开始 ==="
- [ ] 左上角显示调试面板

**如果失败**: 检查Autoload配置和场景引用

---

### Test 2: 玩家移动
**操作**: 按WASD键
**预期结果**:
- [ ] 玩家（蓝色方块）响应WASD移动
- [ ] 移动流畅，速度合理
- [ ] 玩家被限制在屏幕内

**如果失败**: 检查 [PlayerController.gd](f:\项目\cpor-a\Entities\player\PlayerController.gd) 的 _physics_process

---

### Test 3: 自动射击
**操作**: 等待1秒
**预期结果**:
- [ ] 每秒看到5个黄色小圆点（子弹）从玩家位置向右发射
- [ ] 子弹匀速飞行
- [ ] 子弹飞出屏幕后消失

**如果失败**: 检查 [WeaponSystem.gd](f:\项目\cpor-a\Entities\player\WeaponSystem.gd) 和 BulletPool

---

### Test 4: 敌人生成
**操作**: 等待2秒
**预期结果**:
- [ ] 屏幕右侧出现红色方块（敌人）
- [ ] 每2秒生成一个新敌人
- [ ] 控制台输出 "生成敌人 #1 位置: ..."
- [ ] 敌人从右向左移动
- [ ] 调试面板显示 "击杀数: 0"

**如果失败**: 检查 [EnemySpawner.gd](f:\项目\cpor-a\Scripts\EnemySpawner.gd)

---

### Test 5: 击杀敌人
**操作**: 移动到敌人前方，让子弹击中敌人
**预期结果**:
- [ ] 敌人被子弹击中时闪白
- [ ] 敌人血量减少（约5秒后消失）
- [ ] 控制台输出 "生成敌人 #X"
- [ ] 调试面板 "击杀数" 增加

**如果失败**: 检查碰撞层设置和 [Projectile.gd](f:\项目\cpor-a\Scripts\Projectile.gd)

---

### Test 6: 卡牌掉落
**操作**: 击杀一个敌人直到消失
**预期结果**:
- [ ] 敌人消失的位置出现黄色矩形（卡牌）
- [ ] 卡牌上显示文字（如 "红3"）
- [ ] 卡牌向左缓慢飘移
- [ ] 调试面板 "剩余牌数" 从144递减到143

**如果失败**: 检查 [LootDropper.gd](f:\项目\cpor-a\Scripts\LootDropper.gd) 的信号连接

---

### Test 7: 捡取卡牌
**操作**: 移动玩家碰撞卡牌
**预期结果**:
- [ ] 卡牌消失
- [ ] 控制台输出 "收集卡牌: 红X"
- [ ] 控制台输出 "手牌[红X ]"
- [ ] 调试面板 "手牌数量" 显示 1/7
- [ ] 调试面板 "收集卡牌" 数量增加

**如果失败**: 检查 [LootCard.gd](f:\项目\cpor-a\Entities\card\LootCard.gd) 碰撞检测

---

### Test 8: 手牌累积
**操作**: 击杀更多敌人，收集更多卡牌
**预期结果**:
- [ ] 手牌数量逐渐增加 (1/7 → 2/7 → 3/7...)
- [ ] 调试面板显示所有手牌
- [ ] 控制台实时输出手牌列表

**如果失败**: 检查 [PlayerController.gd](f:\项目\cpor-a\Entities\player\PlayerController.gd) 的 add_card_to_hand

---

### Test 9: 组成顺子（核心测试！）
**操作**: 收集3张同色连续的牌（如红1、红2、红3）
**预期结果**:
- [ ] 控制台输出 ">>> 可打出组合: 红1 红2 红3"
- [ ] 控制台输出 "Buff更新: 倍率=2.0 类型=sequence"
- [ ] 调试面板显示 "伤害倍率: 2.0x"
- [ ] 调试面板显示 "组合类型: sequence"
- [ ] **明显感觉击杀速度变快**（约2.5秒击杀）

**如果失败**: 检查 [HandEvaluator.gd](f:\项目\cpor-a\Scripts\HandEvaluator.gd) 的顺子检测逻辑

---

### Test 10: 组成刻子
**操作**: 收集3张同色同数字的牌（如红5、红5、红5）
**预期结果**:
- [ ] 控制台输出 ">>> 可打出组合: 红5 红5 红5"
- [ ] 控制台输出 "Buff更新: 倍率=2.5 类型=triplet"
- [ ] 调试面板显示 "伤害倍率: 2.5x"
- [ ] **击杀速度更快**（约2秒击杀）

**如果失败**: 检查刻子检测逻辑

---

### Test 11: 牌库消耗
**操作**: 持续游戏2-3分钟
**预期结果**:
- [ ] 调试面板 "剩余牌数" 持续下降
- [ ] 每击杀一个敌人，牌数减1
- [ ] 144 → 143 → 142 → ...

**如果失败**: 检查 [DeckLibrary.gd](f:\项目\cpor-a\Scripts\DeckLibrary.gd) 的 draw_card

---

### Test 12: 玩家受伤
**操作**: 故意让敌人碰到玩家
**预期结果**:
- [ ] 玩家闪红
- [ ] 调试面板 "玩家血量" 减少（100 → 94 → 88...）
- [ ] 控制台输出伤害信息
- [ ] 敌人碰撞后也消失

**如果失败**: 检查 [PlayerController.gd](f:\项目\cpor-a\Entities\player\PlayerController.gd) 的 take_damage

---

### Test 13: 游戏结束
**操作**: 让玩家血量归零
**预期结果**:
- [ ] 玩家消失
- [ ] 控制台输出 "=== 游戏结束 ==="
- [ ] 控制台输出统计数据（击杀数、收集数等）
- [ ] 敌人停止生成

**如果失败**: 检查 [StageCoordinator.gd](f:\项目\cpor-a\Core\StageCoordinator.gd) 的 game_over 处理

---

## 📊 性能测试

### Test 14: 长时间运行
**操作**: 游戏运行5分钟
**预期结果**:
- [ ] FPS保持稳定（60fps）
- [ ] 无内存泄漏
- [ ] 子弹池正常回收
- [ ] 敌人数量保持在10个以内

---

## 🐛 常见问题排查

### 问题1: 子弹不发射
**原因**: BulletPool找不到
**解决**: 确认project.godot中BulletPool在Autoload列表

### 问题2: 敌人不生成
**原因**: EnemySpawner未启动
**解决**: 检查StageCoordinator的_enter_battle_state方法

### 问题3: 卡牌不掉落
**原因**: 信号未连接
**解决**: 在LootDropper._ready中确认SignalBus.enemy_died.connect

### 问题4: Buff不生效
**原因**: HandEvaluator未正确评估
**解决**: 检查_find_sequences和_find_triplets方法

### 问题5: 调试面板不显示
**原因**: DebugPanel脚本路径错误
**解决**: 在MainGame.tscn中检查ExtResource路径

---

## ✅ 完整测试通过标准

MVP完整通过需要满足以下所有条件：

- [x] 所有13个核心测试全部通过
- [x] 无控制台红色错误
- [x] 能够从启动→战斗→击杀→收集→Buff→结束完整流程
- [x] 144张牌库正确消耗
- [x] 顺子和刻子正确检测和应用Buff

---

## 🎉 测试完成后

如果所有测试通过，恭喜！MVP框架已完整可用。

下一步可以：
1. 开始实现手动打出牌组功能
2. 添加真实的UI界面
3. 实现时控系统
4. 添加更多敌人类型
5. 实现Boss战

---

**测试版本**: MVP-0  
**测试日期**: 2026-01-12  
**预计测试时间**: 15-20分钟
