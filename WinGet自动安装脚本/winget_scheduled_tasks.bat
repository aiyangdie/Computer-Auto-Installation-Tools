@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo      Windows软件定时更新任务 (基于WinGet)
echo ===================================================
echo.

:: 检查是否以管理员身份运行
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 此脚本需要管理员权限才能创建计划任务。
    echo 请右键点击此脚本并选择"以管理员身份运行"。
    pause
    exit /b 1
)

:: 检查WinGet是否安装
where winget >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 未找到WinGet，请确保您的Windows版本支持WinGet并已安装。
    echo WinGet在Windows 10 1709及更高版本中可用。
    pause
    exit /b 1
)

:: 创建或检查更新脚本目录
set "scripts_dir=%ProgramData%\WingetAutomation"
if not exist "%scripts_dir%" mkdir "%scripts_dir%"

:menu
cls
echo 请选择操作:
echo.
echo [1] 创建每周自动更新任务
echo [2] 创建每月自动更新任务
echo [3] 创建自定义更新计划
echo [4] 查看现有的WinGet计划任务
echo [5] 删除现有的WinGet计划任务
echo [6] 退出
echo.
set /p choice=请输入选项(1-6): 

if "%choice%"=="1" goto weekly_update
if "%choice%"=="2" goto monthly_update
if "%choice%"=="3" goto custom_update
if "%choice%"=="4" goto list_tasks
if "%choice%"=="5" goto delete_task
if "%choice%"=="6" goto end

echo.
echo 无效的选择，请重试。
timeout /t 2 >nul
goto menu

:weekly_update
cls
echo ===================================================
echo             创建每周自动更新任务
echo ===================================================
echo.
echo 请选择每周更新的日期:
echo.
echo [1] 星期一
echo [2] 星期二
echo [3] 星期三
echo [4] 星期四
echo [5] 星期五
echo [6] 星期六
echo [7] 星期日
echo.
set /p day_choice=请选择(1-7): 

set "day_of_week="
if "%day_choice%"=="1" set "day_of_week=MON"
if "%day_choice%"=="2" set "day_of_week=TUE"
if "%day_choice%"=="3" set "day_of_week=WED"
if "%day_choice%"=="4" set "day_of_week=THU"
if "%day_choice%"=="5" set "day_of_week=FRI"
if "%day_choice%"=="6" set "day_of_week=SAT"
if "%day_choice%"=="7" set "day_of_week=SUN"

if "%day_of_week%"=="" (
    echo 无效的选择，请重试。
    timeout /t 2 >nul
    goto weekly_update
)

echo.
echo 请输入每周更新的时间(24小时制，例如 19:30):
set /p update_time=时间: 

:: 验证时间格式
echo %update_time%|findstr /r "^[0-2][0-9]:[0-5][0-9]$" >nul
if %ERRORLEVEL% NEQ 0 (
    echo 时间格式无效，请使用HH:MM格式(例如 19:30)
    pause
    goto weekly_update
)

:: 创建自动更新脚本
call :create_update_script

:: 创建每周任务
set "task_name=WinGet每周自动更新"
set "schedule=WEEKLY"
set "modifier=/DU 00:30 /RI 1 /D %day_of_week%"

call :create_scheduled_task "%task_name%" "%schedule%" "%update_time%" "%modifier%"

echo.
echo 成功创建每周自动更新任务，将在每%day_of_week%的%update_time%运行。
pause
goto menu

:monthly_update
cls
echo ===================================================
echo             创建每月自动更新任务
echo ===================================================
echo.
echo 请输入每月更新的日期(1-28):
set /p day_of_month=日期: 

:: 验证日期范围
if %day_of_month% LSS 1 (
    echo 日期必须在1-28之间
    pause
    goto monthly_update
)
if %day_of_month% GTR 28 (
    echo 日期必须在1-28之间（避免月底日期问题）
    pause
    goto monthly_update
)

