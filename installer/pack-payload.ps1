param()

$ErrorActionPreference = "Stop"
$MainProject = "D:\PaxMD"
$InstallerProject = "D:\PaxMD\installer"
$UninstallerProject = "D:\PaxMD\uninstaller"
$PayloadZip = "$InstallerProject\src-tauri\payload.zip"
$TempDir = "$env:TEMP\pax-md-payload"

Write-Host "=== Creating payload archive ===" -ForegroundColor Cyan

# Clean temp directory
if (Test-Path $TempDir) {
    Remove-Item "$TempDir\*" -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

# 1. Main exe (cargo package name: pax-md; Test-Path is case-insensitive on Windows)
$mainExe = "$MainProject\src-tauri\target\release\pax-md.exe"
if (Test-Path $mainExe) {
    Copy-Item $mainExe $TempDir\
    Write-Host "  [OK] pax-md.exe"
} else {
    Write-Warning "  [WARN] pax-md.exe not found (build main app first: pnpm tauri build)"
}

# 2. Markdown file association icon (expected in install dir by associate_md_files)
$mdIcon = "$MainProject\src-tauri\icons\md-file.ico"
if (Test-Path $mdIcon) {
    Copy-Item $mdIcon $TempDir\
    Write-Host "  [OK] md-file.ico"
} else {
    Write-Warning "  [WARN] md-file.ico not found (skipping)"
}

# 3. Uninstaller (cargo package name: uninstPaxMD)
$uninstExe = "$UninstallerProject\src-tauri\target\release\uninstPaxMD.exe"
if (Test-Path $uninstExe) {
    Copy-Item $uninstExe $TempDir\
    Write-Host "  [OK] uninstPaxMD.exe"
} else {
    Write-Warning "  [WARN] uninstPaxMD.exe not found (build uninstaller first)"
}

# 4. Create ZIP
Write-Host "`nCompressing payload..." -ForegroundColor Cyan
if (Test-Path $PayloadZip) {
    Remove-Item $PayloadZip -Force
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($TempDir, $PayloadZip, [System.IO.Compression.CompressionLevel]::Optimal, $false)

$zipSize = (Get-ChildItem $PayloadZip).Length
$fileCount = (Get-ChildItem $TempDir -Recurse -File | Measure-Object).Count
Write-Host "  [DONE] $fileCount files -> payload.zip, $('{0:N1}' -f ($zipSize / 1MB)) MB" -ForegroundColor Green

# Cleanup temp
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
