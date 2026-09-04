# Upload a release asset with the .NET streaming fallback for big files.
# Usage:
#   powershell -File upload-asset.ps1 -Repo "nalbe/repo" -ReleaseId 123456 -File "C:\x.zip" [-AssetName "x.zip"]
param(
  [Parameter(Mandatory=$true)][string]$Repo,
  [Parameter(Mandatory=$true)][int]$ReleaseId,
  [Parameter(Mandatory=$true)][string]$File,
  [string]$AssetName = ""
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $File)) { Write-Host "File not found: $File" -ForegroundColor Red; exit 1 }
if (-not $AssetName) { $AssetName = [System.IO.Path]::GetFileName($File) }
$sizeMB = [math]::Round((Get-Item $File).Length / 1MB, 1)

$cred = "protocol=https`nhost=github.com`n`n" | git credential fill 2>$null
$token = ($cred | Select-String '^password=').ToString().Substring(9)
$url = "https://uploads.github.com/repos/$Repo/releases/$ReleaseId/assets?name=$AssetName"

if ($sizeMB -lt 10) {
  # fast path: curl
  & curl.exe -sS -X POST -H "Authorization: token $token" -H "Content-Type: application/zip" --data-binary "@$File" $url
} else {
  # big files hang in curl.exe on this box; stream via .NET HttpClient instead
  Write-Host "File is $sizeMB MB - using .NET streaming upload (slow but reliable, ~3-4 min for 27 MB)" -ForegroundColor Yellow
  Add-Type -AssemblyName System.Net.Http
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
  $fs = [System.IO.File]::OpenRead($File)
  try {
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromMinutes(15)
    $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, $url)
    $req.Headers.Add("Authorization", "token $token")
    $content = New-Object System.Net.Http.StreamContent($fs)
    $content.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/zip")
    $req.Content = $content
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $resp = $client.SendAsync($req).Result
    $sw.Stop()
    Write-Host "`nHTTP: $([int]$resp.StatusCode) in $([math]::Round($sw.Elapsed.TotalSeconds))s" -ForegroundColor Cyan
    if ($resp.IsSuccessStatusCode) {
      $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json | Select-Object id, name, size, browser_download_url | Format-List
    } else {
      Write-Host "Upload failed:" -ForegroundColor Red
      $resp.Content.ReadAsStringAsync().Result
      exit 1
    }
  } finally {
    $fs.Dispose()
  }
}