# Reads the GitHub token from Windows Credential Manager via git-credential-manager.
# Usage: powershell -File get-token.ps1
# Prints lines: username=... / password=... (same protocol as git credential fill)
$in = "protocol=https`nhost=github.com`n`n"
$out = $in | git credential fill 2>$null
$out
if ($LASTEXITCODE -ne 0) {
  Write-Host "git credential fill failed. Install git-credential-manager and sign in:" -ForegroundColor Red
  Write-Host "  gh auth login  (or  git credential-manager github login)" -ForegroundColor Yellow
  exit 1
}