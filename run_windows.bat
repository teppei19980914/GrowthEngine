@echo off
chcp 65001 >nul
echo Starting YumeLog Windows App...
cd /d "%~dp0"
flutter run -d windows
pause
