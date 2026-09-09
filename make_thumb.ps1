param([string]$textJson, [string]$logo, [string]$out)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$GP = 'System.Drawing.Drawing2D'
$t = [System.IO.File]::ReadAllText($textJson, [Text.Encoding]::UTF8) | ConvertFrom-Json

$W = 1280; $H = 720
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'ClearTypeGridFit'; $g.InterpolationMode = 'HighQualityBicubic'

$c1 = [System.Drawing.Color]::FromArgb(255, 7, 19, 46)
$c2 = [System.Drawing.Color]::FromArgb(255, 16, 44, 100)
$g.FillRectangle((New-Object "$GP.LinearGradientBrush" (New-Object System.Drawing.RectangleF 0,0,$W,$H), $c1, $c2, 25.0), 0, 0, $W, $H)

$gold  = [System.Drawing.Color]::FromArgb(255, 228, 161, 27)
$goldB = New-Object System.Drawing.SolidBrush $gold
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$sub   = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 205, 220, 250))
$photoZone = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, 255, 255, 255))
$dashPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(90, 228, 161, 27)), 3
$dashPen.DashStyle = 'Dash'

# left photo zone (guide)
$g.FillRectangle($photoZone, 0, 0, 520, $H)
$g.DrawRectangle($dashPen, 12, 12, 496, $H - 24)
$sfC = New-Object System.Drawing.StringFormat; $sfC.Alignment='Center'; $sfC.LineAlignment='Center'
$g.DrawString($t.note, (New-Object System.Drawing.Font 'Tahoma',13,([System.Drawing.FontStyle]::Regular)), $sub, (New-Object System.Drawing.RectangleF 20,($H-70),480,40), $sfC)

# right text block
$tx = 560
# kicker pill
$g.FillRectangle($goldB, $tx, 96, 250, 46)
$g.DrawString($t.kicker, (New-Object System.Drawing.Font 'Tahoma',20,([System.Drawing.FontStyle]::Bold)), (New-Object System.Drawing.SolidBrush $c1), (New-Object System.Drawing.RectangleF $tx,96,250,46), $sfC)

$g.DrawString($t.line1, (New-Object System.Drawing.Font 'Tahoma',52,([System.Drawing.FontStyle]::Bold)), $white, $tx, 168)
$g.DrawString($t.line2, (New-Object System.Drawing.Font 'Tahoma',72,([System.Drawing.FontStyle]::Bold)), $goldB, $tx, 236)

# score big
$g.DrawString($t.score, (New-Object System.Drawing.Font 'Tahoma',110,([System.Drawing.FontStyle]::Bold)), $white, $tx, 344)

$g.DrawString($t.sub, (New-Object System.Drawing.Font 'Tahoma',20,([System.Drawing.FontStyle]::Regular)), $sub, $tx, 500)

# logo bottom-right
if ($logo -and (Test-Path $logo)) {
  $lg = [System.Drawing.Image]::FromFile($logo)
  $lw = 92; $lh = [int]($lg.Height * $lw / $lg.Width)
  $g.DrawImage($lg, ($W - $lw - 26), ($H - $lh - 22), $lw, $lh)
  $lg.Dispose()
}
$g.FillRectangle($goldB, 0, 0, $W, 7)
$g.FillRectangle($goldB, 0, $H - 7, $W, 7)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host ("saved $out  ${W}x${H}  " + [math]::Round((Get-Item $out).Length/1KB) + " KB")
