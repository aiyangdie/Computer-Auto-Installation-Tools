@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo     Windows分类软件安装工具 (基于WinGet)
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
    echo 警告: 此脚本未以管理员身份运行，某些软件可能无法正确安装。
    echo 建议以管理员身份运行此脚本。
    echo.
    choice /C YN /M "是否继续？(Y/N)"
    if !ERRORLEVEL! EQU 2 goto :EOF
    echo.
)

:: 创建目录
set "categories_dir=%~dp0软件分类"
if not exist "%categories_dir%" mkdir "%categories_dir%"

:: 检查分类目录
if not exist "%categories_dir%\开发工具.txt" (
    echo 未找到分类文件，正在创建示例分类...
    
    :: 创建开发工具分类
    (
        echo # 开发工具列表
        echo Microsoft.VisualStudioCode      # VS Code
        echo Git.Git                         # Git版本控制
        echo Python.Python.3.12              # Python 3.12
        echo JetBrains.PyCharm.Community     # PyCharm社区版
        echo Microsoft.VisualStudio.2022.Community # Visual Studio 2022社区版
        echo OpenJS.NodeJS                   # Node.js
        echo Docker.DockerDesktop            # Docker桌面版
    ) > "%categories_dir%\开发工具.txt"
    
    :: 创建办公软件分类
    (
        echo # 办公软件列表
        echo Microsoft.Office                # Microsoft Office
        echo Tencent.TencentMeeting         # 腾讯会议
        echo Alibaba.DingTalk               # 钉钉
        echo Tencent.WeChat.Work            # 企业微信
        echo Youdao.YoudaoDict              # 有道词典
        echo Kingsoft.WPSOffice             # WPS Office
        echo Mozilla.Thunderbird            # Thunderbird邮件客户端
    ) > "%categories_dir%\办公软件.txt"
    
    :: 创建系统工具分类
    (
        echo # 系统工具列表
        echo Microsoft.PowerToys            # 微软PowerToys
        echo Microsoft.WindowsTerminal      # Windows终端
        echo 7zip.7zip                      # 7-Zip压缩工具
        echo voidtools.Everything           # Everything搜索工具
        echo CPUID.CPU-Z                    # CPU-Z硬件监测
        echo TechPowerUp.GPU-Z              # GPU-Z显卡监测
        echo REALiX.HWiNFO                  # HWiNFO系统信息
        echo Notepad++.Notepad++            # Notepad++文本编辑器
    ) > "%categories_dir%\系统工具.txt"
    
    :: 创建浏览器分类
    (
        echo # 浏览器列表
        echo Google.Chrome                  # Google Chrome
        echo Mozilla.Firefox                # Mozilla Firefox
        echo Microsoft.Edge                 # Microsoft Edge
        echo Opera.Opera                    # Opera浏览器
        echo Brave.Brave                    # Brave浏览器
    ) > "%categories_dir%\浏览器.txt"
    
    :: 创建聊天通讯分类
    (
        echo # 聊天通讯软件列表
        echo Tencent.WeChat                 # 微信
        echo Tencent.QQ                     # QQ
        echo Alibaba.AliWangwang            # 阿里旺旺
        echo Telegram.TelegramDesktop       # Telegram桌面版
        echo Discord.Discord                # Discord
    ) > "%categories_dir%\聊天通讯.txt"
    
    :: 创建多媒体分类
    (
        echo # 多媒体软件列表
        echo VideoLAN.VLC                   # VLC媒体播放器
        echo PotPlayer.PotPlayer            # PotPlayer视频播放器
        echo Daum.PotPlayer                 # PotPlayer另一个版本
        echo Tencent.QQMusic                # QQ音乐
        echo NetEase.CloudMusic             # 网易云音乐
        echo GIMP.GIMP                      # GIMP图像编辑器
        echo IrfanView.IrfanView            # IrfanView图像查看器
    ) > "%categories_dir%\多媒体.txt"
    
    echo 已创建示例分类文件在: %categories_dir%
    echo 你可以编辑这些文件来自定义每个分类的软件列表。
    echo.
)

:: 创建日志文件
set "logfile=%~dp0winget_install_log_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "logfile=%logfile: =0%"
echo 日志文件将保存在: %logfile%
echo.

:: 初始化日志文件
echo Windows分类软件安装日志 - %date% %time% > "%logfile%"
echo ============================================== >> "%logfile%"
echo. >> "%logfile%"

:menu
cls
echo 请选择要安装的软件分类:
echo.
set category_count=0

:: 列出所有分类
for %%f in ("%categories_dir%\*.txt") do (
    set /a category_count+=1
    set "category_name[!category_count!]=%%~nf"
    set "category_file[!category_count!]=%%f"
    echo [!category_count!] %%~nf
)

