@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo     Windows软件包管理器修复工具 (WinGet修复)
echo ===================================================
echo.

:: 获取管理员权限
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 此工具需要管理员权限才能执行修复操作。
    echo 请右键点击此脚本并选择"以管理员身份运行"。
    pause
    exit /b 1
)

:: 设置日志文件
set "log_dir=%TEMP%\winget_repair_logs"
if not exist "%log_dir%" mkdir "%log_dir%"

set "log_file=%log_dir%\repair_log_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "log_file=%log_file: =0%"

echo Windows软件包管理器修复日志 > "%log_file%"
echo 日期: %date% 时间: %time% >> "%log_file%"
echo ================================================== >> "%log_file%"
echo. >> "%log_file%"

:menu
cls
echo 请选择要执行的修复操作:
echo.
echo [1] 检查WinGet状态
echo [2] 重置WinGet源
echo [3] 重置应用商店缓存
echo [4] 修复WinGet组件
echo [5] 修复网络连接问题
echo [6] 清理WinGet缓存
echo [7] 重新安装WinGet
echo [8] 查看诊断信息
echo [9] 退出
echo.
set /p choice=请输入选项(1-9): 

if "%choice%"=="1" goto check_status
if "%choice%"=="2" goto reset_sources
if "%choice%"=="3" goto reset_store_cache
if "%choice%"=="4" goto repair_components
if "%choice%"=="5" goto fix_network
if "%choice%"=="6" goto clean_cache
if "%choice%"=="7" goto reinstall_winget
if "%choice%"=="8" goto diagnostics
if "%choice%"=="9" goto end

echo.
echo 无效的选择，请重试。
timeout /t 2 >nul
goto menu

:check_status
cls
echo ===================================================
echo                检查WinGet状态
echo ===================================================
echo.

echo 正在检查WinGet是否已安装...
echo.

echo 检查WinGet版本: >> "%log_file%"
where winget >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo WinGet已安装。
    echo WinGet已安装。 >> "%log_file%"
    echo.
    echo WinGet版本信息:
    winget --version
    winget --version >> "%log_file%"
    echo. >> "%log_file%"
) else (
    echo WinGet未安装或无法找到。
    echo WinGet未安装或无法找到。 >> "%log_file%"
    echo. >> "%log_file%"
    goto winget_not_found
)

echo.
echo 检查WinGet源状态...
echo.

echo 检查WinGet源状态: >> "%log_file%"
echo. >> "%log_file%"

winget source list
winget source list >> "%log_file%" 2>&1
echo. >> "%log_file%"

echo.
echo 检查应用安装器服务状态...
echo.

echo 检查应用安装器服务状态: >> "%log_file%"
sc query appinstaller > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo 应用安装器服务已安装。
    echo 应用安装器服务已安装。 >> "%log_file%"
) else (
    echo 应用安装器服务未安装或无法访问。
    echo 应用安装器服务未安装或无法访问。 >> "%log_file%"
)
echo. >> "%log_file%"

echo.
echo 检查Microsoft Store状态...
echo.

echo 检查Microsoft Store状态: >> "%log_file%"
powershell -Command "Get-AppxPackage -Name Microsoft.WindowsStore" > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Microsoft Store已安装。
    echo Microsoft Store已安装。 >> "%log_file%"
) else (
    echo Microsoft Store未安装或已损坏。
    echo Microsoft Store未安装或已损坏。 >> "%log_file%"
)
echo. >> "%log_file%"

echo.
echo 检查完成。请查看上面的信息确定WinGet的状态。
echo 如果发现问题，请选择相应的修复选项。
echo.
pause
goto menu

:reset_sources
cls
echo ===================================================
echo                重置WinGet源
echo ===================================================
echo.

echo 正在检查WinGet源状态...
echo.
winget source list
echo.

echo 是否要重置所有WinGet源？这将删除所有自定义源并恢复默认源。
choice /C YN /M "确认重置？(Y/N)"
if %ERRORLEVEL% EQU 2 goto menu

echo.
echo 正在重置WinGet源...
echo 重置WinGet源: >> "%log_file%"
winget source reset --force
echo 退出代码: %ERRORLEVEL% >> "%log_file%"
echo. >> "%log_file%"

echo.
echo 重置完成。正在验证源状态...
echo.
echo 重置后源状态: >> "%log_file%"
winget source list
winget source list >> "%log_file%"
echo. >> "%log_file%"

echo.
pause
goto menu

