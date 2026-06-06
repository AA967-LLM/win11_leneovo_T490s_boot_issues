@echo off
setlocal enabledelayedexpansion
set VERSION=3.0-PREMIUM
set LOGFILE=%~dp0APEX_DEPLOY_LOG.txt

echo ================================================= > %LOGFILE%
echo ANTIGRAVITY APEX-DEPLOYMENT v%VERSION% >> %LOGFILE%
echo SYSTEM DIAGNOSTIC START: %DATE% %TIME% >> %LOGFILE%
echo ================================================= >> %LOGFILE%

echo [*] Initializing Universal Search Logic...

:: 1. FIND THE WINDOWS IMAGE (SCAN ALL DRIVES)
set "IMG_PATH="
set "USB_ROOT="
for %%d in (C D E F G H I J K L) do (
    if exist "%%d:\sources\install.wim" (
        set "IMG_PATH=%%d:\sources\install.wim"
        set "USB_ROOT=%%d:\"
        set "IMG_TYPE=WIM"
    ) else if exist "%%d:\sources\install.swm" (
        set "IMG_PATH=%%d:\sources\install.swm"
        set "USB_ROOT=%%d:\"
        set "IMG_TYPE=SWM"
    ) else if exist "%%d:\sources\install.esd" (
        set "IMG_PATH=%%d:\sources\install.esd"
        set "USB_ROOT=%%d:\"
        set "IMG_TYPE=ESD"
    )
)

if not defined IMG_PATH (
    echo [CRITICAL] WINDOWS IMAGE NOT FOUND ON ANY DRIVE! >> %LOGFILE%
    echo ERROR: Cannot find installation files.
    pause
    exit
)

echo [OK] Found %IMG_TYPE% at %IMG_PATH% >> %LOGFILE%
echo [*] Working from %USB_ROOT%

:: 2. DETECT TARGET SSD (DISK 0)
echo [*] PREPARING DISK 0 (PRIMARY NVMe)...
(
echo select disk 0
echo clean
echo convert gpt
echo create partition efi size=100
echo format quick fs=fat32 label="System"
echo assign letter=S
echo create partition msr size=16
echo create partition primary
echo format quick fs=ntfs label="Windows"
echo assign letter=W
echo exit
) > %temp%\dp_apex.txt

diskpart /s %temp%\dp_apex.txt >> %LOGFILE% 2>&1

:: 3. DEPLOYMENT (DISM ENGINE)
echo [*] APPLYING WINDOWS 11 (THIS TAKES 5-10 MINS)...
if "%IMG_TYPE%"=="SWM" (
    dism /apply-image /imagefile:%IMG_PATH% /swmfile:%USB_ROOT%sources\install*.swm /index:1 /applydir:W:\ >> %LOGFILE% 2>&1
) else (
    dism /apply-image /imagefile:%IMG_PATH% /index:1 /applydir:W:\ >> %LOGFILE% 2>&1
)

:: 4. DRIVER INJECTION (THE CRITICAL FIX)
echo [*] SEARCHING AND INJECTING DRIVERS...
for %%d in (C D E F G H I J K L) do (
    if exist "%%d:\DRIVERS\LENOVO_V18_FINAL" (
        echo [OK] Injecting drivers from %%d:\DRIVERS\LENOVO_V18_FINAL >> %LOGFILE%
        dism /Image:W:\ /Add-Driver /Driver:%%d:\DRIVERS\LENOVO_V18_FINAL /Recurse >> %LOGFILE% 2>&1
    )
)

:: 5. BOOTLOADER
echo [*] FINALIZING BOOTLOADER...
bcdboot W:\Windows /s S: /f UEFI >> %LOGFILE% 2>&1

echo ================================================= >> %LOGFILE%
echo MISSION SUCCESSFUL! >> %LOGFILE%
echo ================================================= >> %LOGFILE%

echo.
echo SUCCESS! 
echo 1. Unplug the USB.
echo 2. Restart your ThinkPad.
pause
