# 灰烬齿轮：裂界之心

Godot + Blender 制作的 2.5D 蒸汽暗黑动作探索游戏。2026-10-09 首次实现，版本 **0.1.0 序章原型**。

## 运行

Windows 发布目录：`E:\Godot\release\灰烬齿轮-裂界之心-0.1.0\`。双击 `AshenGears.exe`，保持同目录 `AshenGears.pck`。开发时用 Godot 打开本仓库 `project.godot`。

## 已可玩内容

- R01 灰闸囚厂 8 房、R02-01 至 03，以及 R00-01 维修所，共 12 个连接房间。
- 井盖、竖梯、开放竖井、折返楼梯；模型和骨骼动作延续上下通道 demo。
- 匕首轻击三连、重击、格挡与弹反、闪避、人类背后暗杀；机械犬及典刑机不能暗杀。
- 救出洛铆后双角色切换，共享位置、速度、通道状态和耐力，分别保存 HP。洛铆使用更高的重击伤害；角色造型仍共用测试骨架。
- 钩索维修台获得 A01；指定锚点瞄准和弹射，刑柱高台验证通行。
- B01 典刑机原型的蓄力、落锤、收招、破势；取得转运表、开放囚厂回环。
- P01 锁销／惰轮／离合器；简化 P02 中水位／蒸汽旁路／排水，各有复位。
- 休息灯、JSON 原子存档及备份恢复、宝箱、铁屑、3 级武器强化、药剂、已探索地图、两人各 2 个技能。
- 新增 Blender 炉体、齿轮、电能柱、机械犬、典刑机及 8 个骨骼战斗动作；熔浆着色、脚步／打击音与原创合成环境低音。

## 操作

| 操作 | 键盘 / 鼠标 | Xbox 布局 |
| --- | --- | --- |
| 移动 / 攀梯 | A D / W S，或方向键 | 左摇杆 / 十字键 |
| 跳跃 / 离梯 / 脱钩 | Space | A |
| 轻击 / 重击 | J K / 鼠标左右键 | X Y |
| 闪避 / 格挡 | Shift / L | B / LB |
| 技能 | Ctrl + J / K | RB + X / Y |
| 潜行 | 地面按住 S | 地面下方向 |
| 交互 / 暗杀 / 休息 | E | 十字键上 |
| 按住预选 / 松开钩索 | Q | LT |
| 切换角色 | F 或 1 / 2 | RT |
| 使用药剂 | R | 十字键下 |
| 地图 / 技能界面 | M / T | View / 暂停菜单进入 |
| 暂停 / 全屏 | Esc / F11 | Menu / — |

敌人橙色提示进入蓄力后才攻击。背向未警觉的人类守卫 1.3 米内可 E 暗杀；跑步靠近会引起警觉。先处理囚门追兵再救洛铆。在休息灯按 E 记录复活与继续游戏的位置，唯一奖励取得后即时保存；生命恢复、药剂补满。默认存档位于 `%APPDATA%\Godot\app_userdata\灰烬齿轮：裂界之心\`。

P01：拔锁销 → 接入惰轮 → 合离合。P02：排水保持关闭 → 开加水 → 水位约 1.0 时关加水 → 开蒸汽旁路 → 开排水。错序可复位，不会永久封门。

## 开发

沿用参考 demo 的 **Godot 4.7.rc.custom_build.df6235838** 和匹配 Windows 模板、**Blender 4.2.9 LTS**。这是本机已有的自定义 RC 引擎，尚未迁移至官方稳定版。使用 Forward+ / Vulkan，当前实机验证设备为 RTX 5070 Laptop GPU，未测最低配置。

`source/` 保留可编辑 Blender 源文件；`source/build_ashen.py` 重建新增模型及战斗动作；`assets/models/` 为嵌入 PBR 贴图的 GLB；`data/rooms.json` 为房间、门、敌人和交互配置；`scripts/` 为控制器、游戏、敌人和 UI。Godot 会从 GLB 自动提取 PNG，提取文件与缓存不提交 Git。

```powershell
& 'D:\Blender\blender-4.2.9-windows-x64\blender.exe' -b --python source/build_ashen.py
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . --editor --import --quit
& 'E:\SourceCode\Games\engine\big_engine\godot\bin\godot.windows.editor.x86_64.console.exe' --headless --path . --export-release 'Windows Ashen Gears' build/AshenGears.exe
```

本机模板路径在 `export_presets.cfg` 中；其他电脑请调整。测试：`-- --qa --capture-dir=绝对截图目录`，使用独立 QA 存档，不替换正常存档。结果写到截图目录上一级 `runtime_tests.json`。

## 当前范围与后续

三个原始设计文档保留在 `docs/`。本原型不是设计文档所规划的完整 30—45 分钟样片或商业成品：当前房间复用五种通道模板，未完成三／四层独立井、A02 壁抓、C02 测试角色、三槽编队、九节点技能树和隔离动画预览。洛铆造型与武器动作需要独立精修；典刑机仍是机制原型，缺少完整多阶段 Boss 和专属处决。R03—R12、其余同伴、变身、装备掉落体系、支线与结局尚未制作。不可把这些文档里的规划当作已实现功能。

参考图仅用于美术方向，没有作为成品背景贴图。当前画面延续本机通道 demo 的石墙、管线、金属与冷暖照明，但未达到参考图的雕刻、布料与场景密度。详细验收和生产差异见 `docs/04_首版实现与开发路线.md`、`qa/VERIFICATION.md`。Godot 许可证与第三方声明位于 `licenses/` 并随发布包附带。
