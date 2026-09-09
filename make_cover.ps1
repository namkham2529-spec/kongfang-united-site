param([string]$textJson, [string]$logo, [string]$out, [int]$W = 1080, [int]$H = 878)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$GP = 'System.Drawing.Drawing2D'
$t = [System.IO.File]::ReadAllText($textJson, [Text.Encoding]::UTF8) | ConvertFrom-Json

$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.TextRenderingHint = 'ClearTypeGridFit'
$g.InterpolationMode = 'HighQualityBicubic'

# navy diagonal gradient
$rectF = New-Object System.Drawing.RectangleF 0, 0, $W, $H
$c1 = [System.Drawing.Color]::FromArgb(255, 7, 19, 46)
$c2 = [System.Drawing.Color]::FromArgb(255, 16, 44, 100)
$bg = New-Object "$GP.LinearGradientBrush" $rectF, $c1, $c2, 60.0
$g.FillRectangle($bg, 0, 0, $W, $H)

# radial glow behind centre
$pth = New-Object "$GP.GraphicsPath"
$pth.AddEllipse(($W/2 - 520), ($H/2 - 420), 1040, 840)
$pgb = New-Object "$GP.PathGradientBrush" $pth
$pgb.CenterColor = [System.Drawing.Color]::FromArgb(70, 90, 140, 220)
$pgb.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 16, 44, 100))
$g.FillPath($pgb, $pth)

# faint pitch motif: centre circle + halfway line
$penFaint = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(26, 255, 255, 255)), 3
$g.DrawEllipse($penFaint, ($W/2 - 150), ($H/2 - 150), 300, 300)
$g.DrawLine($penFaint, 0, ($H/2), $W, ($H/2))
$g.DrawEllipse($penFaint, ($W/2 - 8), ($H/2 - 8), 16, 16)
$arc = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(20, 255, 255, 255)), 3
$g.DrawArc($arc, -170, ($H/2 - 170), 340, 340, -55, 110)
$g.DrawArc($arc, ($W - 170), ($H/2 - 170), 340, 340, 125, 110)

# gold bars top & bottom
$goldC = [System.Drawing.Color]::FromArgb(255, 228, 161, 27)
$goldB = New-Object System.Drawing.SolidBrush $goldC
$g.FillRectangle($goldB, 0, 0, $W, 10)
$g.FillRectangle($goldB, 0, $H - 10, $W, 10)

# logo
if ($logo -and (Test-Path $logo)) {
  $lg = [System.Drawing.Image]::FromFile($logo)
  $lw = 210; $lh = [int]($lg.Height * $lw / $lg.Width)
  $g.DrawImage($lg, [int](($W - $lw)/2), 120, $lw, $lh)
  $lg.Dispose()
}

$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$sub = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(210, 205, 220, 250))
$sfC = New-Object System.Drawing.StringFormat
$sfC.Alignment = 'Center'; $sfC.LineAlignment = 'Center'

$fTh = New-Object System.Drawing.Font 'Tahoma', 58, ([System.Drawing.FontStyle]::Bold)
$fEn = New-Object System.Drawing.Font 'Tahoma', 22, ([System.Drawing.FontStyle]::Bold)
$fTag = New-Object System.Drawing.Font 'Tahoma', 19, ([System.Drawing.FontStyle]::Regular)
$fFoot = New-Object System.Drawing.Font 'Tahoma', 13, ([System.Drawing.FontStyle]::Bold)

$rEn = New-Object System.Drawing.RectangleF 0, 372, $W, 34
$g.DrawString($t.en, $fEn, $goldB, $rEn, $sfC)
$rTh = New-Object System.Drawing.RectangleF 0, 406, $W, 92
$g.DrawString($t.th, $fTh, $white, $rTh, $sfC)

# tag on a gold rule
$g.FillRectangle($goldB, [int]($W/2 - 210), 520, 420, 2)
$rTag = New-Object System.Drawing.RectangleF 0, 534, $W, 34
$g.DrawString($t.tag, $fTag, $sub, $rTag, $sfC)

$rFoot = New-Object System.Drawing.RectangleF 0, ($H - 70), $W, 26
$g.DrawString($t.foot, $fFoot, (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(150, 205, 220, 250))), $rFoot, $sfC)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host ("saved $out  ${W}x${H}  " + [math]::Round((Get-Item $out).Length/1KB) + " KB")
