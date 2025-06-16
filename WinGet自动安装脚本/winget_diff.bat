@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo    Windows软件差异比较工具 (基于WinGet)
echo ===================================================
echo.

:: 检查WinGet是否安装
where winget >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 未找到WinGet，请确保您的Windows版本支持WinGet并已安装。
    echo WinGet在Windows 10 1709及更高版本中可用。
    goto :EOF
)

:: 设置文件路径
set "temp_dir=%TEMP%\winget_diff"
set "current_export=%temp_dir%\current_installed.json"
set "compare_export=%temp_dir%\compare_installed.json"
set "diff_file=%temp_dir%\software_diff.txt"

:: 创建临时目录
if not exist "%temp_dir%" mkdir "%temp_dir%"

:menu
cls
echo 选择操作:
echo.
echo [1] 导出当前电脑软件列表(第一步)
echo [2] 导入对比电脑软件列表并比较(第二步)
echo [3] 安装缺少的软件
echo [4] 删除临时文件
echo [5] 退出
echo.
set /p choice=请输入选项(1-5): 

if "%choice%"=="1" goto export_current
if "%choice%"=="2" goto import_compare
if "%choice%"=="3" goto install_missing
if "%choice%"=="4" goto cleanup
if "%choice%"=="5" goto end

echo.
echo 无效的选择，请重试。
timeout /t 2 >nul
goto menu

:export_current
cls
echo ===================================================
echo           导出当前电脑已安装软件列表
echo ===================================================
echo.
echo 正在导出当前电脑已安装的软件列表...
echo 这可能需要一段时间，请耐心等待...
echo.

if exist "%current_export%" (
    echo 警告: 已存在之前导出的文件 
    echo 路径: %current_export%
    echo.
    choice /C YN /M "是否覆盖? (Y/N)"
    if !ERRORLEVEL! EQU 2 goto menu
)

winget export -o "%current_export%" --accept-source-agreements

if %ERRORLEVEL% EQU 0 (
    echo.
    echo 导出成功! 文件保存在: %current_export%
    echo.
    echo 请将此文件复制到需要比较的另一台电脑上，
    echo 并在该电脑上运行本工具的第2步进行比较。
) else (
    echo.
    echo 导出失败，错误代码: %ERRORLEVEL%
)

echo.
pause
goto menu

:import_compare
cls
echo ===================================================
echo           导入对比电脑软件列表并比较
echo ===================================================
echo.

if not exist "%current_export%" (
    echo 错误: 未找到当前电脑的软件列表。
    echo 请先运行第1步导出当前电脑的软件列表。
    echo.
    pause
    goto menu
)

echo 请选择对比电脑软件列表文件的来源:
echo.
echo [1] 从其他电脑复制的JSON文件
echo [2] 导出当前电脑作为对比基准
echo [3] 返回主菜单
echo.
set /p source_choice=请输入选项(1-3): 

if "%source_choice%"=="1" (
    echo.
    echo 请将另一台电脑导出的JSON文件路径复制到下方
    echo 例如: C:\Users\用户名\Desktop\installed_software.json
    echo.
    set /p compare_file=文件路径: 
    
    if not exist "!compare_file!" (
        echo 错误: 未找到指定的文件: !compare_file!
        pause
        goto import_compare
    )
    
    copy "!compare_file!" "%compare_export%" >nul
    goto do_compare
)

if "%source_choice%"=="2" (
    echo.
    echo 正在导出当前电脑软件列表作为对比基准...
    echo.
    winget export -o "%compare_export%" --accept-source-agreements
    
    if %ERRORLEVEL% NEQ 0 (
        echo 导出失败，错误代码: %ERRORLEVEL%
        pause
        goto menu
    )
    
    goto do_compare
)

if "%source_choice%"=="3" goto menu

echo.
echo 无效的选择，请重试。
timeout /t 2 >nul
goto import_compare

:do_compare
cls
echo ===================================================
echo                 比较软件差异
echo ===================================================
echo.
echo 正在比较软件列表差异...
echo.

