@echo off
chcp 65001 >nul
echo Starting YumeLog on Chrome...
cd /d "%~dp0"
flutter run -d chrome --web-port=8080
pause
