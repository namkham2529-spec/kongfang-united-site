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

$c1 = [System.Drawing.Color]::FromArgb(255, 7, 19, 46)
$c2 = [System.Drawing.Color]::FromArgb(255, 16, 44, 100)
$g.FillRectangle((New-Object "$GP.LinearGradientBrush" (New-Object System.Drawing.RectangleF 0,0,$W,$H), $c1, $c2, 45.0), 0, 0, $W, $H)

$gold  = [System.Drawing.Color]::FromArgb(255, 228, 161, 27)
$goldB = New-Object System.Drawing.SolidBrush $gold
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$sub   = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(210, 205, 220, 250))
$slotBr = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(28, 255, 255, 255))
$dash  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120, 228, 161, 27)), 4
$dash.DashStyle = 'Dash'
$sfC = New-Object System.Drawing.StringFormat; $sfC.Alignment = 'Center'; $sfC.LineAlignment = 'Center'

$g.FillRectangle($goldB, 0, 0, $W, 10)
$g.FillRectangle($goldB, 0, $H - 10, $W, 10)

$logoBottom = [int]($H * 0.12)
if ($logo -and (Test-Path $logo)) {
  $lg = [System.Drawing.Image]::FromFile($logo)
  $lw = [int]($W * 0.135); $lh = [int]($lg.Height * $lw / $lg.Width)
  $ly = [int]($H * 0.07)
  $g.DrawImage($lg, [int](($W - $lw)/2), $ly, $lw, $lh)
  $lg.Dispose()
  $logoBottom = $ly + $lh
}

$szBig = [int]($W * 0.046); if ($szBig -lt 34) { $szBig = 34 }
$szMid = [int]($W * 0.022); if ($szMid -lt 17) { $szMid = 17 }
$szSm  = [int]($W * 0.017); if ($szSm -lt 14) { $szSm = 14 }
$fBig = New-Object System.Drawing.Font 'Tahoma', $szBig, $FS::Bold
$fMid = New-Object System.Drawing.Font 'Tahoma', $szMid, $FS::Bold
$fSm  = New-Object System.Drawing.Font 'Tahoma', $szSm, $FS::Regular

$ctaY = $logoBottom + [int]($H * 0.03)
$g.DrawString($t.cta,  $fBig, $white, (New-Object System.Drawing.RectangleF 0, $ctaY, $W, ([int]($szBig*1.7))), $sfC)
$g.DrawString($t.cta2, $fMid, $goldB, (New-Object System.Drawing.RectangleF 0, ($ctaY + [int]($szBig*1.7)), $W, ([int]($szMid*1.9))), $sfC)

# video slots (dashed placeholders where they drop YouTube end-screen elements)
$fSlot = New-Object System.Drawing.Font 'Tahoma', $szMid, $FS::Bold
function DrawSlot($sx, $sy, $sw, $sh) {
  $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = 44
  $gp.AddArc($sx, $sy, $d, $d, 180, 90)
  $gp.AddArc(($sx + $sw - $d), $sy, $d, $d, 270, 90)
  $gp.AddArc(($sx + $sw - $d), ($sy + $sh - $d), $d, $d, 0, 90)
  $gp.AddArc($sx, ($sy + $sh - $d), $d, $d, 90, 90)
  $gp.CloseFigure()
  $g.FillPath($slotBr, $gp); $g.DrawPath($dash, $gp)
  $g.DrawString($t.slot, $fSlot, $sub, (New-Object System.Drawing.RectangleF $sx, $sy, $sw, $sh), $sfC)
  $gp.Dispose()
}
$slotTop = $ctaY + [int]($szBig * 1.7) + [int]($szMid * 1.9) + [int]($H * 0.03)
if ($aspect -eq "9x16") {
  $slotW = [int]($W * 0.78); $slotH = [int]($slotW * 9 / 16); $gap = [int]($W * 0.05)
  $sx = [int](($W - $slotW) / 2)
  DrawSlot $sx $slotTop $slotW $slotH
  DrawSlot $sx ($slotTop + $slotH + $gap) $slotW $slotH
} else {
  $slotW = [int]($W * 0.355); $slotH = [int]($slotW * 9 / 16); $gap = [int]($W * 0.04)
  $totalW = $slotW * 2 + $gap
  $sx = [int](($W - $totalW) / 2)
  DrawSlot $sx $slotTop $slotW $slotH
  DrawSlot ($sx + $slotW + $gap) $slotTop $slotW $slotH
}

$rF = New-Object System.Drawing.RectangleF 0, ([int]($H - $H*0.09)), $W, ([int]($W*0.04))
$g.DrawString($t.handle, $fSm, $sub, $rF, $sfC)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host ("saved $out  ${W}x${H}")
