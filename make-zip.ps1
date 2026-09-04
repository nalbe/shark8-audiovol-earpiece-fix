# Zip a directory into an archive, excluding VCS/build noise.
# Usage:
#   powershell -File make-zip.ps1 -Dir "C:\src\project" -Out "C:\out\project.zip"
param(
  [Parameter(Mandatory=$true)][string]$Dir,
  [Parameter(Mandatory=$true)][string]$Out
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $Dir)) { Write-Host "Dir not found: $Dir" -ForegroundColor Red; exit 1 }
if (Test-Path $Out) { Remove-Item $Out -Force }

$files = Get-ChildItem $Dir -Recurse -File | Where-Object {
  $_.FullName -notmatch "\\.git\\" -and
  $_.FullName -notmatch "\\(build|\.gradle|\.kotlin)\\" -and
  $_.Name -ne "build_out.txt"
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$fs = [System.IO.Compression.ZipFile]::Open($Out, 'Create')
try {
  foreach ($f in $files) {
    $rel = $f.FullName.Substring($Dir.Length + 1)
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($fs, $f.FullName, $rel.Replace('\','/')) | Out-Null
  }
} finally { $fs.Dispose() }
$item = Get-Item $Out
Write-Host ("zip created: {0} ({1} bytes, {2} files)" -f $item.Name, $item.Length, $files.Count) -ForegroundColor Green

# verify integrity: read every entry (forces CRC check)
$z = [System.IO.Compression.ZipFile]::OpenRead($Out)
$bad = 0
foreach ($e in $z.Entries) {
  try {
    $s = $e.Open(); $buf = New-Object byte[] 4096
    while (($n = $s.Read($buf, 0, 4096)) -gt 0) {}
    $s.Close()
  } catch { $bad++; Write-Host ("CORRUPT: {0}" -f $e.FullName) -ForegroundColor Red }
}
$z.Dispose()
Write-Host ("integrity: {0} entries, {1} corrupt" -f $files.Count, $bad) -ForegroundColor Green