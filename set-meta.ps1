# Set description and/or topics on a repo.
# Usage:
#   powershell -File set-meta.ps1 -Repo "nalbe/repo" [-Desc "text"] [-Topics "a,b,c"]
param(
  [Parameter(Mandatory=$true)][string]$Repo,
  [string]$Desc = "",
  [string]$Topics = ""
)
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($Desc) {
  $body = @{ description = $Desc } | ConvertTo-Json -Compress
  $bodyFile = Join-Path $env:TEMP ("desc_{0}.json" -f [guid]::NewGuid().ToString("N"))
  [System.IO.File]::WriteAllText($bodyFile, $body)
  try {
    & powershell -File (Join-Path $dir "gh.ps1") PATCH "https://api.github.com/repos/$Repo" $bodyFile | Out-Null
    Write-Host ("description set on {0}" -f $Repo) -ForegroundColor Green
  } finally { Remove-Item $bodyFile -Force -ErrorAction SilentlyContinue }
}

if ($Topics) {
  $names = $Topics -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  $body = @{ names = $names } | ConvertTo-Json -Compress
  $bodyFile = Join-Path $env:TEMP ("topics_{0}.json" -f [guid]::NewGuid().ToString("N"))
  [System.IO.File]::WriteAllText($bodyFile, $body)
  try {
    & powershell -File (Join-Path $dir "gh.ps1") PUT "https://api.github.com/repos/$Repo/topics" $bodyFile | Out-Null
    Write-Host ("topics set: {0}" -f ($names -join ", ")) -ForegroundColor Green
  } finally { Remove-Item $bodyFile -Force -ErrorAction SilentlyContinue }
}