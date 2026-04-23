# Similar Projects Notes

这份速记只记录对 `godot-toolbox` 设计有参考价值的方向：

- 偏成品模板：提供菜单、场景切换、设置页、导出流程
  - 例：`Maaack/Godot-Game-Template`
- 偏通用 starter：提供轻量目录骨架和基础脚本
  - 例：`crystal-bit/godot-game-template`
- 偏工程化模板：强调测试、CI、代码质量门和自动化
  - 例：`chickensoft-games/GodotGame`

对本仓库最有参考价值的是第三类：

- 把工程基线和可选能力分层
- 优先保证 Day 0 自动化可运行
- 让新项目通过脚本选装 pack，而不是把所有插件默认塞进模板
