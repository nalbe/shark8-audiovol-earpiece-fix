# Create a release and (optionally) upload one asset.
# Usage:
#   powershell -File new-release.ps1 -Repo "nalbe/repo" -Tag "v1.0.0" -Body "notes" [-Asset "C:\x.zip"] [-AssetName "x.zip"]
param(
  [Parameter(Mandatory=$true)][string]$Repo,
  [Parameter(Mandatory=$true)][string]$Tag,
  [Parameter(Mandatory=$true)][string]$Body,
  [string]$Asset = "",
  [string]$AssetName = ""
)
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

$body = @{ tag_name = $Tag; name = $Tag; body = $Body } | ConvertTo-Json -Compress
$bodyFile = Join-Path $env:TEMP ("rel_body_{0}.json" -f [guid]::NewGuid().ToString("N"))
[System.IO.File]::WriteAllText($bodyFile, $body)

try {
  $resp = & powershell -File (Join-Path $dir "gh.ps1") POST "https://api.github.com/repos/$Repo/releases" $bodyFile
  $rel = $resp | Out-String | ConvertFrom-Json
  if (-not $rel.id) { Write-Host "Release creation failed:" -ForegroundColor Red; $resp; exit 1 }
  Write-Host ("Release {0} created: id {1}" -f $Tag, $rel.id) -ForegroundColor Green

  if ($Asset) {
    if (-not $AssetName) { $AssetName = [System.IO.Path]::GetFileName($Asset) }
    & powershell -File (Join-Path $dir "upload-asset.ps1") -Repo $Repo -ReleaseId $rel.id -File $Asset -AssetName $AssetName
  }
} finally {
  Remove-Item $bodyFile -Force -ErrorAction SilentlyContinue
}