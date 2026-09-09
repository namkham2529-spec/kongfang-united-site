$ErrorActionPreference = 'Stop'
$root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$port = 8000
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $port)
$listener.Start()
Write-Host "Serving $root on 127.0.0.1:$port (any Host header, e.g. kongfangunited.localhost)"

function Get-Mime($ext){
  switch ($ext.ToLower()){
    '.html' { 'text/html; charset=utf-8' }
    '.css'  { 'text/css; charset=utf-8' }
    '.js'   { 'application/javascript; charset=utf-8' }
    '.json' { 'application/json; charset=utf-8' }
    '.png'  { 'image/png' }
    '.jpg'  { 'image/jpeg' }
    '.jpeg' { 'image/jpeg' }
    '.svg'  { 'image/svg+xml' }
    '.ico'  { 'image/x-icon' }
    default { 'application/octet-stream' }
  }
}

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $ns = $client.GetStream()
    $ns.ReadTimeout = 5000
    $sr = New-Object System.IO.StreamReader($ns, [System.Text.Encoding]::ASCII)
    $requestLine = $sr.ReadLine()
    if ([string]::IsNullOrEmpty($requestLine)) { $client.Close(); continue }
    # drain headers
    while ($true) { $h = $sr.ReadLine(); if ($null -eq $h -or $h -eq '') { break } }

    $parts = $requestLine.Split(' ')
    $rawPath = if ($parts.Length -ge 2) { $parts[1] } else { '/' }
    $rawPath = $rawPath.Split('?')[0]
    $rel = [System.Uri]::UnescapeDataString($rawPath.TrimStart('/'))
    if ([string]::IsNullOrEmpty($rel)) { $rel = 'index.html' }
    $full = [System.IO.Path]::GetFullPath((Join-Path $root $rel))

    $bw = New-Object System.IO.BinaryWriter($ns)
    if ($full.StartsWith($root) -and (Test-Path $full -PathType Leaf)) {
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $mime = Get-Mime ([System.IO.Path]::GetExtension($full))
      $head = "HTTP/1.1 200 OK`r`nContent-Type: $mime`r`nContent-Length: $($bytes.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
      $bw.Write([System.Text.Encoding]::ASCII.GetBytes($head))
      $bw.Write($bytes)
    } else {
      $body = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found')
      $head = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain; charset=utf-8`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
      $bw.Write([System.Text.Encoding]::ASCII.GetBytes($head))
      $bw.Write($body)
    }
    $bw.Flush()
  } catch {
    Write-Host "err: $($_.Exception.Message)"
  } finally {
    $client.Close()
  }
}
