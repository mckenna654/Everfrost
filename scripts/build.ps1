$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$addon = Join-Path $projectRoot 'addon/Everfrost'
$toc = Get-Content -LiteralPath (Join-Path $addon 'Everfrost.toc')
$versionLine = $toc | Where-Object { $_ -match '^## Version: ' }
$version = ($versionLine -replace '^## Version: ', '').Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid addon version' }
$dist = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Path $dist -Force | Out-Null
$archive = Join-Path $dist "Everfrost-$version.zip"
Compress-Archive -LiteralPath $addon -DestinationPath $archive -Force
Write-Output $archive
