# Rename a repo, then update the local remote URL.
# Usage:
#   powershell -File rename-repo.ps1 -Repo "nalbe/old-name" -NewName "new-name" [-LocalDir "C:\path\clone"]
param(
  [Parameter(Mandatory=$true)][string]$Repo,
  [Parameter(Mandatory=$true)][string]$NewName,
  [string]$LocalDir = ""
)
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

$body = @{ name = $NewName } | ConvertTo-Json -Compress
$bodyFile = Join-Path $env:TEMP ("rename_{0}.json" -f [guid]::NewGuid().ToString("N"))
[System.IO.File]::WriteAllText($bodyFile, $body)
try {
  $resp = & powershell -File (Join-Path $dir "gh.ps1") PATCH "https://api.github.com/repos/$Repo" $bodyFile
  if ($resp | Select-String '"full_name"') {
    Write-Host ("renamed: {0} -> {1}" -f $Repo, $NewName) -ForegroundColor Green
  } else {
    Write-Host "Rename failed:" -ForegroundColor Red; $resp; exit 1
  }
} finally { Remove-Item $bodyFile -Force -ErrorAction SilentlyContinue }

if ($LocalDir) {
  if (-not (Test-Path (Join-Path $LocalDir ".git"))) { Write-Host "Not a git repo: $LocalDir" -ForegroundColor Yellow }
  else {
    git -C $LocalDir remote set-url origin "https://github.com/nalbe/$NewName.git"
    if ($?) { Write-Host ("local remote updated in {0}" -f $LocalDir) -ForegroundColor Green }
  }
}