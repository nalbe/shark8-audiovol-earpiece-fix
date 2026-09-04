# Full pipeline: turn a local project dir into a public GitHub repo with
# release + zip asset. Use for the next "подъехал проект" case.
#   powershell -File push-repo.ps1 -Dir "C:\x\project" -Name "cool-name" -Desc "..." -Topics "android,gsi"
param(
  [Parameter(Mandatory=$true)][string]$Dir,
  [Parameter(Mandatory=$true)][string]$Name,
  [Parameter(Mandatory=$true)][string]$Desc,
  [string]$Topics = "",
  [string]$ZipPath = "",
  [string]$ReleaseTag = "v1.0.0"
)
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path $Dir)) { Write-Host "Dir not found: $Dir" -ForegroundColor Red; exit 1 }

# 0. token
$cred = "protocol=https`nhost=github.com`n`n" | git credential fill 2>$null
$token = ($cred | Select-String '^password=').ToString().Substring(9)
if (-not $token) { Write-Host "No token" -ForegroundColor Red; exit 1 }

# 1. git init if needed + identity + .gitattributes
if (-not (Test-Path (Join-Path $Dir ".git"))) { git -C $Dir init | Out-Null }
if (-not (Test-Path (Join-Path $Dir ".gitattributes"))) {
  Set-Content -Path (Join-Path $Dir ".gitattributes") -Value "* text eol=lf" -Encoding ascii -NoNewline
}
git -C $Dir add -A | Out-Null
git -C $Dir -c user.name="nalbe" -c user.email="nalbe@ya.ru" commit -m "Initial commit" 2>&1 | Out-Null

# 2. create repo on GitHub
$body = @{ name = $Name; description = $Desc; has_issues = $true; has_projects = $false; has_wiki = $false } | ConvertTo-Json -Compress
$bodyFile = Join-Path $env:TEMP ("newrepo_{0}.json" -f [guid]::NewGuid().ToString("N"))
[System.IO.File]::WriteAllText($bodyFile, $body)
$resp = ""
try {
  $resp = & powershell -File (Join-Path $dir "gh.ps1") POST "https://api.github.com/user/repos" $bodyFile | Out-String
} finally { Remove-Item $bodyFile -Force -ErrorAction SilentlyContinue }
$pat = '"full_name": "nalbe/' + $Name + '"'
if ($resp -notmatch [regex]::Escape($pat)) { Write-Host "Repo creation failed:" -ForegroundColor Red; $resp; exit 1 }
Write-Host ("repo created: https://github.com/nalbe/{0}" -f $Name) -ForegroundColor Green

# 3. push
$remote = git -C $Dir remote get-url origin 2>$null
if (-not $remote) { git -C $Dir remote add origin "https://github.com/nalbe/$Name.git" }
else { git -C $Dir remote set-url origin "https://github.com/nalbe/$Name.git" }
git -C $Dir push -u origin main 2>&1 | Out-Null
Write-Host ("pushed: {0}" -f $Name) -ForegroundColor Green

# 4. topics + description
if ($Topics) { & powershell -File (Join-Path $dir "set-meta.ps1") -Repo "nalbe/$Name" -Desc $Desc -Topics $Topics }
else { & powershell -File (Join-Path $dir "set-meta.ps1") -Repo "nalbe/$Name" -Desc $Desc }

# 5. release + zip asset
if (-not $ZipPath) {
  $zipBase = $Dir.Split('\')[-1].Replace('_','-')
  $ZipPath = Join-Path $env:TEMP ($zipBase + "-release.zip")
  & powershell -File (Join-Path $dir "make-zip.ps1") -Dir $Dir -Out $ZipPath
}
& powershell -File (Join-Path $dir "new-release.ps1") -Repo "nalbe/$Name" -Tag $ReleaseTag -Body $Desc -Asset $ZipPath
Write-Host "DONE: https://github.com/nalbe/$Name" -ForegroundColor Green