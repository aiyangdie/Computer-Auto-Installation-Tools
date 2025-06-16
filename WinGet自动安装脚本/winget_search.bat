@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo        Windows软件搜索工具 (基于WinGet)
echo ===================================================
echo.

:: 检查WinGet是否安装
where winget >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 未找到WinGet，请确保您的Windows版本支持WinGet并已安装。
    echo WinGet在Windows 10 1709及更高版本中可用。
    goto :EOF
)

:menu
cls
echo 请选择搜索方式:
echo.
echo [1] 关键词搜索
echo [2] 按分类搜索
echo [3] 按来源搜索
echo [4] 高级搜索（组合条件）
echo [5] 退出
echo.
set /p choice=请输入选项(1-5): 

if "%choice%"=="1" goto keyword_search
if "%choice%"=="2" goto category_search
if "%choice%"=="3" goto source_search
if "%choice%"=="4" goto advanced_search
if "%choice%"=="5" goto end

echo.
echo 无效的选择，请重试。
timeout /t 2 >nul
goto menu

:keyword_search
cls
echo ===================================================
echo                关键词搜索
echo ===================================================
echo.
echo 请输入要搜索的关键词，多个关键词用空格分隔
echo 例如: "video player" 或 "office pdf editor"
echo.
set /p keywords=搜索关键词: 

if "%keywords%"=="" (
    echo 搜索关键词不能为空！
    pause
    goto keyword_search
)

echo.
echo 正在搜索包含 "%keywords%" 的软件...
echo.

:: 调用搜索函数
call :do_search "%keywords%"

echo.
call :ask_install
goto menu

:category_search
cls
echo ===================================================
echo                分类搜索
echo ===================================================
echo.
echo 常用分类列表:
echo.
echo [1] 开发工具 (Development)
echo [2] 办公软件 (Productivity)
echo [3] 通信工具 (Communication)
echo [4] 媒体播放器 (Entertainment)
echo [5] 安全软件 (Security)
echo [6] 实用工具 (Utilities)
echo [7] 其他分类 (手动输入)
echo.
set /p cat_choice=请选择分类(1-7): 

set "category="
if "%cat_choice%"=="1" set "category=Development"
if "%cat_choice%"=="2" set "category=Productivity"
if "%cat_choice%"=="3" set "category=Communication"
if "%cat_choice%"=="4" set "category=Entertainment"
if "%cat_choice%"=="5" set "category=Security"
if "%cat_choice%"=="6" set "category=Utilities"
if "%cat_choice%"=="7" (
    echo.
    echo 请输入分类名称，例如: "Video" 或 "Graphics & Design"
    echo.
    set /p category=分类名称: 
)

if "%category%"=="" (
    echo 分类不能为空！
    pause
    goto category_search
)

echo.
echo 正在搜索分类为 "%category%" 的软件...
echo.

:: 搜索指定分类
winget search --tag "%category%"

echo.
call :ask_install
goto menu

:source_search
cls
echo ===================================================
echo                按来源搜索
echo ===================================================
echo.
echo 正在获取可用的软件来源...
echo.
winget source list

echo.
echo 常用来源:
echo [1] winget - Microsoft官方应用商店
echo [2] msstore - Microsoft Store
echo [3] 其他来源 (手动输入)
echo.
set /p source_choice=请选择来源(1-3): 

set "source="
if "%source_choice%"=="1" set "source=winget"
if "%source_choice%"=="2" set "source=msstore"
if "%source_choice%"=="3" (
    echo.
    set /p source=请输入来源名称: 
)

if "%source%"=="" (
    echo 来源不能为空！
    pause
    goto source_search
)

echo.
echo 请输入要在 "%source%" 中搜索的关键词(可选):
set /p keywords=搜索关键词: 

echo.
if "%keywords%"=="" (
    echo 正在搜索 "%source%" 来源的所有软件...
    winget search --source "%source%"
) else (
    echo 正在搜索 "%source%" 来源中包含 "%keywords%" 的软件...
    winget search "%keywords%" --source "%source%"
)

echo.
call :ask_install
goto menu

:advanced_search
cls
echo ===================================================
echo                高级搜索
echo ===================================================
echo.
echo 请输入搜索关键词(可选):
set /p keywords=搜索关键词: 

echo.
echo 请输入分类标签(可选):
set /p tag=分类标签: 

echo.
echo 请选择搜索来源:
echo [1] 所有来源
echo [2] winget
echo [3] msstore
echo [4] 其他来源
echo.
set /p source_choice=请选择(1-4): 

set "source="
if "%source_choice%"=="2" set "source=winget"
if "%source_choice%"=="3" set "source=msstore"
if "%source_choice%"=="4" (
    echo.
    set /p source=请输入来源名称: 
)

:: 构建命令
set "command=winget search"

if "%keywords%" NEQ "" (
    set "command=!command! "%keywords%""
)

if "%tag%" NEQ "" (
    set "command=!command! --tag "%tag%""
)

if "%source%" NEQ "" (
    set "command=!command! --source "%source%""
)

echo.
echo 执行搜索: !command!
echo.

:: 执行搜索
!command!

echo.
call :ask_install
goto menu

:: 执行搜索函数
:do_search
set "search_term=%~1"
winget search "%search_term%"
exit /b

:: 询问是否安装函数
:ask_install
echo.
echo 是否要安装以上列表中的软件？
choice /C YN /M "安装软件(Y/N):"
if %ERRORLEVEL% EQU 2 exit /b

echo.
set /p app_id=请输入要安装的软件ID(精确ID): 
if "%app_id%"=="" (
    echo 软件ID不能为空！
    goto ask_install
)

echo.
echo 正在安装 %app_id%...
echo.

:: 检查是否以管理员身份运行
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 警告: 此脚本未以管理员身份运行，某些软件可能无法正确安装。
    echo 建议以管理员身份运行此脚本。
    echo.
    choice /C YN /M "是否继续？(Y/N)"
    if !ERRORLEVEL! EQU 2 exit /b
    echo.
)

winget install --id "%app_id%" --accept-source-agreements --accept-package-agreements

echo.
echo 安装完成。是否继续安装其他软件？
choice /C YN /M "继续安装(Y/N):"
if %ERRORLEVEL% EQU 1 goto ask_install
exit /b

:end
echo.
echo 感谢使用Windows软件搜索工具！
echo.
exit /b 0 