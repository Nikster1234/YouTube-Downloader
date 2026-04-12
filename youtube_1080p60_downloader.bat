@echo off
set SCRIPT=%~dp0youtube_1080p60_downloader.ps1
powershell -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT%" %*
pause
