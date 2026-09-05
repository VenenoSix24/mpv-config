# 修改记录

总索引。单次大改动可单独写一份详细 md 放在本目录。

| 日期 | 类型 | 涉及文件 | 说明 |
|------|------|----------|------|
| 2026-09-05 | 初始化 | 全部 | 从 C:\Softwares\mpv-lazy\portable_config 收录基线配置，建立仓库 |
| 2026-09-05 | 配置 | mpv.conf、input_uosc.conf、mpv360 三件套 | 对比上游 lite（mpv-lazy-20260510）梳理本地全部自定义项，详见 [2026-09-05_对比上游记录本地自定义.md](2026-09-05_对比上游记录本地自定义.md) |
| 2026-09-05 | 功能 | config/script-opts.conf | uosc 底栏新增"旋转画面"按钮（启用 uosc-controls 自定义布局，在 loop-file 与 prev 之间插入 command:rotate_right 按钮，循环 0/90/180/270） |
| 2026-09-05 | 功能 | config/script-opts.conf | uosc 底栏新增弹幕控件：stream-quality 后插入 button:danmaku（弹幕搜索）与 cycle:toggle_on:show_danmaku@uosc_danmaku（弹幕开关），配合 uosc_danmaku 2.2.0 |

## 记录约定

- 类型：初始化 / 功能 / 样式 / 修复 / 配置 / 升级
- 涉及文件写相对 `config/` 的路径
- 大改动另建详细文档，命名 `YYYY-MM-DD_标题.md`，内容包含：改了哪里、为什么、怎么改的、如何回滚