:: 创建或清空差异文件
echo 软件差异比较报告 > "%diff_file%"
echo 生成时间: %date% %time% >> "%diff_file%"
echo ================================================== >> "%diff_file%"
echo. >> "%diff_file%"

:: 提取软件ID列表
set "current_list=%temp_dir%\current_list.txt"
set "compare_list=%temp_dir%\compare_list.txt"

:: 提取当前电脑软件ID
type "%current_export%" | findstr /C:"PackageIdentifier" > "%current_list%"
:: 提取对比电脑软件ID
type "%compare_export%" | findstr /C:"PackageIdentifier" > "%compare_list%"

:: 清理提取的ID
set "current_list_clean=%temp_dir%\current_list_clean.txt"
set "compare_list_clean=%temp_dir%\compare_list_clean.txt"

:: 清理ID文本
type nul > "%current_list_clean%"
for /f "tokens=2 delims=: " %%a in ('type "%current_list%"') do (
    set "line=%%a"
    set "line=!line:"=!"
    set "line=!line:,=!"
    echo !line! >> "%current_list_clean%"
)

type nul > "%compare_list_clean%"
for /f "tokens=2 delims=: " %%a in ('type "%compare_list%"') do (
    set "line=%%a"
    set "line=!line:"=!"
    set "line=!line:,=!"
    echo !line! >> "%compare_list_clean%"
)

:: 找出当前电脑独有的软件（在对比电脑上缺少的软件）
echo 在当前电脑上安装但在对比电脑上缺少的软件: >> "%diff_file%"
echo ================================================== >> "%diff_file%"
set found_missing=0
for /f "usebackq tokens=*" %%a in ("%current_list_clean%") do (
    set found=0
    for /f "usebackq tokens=*" %%b in ("%compare_list_clean%") do (
        if "%%a"=="%%b" set found=1
    )
    if !found!==0 (
        echo %%a >> "%diff_file%"
        set found_missing=1
    )
)
if !found_missing!==0 echo [无] >> "%diff_file%"
echo. >> "%diff_file%"

:: 找出对比电脑独有的软件（在当前电脑上缺少的软件）
echo 在对比电脑上安装但在当前电脑上缺少的软件: >> "%diff_file%"
echo ================================================== >> "%diff_file%"
set found_missing=0
for /f "usebackq tokens=*" %%a in ("%compare_list_clean%") do (
    set found=0
    for /f "usebackq tokens=*" %%b in ("%current_list_clean%") do (
        if "%%a"=="%%b" set found=1
    )
    if !found!==0 (
        echo %%a >> "%diff_file%"
        set found_missing=1
    )
)
if !found_missing!==0 echo [无] >> "%diff_file%"

:: 提取缺少的软件到单独文件用于安装
set "missing_software=%temp_dir%\missing_software.txt"
echo 在对比电脑上安装但在当前电脑上缺少的软件: > "%missing_software%"
set found_missing=0
for /f "usebackq tokens=*" %%a in ("%compare_list_clean%") do (
    set found=0
    for /f "usebackq tokens=*" %%b in ("%current_list_clean%") do (
        if "%%a"=="%%b" set found=1
    )
    if !found!==0 (
        echo %%a >> "%missing_software%"
        set found_missing=1
    )
)

echo.
echo 比较完成！差异报告已保存到:
echo %diff_file%
echo.
echo 正在打开差异报告...
start notepad "%diff_file%"

echo.
pause
goto menu

:install_missing
cls
echo ===================================================
echo             安装缺少的软件
echo ===================================================
echo.

if not exist "%missing_software%" (
    echo 错误: 未找到缺少软件的列表。
    echo 请先运行第2步导入对比并生成差异报告。
    echo.
    pause
    goto menu
)

:: 检查缺少的软件列表是否为空
set "is_empty=1"
for /f "usebackq tokens=*" %%a in ("%missing_software%") do (
    set "line=%%a"
    if not "!line:~0,2!"=="在对" (
        set "is_empty=0"
    )
)

