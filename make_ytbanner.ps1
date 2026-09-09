param([string]$textJson, [string]$logo, [string]$out)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$GP = 'System.Drawing.Drawing2D'
$t = [System.IO.File]::ReadAllText($textJson, [Text.Encoding]::UTF8) | ConvertFrom-Json

$W = 2048; $H = 1152
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'ClearTypeGridFit'; $g.InterpolationMode = 'HighQualityBicubic'

$rectF = New-Object System.Drawing.RectangleF 0, 0, $W, $H
$c1 = [System.Drawing.Color]::FromArgb(255, 7, 19, 46)
$c2 = [System.Drawing.Color]::FromArgb(255, 16, 44, 100)
$g.FillRectangle((New-Object "$GP.LinearGradientBrush" $rectF, $c1, $c2, 20.0), 0, 0, $W, $H)

$pth = New-Object "$GP.GraphicsPath"; $pth.AddEllipse(($W/2 - 760), ($H/2 - 380), 1520, 760)
$pgb = New-Object "$GP.PathGradientBrush" $pth
$pgb.CenterColor = [System.Drawing.Color]::FromArgb(66, 90, 140, 220)
$pgb.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 16, 44, 100))
$g.FillPath($pgb, $pth)

$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(15, 255, 255, 255)), 3
$g.DrawEllipse($pen, ($W/2 - 230), ($H/2 - 230), 460, 460)
$arc = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(12, 255, 255, 255)), 3
$g.DrawArc($arc, -260, ($H/2 - 260), 520, 520, -55, 110)
$g.DrawArc($arc, ($W - 260), ($H/2 - 260), 520, 520, 125, 110)

$gold = [System.Drawing.Color]::FromArgb(255, 228, 161, 27)
$goldB = New-Object System.Drawing.SolidBrush $gold
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$sub = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(214, 205, 220, 250))
$dim = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(150, 200, 214, 246))

$fEn  = New-Object System.Drawing.Font 'Tahoma', 21, ([System.Drawing.FontStyle]::Bold)
$fTh  = New-Object System.Drawing.Font 'Tahoma', 66, ([System.Drawing.FontStyle]::Bold)
$fTag = New-Object System.Drawing.Font 'Tahoma', 21, ([System.Drawing.FontStyle]::Regular)
$fTop = New-Object System.Drawing.Font 'Tahoma', 19, ([System.Drawing.FontStyle]::Bold)

$sfC = New-Object System.Drawing.StringFormat; $sfC.Alignment = 'Center'; $sfC.LineAlignment = 'Center'

# --- centred stack: logo above text, whole group centred in the safe band ---
$cx = $W / 2
$logoY = 300
if ($logo -and (Test-Path $logo)) {
  $lg = [System.Drawing.Image]::FromFile($logo)
  $lw = 168; $lh = [int]($lg.Height * $lw / $lg.Width)
  $g.DrawImage($lg, [int]($cx - $lw/2), $logoY, $lw, $lh)
  $lg.Dispose()
}

$g.DrawString($t.en,  $fEn,  $goldB, (New-Object System.Drawing.RectangleF 0, 500, $W, 30), $sfC)
$g.DrawString($t.th,  $fTh,  $white, (New-Object System.Drawing.RectangleF 0, 534, $W, 92), $sfC)
$g.DrawString($t.tag, $fTag, $sub,   (New-Object System.Drawing.RectangleF 0, 632, $W, 32), $sfC)

$g.FillRectangle($goldB, [int]($cx - 340), 686, 680, 2)
$g.DrawString($t.topics, $fTop, $dim,   (New-Object System.Drawing.RectangleF 0, 700, $W, 28), $sfC)
$g.DrawString($t.sched,  $fTop, $goldB, (New-Object System.Drawing.RectangleF 0, 736, $W, 28), $sfC)

$g.FillRectangle($goldB, 0, 0, $W, 8)
$g.FillRectangle($goldB, 0, $H - 8, $W, 8)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host ("saved $out  ${W}x${H}  " + [math]::Round((Get-Item $out).Length/1KB) + " KB")