:reset_store_cache
cls
echo ===================================================
echo               重置应用商店缓存
echo ===================================================
echo.

echo 警告: 此操作将重置Microsoft Store和应用安装器的缓存。
echo 这可能会导致您需要重新登录商店账户。
echo.
choice /C YN /M "确认继续？(Y/N)"
if %ERRORLEVEL% EQU 2 goto menu

echo.
echo 正在重置Microsoft Store缓存...
echo 重置Microsoft Store缓存: >> "%log_file%"
echo.

echo 1. 停止Store相关服务...
net stop wuauserv > nul 2>&1
net stop bits > nul 2>&1
net stop appidsvc > nul 2>&1
echo 服务已停止。

echo 2. 清理Store缓存...
rd /s /q "%localappdata%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache" 2> nul
rd /s /q "%localappdata%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState" 2> nul
echo 缓存已清理。

echo 3. 重启服务...
net start wuauserv > nul 2>&1
net start bits > nul 2>&1
net start appidsvc > nul 2>&1
echo 服务已重启。

echo 4. 重置应用安装器缓存...
powershell -Command "Get-AppxPackage -Name Microsoft.DesktopAppInstaller | Reset-AppxPackage" >> "%log_file%" 2>&1
if %ERRORLEVEL% EQU 0 (
    echo 应用安装器已重置。
) else (
    echo 重置应用安装器时出错，错误代码: %ERRORLEVEL%
)

echo.
echo 缓存重置完成。建议重启电脑以完成修复过程。
echo 缓存重置完成。 >> "%log_file%"
echo. >> "%log_file%"

echo.
pause
goto menu

:repair_components
cls
echo ===================================================
echo              修复WinGet组件
echo ===================================================
echo.

echo 此操作将尝试修复WinGet和相关组件。
echo.

echo 1. 验证WinGet基本功能...
where winget >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WinGet未安装或无法找到，请先尝试重新安装WinGet。
    pause
    goto menu
)

echo 2. 检查Windows应用安装器包...
echo 检查Windows应用安装器包: >> "%log_file%"
powershell -Command "Get-AppxPackage -Name Microsoft.DesktopAppInstaller" | findstr "PackageFullName" > nul
if %ERRORLEVEL% NEQ 0 (
    echo 未找到Windows应用安装器包。
    echo 未找到Windows应用安装器包。 >> "%log_file%"
    echo 将尝试重新安装...
    echo 尝试重新安装应用安装器... >> "%log_file%"
    
    echo.
    echo 正在尝试从Microsoft Store安装应用安装器...
    powershell -Command "Start-Process 'ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1'"
    echo 请在Microsoft Store中完成安装，然后按任意键继续...
    pause > nul
) else (
    echo Windows应用安装器包已找到。
    echo Windows应用安装器包已找到。 >> "%log_file%"
)
echo. >> "%log_file%"

echo 3. 修复WinGet注册表项...
echo 修复WinGet注册表项: >> "%log_file%"
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /f > nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 1 /f > nul 2>&1
echo 注册表项已修复。
echo 注册表项已修复。 >> "%log_file%"
echo. >> "%log_file%"

echo 4. 重置应用安装器...
echo 重置应用安装器: >> "%log_file%"
powershell -Command "Get-AppxPackage -Name Microsoft.DesktopAppInstaller | Reset-AppxPackage" >> "%log_file%" 2>&1
echo 应用安装器已重置。
echo. >> "%log_file%"

echo 5. 验证修复结果...
where winget >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo WinGet命令可用，修复可能已成功。
    echo WinGet命令可用，修复可能已成功。 >> "%log_file%"
    echo.
    echo 验证WinGet版本:
    winget --version
    winget --version >> "%log_file%"
) else (
    echo WinGet命令仍然不可用，可能需要重新安装。
    echo WinGet命令仍然不可用，可能需要重新安装。 >> "%log_file%"
    echo 请尝试"重新安装WinGet"选项。
)
echo. >> "%log_file%"

echo.
echo 修复操作完成。建议重启电脑以完成修复过程。
echo.
pause
goto menu

:fix_network
cls
echo ===================================================
echo              修复网络连接问题
echo ===================================================
echo.

echo 此操作将尝试修复可能影响WinGet的网络问题。
echo.

echo 1. 检查网络连接...
ping -n 1 www.microsoft.com > nul
if %ERRORLEVEL% NEQ 0 (
    echo 警告: 无法连接到Microsoft服务器。
    echo 请确保您的网络连接正常工作。
    echo.
    pause
    goto menu
)

