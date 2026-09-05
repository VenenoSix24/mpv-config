@echo off
rem 把当前 mpv 安装目录的 portable_config 收回仓库（安装目录 -> config）
rem 用法：直接双击，或命令行运行。日常改完配置后跑这个，再 git commit。
rem 如果换了新安装目录，改下面的 MPV_DIR 即可。

set "MPV_DIR=C:\Softwares\mpv-lazy"
set "REPO_DIR=%~dp0"

robocopy "%MPV_DIR%\portable_config" "%REPO_DIR%config" /MIR /XD _cache /NFL /NDL /NJH /NP
if errorlevel 8 (echo 同步失败，请检查路径 & exit /b 1)
echo 已把 %MPV_DIR%\portable_config 收回到仓库 config 目录（不含 _cache）
echo 记得运行 git status 查看、git commit 提交。
pause
