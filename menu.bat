@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title 《细胞到奇点》存档修改工具箱

:MENU
cls
echo =================================================================
echo        《细胞到奇点》(Cell to Singularity) 存档修改与管理工具箱
echo =================================================================
echo.
echo   [1] 查看当前存档状态（各货币、资源与统计概况）
echo   [2] 修改粉色达尔文素 (Darwinium)
echo   [3] 修改熵 (Entropy)
echo   [4] 修改想法 (Ideas)
echo   [5] 修改中生代突变剂 (Mutagen / 恐龙化石)
echo   [6] 修改超越篇星尘/暗物质 (Stardust / Dark Matter)
echo   [7] 导出完整存档为 JSON 格式
echo   [8] 创建当前存档的安全备份
echo   [9] 重新编译 SaveEditor 源码
echo   [0] 退出
echo.
echo =================================================================
set /p choice="请输入选项编号 [0-9]: "

if "%choice%"=="1" goto STATUS
if "%choice%"=="2" goto SET_DARWIN
if "%choice%"=="3" goto SET_ENTROPY
if "%choice%"=="4" goto SET_IDEAS
if "%choice%"=="5" goto SET_MUTAGEN
if "%choice%"=="6" goto SET_STARDUST
if "%choice%"=="7" goto EXPORT
if "%choice%"=="8" goto BACKUP
if "%choice%"=="9" goto COMPILE
if "%choice%"=="0" exit /b 0
goto MENU

:STATUS
cls
if not exist "bin\SaveEditor.exe" call build.bat
bin\SaveEditor.exe status
echo.
pause
goto MENU

:SET_DARWIN
cls
echo -----------------------------------------------------------------
echo [提示] 建议在游戏关闭状态下修改。
set /p val="请输入想要设置的达尔文素数量 (默认 100000): "
if "%val%"=="" set val=100000
bin\SaveEditor.exe set-darwin %val%
echo.
pause
goto MENU

:SET_ENTROPY
cls
set /p val="请输入想要设置的熵数值 (如 1000000000 或 1e12): "
if not "%val%"=="" bin\SaveEditor.exe set-entropy %val%
echo.
pause
goto MENU

:SET_IDEAS
cls
set /p val="请输入想要设置的想法数值 (如 1000000000 或 1e12): "
if not "%val%"=="" bin\SaveEditor.exe set-ideas %val%
echo.
pause
goto MENU

:SET_MUTAGEN
cls
set /p val="请输入想要设置的突变剂数量 (如 50000): "
if not "%val%"=="" bin\SaveEditor.exe set-mutagen %val%
echo.
pause
goto MENU

:SET_STARDUST
cls
set /p val="请输入想要设置的星尘/暗物质数量 (如 50000): "
if not "%val%"=="" bin\SaveEditor.exe set-stardust %val%
echo.
pause
goto MENU

:EXPORT
cls
bin\SaveEditor.exe export "save_export.json"
echo.
pause
goto MENU

:BACKUP
cls
bin\SaveEditor.exe backup
echo.
pause
goto MENU

:COMPILE
cls
call build.bat
pause
goto MENU
