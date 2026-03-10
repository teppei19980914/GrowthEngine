@echo off
chcp 65001 >nul
echo Building YumeLog Windows App (Release)...
cd /d "%~dp0"
flutter build windows --release
echo.
echo Build complete!
echo Executable: build\windows\x64\runner\Release\yume_log.exe
echo.
start "" "build\windows\x64\runner\Release"
pause
