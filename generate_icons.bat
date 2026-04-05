@echo off
echo Generating app icons for Monivo...

echo Step 1: Cleaning project...
flutter clean

echo Step 2: Getting packages...
flutter pub get

echo Step 3: Removing old icon folders...
if exist "android\app\src\main\res\mipmap-hdpi" rmdir /s /q "android\app\src\main\res\mipmap-hdpi"
if exist "android\app\src\main\res\mipmap-mdpi" rmdir /s /q "android\app\src\main\res\mipmap-mdpi"
if exist "android\app\src\main\res\mipmap-xhdpi" rmdir /s /q "android\app\src\main\res\mipmap-xhdpi"
if exist "android\app\src\main\res\mipmap-xxhdpi" rmdir /s /q "android\app\src\main\res\mipmap-xxhdpi"
if exist "android\app\src\main\res\mipmap-xxxhdpi" rmdir /s /q "android\app\src\main\res\mipmap-xxxhdpi"
if exist "android\app\src\main\res\drawable" rmdir /s /q "android\app\src\main\res\drawable"

echo Step 4: Generating new icons...
flutter pub run flutter_launcher_icons

echo.
echo Step 5: Creating additional drawable resources...
if not exist "android\app\src\main\res\drawable" mkdir "android\app\src\main\res\drawable"

echo Step 6: Copying notification icon...
copy "assets\icons\monivoappicontransparent.png" "android\app\src\main\res\drawable\monivoappnotification.png" /Y

echo.
echo Done! Icons generated successfully.
echo Now rebuild your app with: flutter run
pause