param([string]$textJson, [string]$logo, [string]$qr, [string]$out, [int]$W = 1080, [int]$H = 1350)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$GP = 'System.Drawing.Drawing2D'
$t = [System.IO.File]::ReadAllText($textJson, [Text.Encoding]::UTF8) | ConvertFrom-Json

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
$sfL = New-Object System.Drawing.StringFormat; $sfL.Alignment = 'Near'; $sfL.LineAlignment = 'Center'

if ($logo -and (Test-Path $logo)) {
  $lg = [System.Drawing.Image]::FromFile($logo)
  $lw = 120; $lh = [int]($lg.Height * $lw / $lg.Width)
  $g.DrawImage($lg, [int](($W - $lw)/2), 56, $lw, $lh); $lg.Dispose()
}
$g.DrawString($t.brand, (New-Object System.Drawing.Font 'Tahoma', 19, ([System.Drawing.FontStyle]::Bold)), $white, (New-Object System.Drawing.RectangleF 0, 188, $W, 30), $sfC)
$g.DrawString($t.eyebrow, (New-Object System.Drawing.Font 'Tahoma', 15, ([System.Drawing.FontStyle]::Bold)), $goldB, (New-Object System.Drawing.RectangleF 0, 230, $W, 26), $sfC)

$fTitle = New-Object System.Drawing.Font 'Tahoma', 60, ([System.Drawing.FontStyle]::Bold)
$g.DrawString($t.title1, $fTitle, $white, (New-Object System.Drawing.RectangleF 0, 266, $W, 88), $sfC)
$g.DrawString($t.title2, $fTitle, $goldB, (New-Object System.Drawing.RectangleF 0, 350, $W, 88), $sfC)

$g.FillRectangle($goldB, [int]($W/2 - 250), 462, 500, 3)
$g.DrawString($t.lead, (New-Object System.Drawing.Font 'Tahoma', 21, ([System.Drawing.FontStyle]::Regular)), $sub, (New-Object System.Drawing.RectangleF 80, 478, ($W - 160), 78), $sfC)

# green LINE box (left) + white QR (right)
$rowY = 576; $rowH = 300
$boxW = 560
RoundRect $g $greenB 80 $rowY $boxW $rowH 24
$g.DrawString($t.lineLabel, (New-Object System.Drawing.Font 'Tahoma', 18, ([System.Drawing.FontStyle]::Bold)), $white, (New-Object System.Drawing.RectangleF 80, ($rowY + 46), $boxW, 28), $sfC)
$g.DrawString($t.lineId, (New-Object System.Drawing.Font 'Tahoma', 44, ([System.Drawing.FontStyle]::Bold)), $white, (New-Object System.Drawing.RectangleF 80, ($rowY + 96), $boxW, 70), $sfC)
$g.DrawString($t.scanNote, (New-Object System.Drawing.Font 'Tahoma', 17, ([System.Drawing.FontStyle]::Regular)), $white, (New-Object System.Drawing.RectangleF 80, ($rowY + 186), $boxW, 60), $sfC)

$qp = $rowH; $qx = 80 + $boxW + 20
RoundRect $g $white $qx $rowY $qp $qp 20
if ($qr -and (Test-Path $qr)) {
  $qi = [System.Drawing.Image]::FromFile($qr)
  $g.DrawImage($qi, ($qx + 22), ($rowY + 22), ($qp - 44), ($qp - 44)); $qi.Dispose()
}

# steps
$fNum = New-Object System.Drawing.Font 'Tahoma', 24, ([System.Drawing.FontStyle]::Bold)
$fStep = New-Object System.Drawing.Font 'Tahoma', 22, ([System.Drawing.FontStyle]::Regular)
$sy = 946
for ($i = 0; $i -lt $t.steps.Count; $i++) {
  $cy = $sy + $i * 92
  $g.FillEllipse($goldB, 100, $cy, 52, 52)
  $g.DrawString([string]($i + 1), $fNum, (New-Object System.Drawing.SolidBrush $c1), (New-Object System.Drawing.RectangleF 100, ($cy - 2), 52, 52), $sfC)
  $g.DrawString($t.steps[$i], $fStep, $white, (New-Object System.Drawing.RectangleF 178, $cy, ($W - 260), 52), $sfL)
}

$g.DrawString($t.foot, (New-Object System.Drawing.Font 'Tahoma', 19, ([System.Drawing.FontStyle]::Bold)), $goldB, (New-Object System.Drawing.RectangleF 0, ($H - 116), $W, 32), $sfC)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host ("saved $out  ${W}x${H}  " + [math]::Round((Get-Item $out).Length/1KB) + " KB")
