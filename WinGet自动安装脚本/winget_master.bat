@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo      Windows软件管理中心 (基于WinGet)
echo ===================================================
echo                 v1.0.0
echo.

:: 检查WinGet是否安装
where winget >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 未找到WinGet，请确保您的Windows版本支持WinGet并已安装。
    echo WinGet在Windows 10 1709及更高版本中可用。
    echo 您可以从Microsoft Store安装"应用安装程序"或访问GitHub下载WinGet。
    echo.
    echo GitHub链接: https://github.com/microsoft/winget-cli/releases
    echo.
    pause
    goto :EOF
)

:: 设置脚本路径
set "script_dir=%~dp0"
set "update_script=%script_dir%winget_update.bat"
set "export_import_script=%script_dir%winget_export_import.bat"
set "categories_script=%script_dir%winget_categories.bat"
set "search_script=%script_dir%winget_search.bat"
set "scheduled_tasks_script=%script_dir%winget_scheduled_tasks.bat"

:menu
cls
echo ===================================================
echo               Windows软件管理中心
echo ===================================================
echo.
echo 请选择要执行的操作:
echo.
echo [1] 搜索并安装软件          [7] 查看已安装软件
echo [2] 更新所有软件            [8] 系统配置管理
echo [3] 分类安装软件            [9] WinGet参数帮助
echo [4] 软件导出导入           [10] 关于本工具
echo [5] 创建定时更新任务       [11] 退出
echo [6] 卸载软件
echo.
set /p choice=请输入选项(1-11): 

if "%choice%"=="1" goto search
if "%choice%"=="2" goto update
if "%choice%"=="3" goto categories
if "%choice%"=="4" goto export_import
if "%choice%"=="5" goto scheduled_tasks
if "%choice%"=="6" goto uninstall
if "%choice%"=="7" goto list_installed
if "%choice%"=="8" goto system_config
if "%choice%"=="9" goto help
if "%choice%"=="10" goto about
if "%choice%"=="11" goto end

echo.
echo 无效的选择，请重试。
timeout /t 2 >nul
goto menu

:search
if exist "%search_script%" (
    call "%search_script%"
) else (
    echo 错误: 未找到搜索脚本文件: %search_script%
    echo 请确保所有脚本文件都在同一目录。
    pause
)
goto menu

:update
if exist "%update_script%" (
    call "%update_script%"
) else (
    echo 错误: 未找到更新脚本文件: %update_script%
    echo 请确保所有脚本文件都在同一目录。
    pause
)
goto menu

:categories
if exist "%categories_script%" (
    call "%categories_script%"
) else (
    echo 错误: 未找到分类脚本文件: %categories_script%
    echo 请确保所有脚本文件都在同一目录。
    pause
)
goto menu

:export_import
if exist "%export_import_script%" (
    call "%export_import_script%"
) else (
    echo 错误: 未找到导出导入脚本文件: %export_import_script%
    echo 请确保所有脚本文件都在同一目录。
    pause
)
goto menu

:scheduled_tasks
:: 检查是否以管理员身份运行
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 创建计划任务需要管理员权限。
    echo 请右键点击此脚本并选择"以管理员身份运行"。
    pause
    goto menu
)

if exist "%scheduled_tasks_script%" (
    call "%scheduled_tasks_script%"
) else (
    echo 错误: 未找到计划任务脚本文件: %scheduled_tasks_script%
    echo 请确保所有脚本文件都在同一目录。
    pause
)
goto menu

:uninstall
cls
echo ===================================================
echo               卸载已安装的软件
echo ===================================================
echo.
echo 请选择卸载方式:
echo.
echo [1] 按名称搜索并卸载
echo [2] 查看所有已安装软件并选择卸载
echo [3] 返回主菜单
echo.
set /p uninstall_choice=请输入选项(1-3): 

if "%uninstall_choice%"=="1" goto uninstall_search
if "%uninstall_choice%"=="2" goto uninstall_list
if "%uninstall_choice%"=="3" goto menu

echo.
echo 无效的选择，请重试。
timeout /t 2 >nul
goto uninstall

