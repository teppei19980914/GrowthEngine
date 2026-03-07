@echo off
chcp 65001 >nul
echo ユメログ - Web体験版を起動しています...
echo.
flutter run -d chrome --web-browser-flag "--incognito"
