@echo off
rem ===========================================================================
rem  《细胞到奇点》存档修改工具箱 —— 交互式菜单
rem  原始项目: https://github.com/hysltway/cell-to-singularity-save-editor
rem  本文件是 SapphireAero 制作的修改版本 (fork)
rem  原项目未声明任何许可证；原始代码著作权归原作者 hysltway 所有。
rem  相对原版的改动详见 README 第 6.2 节「来源与许可」。
rem ===========================================================================
rem 记住进入前的控制台代码页，退出时还原，避免把用户窗口永久留在 65001
for /f "tokens=2 delims=:" %%a in ('chcp') do for /f "tokens=1" %%b in ("%%a") do set "OLDCP=%%b"
chcp 65001 >nul
setlocal enabledelayedexpansion
title 《细胞到奇点》存档修改工具箱Sap版
cd /d "%~dp0"

:MENU
cls
echo =================================================================
echo        《细胞到奇点》(Cell to Singularity) 存档修改与管理工具箱 Sap版
echo =================================================================
echo.
echo   [1] 查看当前存档状态（各货币、资源与统计概况）
echo   [2] 修改粉色达尔文 (内购货币 Darwinium)
echo   [3] 修改罗吉特 (成就货币 Logits / Doobers)
echo   [4] 修改熵 (默认货币 Entropy)
echo   [5] 修改想法 (人类货币 Ideas)
echo   [6] 修改化石/中生代突变剂 (恐龙货币 Mutagen / 恐龙化石)
echo   [7] 修改超越篇星尘/暗物质 (星际货币 Stardust / Dark Matter)
echo   [8] 导出完整存档为 JSON 格式
echo   [9] 创建当前存档的安全备份
echo   [10] 重新编译 SaveEditor 源码
echo   [0] 退出
echo.
echo =================================================================
set /p choice="请输入选项编号 [0-10]: "

if "%choice%"=="1" goto STATUS
if "%choice%"=="2" goto SET_DARWIN
if "%choice%"=="3" goto SET_LOGIT
if "%choice%"=="4" goto SET_ENTROPY
if "%choice%"=="5" goto SET_IDEAS
if "%choice%"=="6" goto SET_MUTAGEN
if "%choice%"=="7" goto SET_STARDUST
if "%choice%"=="8" goto EXPORT
if "%choice%"=="9" goto BACKUP
if "%choice%"=="10" goto COMPILE
if "%choice%"=="0" goto EXIT
goto MENU

:STATUS
cls
call :ENSURE_EXE
if errorlevel 1 goto MENU
bin\SaveEditor.exe status
echo.
pause
goto MENU

:SET_DARWIN
cls
call :ENSURE_EXE
if errorlevel 1 goto MENU
echo -----------------------------------------------------------------
echo [提示] 建议在游戏关闭状态下修改。
set /p val="请输入想要设置的达尔文素数量 (默认 100000): "
if "%val%"=="" set val=100000
bin\SaveEditor.exe set-darwin %val%
echo.
pause
goto MENU

:SET_LOGIT
cls
call :ENSURE_EXE
if errorlevel 1 goto MENU
echo -----------------------------------------------------------------
echo [提示] 建议在游戏关闭状态下修改。
set /p val="请输入想要设置的罗吉特数量 (默认 100000): "
if "%val%"=="" set val=100000
bin\SaveEditor.exe set-logit %val%
echo.
pause
goto MENU

:SET_ENTROPY
cls
call :ENSURE_EXE
if errorlevel 1 goto MENU
set /p val="请输入想要设置的熵数值 (如 1000000000 或 1e12): "
if not "%val%"=="" bin\SaveEditor.exe set-entropy %val%
echo.
pause
goto MENU

:SET_IDEAS
cls
call :ENSURE_EXE
if errorlevel 1 goto MENU
set /p val="请输入想要设置的想法数值 (如 1000000000 或 1e12): "
if not "%val%"=="" bin\SaveEditor.exe set-ideas %val%
echo.
pause
goto MENU

:SET_MUTAGEN
cls
call :ENSURE_EXE
if errorlevel 1 goto MENU
set /p val="请输入想要设置的突变剂数量 (如 50000): "
if not "%val%"=="" bin\SaveEditor.exe set-mutagen %val%
echo.
pause
goto MENU

:SET_STARDUST
cls
call :ENSURE_EXE
if errorlevel 1 goto MENU
set /p val="请输入想要设置的星尘/暗物质数量 (如 50000): "
if not "%val%"=="" bin\SaveEditor.exe set-stardust %val%
echo.
pause
goto MENU

:EXPORT
cls
call :ENSURE_EXE
if errorlevel 1 goto MENU
bin\SaveEditor.exe export "save_export.json"
echo.
pause
goto MENU

:BACKUP
cls
call :ENSURE_EXE
if errorlevel 1 goto MENU
bin\SaveEditor.exe backup
echo.
pause
goto MENU

:COMPILE
cls
call build.bat
pause
goto MENU

:ENSURE_EXE
rem 确保 bin\SaveEditor.exe 存在；缺失时自动调用 build.bat 编译
if exist "bin\SaveEditor.exe" exit /b 0
echo.
echo [提示] 未找到 bin\SaveEditor.exe，正在自动编译...
echo.
call build.bat
if exist "bin\SaveEditor.exe" exit /b 0
echo.
echo [错误] 编译失败，请手动运行 build.bat 查看详细原因。
echo.
pause
exit /b 1

:EXIT
if defined OLDCP chcp %OLDCP% >nul 2>nul
exit /b 0
