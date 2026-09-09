param([string]$textJson, [string]$crestL, [string]$crestR, [string]$out, [string]$aspect = "16x9")
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$GP = 'System.Drawing.Drawing2D'
$FS = [System.Drawing.FontStyle]
$t = [System.IO.File]::ReadAllText($textJson, [Text.Encoding]::UTF8) | ConvertFrom-Json

if ($aspect -eq "9x16") { $W = 1080; $H = 1920 } else { $W = 1920; $H = 1080 }
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'ClearTypeGridFit'; $g.InterpolationMode = 'HighQualityBicubic'

$c1 = [System.Drawing.Color]::FromArgb(255, 6, 15, 38)
$c2 = [System.Drawing.Color]::FromArgb(255, 14, 40, 92)
$rf = New-Object System.Drawing.RectangleF 0, 0, $W, $H
$bgBrush = New-Object "$GP.LinearGradientBrush" $rf, $c1, $c2, 90.0
$g.FillRectangle($bgBrush, 0, 0, $W, $H)

$gold  = [System.Drawing.Color]::FromArgb(255, 228, 161, 27)
$goldB = New-Object System.Drawing.SolidBrush $gold
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$sub   = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 205, 220, 250))
$navyBr = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235, 8, 20, 48))
$inkBr  = New-Object System.Drawing.SolidBrush $c1
$sfC = New-Object System.Drawing.StringFormat
$sfC.Alignment = 'Center'; $sfC.LineAlignment = 'Center'

$g.FillRectangle($goldB, 0, 0, $W, 10)
$g.FillRectangle($goldB, 0, ($H - 10), $W, 10)

$cx = [int]($W / 2)
$cy = [int]($H * 0.44)

$szFT    = [int]($W * 0.024); if ($szFT -lt 20) { $szFT = 20 }
$szScore = [int]($W * 0.105); if ($szScore -lt 90) { $szScore = 90 }
$szName  = [int]($W * 0.021); if ($szName -lt 17) { $szName = 17 }
$szNote  = [int]($W * 0.026); if ($szNote -lt 20) { $szNote = 20 }
$szFoot  = [int]($W * 0.017); if ($szFoot -lt 14) { $szFoot = 14 }
$fFT    = New-Object System.Drawing.Font 'Tahoma', $szFT, $FS::Bold
$fScore = New-Object System.Drawing.Font 'Tahoma', $szScore, $FS::Bold
$fName  = New-Object System.Drawing.Font 'Tahoma', $szName, $FS::Bold
$fNote  = New-Object System.Drawing.Font 'Tahoma', $szNote, $FS::Bold
$fFoot  = New-Object System.Drawing.Font 'Tahoma', $szFoot, $FS::Regular

function Band($x, $y, $w, $h, $rad, $brush) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $dd = $rad * 2
  $p.AddArc($x, $y, $dd, $dd, 180, 90)
  $p.AddArc(($x + $w - $dd), $y, $dd, $dd, 270, 90)
  $p.AddArc(($x + $w - $dd), ($y + $h - $dd), $dd, $dd, 0, 90)
  $p.AddArc($x, ($y + $h - $dd), $dd, $dd, 90, 90)
  $p.CloseFigure()
  $g.FillPath($brush, $p)
  $p.Dispose()
}
function Center($text, $font, $brush, $y, $h) {
  $r = New-Object System.Drawing.RectangleF 0, $y, $W, $h
  $g.DrawString($text, $font, $brush, $r, $sfC)
}
function At($text, $font, $brush, $x, $y, $w, $h) {
  $r = New-Object System.Drawing.RectangleF $x, $y, $w, $h
  $g.DrawString($text, $font, $brush, $r, $sfC)
}

# FULL TIME pill
$pw = [int]($W * 0.36); $ph = [int]($W * 0.052)
$ftY = [int]($cy - $W * 0.21)
Band ([int]($cx - $pw/2)) $ftY $pw $ph 24 $goldB
Center $t.ft $fFT $inkBr $ftY $ph

# crests (pushed to the outer thirds, clear of the centre score)
$crSize = [int]($W * 0.155)
$lx = [int]($W * 0.11)
$rx = [int]($W - $W * 0.11 - $crSize)
function DrawCrest($path, $x) {
  if ($path -and (Test-Path $path)) {
    $ci = [System.Drawing.Image]::FromFile($path)
    $ch = [int]($ci.Height * $crSize / $ci.Width)
    $g.DrawImage($ci, $x, [int]($cy - $ch/2), $crSize, $ch)
    $ci.Dispose()
  }
}
DrawCrest $crestL $lx
DrawCrest $crestR $rx

# score  L  dash  R  (tight centred group)
$sBox = [int]($W * 0.10)
At $t.scoreL $fScore $white ([int]($cx - $W*0.070 - $sBox/2)) ([int]($cy - $szScore)) $sBox ($szScore*2)
At $t.dash   $fScore $goldB ([int]($cx - $W*0.045)) ([int]($cy - $szScore)) ([int]($W*0.09)) ($szScore*2)
At $t.scoreR $fScore $white ([int]($cx + $W*0.070 - $sBox/2)) ([int]($cy - $szScore)) $sBox ($szScore*2)

# team names under crests
$nameY = [int]($cy + $crSize * 0.66)
$nameW = [int]($W * 0.40)
At $t.teamL $fName $sub ([int]($lx + $crSize/2 - $nameW/2)) $nameY $nameW ([int]($szName*2.4))
At $t.teamR $fName $sub ([int]($rx + $crSize/2 - $nameW/2)) $nameY $nameW ([int]($szName*2.4))

# note strip
$noteH = [int]($szNote * 2.4)
$ny = [int]($cy + $W * 0.205)
$g.FillRectangle($navyBr, 0, $ny, $W, $noteH)
$g.FillRectangle($goldB, 0, $ny, $W, 3)
$g.FillRectangle($goldB, 0, ($ny + $noteH - 3), $W, 3)
Center $t.note $fNote $goldB $ny $noteH

# footer
Center $t.foot $fFoot $sub ([int]($H - $H*0.085)) ([int]($szFoot*2.2))

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output ("saved " + $out)
