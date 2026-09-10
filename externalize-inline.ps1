# Post-build: pull remaining inline data:image URIs out of _deploy/index.html into _deploy/images/ .
# PowerShell port of externalize-inline.js (no Node.js required).
# Run AFTER build.ps1, BEFORE makezip.ps1 -- build.ps1 now calls this automatically.
#   powershell -ExecutionPolicy Bypass -File externalize-inline.ps1
$ErrorActionPreference = 'Stop'
$root    = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$htmlPath = Join-Path $root '_deploy\index.html'
$imgDir   = Join-Path $root '_deploy\images'
$U        = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path $htmlPath)) { Write-Error 'no _deploy/index.html - run build.ps1 first'; exit 1 }
if (-not (Test-Path $imgDir))   { New-Item -ItemType Directory -Path $imgDir | Out-Null }

$html   = [System.IO.File]::ReadAllText($htmlPath, $U)
$before  = [System.Text.Encoding]::UTF8.GetByteCount($html)
$extOf   = @{ 'image/png' = 'png'; 'image/jpeg' = 'jpg'; 'image/jpg' = 'jpg'; 'image/gif' = 'gif'; 'image/webp' = 'webp'; 'image/svg+xml' = 'svg' }
$MIN     = 2048   # leave tiny blobs inline

$sha1  = [System.Security.Cryptography.SHA1]::Create()
$seen  = @{}
$stats = [pscustomobject]@{ n = 0; kept = 0; bytesOut = 0 }

$evaluator = {
  param($m)
  $mime = $m.Groups[1].Value.ToLower()
  $b64  = $m.Groups[2].Value
  $ext  = $extOf[$mime]
  if (-not $ext) { $stats.kept++; return $m.Value }
  try { $buf = [Convert]::FromBase64String($b64) } catch { $stats.kept++; return $m.Value }
  if ($buf.Length -lt $MIN) { $stats.kept++; return $m.Value }
  $hash = -join ($sha1.ComputeHash($buf) | ForEach-Object { $_.ToString('x2') })
  $hash = $hash.Substring(0, 16)
  $name = 'x_' + $hash + '.' + $ext
  if (-not $seen.ContainsKey($hash)) {
    [System.IO.File]::WriteAllBytes((Join-Path $imgDir $name), $buf)
    $seen[$hash] = $name
    $stats.bytesOut += $buf.Length
    $stats.n++
  }
  return 'images/' + $name
}

$pattern = 'data:(image/[a-z0-9.+-]+);base64,([A-Za-z0-9+/=]+)'
$html = [regex]::Replace($html, $pattern, $evaluator)

[System.IO.File]::WriteAllText($htmlPath, $html, $U)
$after = [System.Text.Encoding]::UTF8.GetByteCount($html)
Write-Host ("externalized {0} unique images ({1:N2} MB) into _deploy/images/" -f $stats.n, ($stats.bytesOut / 1MB))
Write-Host ("_deploy/index.html: {0:N2} MB -> {1:N0} KB  ({2} tiny blobs kept inline)" -f ($before / 1MB), ($after / 1KB), $stats.kept)