echo [A] 安装所有分类
echo [E] 编辑分类
echo [Q] 退出
echo.

set /p choice=请输入选项: 

:: 处理选择
if /i "%choice%"=="Q" goto end
if /i "%choice%"=="A" goto install_all
if /i "%choice%"=="E" goto edit_categories

:: 检查数字选择
set /a choice_num=%choice% 2>nul
if %choice_num% LSS 1 goto invalid_choice
if %choice_num% GTR %category_count% goto invalid_choice

:: 安装选定分类
call :install_category "!category_file[%choice_num%]!" "!category_name[%choice_num%]!"
goto menu

:invalid_choice
echo.
echo 无效的选择，请重试。
pause
goto menu

:install_all
echo.
echo 将安装所有分类的软件，这可能需要较长时间。
choice /C YN /M "是否继续？(Y/N)"
if %ERRORLEVEL% EQU 2 goto menu

for /l %%i in (1,1,%category_count%) do (
    call :install_category "!category_file[%%i]!" "!category_name[%%i]!"
)

echo.
echo 所有分类的软件安装已完成！
echo 详细日志请查看: %logfile%
echo.
pause
goto menu

:edit_categories
echo.
echo 请选择要编辑的分类文件:
echo.

for /l %%i in (1,1,%category_count%) do (
    echo [%%i] !category_name[%%i]!
)

echo [N] 创建新分类
echo [B] 返回主菜单
echo.

set /p edit_choice=请输入选项: 

if /i "%edit_choice%"=="B" goto menu
if /i "%edit_choice%"=="N" goto create_new_category

set /a edit_num=%edit_choice% 2>nul
if %edit_num% LSS 1 goto invalid_edit
if %edit_num% GTR %category_count% goto invalid_edit

:: 打开选定的分类文件进行编辑
start notepad "!category_file[%edit_num%]!"
goto menu

:invalid_edit
echo.
echo 无效的选择，请重试。
pause
goto edit_categories

:create_new_category
echo.
set /p new_category=请输入新分类名称: 

if "%new_category%"=="" (
    echo 分类名称不能为空！
    pause
    goto edit_categories
)

set "new_file=%categories_dir%\%new_category%.txt"

if exist "%new_file%" (
    echo 该分类已存在！
    pause
    goto edit_categories
)

(
    echo # %new_category%软件列表
    echo # 格式: [软件ID] # [软件说明]
    echo # 
    echo # 示例:
    echo # Microsoft.VisualStudioCode      # VS Code
) > "%new_file%"

echo.
echo 已创建新分类: %new_category%
echo 现在将打开编辑器以编辑该分类。
pause
start notepad "%new_file%"
goto menu

:install_category
set "category_file=%~1"
set "category_name=%~2"

echo.
echo ===================================================
echo 正在安装 %category_name% 分类的软件...
echo ===================================================
echo.

echo [%date% %time%] 开始安装 %category_name% 分类的软件... >> "%logfile%"
echo. >> "%logfile%"

set app_count=0
set success_count=0
set failed_count=0

:: 读取分类文件中的软件
for /f "tokens=1* delims= " %%a in ('type "%category_file%" ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set /a app_count+=1
    set "app_id=%%a"
    
    :: 尝试提取注释作为应用名称
    set "app_name=%%a"
    set "comment=%%b"
    if "%%b" NEQ "" (
        if "!comment:~0,1!" == "#" (
            set "app_name=!comment:~1!"
            set "app_name=!app_name:~1!"
        )
    )
    
    echo [!app_count!] 正在安装 !app_name! (!app_id!)...
    echo [%date% %time%] 正在安装 !app_name! (!app_id!)... >> "%logfile%"
    
    winget install --id !app_id! --accept-source-agreements --accept-package-agreements >> "%logfile%" 2>&1
    
    if !ERRORLEVEL! EQU 0 (
        set /a success_count+=1
        echo [成功] !app_name! 安装完成
        echo [%date% %time%] [成功] !app_name! 安装完成 >> "%logfile%"
    ) else (
        set /a failed_count+=1
        echo [失败] !app_name! 安装失败，错误代码: !ERRORLEVEL!
        echo [%date% %time%] [失败] !app_name! 安装失败，错误代码: !ERRORLEVEL! >> "%logfile%"
    )
    
    echo. >> "%logfile%"
    echo.
)

echo %category_name% 分类安装完成！成功: %success_count%，失败: %failed_count%
echo [%date% %time%] %category_name% 分类安装完成！成功: %success_count%，失败: %failed_count% >> "%logfile%"
echo. >> "%logfile%"

echo.
pause
exit /b

:end
echo.
echo 感谢使用Windows分类软件安装工具！
echo.
exit /b 0 