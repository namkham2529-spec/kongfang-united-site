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
$sub   = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(224, 205, 220, 250))
$photoZone = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(28, 255, 255, 255))
$dashPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(85, 228, 161, 27)), 3
$dashPen.DashStyle = 'Dash'
$sfC = New-Object System.Drawing.StringFormat; $sfC.Alignment='Center'; $sfC.LineAlignment='Center'

# left photo guide zone
$g.FillRectangle($photoZone, 0, 0, 500, $H)
$g.DrawRectangle($dashPen, 12, 12, 476, $H - 24)
$g.DrawString($t.photoNote, (New-Object System.Drawing.Font 'Tahoma',13,([System.Drawing.FontStyle]::Regular)), $sub, (New-Object System.Drawing.RectangleF 20,($H-64),460,40), $sfC)

$tx = 540
# kicker pill
$rgb = ($t.kickerColor).Split(',')
$kb = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,[int]$rgb[0],[int]$rgb[1],[int]$rgb[2]))
$pillW = 40 + $t.kicker.Length * 20
$g.FillRectangle($kb, $tx, 86, $pillW, 48)
$g.DrawString($t.kicker, (New-Object System.Drawing.Font 'Tahoma',20,([System.Drawing.FontStyle]::Bold)), $white, (New-Object System.Drawing.RectangleF $tx,86,$pillW,48), $sfC)

# headline lines
$l1s = 48; if ($t.line1Size) { $l1s = [int]$t.line1Size }
$l2s = 62; if ($t.line2Size) { $l2s = [int]$t.line2Size }
$f1 = New-Object System.Drawing.Font 'Tahoma', $l1s, ([System.Drawing.FontStyle]::Bold)
$g.DrawString($t.line1, $f1, $white, $tx, 158)
if ($t.line2) {
  $f2 = New-Object System.Drawing.Font 'Tahoma', $l2s, ([System.Drawing.FontStyle]::Bold)
  $g.DrawString($t.line2, $f2, $goldB, $tx, ([int](158 + $l1s * 1.35)))
}

# big element (score / number / word)
if ($t.big) {
  $g.DrawString($t.big, (New-Object System.Drawing.Font 'Tahoma',(([int]$t.bigSize)),([System.Drawing.FontStyle]::Bold)), $white, $tx, ([int]$t.bigY))
}
# subtitle
if ($t.sub) { $g.DrawString($t.sub, (New-Object System.Drawing.Font 'Tahoma',21,([System.Drawing.FontStyle]::Regular)), $sub, $tx, ([int]$t.subY)) }

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
Write-Host ("saved $out")
