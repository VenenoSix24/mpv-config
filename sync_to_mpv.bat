@echo off
rem 把仓库里的配置部署到当前 mpv 安装目录（config -> 安装目录）
rem 用 /E 覆盖复制但不删除目标已有文件：
rem   - 部署到全新安装的新版 mpv-lazy 时，作者新增的文件不会被清掉
rem   - 需要删除某个配置文件时请两边手动删，或用 /MIR 自行修改本脚本
rem 如果换了新安装目录，改下面的 MPV_DIR 即可。

set "MPV_DIR=C:\Softwares\mpv-lazy"
set "REPO_DIR=%~dp0"

robocopy "%REPO_DIR%config" "%MPV_DIR%\portable_config" /E /XD _cache /NFL /NDL /NJH /NP
if errorlevel 8 (echo 同步失败，请检查路径 & exit /b 1)
echo 已把仓库 config 部署到 %MPV_DIR%\portable_config
pause
