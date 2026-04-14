# Build-Installer.ps1
# Builds the Church Program Generator APK installer.
# Run from the project root: .\Build-Installer.ps1
# Optional: .\Build-Installer.ps1 -FlutterPath "C:\flutter"

param(
    [string]$FlutterPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$OutputDir   = Join-Path $ProjectRoot "installer"

# ─── Locate Flutter ────────────────────────────────────────────────────────────
function Find-Flutter {
    # 1. Explicit parameter
    if ($FlutterPath -ne "") {
        $candidate = Join-Path $FlutterPath "bin\flutter.bat"
        if (Test-Path $candidate) { return $candidate }
        Write-Error "flutter.bat not found at: $candidate"
    }

    # 2. Already on PATH
    $inPath = Get-Command flutter -ErrorAction SilentlyContinue
    if ($inPath) { return $inPath.Source }

    # 3. Common install locations
    $candidates = @(
        "C:\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat",
        "C:\tools\flutter\bin\flutter.bat",
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "$env:USERPROFILE\development\flutter\bin\flutter.bat"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }

    Write-Host ""
    Write-Host "ERROR: Flutter SDK not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Flutter from https://docs.flutter.dev/get-started/install/windows"
    Write-Host "Then re-run:  .\Build-Installer.ps1 -FlutterPath `"C:\flutter`""
    exit 1
}

$Flutter = Find-Flutter
Write-Host "Using Flutter: $Flutter" -ForegroundColor Cyan

# ─── Check / create keystore ───────────────────────────────────────────────────
$KeyProperties = Join-Path $ProjectRoot "android\key.properties"
$KeystoreJks   = Join-Path $ProjectRoot "upload-keystore.jks"

if (-not (Test-Path $KeyProperties)) {
    Write-Host ""
    Write-Host "No release keystore found. Generating one now..." -ForegroundColor Yellow
    Write-Host "(You will be prompted for passwords. Keep them safe!)"
    Write-Host ""

    # Locate keytool (ships with any JDK)
    $keytool = Get-Command keytool -ErrorAction SilentlyContinue
    if (-not $keytool) {
        # Try Flutter's bundled Java
        $flutterBinDir = Split-Path $Flutter
        $javaHome = Join-Path (Split-Path $flutterBinDir) "bin\cache\artifacts\engine\windows-x64\flutter_jit_runner"
        $keytool = Get-ChildItem "$env:PROGRAMFILES\Eclipse Adoptium","$env:PROGRAMFILES\Java","$env:PROGRAMFILES\Microsoft","$env:LOCALAPPDATA\Programs\Android\Android Studio\jbr" `
                   -Recurse -Filter keytool.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($keytool) { $keytool = $keytool.FullName } else {
            Write-Host "keytool not found. Install a JDK (e.g. Eclipse Temurin) and ensure it is on your PATH." -ForegroundColor Red
            exit 1
        }
    } else {
        $keytool = $keytool.Source
    }

    $storePass = Read-Host "Enter keystore password (min 6 chars)" -AsSecureString
    $keyPass   = Read-Host "Re-enter for key password (or press Enter to use same)" -AsSecureString
    $storePassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePass))
    $keyPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPass))
    if ($keyPassPlain -eq "") { $keyPassPlain = $storePassPlain }

    & $keytool -genkey -v `
        -keystore $KeystoreJks `
        -alias upload `
        -keyalg RSA -keysize 2048 -validity 10000 `
        -storepass $storePassPlain `
        -keypass  $keyPassPlain `
        -dname "CN=Church Program Generator, OU=Church, O=Church, L=Unknown, S=Unknown, C=US"

    # Write key.properties
    @"
storePassword=$storePassPlain
keyPassword=$keyPassPlain
keyAlias=upload
storeFile=..\upload-keystore.jks
"@ | Set-Content $KeyProperties -Encoding UTF8

    Write-Host "Keystore created: $KeystoreJks" -ForegroundColor Green
    Write-Host "IMPORTANT: Back up upload-keystore.jks and android\key.properties securely." -ForegroundColor Yellow
} else {
    Write-Host "Release keystore found." -ForegroundColor Green
}

# ─── Build ─────────────────────────────────────────────────────────────────────
Set-Location $ProjectRoot

Write-Host ""
Write-Host "Running flutter pub get..." -ForegroundColor Cyan
& $Flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Error "flutter pub get failed"; exit 1 }

Write-Host ""
Write-Host "Building release APK..." -ForegroundColor Cyan
& $Flutter build apk --release
if ($LASTEXITCODE -ne 0) { Write-Error "flutter build apk failed"; exit 1 }

# ─── Copy to installer/ ────────────────────────────────────────────────────────
$BuiltApk = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $BuiltApk)) {
    Write-Error "APK not found at expected path: $BuiltApk"
    exit 1
}

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory $OutputDir | Out-Null }

$Version  = (& $Flutter --version --machine 2>$null | ConvertFrom-Json).flutterVersion
$Stamp    = Get-Date -Format "yyyyMMdd"
$DestName = "ChurchProgramGenerator-v$Stamp.apk"
$DestPath = Join-Path $OutputDir $DestName

Copy-Item $BuiltApk $DestPath -Force

Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host " APK ready: installer\$DestName" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Install on a device:"
Write-Host "  adb install `"$DestPath`""
Write-Host "  -- or --"
Write-Host "  Copy the APK to your phone and open it (enable 'Install unknown apps' first)."
Write-Host ""