echo.
echo 请输入每月更新的时间(24小时制，例如 19:30):
set /p update_time=时间: 

:: 验证时间格式
echo %update_time%|findstr /r "^[0-2][0-9]:[0-5][0-9]$" >nul
if %ERRORLEVEL% NEQ 0 (
    echo 时间格式无效，请使用HH:MM格式(例如 19:30)
    pause
    goto monthly_update
)

:: 创建自动更新脚本
call :create_update_script

:: 创建每月任务
set "task_name=WinGet每月自动更新"
set "schedule=MONTHLY"
set "modifier=/DU 00:30 /RI 1 /D %day_of_month%"

call :create_scheduled_task "%task_name%" "%schedule%" "%update_time%" "%modifier%"

echo.
echo 成功创建每月自动更新任务，将在每月%day_of_month%日的%update_time%运行。
pause
goto menu

:custom_update
cls
echo ===================================================
echo             创建自定义更新计划
echo ===================================================
echo.
echo 请选择更新频率:
echo.
echo [1] 每天
echo [2] 每周
echo [3] 每月
echo [4] 开机时
echo [5] 用户登录时
echo.
set /p freq_choice=请选择(1-5): 

set "schedule="
set "modifier="
set "prompt_time=1"

if "%freq_choice%"=="1" (
    set "schedule=DAILY"
    set "modifier=/DU 00:30 /RI 1"
    set "task_name=WinGet每天自动更新"
)
if "%freq_choice%"=="2" (
    goto weekly_update
)
if "%freq_choice%"=="3" (
    goto monthly_update
)
if "%freq_choice%"=="4" (
    set "schedule=ONSTART"
    set "modifier=/DELAY 0:15:00"
    set "task_name=WinGet开机自动更新"
    set "prompt_time=0"
)
if "%freq_choice%"=="5" (
    set "schedule=ONLOGON"
    set "modifier=/DELAY 0:10:00"
    set "task_name=WinGet登录自动更新"
    set "prompt_time=0"
)

if "%schedule%"=="" (
    echo 无效的选择，请重试。
    timeout /t 2 >nul
    goto custom_update
)

set "update_time=00:00"
if "%prompt_time%"=="1" (
    echo.
    echo 请输入更新的时间(24小时制，例如 19:30):
    set /p update_time=时间: 
    
    :: 验证时间格式
    echo %update_time%|findstr /r "^[0-2][0-9]:[0-5][0-9]$" >nul
    if %ERRORLEVEL% NEQ 0 (
        echo 时间格式无效，请使用HH:MM格式(例如 19:30)
        pause
        goto custom_update
    )
)

:: 创建自动更新脚本
call :create_update_script

:: 创建计划任务
call :create_scheduled_task "%task_name%" "%schedule%" "%update_time%" "%modifier%"

echo.
echo 成功创建自定义更新任务。
pause
goto menu

:list_tasks
cls
echo ===================================================
echo             查看现有WinGet计划任务
echo ===================================================
echo.
echo 正在查询WinGet相关的计划任务...
echo.

schtasks /query /fo list /v | findstr /i "winget" > "%temp%\winget_tasks.txt"
type "%temp%\winget_tasks.txt"

if %ERRORLEVEL% NEQ 0 (
    echo 未找到WinGet相关的计划任务。
)

echo.
pause
goto menu

:delete_task
cls
echo ===================================================
echo             删除WinGet计划任务
echo ===================================================
echo.
echo 现有的WinGet相关任务:
echo.

set task_count=0
set "task_list="

:: 列出所有WinGet相关任务
for /f "tokens=1 delims=:" %%a in ('schtasks /query /fo list ^| findstr /i /c:"TaskName:"') do (
    set "taskname=%%a"
    set "taskname=!taskname:~10!"
    
    echo !taskname! | findstr /i "winget" > nul
    if !ERRORLEVEL! EQU 0 (
        set /a task_count+=1
        set "task_name[!task_count!]=!taskname!"
        echo [!task_count!] !taskname!
    )
)

