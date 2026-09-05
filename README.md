# mpv-config

mpv-lazy（hooke007/mpv_PlayKit）的配置管理仓库。mpv-lazy 升级时需要全新安装到另一个目录、迁移配置后删除旧目录，所以配置以本仓库为唯一权威版本，安装目录只是部署目标。

## 目录结构

- `config/` — 实际维护的 portable_config 全部内容。
- `docs/` — 修改记录。`CHANGELOG.md` 是总索引，单次较大的改动单独一份 md。
- `upstream/` — 每次安装新版 mpv-lazy 时留存的原版 portable_config 快照，用于升级时对比。其中 `mpv_PlayKit_git` 是上游仓库的本地克隆：日常对比用 `lite` 分支（懒人包的配置源头），查 uosc 等脚本完整源码或移植 main 独有功能时用 `main` 分支。
- `sync_from_mpv.bat` — 安装目录 -> 仓库。
- `sync_to_mpv.bat` — 仓库 -> 安装目录。
- `升级.bat` — 一键升级辅助（详见下文流程第 3 步），生成的上游变更报告放在 `upgrade_reports/`（生成产物，不入库）。

## 升级到新版 mpv-lazy 的流程

1. 在新目录全新安装新版 mpv-lazy（旧目录若已改名为 `mpv-lazy-old` 之类，脚本里直接填路径即可）。
2. 把 B 目录的原版 `portable_config` 整个复制到 `upstream/`，命名如 `v20260905_orig_portable_config`。
3. 双击运行 `升级.bat`，按提示输入旧版/新版安装目录（直接回车使用默认路径）。脚本会自动完成：
   - 从旧版迁移 `_cache`（watch_later / shader / icc 等运行数据）到新版；
   - 对比新旧两版安装包自带的 `portable_config`，把上游变更报告写到 `upgrade_reports/`；
   - 把仓库 `config/` 部署到新版目录（不删除新版目录里上游新增的文件）。
4. 打开报告审阅上游变更，需要合并的内容改到仓库 `config/` 里，再跑一次 `sync_to_mpv.bat` 或重跑 `升级.bat`。
5. 在 B 目录验证没问题后删除旧安装目录，运行 `sync_from_mpv.bat` 回收最终状态并 git 提交（含 CHANGELOG）。
