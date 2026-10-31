@echo off
rem Runs create-postbank-chart.ps1 without changing the machines PowerShell policy.
rem Usage: create-postbank-chart.cmd http://localhost:5000 AdminPassword [C:\path\logo.png]
if "%~2"=="" (
  echo Usage: create-postbank-chart.cmd ApiUrl AdminPassword [LogoPath]
  pause
  exit /b 1
)
if "%~3"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0create-postbank-chart.ps1" -ApiUrl "%~1" -AdminPassword "%~2"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0create-postbank-chart.ps1" -ApiUrl "%~1" -AdminPassword "%~2" -LogoPath "%~3"
)
pause
