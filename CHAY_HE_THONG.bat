@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0KHOI_TAO.ps1"
if errorlevel 1 goto error
docker compose config --quiet
if errorlevel 1 goto error
docker compose up -d
if errorlevel 1 goto error
docker compose ps
echo Website: http://localhost:8080
echo phpMyAdmin: http://localhost:8081
echo Prometheus: http://localhost:9090
echo Grafana: http://localhost:3000
echo Wait for MySQL initialization, then open the website.
pause
exit /b 0
:error
echo Failed. Check the error above and Docker Desktop Linux containers.
pause
exit /b 1
