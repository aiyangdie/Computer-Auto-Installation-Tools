@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo     Windows软件批量更新工具 (基于WinGet)
echo ===================================================
echo.

:: 检查WinGet是否安装
where winget >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 未找到WinGet，请确保您的Windows版本支持WinGet并已安装。
    echo WinGet在Windows 10 1709及更高版本中可用。
    goto :EOF
)

:: 检查是否以管理员身份运行
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 警告: 此脚本未以管理员身份运行，某些软件可能无法正确更新。
    echo 建议以管理员身份运行此脚本。
    echo.
    choice /C YN /M "是否继续？(Y/N)"
    if !ERRORLEVEL! EQU 2 goto :EOF
    echo.
)

:: 创建日志文件
set "logfile=%~dp0winget_update_log_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "logfile=%logfile: =0%"
echo 日志文件将保存在: %logfile%
echo.

:: 初始化日志文件
echo Windows软件更新日志 - %date% %time% > "%logfile%"
echo ============================================== >> "%logfile%"
echo. >> "%logfile%"

:: 列出可更新的软件
echo 正在检查可更新的软件...
echo 正在检查可更新的软件... >> "%logfile%"
echo. >> "%logfile%"

winget upgrade >> "%logfile%"

:: 统计可更新的软件数量
for /f "tokens=1,2" %%a in ('winget upgrade ^| find /c /v ""') do set total_lines=%%a
for /f "tokens=1,2" %%a in ('winget upgrade ^| findstr "没有可用的升级" ^| find /c /v ""') do set no_upgrade_lines=%%a

if %total_lines% LEQ 3 (
    echo 没有可更新的软件包。
    echo 没有可更新的软件包。 >> "%logfile%"
    goto end
)

:: 显示更新信息
echo.
echo 找到可更新的软件包，是否要更新全部？
choice /C YN /M "更新全部软件？(Y/N)"
if %ERRORLEVEL% EQU 2 (
    echo 操作已取消。
    echo 操作已取消。 >> "%logfile%"
    goto end
)

echo.
echo 正在更新所有软件...
echo 正在更新所有软件... >> "%logfile%"
echo. >> "%logfile%"

:: 执行更新
winget upgrade --all --accept-source-agreements --accept-package-agreements >> "%logfile%" 2>&1

echo.
echo 更新过程已完成！
echo 更新过程已完成！ >> "%logfile%"

:end
echo.
echo 详细日志请查看: %logfile%
echo.
pause 