echo 2. 重置网络设置...
echo 重置网络设置: >> "%log_file%"
echo a. 重置网络适配器...
ipconfig /release > nul
ipconfig /flushdns > nul
ipconfig /renew > nul
echo 网络适配器已重置。

echo b. 重置Winsock...
netsh winsock reset catalog >> "%log_file%" 2>&1
echo Winsock已重置。

echo c. 重置Windows防火墙...
netsh advfirewall reset >> "%log_file%" 2>&1
echo 防火墙已重置。

echo d. 重置HTTP/HTTPS设置...
netsh winhttp reset proxy >> "%log_file%" 2>&1
echo HTTP设置已重置。
echo. >> "%log_file%"

echo 3. 配置WinGet源...
echo 配置WinGet源: >> "%log_file%"
winget source reset --force >> "%log_file%" 2>&1
echo WinGet源已重置。
echo. >> "%log_file%"

echo 4. 验证网络连接...
echo 验证网络连接: >> "%log_file%"
ping www.microsoft.com -n 2 >> "%log_file%" 2>&1
if %ERRORLEVEL% EQU 0 (
    echo 网络连接正常。
    echo 网络连接正常。 >> "%log_file%"
) else (
    echo 网络连接仍有问题，请检查网络设置或咨询网络管理员。
    echo 网络连接仍有问题。 >> "%log_file%"
)
echo. >> "%log_file%"

echo.
echo 网络设置已重置。建议重启电脑以完成网络修复过程。
echo.
pause
goto menu

:clean_cache
cls
echo ===================================================
echo               清理WinGet缓存
echo ===================================================
echo.

echo 此操作将清理WinGet的缓存文件和临时数据。
echo.
choice /C YN /M "确认继续？(Y/N)"
if %ERRORLEVEL% EQU 2 goto menu

echo.
echo 正在清理WinGet缓存...
echo 清理WinGet缓存: >> "%log_file%"

echo 1. 清理WinGet本地存储库缓存...
set "local_cache=%LOCALAPPDATA%\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalCache\Microsoft\WinGet"
if exist "%local_cache%" (
    rd /s /q "%local_cache%" > nul 2>&1
    mkdir "%local_cache%" > nul 2>&1
    echo WinGet本地存储库缓存已清理。
    echo WinGet本地存储库缓存已清理。 >> "%log_file%"
) else (
    echo 未找到WinGet本地缓存目录。
    echo 未找到WinGet本地缓存目录。 >> "%log_file%"
)

echo 2. 清理WinGet源缓存...
winget source reset --force > nul 2>&1
echo WinGet源缓存已清理。
echo WinGet源缓存已清理。 >> "%log_file%"

echo 3. 清理临时下载文件...
set "temp_files=%TEMP%\WinGet"
if exist "%temp_files%" (
    rd /s /q "%temp_files%" > nul 2>&1
    echo WinGet临时文件已清理。
    echo WinGet临时文件已清理。 >> "%log_file%"
) else (
    echo 未找到WinGet临时文件目录。
    echo 未找到WinGet临时文件目录。 >> "%log_file%"
)

echo.
echo WinGet缓存清理完成。
echo WinGet缓存清理完成。 >> "%log_file%"
echo. >> "%log_file%"

echo.
pause
goto menu

:reinstall_winget
cls
echo ===================================================
echo               重新安装WinGet
echo ===================================================
echo.

echo 此操作将尝试卸载并重新安装WinGet。
echo.
choice /C YN /M "确认继续？(Y/N)"
if %ERRORLEVEL% EQU 2 goto menu

echo.
echo 1. 卸载现有的WinGet...
echo 卸载现有的WinGet: >> "%log_file%"
powershell -Command "Get-AppxPackage -Name Microsoft.DesktopAppInstaller | Remove-AppxPackage" >> "%log_file%" 2>&1

if %ERRORLEVEL% EQU 0 (
    echo WinGet已成功卸载。
) else (
    echo 卸载WinGet时出错，错误代码: %ERRORLEVEL%
    echo 将继续尝试安装新版本。
)

echo 2. 提供安装选项...
echo.
echo 请选择WinGet安装方式:
echo.
echo [1] 从Microsoft Store安装 (推荐)
echo [2] 从GitHub下载最新版本手动安装
echo [3] 返回上级菜单
echo.
set /p install_choice=请输入选项(1-3): 

