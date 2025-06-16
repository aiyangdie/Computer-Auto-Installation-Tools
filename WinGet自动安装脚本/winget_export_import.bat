@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo      Windows软件导出导入工具 (基于WinGet)
echo ===================================================
echo.

:: 检查WinGet是否安装
where winget >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 未找到WinGet，请确保您的Windows版本支持WinGet并已安装。
    echo WinGet在Windows 10 1709及更高版本中可用。
    goto :EOF
)

:: 设置导出文件名
set "export_file=%~dp0installed_software.json"

:menu
echo 请选择操作:
echo.
echo [1] 导出已安装的软件列表
echo [2] 导入软件列表并安装
echo [3] 查看已保存的软件列表
echo [4] 退出
echo.
choice /C 1234 /M "请输入选项(1-4):"

if %ERRORLEVEL% EQU 1 goto export
if %ERRORLEVEL% EQU 2 goto import
if %ERRORLEVEL% EQU 3 goto view
if %ERRORLEVEL% EQU 4 goto end

:export
echo.
echo 正在导出已安装的软件列表...
if exist "%export_file%" (
    echo.
    echo 警告: 文件 %export_file% 已存在
    choice /C YN /M "是否覆盖? (Y/N)"
    if !ERRORLEVEL! EQU 2 goto menu
)

winget export -o "%export_file%" --accept-source-agreements

if %ERRORLEVEL% EQU 0 (
    echo.
    echo 导出成功! 文件保存在: %export_file%
) else (
    echo.
    echo 导出失败，错误代码: %ERRORLEVEL%
)
echo.
pause
goto menu

:import
echo.
if not exist "%export_file%" (
    echo 错误: 未找到软件列表文件 %export_file%
    echo 请先导出软件列表或将列表文件放在当前目录。
    echo.
    pause
    goto menu
)

echo 找到软件列表文件: %export_file%
echo.
choice /C YN /M "是否开始导入并安装? (Y/N)"
if %ERRORLEVEL% EQU 2 goto menu

echo.
echo 正在导入软件列表并安装...
echo.

:: 检查是否以管理员身份运行
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 警告: 此脚本未以管理员身份运行，某些软件可能无法正确安装。
    echo 建议以管理员身份运行此脚本。
    echo.
    choice /C YN /M "是否继续？(Y/N)"
    if !ERRORLEVEL! EQU 2 goto menu
    echo.
)

:: 创建日志文件
set "logfile=%~dp0winget_import_log_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "logfile=%logfile: =0%"
echo 日志文件将保存在: %logfile%
echo.

:: 初始化日志文件
echo Windows软件导入安装日志 - %date% %time% > "%logfile%"
echo ============================================== >> "%logfile%"
echo. >> "%logfile%"

:: 执行导入安装
winget import -i "%export_file%" --accept-package-agreements --accept-source-agreements >> "%logfile%" 2>&1

echo.
echo 导入安装完成！详细日志请查看: %logfile%
echo.
pause
goto menu

:view
echo.
if not exist "%export_file%" (
    echo 错误: 未找到软件列表文件 %export_file%
    echo 请先导出软件列表。
    echo.
    pause
    goto menu
)

echo 软件列表内容:
echo ============================================
type "%export_file%" | findstr "PackageIdentifier"
echo ============================================
echo.
pause
goto menu

:end
echo.
echo 感谢使用WinGet导出导入工具!
echo.
exit /b 0 