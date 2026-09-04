# Generic GitHub API wrapper.
# Usage:
#   powershell -File gh.ps1 GET  "https://api.github.com/user"
#   powershell -File gh.ps1 POST "https://api.github.com/user/repos" "C:\path\body.json"
#   powershell -File gh.ps1 PATCH "https://api.github.com/repos/nalbe/x" "C:\path\body.json"
#   powershell -File gh.ps1 DELETE "https://api.github.com/repos/nalbe/x"
# Body is ALWAYS read from a file (inline JSON in PowerShell gets mangled).
param(
  [Parameter(Mandatory=$true)][string]$Method,
  [Parameter(Mandatory=$true)][string]$Url,
  [string]$BodyFile = ""
)
$ErrorActionPreference = "Stop"
$cred = "protocol=https`nhost=github.com`n`n" | git credential fill 2>$null
$token = ($cred | Select-String '^password=').ToString().Substring(9)
if (-not $token) { Write-Host "No token via git credential fill" -ForegroundColor Red; exit 1 }

$args = @("-sS", "-X", $Method, "-H", "Authorization: token $token")
if ($BodyFile) {
  if (-not (Test-Path $BodyFile)) { Write-Host "Body file not found: $BodyFile" -ForegroundColor Red; exit 1 }
  $args += @("-H", "Content-Type: application/json", "--data-binary", "@$BodyFile")
}
$args += $Url
& curl.exe @args 2>&1