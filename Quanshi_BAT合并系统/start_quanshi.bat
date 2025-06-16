@echo off
:: Quanshi BAT文件合并系统 - 启动脚本
:: 此脚本用于在Windows系统上快速启动Quanshi系统

echo 正在启动Quanshi BAT文件合并系统...
echo.

:: 检查Python是否安装
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 未检测到Python安装!
    echo 请安装Python 3.6或更高版本后再试。
    echo 您可以从 https://www.python.org/downloads/ 下载Python。
    echo.
    pause
    exit /b 1
)

:: 检查启动器文件是否存在
if not exist "%~dp0quanshi_launcher.py" (
    echo 错误: 未找到quanshi_launcher.py文件!
    echo 请确保所有Quanshi系统文件都在当前目录中。
    echo.
    pause
    exit /b 1
)

:: 启动Quanshi系统
python "%~dp0quanshi_launcher.py"

:: 如果启动器返回错误，显示错误信息
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Quanshi系统运行时出现错误，错误代码: %ERRORLEVEL%
    echo.
    pause
)

exit /b 