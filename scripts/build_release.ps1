param(
  [string]$Root,
  [string]$OutZip,
  [string]$ModuleDir = 'module'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $OutZip) { Remove-Item $OutZip -Force }
$mdir = Join-Path $Root $ModuleDir
$fs = [System.IO.File]::Open($OutZip, [System.IO.FileMode]::CreateNew)
$a = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
Get-ChildItem -Recurse -File $mdir | ForEach-Object {
  $rel = $_.FullName.Substring($mdir.Length + 1) -replace '\\','/'
  [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($a, $_.FullName, $rel) | Out-Null
}
$a.Dispose(); $fs.Dispose()
"Zip: $OutZip"
[System.IO.Compression.ZipFile]::OpenRead($OutZip).Entries | ForEach-Object { "  $($_.FullName) [$($_.Length)]" }