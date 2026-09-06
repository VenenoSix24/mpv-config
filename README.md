# mpv-config

mpv-lazy（hooke007/mpv_PlayKit）的自用配置管理仓库。
>适用于 AMD 显卡，如 AMD Radeon RX 6750 GRE 12GB。

## 目录结构

- `config/` — 实际维护的 portable_config 全部内容。
- `docs/` — 修改记录。`CHANGELOG.md` 是总索引，单次较大的改动单独一份 md。
- `upstream/` — 每次安装新版 mpv-lazy 时留存的原版 portable_config 快照，用于升级时对比。其中 `mpv_PlayKit_git` 是上游仓库的本地克隆：日常对比用 `lite` 分支（懒人包的配置源头），查 uosc 等脚本完整源码或移植 main 独有功能时用 `main` 分支。
- `sync_from_mpv.bat` — 安装目录 -> 仓库。
- `sync_to_mpv.bat` — 仓库 -> 安装目录。
- `update.bat` — 懒人包更新辅助（详见下文流程第 3 步），生成的上游变更报告放在 `upgrade_reports/`。

## 升级到新版 mpv-lazy 的流程

1. 在新目录全新安装新版 mpv-lazy。
2. 双击运行 `update.bat`，窗口选择旧版/新版安装目录。脚本会自动完成：
   - 从旧版迁移 `_cache`（watch_later / shader / icc 等运行数据）到新版；
   - 把新版原版 `portable_config` 快照到 `upstream/v<日期>_orig_portable_config`；
   - 对比新旧两版安装包自带的 `portable_config`，把上游变更报告写到 `upgrade_reports/`；
   - 把仓库 `config/` 部署到新版目录。
3. 打开报告审阅上游变更，需要合并的内容改到仓库 `config/` 里，再跑一次 `sync_to_mpv.bat` 或重跑 `update.bat`。
4. 在验证没问题后删除旧安装目录，运行 `sync_from_mpv.bat` 回收最终状态。
