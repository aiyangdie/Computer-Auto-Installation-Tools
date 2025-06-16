@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo     Windows软件自定义安装脚本 (基于WinGet)
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

:: 检查软件列表文件是否存在
set "software_list_file=%~dp0software_list.txt"
if not exist "%software_list_file%" (
    echo 未找到软件列表文件 software_list.txt
    echo 正在创建一个示例文件，请根据需要修改后再次运行此脚本。
    
    (
        echo # 软件列表文件 - 每行一个软件ID，井号开头的行为注释
        echo # 格式: [软件ID] [可选说明]
        echo.
        echo # 系统工具
        echo Microsoft.PowerToys                  # PowerToys
        echo Microsoft.WindowsTerminal            # Windows Terminal
        echo CPUID.CPU-Z                          # CPU-Z
        echo voidtools.Everything                 # Everything搜索工具
        echo Notepad++.Notepad++                  # Notepad++编辑器
        echo.
        echo # 浏览器
        echo Google.Chrome                        # Google Chrome
        echo Mozilla.Firefox                      # Mozilla Firefox
        echo Microsoft.Edge                       # Microsoft Edge
        echo.
        echo # 开发工具
        echo Git.Git                              # Git版本控制
        echo Microsoft.VisualStudioCode           # VS Code
        echo Python.Python.3.12                   # Python 3.12
        echo.
        echo # 通讯工具
        echo Tencent.WeChat                       # 微信
        echo Tencent.QQ                           # QQ
        echo.
        echo # 其他工具
        echo 7zip.7zip                            # 7-Zip解压缩
        echo Bandisoft.Bandizip                   # Bandizip解压缩
        echo Baidu.BaiduNetdisk                   # 百度网盘
    ) > "%software_list_file%"
    
    echo 已创建示例软件列表文件: %software_list_file%
    echo 请编辑该文件以自定义要安装的软件，然后再次运行此脚本。
    echo.
    pause
    goto :EOF
)

:: 创建日志文件
set "logfile=%~dp0winget_install_log_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "logfile=%logfile: =0%"
echo 日志文件将保存在: %logfile%
echo.

:: 初始化日志文件
echo Windows软件自动安装日志 - %date% %time% > "%logfile%"
echo ============================================== >> "%logfile%"
echo. >> "%logfile%"

:: 读取软件列表
echo 从 %software_list_file% 读取要安装的软件列表:
echo ---------------------------------------------
set "app_count=0"
for /f "tokens=1* delims= " %%a in ('type "%software_list_file%" ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set /a "app_count+=1"
    set "app_id[!app_count!]=%%a"
    
    :: 尝试提取注释作为应用名称
    set "app_name[!app_count!]=%%a"
    if "%%b" NEQ "" (
        set "comment=%%b"
        if "!comment:~0,1!" == "#" (
            set "app_name[!app_count!]=!comment:~1!"
            set "app_name[!app_count!]=!app_name[!app_count!]:~1!"
        )
    )
    
    echo !app_count!. !app_id[!app_count!]! - !app_name[!app_count!]!
)
echo ---------------------------------------------
echo 共找到 %app_count% 个应用程序
echo.

if %app_count% EQU 0 (
    echo 未在软件列表文件中找到任何有效的软件条目。
    echo 请编辑文件 %software_list_file% 添加要安装的软件。
    pause
    goto :EOF
)

choice /C YN /M "是否继续安装上述软件？(Y/N)"
if %ERRORLEVEL% EQU 2 goto :EOF
echo.

echo 开始安装软件...
echo.

:: 安装软件
set "success_count=0"
set "failed_count=0"

for /l %%i in (1, 1, %app_count%) do (
    set "current_id=!app_id[%%i]!"
    set "current_name=!app_name[%%i]!"
    
    echo [%%i/%app_count%] 正在安装 !current_name! (!current_id!)...
    echo [%date% %time%] 正在安装 !current_name! (!current_id!)... >> "%logfile%"
    
    winget install --id !current_id! --accept-source-agreements --accept-package-agreements >> "%logfile%" 2>&1
    
    if !ERRORLEVEL! EQU 0 (
        set /a "success_count+=1"
        echo [成功] !current_name! 安装完成
        echo [%date% %time%] [成功] !current_name! 安装完成 >> "%logfile%"
    ) else (
        set /a "failed_count+=1"
        echo [失败] !current_name! 安装失败，错误代码: !ERRORLEVEL!
        echo [%date% %time%] [失败] !current_name! 安装失败，错误代码: !ERRORLEVEL! >> "%logfile%"
    )
    
    echo. >> "%logfile%"
    echo.
)

echo 安装完成！成功: %success_count%，失败: %failed_count%
echo [%date% %time%] 安装完成！成功: %success_count%，失败: %failed_count% >> "%logfile%"
echo 详细日志请查看: %logfile%

:: 提示按任意键退出
echo.
pause
goto :EOF 