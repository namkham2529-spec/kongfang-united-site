param([string]$textJson, [string]$logo, [string]$out, [string]$aspect = "16x9")
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$GP = 'System.Drawing.Drawing2D'
$FS = [System.Drawing.FontStyle]
$t = [System.IO.File]::ReadAllText($textJson, [Text.Encoding]::UTF8) | ConvertFrom-Json

if ($aspect -eq "9x16") { $W = 1080; $H = 1920 } else { $W = 1920; $H = 1080 }
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'ClearTypeGridFit'; $g.InterpolationMode = 'HighQualityBicubic'

$c1 = [System.Drawing.Color]::FromArgb(255, 6, 16, 40)
$c2 = [System.Drawing.Color]::FromArgb(255, 14, 40, 92)
$g.FillRectangle((New-Object "$GP.LinearGradientBrush" (New-Object System.Drawing.RectangleF 0,0,$W,$H), $c1, $c2, 90.0), 0, 0, $W, $H)

# centre glow
$pth = New-Object "$GP.GraphicsPath"; $pth.AddEllipse(($W/2 - $W*0.4), ($H/2 - $W*0.4), $W*0.8, $W*0.8)
$pgb = New-Object "$GP.PathGradientBrush" $pth
$pgb.CenterColor = [System.Drawing.Color]::FromArgb(90, 90, 140, 220)
$pgb.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 14, 40, 92))
$g.FillPath($pgb, $pth)

$gold = [System.Drawing.Color]::FromArgb(255, 228, 161, 27)
$goldB = New-Object System.Drawing.SolidBrush $gold
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$sub = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(214, 205, 220, 250))
$sfC = New-Object System.Drawing.StringFormat; $sfC.Alignment = 'Center'; $sfC.LineAlignment = 'Center'

if ($logo -and (Test-Path $logo)) {
  $lg = [System.Drawing.Image]::FromFile($logo)
  $lw = [int]($W * 0.24); $lh = [int]($lg.Height * $lw / $lg.Width)
  $ly = if ($aspect -eq "9x16") { [int]($H * 0.30) } else { [int]($H * 0.20) }
  $g.DrawImage($lg, [int](($W - $lw)/2), $ly, $lw, $lh)
  $lg.Dispose()
  $baseY = $ly + $lh + [int]($H * 0.02)
} else { $baseY = [int]($H * 0.42) }

$szEn = [int]($W * 0.020); if ($szEn -lt 16) { $szEn = 16 }
$szTh = [int]($W * 0.052); if ($szTh -lt 40) { $szTh = 40 }
$szTag = [int]($W * 0.019); if ($szTag -lt 15) { $szTag = 15 }
$fEn = New-Object System.Drawing.Font 'Tahoma', $szEn, $FS::Bold
$fTh = New-Object System.Drawing.Font 'Tahoma', $szTh, $FS::Bold
$fTag = New-Object System.Drawing.Font 'Tahoma', $szTag, $FS::Regular

$g.DrawString($t.en, $fEn, $goldB, (New-Object System.Drawing.RectangleF 0, $baseY, $W, ([int]($W*0.04))), $sfC)
$g.DrawString($t.th, $fTh, $white, (New-Object System.Drawing.RectangleF 0, ($baseY + [int]($W*0.045)), $W, ([int]($W*0.09))), $sfC)
$ry = $baseY + [int]($W*0.045) + [int]($W*0.10)
$g.FillRectangle($goldB, [int]($W/2 - $W*0.14), $ry, [int]($W*0.28), 3)
$g.DrawString($t.tag, $fTag, $sub, (New-Object System.Drawing.RectangleF 0, ($ry + 14), $W, ([int]($W*0.04))), $sfC)

$g.FillRectangle($goldB, 0, 0, $W, 8)
$g.FillRectangle($goldB, 0, $H - 8, $W, 8)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host ("saved $out  ${W}x${H}")
