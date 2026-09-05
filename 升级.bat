@echo off
@REM 本文件为 ANSI(GBK) 编码 + CRLF 换行，请勿用 UTF-8 保存
setlocal enabledelayedexpansion

@REM ============================================================
@REM  mpv-lazy 升级辅助脚本（配合本仓库使用）
@REM
@REM  用法：直接双击运行，按提示输入旧版/新版安装目录
@REM  流程：
@REM    1. 从旧版迁移 _cache（watch_later / shader / icc 等运行数据）
@REM    2. 对比旧版与新版的 portable_config，生成上游变更报告
@REM    3. 将本仓库 config/ 部署到新版目录
@REM
@REM  报告输出到仓库 upgrade_reports\ 目录，升级后请自行审阅：
@REM    - 上游新增/删除/修改的配置项是否需要合并进仓库 config/
@REM    - 合并完成后用 sync_from_mpv.bat 回收，再 git 提交
@REM ============================================================

set "REPO=%~dp0"
if "%REPO:~-1%"=="\" set "REPO=%REPO:~0,-1%"
set "CONFIG=%REPO%\config"

echo.
echo ===== mpv-lazy 升级辅助 =====
echo.

@REM ---- 输入目录（回车使用默认值） ----
set "OLD_DEFAULT=%REPO%\..\mpv-lazy-old"
set "NEW_DEFAULT=%REPO%\..\mpv-lazy"
pushd "%OLD_DEFAULT%" 2>nul && set "OLD_DEFAULT=!cd!" & popd
pushd "%NEW_DEFAULT%" 2>nul && set "NEW_DEFAULT=!cd!" & popd

set "OLD_DIR="
set /p "OLD_DIR=旧版安装目录（旧版大概率已改名为 mpv-lazy-old，回车默认 %OLD_DEFAULT% ）： "
if not defined OLD_DIR set "OLD_DIR=%OLD_DEFAULT%"

set "NEW_DIR="
set /p "NEW_DIR=新版安装目录（回车默认 %NEW_DEFAULT% ）： "
if not defined NEW_DIR set "NEW_DIR=%NEW_DEFAULT%"

@REM ---- 去除可能的引号与结尾反斜杠 ----
set "OLD_DIR=%OLD_DIR:"=%"
set "NEW_DIR=%NEW_DIR:"=%"
if "%OLD_DIR:~-1%"=="\" set "OLD_DIR=%OLD_DIR:~0,-1%"
if "%NEW_DIR:~-1%"=="\" set "NEW_DIR=%NEW_DIR:~0,-1%"

@REM ---- 检查目录 ----
if not exist "%OLD_DIR%\portable_config" (
    echo [错误] 旧版目录不存在或缺少 portable_config：%OLD_DIR%
    goto end
)
if not exist "%NEW_DIR%\portable_config" (
    echo [错误] 新版目录不存在或缺少 portable_config（请先完成新版安装）：%NEW_DIR%
    goto end
)
if not exist "%CONFIG%\mpv.conf" (
    echo [错误] 仓库 config 目录异常，找不到 %CONFIG%\mpv.conf
    goto end
)

for %%i in ("%OLD_DIR%") do set "OLD_NAME=%%~nxi"
for %%i in ("%NEW_DIR%") do set "NEW_NAME=%%~nxi"

echo.
echo 旧版：%OLD_DIR%
echo 新版：%NEW_DIR%
echo.
set /p "CONFIRM=确认以上目录无误并开始升级？（输入 y 继续）： "
if /i not "%CONFIRM%"=="y" goto end

@REM ============================================================
@REM  步骤 1：迁移 _cache 运行数据（watch_later / shader / icc）
@REM ============================================================
echo.
echo [1/3] 正在从旧版迁移 _cache 运行数据...
if exist "%OLD_DIR%\portable_config\_cache" (
    robocopy "%OLD_DIR%\portable_config\_cache" "%NEW_DIR%\portable_config\_cache" /E /NFL /NDL /NJH /NJS >nul
    echo       已迁移 _cache。
) else (
    echo       旧版没有 _cache 目录，跳过。
)

@REM ============================================================
@REM  步骤 2：生成旧版 vs 新版（上游）变更报告
@REM ============================================================
echo [2/3] 正在生成上游变更报告...

set "STAMP=%date:~0,4%-%date:~5,2%-%date:~8,2%"
set "REPORT_DIR=%REPO%\upgrade_reports"
set "REPORT=%REPORT_DIR%\%STAMP%_old_vs_new_diff.txt"
if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%"

set "TMP_OLD=%TEMP%\mpv_upg_old"
set "TMP_NEW=%TEMP%\mpv_upg_new"
rd /s /q "%TMP_OLD%" 2>nul
rd /s /q "%TMP_NEW%" 2>nul

@REM 排除 _cache 与编辑器历史，只对比真实配置
robocopy "%OLD_DIR%\portable_config" "%TMP_OLD%" /MIR /XD _cache .history /NFL /NDL /NJH /NJS >nul
robocopy "%NEW_DIR%\portable_config" "%TMP_NEW%" /MIR /XD _cache .history /NFL /NDL /NJH /NJS >nul

set "GIT=C:\Program Files\Git\bin\git.exe"
if not exist "%GIT%" set "GIT=git"

(
    echo # mpv-lazy 上游变更报告（旧版 %OLD_NAME% vs 新版 %NEW_NAME%）
    echo # 生成时间：%date% %time%
    echo # 说明：此报告对比的是两个安装包自带的 portable_config，
    echo #       反映上游新版本相对旧版本的改动，用于判断哪些新内容
    echo #       需要合并进本仓库 config/ 再重新部署。
    echo #       仓库自定义内容不会出现在此报告中（部署发生在对比之后）。
    echo.
) > "%REPORT%"

"%GIT%" -c core.autocrlf=false diff --no-index --ignore-cr-at-eol --stat "%TMP_OLD%" "%TMP_NEW%" >> "%REPORT%" 2>nul
echo. >> "%REPORT%"
"%GIT%" -c core.autocrlf=false diff --no-index --ignore-cr-at-eol "%TMP_OLD%" "%TMP_NEW%" >> "%REPORT%" 2>nul

rd /s /q "%TMP_OLD%" 2>nul
rd /s /q "%TMP_NEW%" 2>nul

echo       报告已生成：%REPORT%

@REM ============================================================
@REM  步骤 3：部署仓库 config/ 到新版目录
@REM ============================================================
echo [3/3] 正在部署仓库 config/ 到新版目录...
@REM 使用 /E 不带 /MIR：不删除新版目录里的文件，
@REM 这样上游新增的文件（本仓库还没有的）得以保留
robocopy "%CONFIG%" "%NEW_DIR%\portable_config" /E /NFL /NDL /NJH /NJS >nul
echo       部署完成。

echo.
echo ===== 升级流程结束 =====
echo.
echo 后续步骤：
echo   1. 打开报告审阅上游变更：%REPORT%
echo   2. 需要合并的内容改到仓库 config\ 里
echo   3. 运行 sync_from_mpv.bat 回收新版目录状态
echo   4. git 提交（含 CHANGELOG）
echo   5. 确认无误后再删除旧版目录 %OLD_NAME%
echo.
start notepad "%REPORT%"

:end
echo.
pause