:uninstall_search
cls
echo ===================================================
echo              按名称搜索并卸载软件
echo ===================================================
echo.
echo 请输入要卸载的软件名称或关键词:
set /p uninstall_keyword=搜索关键词: 

if "%uninstall_keyword%"=="" (
    echo 搜索关键词不能为空！
    pause
    goto uninstall_search
)

echo.
echo 搜索匹配 "%uninstall_keyword%" 的已安装软件...
echo.

:: 搜索已安装的软件
winget list "%uninstall_keyword%"

echo.
echo 是否要卸载上述列表中的软件？
choice /C YN /M "卸载软件(Y/N):"
if %ERRORLEVEL% EQU 2 goto uninstall

echo.
set /p app_id=请输入要卸载的软件ID(精确ID): 
if "%app_id%"=="" (
    echo 软件ID不能为空！
    pause
    goto uninstall_search
)

echo.
echo 确定要卸载 %app_id% 吗?
choice /C YN /M "确认卸载(Y/N):"
if %ERRORLEVEL% EQU 2 goto uninstall_search

echo.
echo 正在卸载 %app_id%...
echo.

winget uninstall --id "%app_id%" --accept-source-agreements

echo.
echo 卸载完成。
pause
goto uninstall

:uninstall_list
cls
echo ===================================================
echo              查看并卸载已安装软件
echo ===================================================
echo.
echo 正在获取已安装的软件列表...
echo 这可能需要一些时间，请耐心等待...
echo.

winget list

echo.
echo 是否要卸载上述列表中的软件？
choice /C YN /M "卸载软件(Y/N):"
if %ERRORLEVEL% EQU 2 goto uninstall

echo.
set /p app_id=请输入要卸载的软件ID(精确ID): 
if "%app_id%"=="" (
    echo 软件ID不能为空！
    pause
    goto uninstall_list
)

echo.
echo 确定要卸载 %app_id% 吗?
choice /C YN /M "确认卸载(Y/N):"
if %ERRORLEVEL% EQU 2 goto uninstall_list

echo.
echo 正在卸载 %app_id%...
echo.

winget uninstall --id "%app_id%" --accept-source-agreements

echo.
echo 卸载完成。
pause
goto uninstall

:list_installed
cls
echo ===================================================
echo              查看已安装的软件
echo ===================================================
echo.
echo 请选择查看方式:
echo.
echo [1] 查看所有已安装软件
echo [2] 按名称搜索已安装软件
echo [3] 返回主菜单
echo.
set /p list_choice=请输入选项(1-3): 

if "%list_choice%"=="1" goto list_all
if "%list_choice%"=="2" goto list_search
if "%list_choice%"=="3" goto menu

echo.
echo 无效的选择，请重试。
timeout /t 2 >nul
goto list_installed

:list_all
cls
echo ===================================================
echo              所有已安装软件列表
echo ===================================================
echo.
echo 正在获取已安装的软件列表...
echo 这可能需要一些时间，请耐心等待...
echo.

winget list

echo.
echo [1] 返回上级菜单
echo [2] 返回主菜单
echo.
set /p back_choice=请输入选项(1-2): 

if "%back_choice%"=="1" goto list_installed
if "%back_choice%"=="2" goto menu

goto list_all

:list_search
cls
echo ===================================================
echo              搜索已安装软件
echo ===================================================
echo.
echo 请输入要搜索的软件名称或关键词:
set /p list_keyword=搜索关键词: 

if "%list_keyword%"=="" (
    echo 搜索关键词不能为空！
    pause
    goto list_search
)

echo.
echo 搜索匹配 "%list_keyword%" 的已安装软件...
echo.

winget list "%list_keyword%"

echo.
echo [1] 继续搜索
echo [2] 返回上级菜单
echo [3] 返回主菜单
echo.
set /p back_choice=请输入选项(1-3): 

if "%back_choice%"=="1" goto list_search
if "%back_choice%"=="2" goto list_installed
if "%back_choice%"=="3" goto menu

goto list_search

