param([string]$textJson, [string]$logo, [string]$out, [int]$W = 1080, [int]$H = 1350)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$GP = 'System.Drawing.Drawing2D'
$t = [System.IO.File]::ReadAllText($textJson, [Text.Encoding]::UTF8) | ConvertFrom-Json

$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'ClearTypeGridFit'; $g.InterpolationMode = 'HighQualityBicubic'

# background
$rectF = New-Object System.Drawing.RectangleF 0, 0, $W, $H
$c1 = [System.Drawing.Color]::FromArgb(255, 7, 19, 46)
$c2 = [System.Drawing.Color]::FromArgb(255, 15, 42, 96)
$bg = New-Object "$GP.LinearGradientBrush" $rectF, $c1, $c2, 70.0
$g.FillRectangle($bg, 0, 0, $W, $H)

$gold = [System.Drawing.Color]::FromArgb(255, 228, 161, 27)
$goldB = New-Object System.Drawing.SolidBrush $gold
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$sub = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 205, 220, 250))
$green = [System.Drawing.Color]::FromArgb(255, 6, 199, 85)
$greenB = New-Object System.Drawing.SolidBrush $green

function RoundRect($gr, $br, $x, $y, $w, $h, $rad) {
  $p = New-Object "$GP.GraphicsPath"; $d = $rad * 2
  $p.AddArc($x, $y, $d, $d, 180, 90); $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90); $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure(); $gr.FillPath($br, $p); $p.Dispose()
}

# faint pitch arc motif bottom
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(20, 255, 255, 255)), 3
$g.DrawEllipse($pen, ($W/2 - 260), ($H - 220), 520, 520)

$g.FillRectangle($goldB, 0, 0, $W, 12)
$g.FillRectangle($goldB, 0, $H - 12, $W, 12)

$sfC = New-Object System.Drawing.StringFormat; $sfC.Alignment = 'Center'; $sfC.LineAlignment = 'Center'
$sfL = New-Object System.Drawing.StringFormat; $sfL.Alignment = 'Near'; $sfL.LineAlignment = 'Center'

# logo + brand
if ($logo -and (Test-Path $logo)) {
  $lg = [System.Drawing.Image]::FromFile($logo)
  $lw = 132; $lh = [int]($lg.Height * $lw / $lg.Width)
  $g.DrawImage($lg, [int](($W - $lw)/2), 70, $lw, $lh); $lg.Dispose()
}
$fBrand = New-Object System.Drawing.Font 'Tahoma', 20, ([System.Drawing.FontStyle]::Bold)
$g.DrawString($t.brand, $fBrand, $white, (New-Object System.Drawing.RectangleF 0, 214, $W, 32), $sfC)

# eyebrow
$fEye = New-Object System.Drawing.Font 'Tahoma', 16, ([System.Drawing.FontStyle]::Bold)
$g.DrawString($t.eyebrow, $fEye, $goldB, (New-Object System.Drawing.RectangleF 0, 262, $W, 28), $sfC)

# title
$fTitle = New-Object System.Drawing.Font 'Tahoma', 66, ([System.Drawing.FontStyle]::Bold)
$g.DrawString($t.title1, $fTitle, $white, (New-Object System.Drawing.RectangleF 0, 300, $W, 96), $sfC)
$g.DrawString($t.title2, $fTitle, $goldB, (New-Object System.Drawing.RectangleF 0, 392, $W, 96), $sfC)

# lead line on gold rules
$g.FillRectangle($goldB, [int]($W/2 - 260), 512, 520, 3)
$fLead = New-Object System.Drawing.Font 'Tahoma', 22, ([System.Drawing.FontStyle]::Regular)
$g.DrawString($t.lead, $fLead, $sub, (New-Object System.Drawing.RectangleF 90, 528, ($W - 180), 90), $sfC)

# LINE box
$boxY = 636; $boxH = 150
RoundRect $g $greenB 120 $boxY ($W - 240) $boxH 22
$fLineL = New-Object System.Drawing.Font 'Tahoma', 17, ([System.Drawing.FontStyle]::Bold)
$fLineId = New-Object System.Drawing.Font 'Tahoma', 40, ([System.Drawing.FontStyle]::Bold)
$g.DrawString($t.lineLabel, $fLineL, $white, (New-Object System.Drawing.RectangleF 120, ($boxY + 26), ($W - 240), 26), $sfC)
$g.DrawString($t.lineId, $fLineId, $white, (New-Object System.Drawing.RectangleF 120, ($boxY + 58), ($W - 240), 66), $sfC)

# steps
$fNum = New-Object System.Drawing.Font 'Tahoma', 26, ([System.Drawing.FontStyle]::Bold)
$fStep = New-Object System.Drawing.Font 'Tahoma', 23, ([System.Drawing.FontStyle]::Regular)
$sy = 852
for ($i = 0; $i -lt $t.steps.Count; $i++) {
  $cy = $sy + $i * 96
  $circ = New-Object System.Drawing.Drawing2D.GraphicsPath
  $g.FillEllipse($goldB, 128, $cy, 56, 56)
  $g.DrawString([string]($i + 1), $fNum, (New-Object System.Drawing.SolidBrush $c1), (New-Object System.Drawing.RectangleF 128, ($cy - 2), 56, 56), $sfC)
  $g.DrawString($t.steps[$i], $fStep, $white, (New-Object System.Drawing.RectangleF 210, $cy, ($W - 300), 56), $sfL)
}

# foot
$fFoot = New-Object System.Drawing.Font 'Tahoma', 20, ([System.Drawing.FontStyle]::Bold)
$g.DrawString($t.foot, $fFoot, $goldB, (New-Object System.Drawing.RectangleF 0, ($H - 118), $W, 32), $sfC)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host ("saved $out  ${W}x${H}  " + [math]::Round((Get-Item $out).Length/1KB) + " KB")
