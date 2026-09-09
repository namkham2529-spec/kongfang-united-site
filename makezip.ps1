$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = $PSScriptRoot
$src  = Join-Path $root '_deploy'
$dst  = Join-Path $root 'deploy.zip'
if (Test-Path $dst) { Remove-Item $dst -Force }
$zip = [System.IO.Compression.ZipFile]::Open($dst, 'Create')
try {
  Get-ChildItem $src -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($src.Length + 1).Replace('\','/')
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $rel, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
  }
} finally { $zip.Dispose() }
$z2 = [System.IO.Compression.ZipFile]::OpenRead($dst)
Write-Host ("entries=" + $z2.Entries.Count + "  first=" + $z2.Entries[0].FullName + "  bytes=" + (Get-Item $dst).Length)
$z2.Dispose()
