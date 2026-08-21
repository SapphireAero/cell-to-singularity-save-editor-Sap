@echo off
setlocal
title Compile SaveEditor
echo ==========================================================
echo   Compiling Cell to Singularity SaveEditor...
echo ==========================================================

set "CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"

set "MANAGED=D:\Software\Gaming\Steam\steamapps\common\Cell to Singularity\CellToSingularity_Data\Managed"

if not exist bin mkdir bin

"%CSC%" /nologo /utf8output ^
    /r:"%MANAGED%\Assembly-CSharp.dll" ^
    /r:"%MANAGED%\Assembly-CSharp-firstpass.dll" ^
    /r:"%MANAGED%\UnityEngine.CoreModule.dll" ^
    /r:"%MANAGED%\UnityEngine.dll" ^
    /r:"%MANAGED%\netstandard.dll" ^
    /out:bin\SaveEditor.exe ^
    src\SaveEditor.cs

if %ERRORLEVEL% equ 0 (
    echo.
    echo ==========================================================
    echo   [Success] Generated: bin\SaveEditor.exe
    echo ==========================================================
) else (
    echo.
    echo   [Error] Compilation failed.
)

echo.
