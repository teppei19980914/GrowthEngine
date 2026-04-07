@echo off
chcp 65001 >nul
echo Starting YumeHashi on Chrome...
cd /d "%~dp0"
flutter run -d chrome --web-port=8081
pause