if %task_count% EQU 0 (
    echo 未找到WinGet相关的计划任务。
    pause
    goto menu
)

echo.
echo [0] 返回上级菜单
echo.
set /p task_choice=请选择要删除的任务编号: 

if "%task_choice%"=="0" goto menu

set /a task_num=%task_choice% 2>nul
if %task_num% LSS 1 goto delete_invalid
if %task_num% GTR %task_count% goto delete_invalid

set "selected_task=!task_name[%task_num%]!"

echo.
echo 确定要删除任务 "!selected_task!" 吗?
choice /C YN /M "删除任务(Y/N):"
if %ERRORLEVEL% EQU 2 goto delete_task

echo.
echo 正在删除任务 "!selected_task!"...
schtasks /delete /tn "!selected_task!" /f

if %ERRORLEVEL% EQU 0 (
    echo 任务已成功删除。
) else (
    echo 删除任务失败，错误代码: %ERRORLEVEL%
)

pause
goto menu

:delete_invalid
echo.
echo 无效的选择，请重试。
timeout /t 2 >nul
goto delete_task

:: 创建自动更新脚本函数
:create_update_script
set "update_script=%scripts_dir%\winget_auto_update.bat"
set "log_dir=%scripts_dir%\logs"

:: 创建日志目录
if not exist "%log_dir%" mkdir "%log_dir%"

:: 创建更新脚本
(
    echo @echo off
    echo setlocal enabledelayedexpansion
    echo.
    echo :: 创建日志文件
    echo set "logfile=%log_dir%\winget_update_%%date:~0,4%%%%date:~5,2%%%%date:~8,2%%_%%time:~0,2%%%%time:~3,2%%%%time:~6,2%%.txt"
    echo set "logfile=%%logfile: =0%%"
    echo.
    echo :: 初始化日志文件
    echo echo Windows软件自动更新日志 - %%date%% %%time%% ^> "%%logfile%%"
    echo echo ============================================== ^>^> "%%logfile%%"
    echo echo. ^>^> "%%logfile%%"
    echo.
    echo :: 列出可更新的软件
    echo echo 正在检查可更新的软件... ^>^> "%%logfile%%"
    echo echo. ^>^> "%%logfile%%"
    echo.
    echo winget upgrade ^>^> "%%logfile%%"
    echo.
    echo :: 更新所有软件
    echo echo. ^>^> "%%logfile%%"
    echo echo 正在更新所有软件... ^>^> "%%logfile%%"
    echo echo. ^>^> "%%logfile%%"
    echo.
    echo winget upgrade --all --accept-source-agreements --accept-package-agreements ^>^> "%%logfile%%" 2^>^&1
    echo.
    echo echo. ^>^> "%%logfile%%"
    echo echo 更新过程已完成！ ^>^> "%%logfile%%"
    echo echo. ^>^> "%%logfile%%"
    echo.
    echo exit /b 0
) > "%update_script%"

echo 已创建自动更新脚本: %update_script%
exit /b

:: 创建计划任务函数
:create_scheduled_task
set "task_name=%~1"
set "schedule=%~2"
set "update_time=%~3"
set "modifier=%~4"

:: 解析时间
for /f "tokens=1,2 delims=:" %%a in ("%update_time%") do (
    set "hour=%%a"
    set "minute=%%b"
)

:: 创建计划任务
schtasks /create /tn "%task_name%" /tr "%update_script%" /sc %schedule% /st %update_time% %modifier% /ru "SYSTEM" /rl HIGHEST /f

if %ERRORLEVEL% EQU 0 (
    echo 计划任务已成功创建。
) else (
    echo 创建计划任务失败，错误代码: %ERRORLEVEL%
)

exit /b

:end
echo.
echo 感谢使用Windows软件定时更新任务创建工具！
echo.
exit /b 0 