if "%install_choice%"=="1" (
    echo.
    echo 正在打开Microsoft Store...
    powershell -Command "Start-Process 'ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1'"
    echo 请在Microsoft Store中完成安装，然后按任意键继续...
    pause > nul
) else if "%install_choice%"=="2" (
    echo.
    echo 正在打开GitHub下载页面...
    start https://github.com/microsoft/winget-cli/releases
    echo 请下载并安装最新版本的WinGet，然后按任意键继续...
    pause > nul
) else if "%install_choice%"=="3" (
    goto menu
) else (
    echo 无效的选择，返回上级菜单...
    timeout /t 2 >nul
    goto reinstall_winget
)

echo 3. 验证安装...
echo.
echo 正在验证WinGet安装...
where winget >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo WinGet已成功安装！
    echo 版本信息:
    winget --version
    echo.
    echo 重新安装成功。
    echo WinGet已成功安装，版本: >> "%log_file%"
    winget --version >> "%log_file%"
) else (
    echo WinGet安装验证失败。
    echo 请确保已完成安装过程或尝试其他安装方法。
    echo WinGet安装验证失败。 >> "%log_file%"
)
echo. >> "%log_file%"

echo.
pause
goto menu

:winget_not_found
echo.
echo WinGet未安装或无法找到。建议尝试以下解决方案:
echo.
echo [1] 从Microsoft Store安装应用安装器
echo [2] 从GitHub下载WinGet最新版本
echo [3] 返回主菜单
echo.
set /p install_choice=请输入选项(1-3): 

if "%install_choice%"=="1" (
    echo.
    echo 正在打开Microsoft Store...
    powershell -Command "Start-Process 'ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1'"
    echo 请在Microsoft Store中完成安装，然后按任意键继续...
    pause > nul
    goto check_status
) else if "%install_choice%"=="2" (
    echo.
    echo 正在打开GitHub下载页面...
    start https://github.com/microsoft/winget-cli/releases
    echo 请下载并安装最新版本的WinGet，然后按任意键继续...
    pause > nul
    goto check_status
) else if "%install_choice%"=="3" (
    goto menu
) else (
    echo 无效的选择，返回上级菜单...
    timeout /t 2 >nul
    goto menu
)

:diagnostics
cls
echo ===================================================
echo               查看诊断信息
echo ===================================================
echo.

echo 正在收集系统和WinGet诊断信息...
echo.

echo 诊断信息收集: >> "%log_file%"
echo. >> "%log_file%"

echo 1. 系统信息:
echo 系统信息: >> "%log_file%"
systeminfo | findstr /C:"OS" >> "%log_file%"
echo. >> "%log_file%"

echo 2. WinGet信息:
echo WinGet信息: >> "%log_file%"
where winget >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    winget --info >> "%log_file%" 2>&1
) else (
    echo WinGet未安装或不可用。 >> "%log_file%"
)
echo. >> "%log_file%"

echo 3. 应用安装器包信息:
echo 应用安装器包信息: >> "%log_file%"
powershell -Command "Get-AppxPackage -Name Microsoft.DesktopAppInstaller" >> "%log_file%" 2>&1
echo. >> "%log_file%"

echo 4. WinGet源信息:
echo WinGet源信息: >> "%log_file%"
where winget >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    winget source list >> "%log_file%" 2>&1
) else (
    echo WinGet未安装或不可用。 >> "%log_file%"
)
echo. >> "%log_file%"

echo 5. 网络连接状态:
echo 网络连接状态: >> "%log_file%"
ipconfig /all | findstr /C:"IPv4" >> "%log_file%"
echo. >> "%log_file%"
ping -n 2 www.microsoft.com >> "%log_file%" 2>&1
echo. >> "%log_file%"

echo 6. Windows更新服务状态:
echo Windows更新服务状态: >> "%log_file%"
sc query wuauserv >> "%log_file%" 2>&1
echo. >> "%log_file%"

echo 7. Microsoft Store服务状态:
echo Microsoft Store服务状态: >> "%log_file%"
powershell -Command "Get-AppxPackage -Name Microsoft.WindowsStore" >> "%log_file%" 2>&1
echo. >> "%log_file%"

echo.
echo 诊断信息收集完成！
echo 日志文件保存在: %log_file%
echo.
echo 是否要查看诊断日志文件?
choice /C YN /M "查看日志文件? (Y/N)"
if %ERRORLEVEL% EQU 1 (
    start notepad "%log_file%"
)

echo.
pause
goto menu

:end
echo.
echo 感谢使用Windows软件包管理器修复工具！
echo 日志文件已保存在: %log_file%
echo.
exit /b 0
