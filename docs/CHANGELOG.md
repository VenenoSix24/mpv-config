# 修改记录

总索引。单次大改动可单独写一份详细 md 放在本目录。

| 日期 | 类型 | 涉及文件 | 说明 |
|------|------|----------|------|
| 2026-09-05 | 初始化 | 全部 | 从 C:\Softwares\mpv-lazy\portable_config 收录基线配置，建立仓库 |
| 2026-09-05 | 配置 | mpv.conf、input_uosc.conf、mpv360 三件套 | 对比上游 lite（mpv-lazy-20260510）梳理本地全部自定义项 |
| 2026-09-06 | 功能 | config/input_uosc.conf、config/vs/、config/mpv.conf | 建立超分/补帧体系：新增 a 键 AI超分+AFMF 串接预设与「开关 AFMF补帧」菜单项，AFMF 全局默认开启；新增 UAI_DML_Anime/Photo/Game.vpy（AnimeJaNai V2L1 / hongyuanyu span / QCOM QuickSRNet）及对应分类预设；RIFE H_Pre 1440→1080 |
| 2026-09-06 | 功能 | config/input_uosc.conf、config/shaders/ | 着色器菜单扩充：登记 ArtCNN（C4F32/C4F16/Chroma）、FSRCNNX 56/fastv2、SSimSuperRes/Downscaler、A4K 抗振铃/重建VL/放大VL、KrigBilateral；移除 NV/TensorRT（DLC-vsNV）专用预设 |
| 2026-09-06 | 文档 | docs/ | 新增《着色器与滤镜说明》整合文档（着色器/VF滤镜/onnx模型清单 + 分类型组合推荐）；删除过时的对比记录、GLSL 下载清单、shader 选择指南 |
| 2026-09-05 | 功能 | config/script-opts.conf | uosc 底栏新增"旋转画面"按钮（启用 uosc-controls 自定义布局，在 loop-file 与 prev 之间插入 command:rotate_right 按钮，循环 0/90/180/270） |
| 2026-09-05 | 功能 | config/script-opts.conf | uosc 底栏新增弹幕控件：stream-quality 后插入 button:danmaku（弹幕搜索）与 cycle:toggle_on:show_danmaku@uosc_danmaku（弹幕开关），配合 uosc_danmaku 2.2.0 |
| 2026-09-05 | 配置 | config/script-opts/uosc_danmaku.conf | 新建弹幕样式配置：字号 38、显示范围 25%、描边 1、透明度 0.7 等，其余选项以注释形式留在文件内 |
| 2026-09-05 | 功能 | config/script-opts.conf、config/script-opts/uosc_danmaku.conf | 底栏追加 button:danmaku_styles（实时样式菜单）与 button:danmaku_menu（弹幕设置总菜单）；开启 autoload_for_url（URL 播放自动加载/继承弹幕） |
| 2026-09-05 | 样式 | config/script-opts.conf | 启用 uosc-thumbnail_mode=continuous：进度条缩略图随鼠标位置即时显示，不再等待停顿后出现 |
| 2026-09-05 | 功能 | 升级.bat、README.md | 新增一键升级辅助脚本：迁移 _cache、生成新旧安装包上游变更报告（upgrade_reports/）、部署 config/ 到新版目录 |
| 2026-09-05 | 功能 | 升级.bat、upgrade.ps1 | 升级脚本重构为 bat 启动器 + PowerShell 实现（UTF-8，避免 GBK 乱码）：目录改用文件夹选择对话框、报告增加新增/删除/修改汇总、排除并迁移 saved-props.json 与 danmaku-history.json 运行时文件、diff 路径简化为 旧版/新版、修正 UTF-8 解码 |

## 记录约定

- 类型：初始化 / 功能 / 样式 / 修复 / 配置 / 升级
- 涉及文件写相对 `config/` 的路径
- 大改动另建详细文档，命名 `YYYY-MM-DD_标题.md`，内容包含：改了哪里、为什么、怎么改的、如何回滚
