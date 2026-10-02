@echo off
rem ===========================================================================
rem  Compile SaveEditor
rem  Fork of hysltway/cell-to-singularity-save-editor, modified by SapphireAero.
rem  Upstream declares no license; original code (c) hysltway.
rem  See README section 6.2 for details.
rem ===========================================================================
setlocal
title Compile SaveEditor

rem 切到脚本自身所在目录，否则从别处调用时下面的 src\ 和 bin\ 相对路径会失效，
rem 报 error CS2001: 未能找到源文件"src\SaveEditor.cs" / warning CS2008: 未指定源文件
cd /d "%~dp0"

echo ==========================================================
echo   Compiling Cell to Singularity SaveEditor...
echo ==========================================================

rem ---------------------------------------------------------------
rem  1) Locate the C# compiler shipped with Windows (.NET Framework 4.x)
rem ---------------------------------------------------------------
set "CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" (
    echo   [Error] csc.exe not found - .NET Framework 4.x is required.
    goto FAIL
)

rem ---------------------------------------------------------------
rem  2) Locate the game's "Managed" folder holding the reference
rem     assemblies (Assembly-CSharp.dll, UnityEngine*.dll, ...).
rem
rem     Resolution order:
rem       a) CTS_MANAGED    - env var override, e.g. set CTS_MANAGED=D:\...\Managed
rem       b) auto-scan      - common Steam layouts on every local drive
rem       c) interactive    - ask the user to paste a path
rem ---------------------------------------------------------------
set "MANAGED="
if defined CTS_MANAGED call :TRY_PATH "%CTS_MANAGED%"
if not defined MANAGED call :SCAN_DRIVES
if not defined MANAGED goto ASK_MANAGED

:RUN_COMPILE
if not exist bin mkdir bin

echo   Compiler : %CSC%
echo   Managed  : %MANAGED%
echo ----------------------------------------------------------

"%CSC%" /nologo /utf8output /codepage:65001 ^
    /r:"%MANAGED%\Assembly-CSharp.dll" ^
    /r:"%MANAGED%\Assembly-CSharp-firstpass.dll" ^
    /r:"%MANAGED%\UnityEngine.CoreModule.dll" ^
    /r:"%MANAGED%\UnityEngine.dll" ^
    /r:"%MANAGED%\netstandard.dll" ^
    /out:bin\SaveEditor.exe ^
    src\SaveEditor.cs

if errorlevel 1 goto FAIL

echo.
echo ==========================================================
echo   [Success] Generated: bin\SaveEditor.exe
echo ==========================================================
echo.
call :MAYBE_PAUSE
exit /b 0

:FAIL
echo.
echo   [Error] Compilation failed.
echo.
call :MAYBE_PAUSE
exit /b 1

rem ---------------------------------------------------------------
rem  Interactive fallback: let the user supply the path at runtime
rem ---------------------------------------------------------------
:ASK_MANAGED
echo.
echo   [Info] Could not find the game's assemblies (Assembly-CSharp.dll)
echo          automatically on this machine.
echo.
echo   Paste ANY of the following - it will be resolved automatically:
echo     - game root    : ...\steamapps\common\Cell to Singularity
echo     - Data folder  : ...\CellToSingularity_Data
echo     - Managed dir  : ...\CellToSingularity_Data\Managed
echo     - steamapps    : ...\steamapps
echo     - Steam library: ...\SteamLibrary
echo     - the .dll itself: ...\Managed\Assembly-CSharp.dll
echo.
echo   Tip: set the CTS_MANAGED environment variable to skip this
echo        prompt on future runs.
echo.
set "USERPATH="
set /p "USERPATH=  Path (press ENTER to abort): "
if not defined USERPATH goto ABORT
set "USERPATH=%USERPATH:"=%"
call :TRY_PATH "%USERPATH%"
if not defined MANAGED (
    echo.
    echo   [Error] Assembly-CSharp.dll not found under: %USERPATH%
    goto ASK_MANAGED
)
echo.
echo   [OK] Managed folder found.
goto RUN_COMPILE

:ABORT
echo.
echo   [Error] No path supplied - compilation aborted.
echo.
call :MAYBE_PAUSE
exit /b 1

rem ===============================================================
rem  Subroutines
rem ===============================================================

rem ---------------------------------------------------------------
rem  Scan the usual Steam library locations on every local drive.
rem ---------------------------------------------------------------
:SCAN_DRIVES
for %%D in (C D E F G H I J K) do (
    if not defined MANAGED call :TRY_PATH "%%D:\SteamLibrary\steamapps\common\Cell to Singularity"
    if not defined MANAGED call :TRY_PATH "%%D:\Steam\steamapps\common\Cell to Singularity"
    if not defined MANAGED call :TRY_PATH "%%D:\Program Files (x86)\Steam\steamapps\common\Cell to Singularity"
    if not defined MANAGED call :TRY_PATH "%%D:\Program Files\Steam\steamapps\common\Cell to Singularity"
    if not defined MANAGED call :TRY_PATH "%%D:\Games\Steam\steamapps\common\Cell to Singularity"
    if not defined MANAGED call :TRY_PATH "%%D:\Software\Gaming\Steam\steamapps\common\Cell to Singularity"
)
exit /b 0

rem ---------------------------------------------------------------
rem  Try to resolve one user/supplied path into the Managed folder.
rem  Accepts the game root, the *_Data folder, the Managed folder,
rem  a steamapps / Steam library folder, or the dll path itself.
rem  Sets MANAGED and returns 0 on success, 1 on failure.
rem ---------------------------------------------------------------
:TRY_PATH
set "P=%~1"
if "%P%"=="" exit /b 1
if /i "%~nx1"=="Assembly-CSharp.dll" set "P=%~dp1"
if "%P:~-1%"=="\" set "P=%P:~0,-1%"

if exist "%P%\Assembly-CSharp.dll" (
    set "MANAGED=%P%"
    exit /b 0
)
if exist "%P%\CellToSingularity_Data\Managed\Assembly-CSharp.dll" (
    set "MANAGED=%P%\CellToSingularity_Data\Managed"
    exit /b 0
)
if exist "%P%\Managed\Assembly-CSharp.dll" (
    set "MANAGED=%P%\Managed"
    exit /b 0
)
if exist "%P%\steamapps\common\Cell to Singularity\CellToSingularity_Data\Managed\Assembly-CSharp.dll" (
    set "MANAGED=%P%\steamapps\common\Cell to Singularity\CellToSingularity_Data\Managed"
    exit /b 0
)
if exist "%P%\common\Cell to Singularity\CellToSingularity_Data\Managed\Assembly-CSharp.dll" (
    set "MANAGED=%P%\common\Cell to Singularity\CellToSingularity_Data\Managed"
    exit /b 0
)
if exist "%P%\Cell to Singularity\CellToSingularity_Data\Managed\Assembly-CSharp.dll" (
    set "MANAGED=%P%\Cell to Singularity\CellToSingularity_Data\Managed"
    exit /b 0
)
exit /b 1

rem ---------------------------------------------------------------
rem  Keep the window open when the script was launched by
rem  double-clicking, so the result stays readable.
rem ---------------------------------------------------------------
:MAYBE_PAUSE
set "CMDLINE=%cmdcmdline%"
set "CMDLINE=%CMDLINE:"=%"
if not "%CMDLINE%"=="%CMDLINE:build.bat=%" pause
exit /b 0
