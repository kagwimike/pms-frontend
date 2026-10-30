@echo off
title PMS Pro Web (Port 5000)
echo ===================================================
echo Starting PMS Pro on fixed Web Port 5000...
echo (Required for Google OAuth Authorized JavaScript Origin)
echo ===================================================
cd /d "%~dp0"
flutter run -d chrome --web-port=5000
pause
