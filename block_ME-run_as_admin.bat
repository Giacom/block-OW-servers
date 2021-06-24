@echo off
echo Run this script as admin, it will add firewall rules to block the ME server
echo Right click on this file -> Run as administrator
echo Alternatively, run a powershell session as admin and run the block-ME-servers.ps1 file

REM change directory to the directory this file is in
cd /D "%~dp0" 

powershell.exe -noprofile -executionpolicy bypass -File block-ME-servers.ps1

echo.
pause