:system_config
cls
echo ===================================================
echo                系统配置管理
echo ===================================================
echo.
echo 请选择要执行的操作:
echo.
echo [1] 查看WinGet配置
echo [2] 查看WinGet源
echo [3] 添加WinGet源
echo [4] 重置WinGet源
echo [5] 返回主菜单
echo.
set /p config_choice=请输入选项(1-5): 

if "%config_choice%"=="1" goto view_config
if "%config_choice%"=="2" goto view_sources
if "%config_choice%"=="3" goto add_source
if "%config_choice%"=="4" goto reset_sources
if "%config_choice%"=="5" goto menu

echo.
echo 无效的选择，请重试。
timeout /t 2 >nul
goto system_config

:view_config
cls
echo ===================================================
echo                查看WinGet配置
echo ===================================================
echo.
echo 正在获取WinGet配置信息...
echo.

winget settings

echo.
pause
goto system_config

:view_sources
cls
echo ===================================================
echo                查看WinGet源
echo ===================================================
echo.
echo 正在获取WinGet源信息...
echo.

winget source list

echo.
pause
goto system_config

:add_source
cls
echo ===================================================
echo                添加WinGet源
echo ===================================================
echo.
echo 请输入要添加的源信息:
echo.
set /p source_name=源名称: 
set /p source_url=源URL: 

if "%source_name%"=="" (
    echo 源名称不能为空！
    pause
    goto add_source
)

if "%source_url%"=="" (
    echo 源URL不能为空！
    pause
    goto add_source
)

echo.
echo 正在添加源 "%source_name%"...
echo.

winget source add %source_name% %source_url%

echo.
pause
goto system_config

:reset_sources
cls
echo ===================================================
echo                重置WinGet源
echo ===================================================
echo.
echo 确定要重置所有WinGet源吗?
echo 这将删除所有自定义源并恢复默认源。
echo.
choice /C YN /M "重置源(Y/N):"
if %ERRORLEVEL% EQU 2 goto system_config

echo.
echo 正在重置WinGet源...
echo.

winget source reset --force

echo.
echo 重置完成。
pause
goto system_config

:help
cls
echo ===================================================
echo                WinGet参数帮助
echo ===================================================
echo.
echo 选择要查看的命令帮助:
echo.
echo [1] winget （整体帮助）
echo [2] winget install （安装命令）
echo [3] winget search （搜索命令）
echo [4] winget list （列表命令）
echo [5] winget upgrade （更新命令）
echo [6] winget uninstall （卸载命令）
echo [7] winget export/import （导出导入命令）
echo [8] winget source （源管理命令）
echo [9] 返回主菜单
echo.
set /p help_choice=请输入选项(1-9): 

if "%help_choice%"=="1" (
    cls
    winget --help
)
if "%help_choice%"=="2" (
    cls
    winget install --help
)
if "%help_choice%"=="3" (
    cls
    winget search --help
)
if "%help_choice%"=="4" (
    cls
    winget list --help
)
if "%help_choice%"=="5" (
    cls
    winget upgrade --help
)
if "%help_choice%"=="6" (
    cls
    winget uninstall --help
)
if "%help_choice%"=="7" (
    cls
    echo ===== EXPORT 命令帮助 =====
    winget export --help
    echo.
    echo ===== IMPORT 命令帮助 =====
    winget import --help
)
if "%help_choice%"=="8" (
    cls
    winget source --help
)
if "%help_choice%"=="9" goto menu

echo.
pause
goto help

:about
cls
echo ===================================================
echo               关于Windows软件管理中心
echo ===================================================
echo.
echo 版本: 1.0.0
echo.
echo 功能概述:
echo - 搜索并安装Windows软件
echo - 批量更新已安装的软件
echo - 按分类安装常用软件
echo - 导出导入软件配置（多电脑同步）
echo - 设置自动更新计划任务
echo - 卸载管理已安装软件
echo - 系统配置与源管理
echo.
echo 本工具基于微软WinGet包管理器，为Windows系统提供简便的
echo 软件管理解决方案。适用于个人电脑自动化部署和日常维护。
echo.
echo 作者: 自动安装程序生成工具
echo.
pause
goto menu

:end
echo.
echo 感谢使用Windows软件管理中心！
echo.
exit /b 0 