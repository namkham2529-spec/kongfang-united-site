param([string]$textJson, [string]$qr, [string]$logo, [string]$out)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$GP = 'System.Drawing.Drawing2D'
$t = [System.IO.File]::ReadAllText($textJson, [Text.Encoding]::UTF8) | ConvertFrom-Json

$W = 1080; $H = 1350
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'ClearTypeGridFit'; $g.InterpolationMode = 'HighQualityBicubic'

$rectF = New-Object System.Drawing.RectangleF 0, 0, $W, $H
$c1 = [System.Drawing.Color]::FromArgb(255, 7, 19, 46)
$c2 = [System.Drawing.Color]::FromArgb(255, 15, 42, 96)
$g.FillRectangle((New-Object "$GP.LinearGradientBrush" $rectF, $c1, $c2, 70.0), 0, 0, $W, $H)

$gold = [System.Drawing.Color]::FromArgb(255, 228, 161, 27)
$goldB = New-Object System.Drawing.SolidBrush $gold
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$sub = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 205, 220, 250))
$greenB = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 6, 199, 85))

function RoundRect($gr, $br, $x, $y, $w, $h, $rad) {
  $p = New-Object "$GP.GraphicsPath"; $d = $rad * 2
  $p.AddArc($x, $y, $d, $d, 180, 90); $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90); $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure(); $gr.FillPath($br, $p); $p.Dispose()
}

$g.FillRectangle($goldB, 0, 0, $W, 12)
$g.FillRectangle($goldB, 0, $H - 12, $W, 12)
$sfC = New-Object System.Drawing.StringFormat; $sfC.Alignment = 'Center'; $sfC.LineAlignment = 'Center'

if ($logo -and (Test-Path $logo)) {
  $lg = [System.Drawing.Image]::FromFile($logo)
  $lw = 130; $lh = [int]($lg.Height * $lw / $lg.Width)
  $g.DrawImage($lg, [int](($W - $lw)/2), 66, $lw, $lh); $lg.Dispose()
}
$g.DrawString($t.brand, (New-Object System.Drawing.Font 'Tahoma', 21, ([System.Drawing.FontStyle]::Bold)), $white, (New-Object System.Drawing.RectangleF 0, 208, $W, 34), $sfC)
$g.DrawString($t.head, (New-Object System.Drawing.Font 'Tahoma', 44, ([System.Drawing.FontStyle]::Bold)), $goldB, (New-Object System.Drawing.RectangleF 0, 258, $W, 70), $sfC)

$panel = 640; $px = [int](($W - $panel)/2); $py = 360
RoundRect $g $white $px $py $panel $panel 34
if ($qr -and (Test-Path $qr)) {
  $qi = [System.Drawing.Image]::FromFile($qr)
  $qs = $panel - 72
  $g.DrawImage($qi, ($px + 36), ($py + 36), $qs, $qs); $qi.Dispose()
}

$chipW = 420; $chipH = 96; $cx = [int](($W - $chipW)/2); $cy = $py + $panel + 40
RoundRect $g $greenB $cx $cy $chipW $chipH 24
$g.DrawString($t.id, (New-Object System.Drawing.Font 'Tahoma', 40, ([System.Drawing.FontStyle]::Bold)), $white, (New-Object System.Drawing.RectangleF $cx, $cy, $chipW, $chipH), $sfC)

$g.DrawString($t.tag, (New-Object System.Drawing.Font 'Tahoma', 21, ([System.Drawing.FontStyle]::Regular)), $sub, (New-Object System.Drawing.RectangleF 60, ($cy + $chipH + 26), ($W - 120), 44), $sfC)
$g.DrawString($t.foot, (New-Object System.Drawing.Font 'Tahoma', 19, ([System.Drawing.FontStyle]::Bold)), $goldB, (New-Object System.Drawing.RectangleF 40, ($H - 122), ($W - 80), 36), $sfC)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host ("saved $out  ${W}x${H}  " + [math]::Round((Get-Item $out).Length/1KB) + " KB")
