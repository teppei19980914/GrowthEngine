@echo off
chcp 65001 >nul
echo ユメハシ - Web体験版を起動しています...
echo.
flutter run -d chrome --web-browser-flag "--incognito"
