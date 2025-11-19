@echo off
echo ================================================
echo  ESP32 BLE Library Cleanup Script
echo ================================================
echo.
echo This script will remove conflicting BLE libraries
echo to fix compilation errors for ESP32 projects.
echo.
echo Target directories:
echo  - ArduinoBLE
echo  - ESP32_BLE_Arduino
echo.
echo Location: %USERPROFILE%\Documents\Arduino\libraries\
echo.
pause

cd /d "%USERPROFILE%\Documents\Arduino\libraries\"

if exist "ArduinoBLE" (
    echo Removing ArduinoBLE...
    rmdir /s /q "ArduinoBLE"
    echo [OK] ArduinoBLE removed
) else (
    echo [INFO] ArduinoBLE not found
)

if exist "ESP32_BLE_Arduino" (
    echo Removing ESP32_BLE_Arduino...
    rmdir /s /q "ESP32_BLE_Arduino"
    echo [OK] ESP32_BLE_Arduino removed
) else (
    echo [INFO] ESP32_BLE_Arduino not found
)

echo.
echo ================================================
echo  Cleanup Complete!
echo ================================================
echo.
echo Next steps:
echo 1. Restart Arduino IDE
echo 2. Open your ESP32 sketch
echo 3. Select: Tools ^> Board ^> ESP32 Dev Module
echo 4. Compile your sketch
echo.
echo The correct ESP32 BLE library will now be used automatically.
echo.
pause
