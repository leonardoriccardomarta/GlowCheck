$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$repo = Split-Path -Parent $root
$flutter = "C:\Users\marta\develop\flutter\bin\flutter.bat"
$app = Join-Path $repo "glowcheck"
$out = Join-Path $root "public"

if (-not (Test-Path $flutter)) {
  throw "Flutter SDK not found at $flutter"
}

Push-Location $app
& $flutter build web --release --dart-define=API_URL=
Pop-Location

if (Test-Path $out) {
  Get-ChildItem $out -Force | Where-Object { $_.Name -ne ".gitkeep" } | Remove-Item -Recurse -Force
}
Copy-Item -Path (Join-Path $app "build\web\*") -Destination $out -Recurse -Force
Write-Output "Packed Flutter web into $out"
