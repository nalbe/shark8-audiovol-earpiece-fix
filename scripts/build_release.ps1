param(
  [string]$Root,
  [string]$OutZip
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $OutZip) { Remove-Item $OutZip -Force }
$fs = [System.IO.File]::Open($OutZip, [System.IO.FileMode]::CreateNew)
$a = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
Get-ChildItem -Recurse -File (Join-Path $Root 'module') | ForEach-Object {
  $rel = $_.FullName.Substring((Join-Path $Root 'module').Length + 1) -replace '\\','/'
  [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($a, $_.FullName, $rel) | Out-Null
}
$a.Dispose(); $fs.Dispose()
"Zip: $OutZip"
[System.IO.Compression.ZipFile]::OpenRead($OutZip).Entries | ForEach-Object { "  $($_.FullName) [$($_.Length)]" }