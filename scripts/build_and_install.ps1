# build_and_install.ps1
# TruFit Bodamma - Local Build & Install Script

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " TruFit Bodamma Local Builder & Installer" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if ADB sees a device
$devices = adb devices | Select-String -Pattern "\bdevice\b"
if ($devices.Count -eq 0) {
    Write-Host "❌ No Android device connected via ADB. Please plug in your phone and enable USB Debugging." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Android device found." -ForegroundColor Green

# Optional: Run flutter analyze and tests
Write-Host "🔍 Running flutter analyze..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Flutter analyze found issues. Continuing anyway..." -ForegroundColor Yellow
}

# Build the APK (using --profile for better local performance while keeping debugging info, 
# or change to --release if keystore is configured)
Write-Host "🔨 Building APK..." -ForegroundColor Yellow
flutter build apk --profile

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

$apkPath = "build\app\outputs\flutter-apk\app-profile.apk"

if (Test-Path $apkPath) {
    Write-Host "✅ Build succeeded. Installing on device..." -ForegroundColor Green
    adb install -r $apkPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🚀 Installation complete! Launching app..." -ForegroundColor Green
        # Launch the app via adb
        adb shell monkey -p com.example.trufit_bodamma -c android.intent.category.LAUNCHER 1
    } else {
        Write-Host "❌ Installation failed." -ForegroundColor Red
    }
} else {
    Write-Host "❌ Could not find the generated APK at $apkPath" -ForegroundColor Red
}