if "%is_empty%"=="1" (
    echo 没有发现缺少的软件。
    echo 当前电脑已包含对比电脑上的所有软件。
    echo.
    pause
    goto menu
)

echo 以下是当前电脑缺少的软件:
echo.
type "%missing_software%" | findstr /v "在对比电脑上安装但在当前电脑上缺少的软件:"
echo.
echo 请选择安装方式:
echo.
echo [1] 安装所有缺少的软件
echo [2] 选择性安装
echo [3] 返回主菜单
echo.
set /p install_choice=请输入选项(1-3): 

if "%install_choice%"=="1" goto install_all
if "%install_choice%"=="2" goto install_selective
if "%install_choice%"=="3" goto menu

echo.
echo 无效的选择，请重试。
timeout /t 2 >nul
goto install_missing

:install_all
cls
echo ===================================================
echo             安装所有缺少的软件
echo ===================================================
echo.

:: 检查是否以管理员身份运行
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 警告: 此脚本未以管理员身份运行，某些软件可能无法正确安装。
    echo 建议以管理员身份运行此脚本。
    echo.
    choice /C YN /M "是否继续？(Y/N)"
    if !ERRORLEVEL! EQU 2 goto install_missing
    echo.
)

echo 开始安装所有缺少的软件...
echo.

set installed=0
set failed=0

for /f "usebackq skip=1 tokens=*" %%a in ("%missing_software%") do (
    set "app_id=%%a"
    echo 正在安装: !app_id! ...
    winget install --id "!app_id!" --accept-source-agreements --accept-package-agreements
    
    if !ERRORLEVEL! EQU 0 (
        set /a installed+=1
        echo [成功] !app_id! 安装完成
    ) else (
        set /a failed+=1
        echo [失败] !app_id! 安装失败，错误代码: !ERRORLEVEL!
    )
    echo.
)

echo 安装完成！成功: %installed%，失败: %failed%
echo.
pause
goto menu

:install_selective
cls
echo ===================================================
echo             选择性安装缺少的软件
echo ===================================================
echo.

:: 检查是否以管理员身份运行
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 警告: 此脚本未以管理员身份运行，某些软件可能无法正确安装。
    echo 建议以管理员身份运行此脚本。
    echo.
    choice /C YN /M "是否继续？(Y/N)"
    if !ERRORLEVEL! EQU 2 goto install_missing
    echo.
)

echo 请输入要安装的软件ID (每次一个):
echo 输入 'exit' 返回主菜单
echo.
echo 缺少的软件列表:
echo ----------------------------------------
type "%missing_software%" | findstr /v "在对比电脑上安装但在当前电脑上缺少的软件:"
echo ----------------------------------------
echo.

:install_loop
set /p app_id=请输入软件ID: 

if /i "%app_id%"=="exit" goto menu

if "%app_id%"=="" (
    echo 软件ID不能为空！
    goto install_loop
)

echo.
echo 正在安装: %app_id% ...
winget install --id "%app_id%" --accept-source-agreements --accept-package-agreements

if %ERRORLEVEL% EQU 0 (
    echo [成功] %app_id% 安装完成
) else (
    echo [失败] %app_id% 安装失败，错误代码: %ERRORLEVEL%
)
echo.

goto install_loop

:cleanup
cls
echo ===================================================
echo             删除临时文件
echo ===================================================
echo.
echo 确定要删除所有临时文件吗?
echo 这将删除导出的软件列表和差异报告。
choice /C YN /M "确认删除? (Y/N)"
if %ERRORLEVEL% EQU 2 goto menu

echo.
echo 正在删除临时文件...
if exist "%temp_dir%" (
    rd /s /q "%temp_dir%" >nul 2>&1
    echo 临时文件已删除。
) else (
    echo 没有找到临时文件。
)

echo.
pause
goto menu

:end
echo.
echo 感谢使用Windows软件差异比较工具！
echo.
exit /b 0 