# mpv-lazy 升级辅助脚本（由 升级.bat 启动）
# 流程：选旧版目录 -> 选新版目录 -> 迁移 _cache -> 快照新版原版配置到 upstream/ -> 生成上游变更报告 -> 部署 config/

$ErrorActionPreference = 'Stop'
# 懒人包配置为 UTF-8 编码，git diff 输出必须按 UTF-8 解码，否则中文变乱码
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
Add-Type -AssemblyName System.Windows.Forms

$Repo = $PSScriptRoot
$Config = Join-Path $Repo 'config'
$GitCandidates = @('C:\Program Files\Git\bin\git.exe', 'C:\Program Files\Git\cmd\git.exe')
$Git = $GitCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Git) { $Git = 'git' }

function Pick-Folder([string]$Description, [string]$Default) {
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description = $Description
    if (Test-Path $Default) { $d.SelectedPath = (Resolve-Path $Default).Path }
    if ($d.ShowDialog() -ne 'OK') { return $null }
    return $d.SelectedPath.TrimEnd('\')
}

function Pause-Exit {
    Write-Host ''
    Read-Host '按回车退出' | Out-Null
    exit
}

# ---- 选择目录 ----
$OldDir = Pick-Folder '选择旧版安装目录' (Join-Path $Repo '..\mpv-lazy-old')
if (-not $OldDir) { Pause-Exit }
$NewDir = Pick-Folder '选择新版安装目录' (Join-Path $Repo '..\mpv-lazy')
if (-not $NewDir) { Pause-Exit }

if (-not (Test-Path (Join-Path $OldDir 'portable_config'))) {
    Write-Host "[错误] 旧版目录缺少 portable_config：$OldDir"; Pause-Exit
}
if (-not (Test-Path (Join-Path $NewDir 'portable_config'))) {
    Write-Host "[错误] 新版目录缺少 portable_config（请先完成新版安装）：$NewDir"; Pause-Exit
}
if (-not (Test-Path (Join-Path $Config 'mpv.conf'))) {
    Write-Host "[错误] 仓库 config 目录异常：$Config"; Pause-Exit
}

$OldName = Split-Path $OldDir -Leaf
$NewName = Split-Path $NewDir -Leaf

Write-Host ''
Write-Host "旧版：$OldDir"
Write-Host "新版：$NewDir"
$confirm = Read-Host '开始升级？(y/N)'
if ($confirm -ne 'y') { Pause-Exit }

# ---- 1. 迁移运行数据（_cache 及根目录下的状态文件） ----
Write-Host ''
Write-Host '[1/4] 迁移运行数据...'
$OldCache = Join-Path $OldDir 'portable_config\_cache'
if (Test-Path $OldCache) {
    robocopy $OldCache (Join-Path $NewDir 'portable_config\_cache') /E /NFL /NDL /NJH /NJS | Out-Null
} else {
    Write-Host '      旧版无 _cache，跳过。'
}
foreach ($f in @('saved-props.json', 'danmaku-history.json')) {
    $src = Join-Path $OldDir "portable_config\$f"
    if (Test-Path $src) { Copy-Item $src (Join-Path $NewDir 'portable_config') -Force }
}

# ---- 2. 快照新版原版配置到 upstream/（必须在部署 config/ 之前，此时新版还是原版） ----
Write-Host '[2/4] 快照新版原版配置到 upstream/...'
$Stamp = Get-Date -Format 'yyyyMMdd'
$SnapDir = Join-Path $Repo "upstream\v${Stamp}_orig_portable_config"
if (Test-Path $SnapDir) {
    Write-Host "      $SnapDir 已存在，跳过快照。"
} else {
    robocopy (Join-Path $NewDir 'portable_config') $SnapDir /E /XD _cache .history /NFL /NDL /NJH /NJS | Out-Null
    Write-Host "      已保存：$SnapDir"
}

# ---- 3. 生成上游变更报告（对比两个安装包自带的 portable_config） ----
Write-Host '[3/4] 生成上游变更报告...'
$Stamp = Get-Date -Format 'yyyy-MM-dd'
$ReportDir = Join-Path $Repo 'upgrade_reports'
$Report = Join-Path $ReportDir "${Stamp}_old_vs_new_diff.txt"
if (-not (Test-Path $ReportDir)) { New-Item -ItemType Directory -Path $ReportDir | Out-Null }

# 运行时状态文件：播放器自动写入，不属于上游配置，不参与对比
$RuntimeFiles = @('saved-props.json', 'danmaku-history.json')

$TmpOld = Join-Path $env:TEMP 'mpv_upg_old'
$TmpNew = Join-Path $env:TEMP 'mpv_upg_new'
Remove-Item $TmpOld, $TmpNew -Recurse -Force -ErrorAction SilentlyContinue
robocopy (Join-Path $OldDir 'portable_config') $TmpOld /MIR /XD _cache .history /XF $RuntimeFiles /NFL /NDL /NJH /NJS | Out-Null
robocopy (Join-Path $NewDir 'portable_config') $TmpNew /MIR /XD _cache .history /XF $RuntimeFiles /NFL /NDL /NJH /NJS | Out-Null

# ---- 汇总：分类列出上游 新增/删除/修改 的文件 ----
$Summary = New-Object System.Collections.Generic.List[string]
$OldFiles = Get-ChildItem $TmpOld -Recurse -File | ForEach-Object { $_.FullName.Substring($TmpOld.Length + 1) }
$NewFiles = Get-ChildItem $TmpNew -Recurse -File | ForEach-Object { $_.FullName.Substring($TmpNew.Length + 1) }
foreach ($f in ($OldFiles + $NewFiles) | Sort-Object -Unique) {
    $inOld = Test-Path (Join-Path $TmpOld $f)
    $inNew = Test-Path (Join-Path $TmpNew $f)
    if ($inOld -and -not $inNew) { $Summary.Add("删除：$f") }
    elseif ($inNew -and -not $inOld) { $Summary.Add("新增：$f") }
    else {
        $h1 = (Get-FileHash (Join-Path $TmpOld $f) -Algorithm MD5).Hash
        $h2 = (Get-FileHash (Join-Path $TmpNew $f) -Algorithm MD5).Hash
        if ($h1 -ne $h2) { $Summary.Add("修改：$f") }
    }
}

$Header = @(
    "# 上游变更报告：$OldName vs $NewName（$Stamp）",
    '# 对比两个安装包自带的 portable_config，用于判断哪些新内容需要合并进仓库 config/。',
    '# 运行时状态文件（saved-props.json 等）已排除。',
    ''
) -join "`r`n"

if ($Summary.Count -eq 0) {
    $Body = $Header + '两个目录的 portable_config 没有差异。'
} else {
    $Body = $Header + ('变更文件汇总：' + "`r`n" + ($Summary -join "`r`n") + "`r`n`r`n" + '================ 逐行差异 ================' + "`r`n")
    $Diff = & $Git -c core.autocrlf=false diff --no-index --ignore-cr-at-eol $TmpOld $TmpNew 2>$null
    # 去掉 diff 头部里的临时目录路径，换成简短的 旧版/新版
    # git 会对路径里的 \ 做转义（\\），因此要同时匹配 原样/转义/正斜杠 三种形式
    foreach ($pair in @(@($TmpOld, '旧版'), @($TmpNew, '新版'))) {
        $src, $label = $pair
        foreach ($variant in @($src, ($src -replace '\\', '\\'), ($src -replace '\\', '/'))) {
            $Diff = $Diff -replace [regex]::Escape($variant), $label
        }
    }
    $Body += ($Diff -join "`r`n")
}
[IO.File]::WriteAllText($Report, $Body, [Text.UTF8Encoding]::new($true))
Remove-Item $TmpOld, $TmpNew -Recurse -Force -ErrorAction SilentlyContinue

# ---- 4. 部署 config/（不删除，保留上游新增文件） ----
Write-Host '[4/4] 部署 config/ 到新版目录...'
robocopy $Config (Join-Path $NewDir 'portable_config') /E /NFL /NDL /NJH /NJS | Out-Null

Write-Host ''
Write-Host "完成。报告：$Report"
Write-Host "后续：按报告合并变更到仓库 config\ ，sync_from_mpv.bat 回收并提交，确认无误后删除旧版 $OldName。"
Start-Process notepad $Report
Pause-Exit
