@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo     Windows软件自动安装脚本 (基于WinGet)
echo ===================================================
echo.

:: 检查WinGet是否安装
where winget >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 未找到WinGet，请确保您的Windows版本支持WinGet并已安装。
    echo WinGet在Windows 10 1709及更高版本中可用。
    echo 如果您确定已安装，请尝试使用以下命令注册：
    echo Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
    goto :EOF
)

:: 检查是否以管理员身份运行
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 警告: 此脚本未以管理员身份运行，某些软件可能无法正确安装。
    echo 建议以管理员身份运行此脚本。
    echo.
    choice /C YN /M "是否继续？(Y/N)"
    if !ERRORLEVEL! EQU 2 goto :EOF
    echo.
)

echo WinGet版本信息:
winget --version
echo.

:: 创建日志文件
set "logfile=%~dp0winget_install_log_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "logfile=%logfile: =0%"
echo 日志文件将保存在: %logfile%
echo.

:: 初始化日志文件
echo Windows软件自动安装日志 - %date% %time% > "%logfile%"
echo ============================================== >> "%logfile%"
echo. >> "%logfile%"

:: 常用软件列表 - 可以根据需求修改
set "software_list=常用软件"
echo 将要安装的软件包括:
echo ---------------------------------------------

:: 系统工具
echo 系统工具:
echo - Microsoft.PowerToys
echo - Microsoft.WindowsTerminal
echo - CPUID.CPU-Z
echo - REALiX.HWiNFO
echo - Nvidia.GeForceExperience
echo - Twilio.Authy
echo - TechPowerUp.GPU-Z
echo - 7zip.7zip
echo - WinSCP.WinSCP
echo - voidtools.Everything
echo - Notepad++.Notepad++
echo.

:: 浏览器
echo 浏览器:
echo - Google.Chrome
echo - Mozilla.Firefox
echo - Microsoft.Edge
echo.

:: 开发工具
echo 开发工具:
echo - Git.Git
echo - Microsoft.VisualStudioCode
echo - Python.Python.3.12
echo - JetBrains.PyCharm.Community
echo - JetBrains.IntelliJIDEA.Community
echo.

:: 通讯工具
echo 通讯工具:
echo - Tencent.WeChat
echo - Tencent.QQ
echo - Tencent.TencentMeeting
echo - Alibaba.DingTalk
echo.

:: 其他工具
echo 其他工具:
echo - Bandisoft.Bandizip
echo - ByteDance.Douyin
echo - Baidu.BaiduNetdisk
echo - Baidu.BaiduTranslate
echo - Alibaba.aDrive
echo.

echo ---------------------------------------------
echo.
choice /C YN /M "是否继续安装？(Y/N)"
if %ERRORLEVEL% EQU 2 goto :EOF
echo.

echo 开始安装软件...
echo.

:: 系统工具
echo 正在安装系统工具...
call :install_app "Microsoft.PowerToys" "PowerToys"
call :install_app "Microsoft.WindowsTerminal" "Windows Terminal"
call :install_app "CPUID.CPU-Z" "CPU-Z"
call :install_app "REALiX.HWiNFO" "HWiNFO"
call :install_app "Nvidia.GeForceExperience" "GeForce Experience"
call :install_app "Twilio.Authy" "Authy"
call :install_app "TechPowerUp.GPU-Z" "GPU-Z"
call :install_app "7zip.7zip" "7-Zip"
call :install_app "WinSCP.WinSCP" "WinSCP"
call :install_app "voidtools.Everything" "Everything"
call :install_app "Notepad++.Notepad++" "Notepad++"

:: 浏览器
echo 正在安装浏览器...
call :install_app "Google.Chrome" "Google Chrome"
call :install_app "Mozilla.Firefox" "Mozilla Firefox"
call :install_app "Microsoft.Edge" "Microsoft Edge"

:: 开发工具
echo 正在安装开发工具...
call :install_app "Git.Git" "Git"
call :install_app "Microsoft.VisualStudioCode" "Visual Studio Code"
call :install_app "Python.Python.3.12" "Python 3.12"
call :install_app "JetBrains.PyCharm.Community" "PyCharm Community"
call :install_app "JetBrains.IntelliJIDEA.Community" "IntelliJ IDEA Community"

:: 通讯工具
echo 正在安装通讯工具...
call :install_app "Tencent.WeChat" "WeChat"
call :install_app "Tencent.QQ" "QQ"
call :install_app "Tencent.TencentMeeting" "Tencent Meeting"
call :install_app "Alibaba.DingTalk" "DingTalk"

:: 其他工具
echo 正在安装其他工具...
call :install_app "Bandisoft.Bandizip" "Bandizip"
call :install_app "ByteDance.Douyin" "Douyin"
call :install_app "Baidu.BaiduNetdisk" "Baidu Netdisk"
call :install_app "Baidu.BaiduTranslate" "Baidu Translate"
call :install_app "Alibaba.aDrive" "Alibaba Drive"

echo.
echo 所有软件安装已完成！
echo 详细日志请查看: %logfile%

:: 提示按任意键退出
echo.
pause
goto :EOF

:install_app
set "app_id=%~1"
set "app_name=%~2"
echo 正在安装 %app_name%...
echo [%date% %time%] 正在安装 %app_name% (%app_id%)... >> "%logfile%"
winget install --id %app_id% --accept-source-agreements --accept-package-agreements >> "%logfile%" 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [成功] %app_name% 安装完成
    echo [%date% %time%] [成功] %app_name% 安装完成 >> "%logfile%"
) else (
    echo [失败] %app_name% 安装失败，错误代码: %ERRORLEVEL%
    echo [%date% %time%] [失败] %app_name% 安装失败，错误代码: %ERRORLEVEL% >> "%logfile%"
)
echo. >> "%logfile%"
echo.
goto :EOF 