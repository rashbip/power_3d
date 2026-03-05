# make_zip.ps1 - Rebuilds power3d_assets.zip from the dev folder
# Run this whenever you update JS files in dev/power3d_assets/
# Usage: .\make_zip.ps1

$source = "$PSScriptRoot\power3d_assets"
$dest = "$PSScriptRoot\..\power3d_assets.zip"

Write-Host "Building ZIP from: $source"
Compress-Archive -Path "$source\*" -DestinationPath $dest -Force
Write-Host "Done! ZIP updated at: $dest"
