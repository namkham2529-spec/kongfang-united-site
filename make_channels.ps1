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
$rowBg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(26, 255, 255, 255))

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
  $g.DrawImage($lg, [int](($W - $lw)/2), 60, $lw, $lh); $lg.Dispose()
}
$g.DrawString($t.brand, (New-Object System.Drawing.Font 'Tahoma', 19, ([System.Drawing.FontStyle]::Bold)), $white, (New-Object System.Drawing.RectangleF 0, 190, $W, 30), $sfC)
$g.DrawString($t.eyebrow, (New-Object System.Drawing.Font 'Tahoma', 15, ([System.Drawing.FontStyle]::Bold)), $goldB, (New-Object System.Drawing.RectangleF 0, 228, $W, 26), $sfC)
$g.DrawString($t.title, (New-Object System.Drawing.Font 'Tahoma', 50, ([System.Drawing.FontStyle]::Bold)), $white, (New-Object System.Drawing.RectangleF 0, 262, $W, 82), $sfC)

# rows
$fTag = New-Object System.Drawing.Font 'Tahoma', 14, ([System.Drawing.FontStyle]::Bold)
$fName = New-Object System.Drawing.Font 'Tahoma', 26, ([System.Drawing.FontStyle]::Bold)
$fVal = New-Object System.Drawing.Font 'Tahoma', 21, ([System.Drawing.FontStyle]::Regular)
$rx = 90; $rw = $W - 180; $rh = 120; $ry = 396
for ($i = 0; $i -lt $t.rows.Count; $i++) {
  $r = $t.rows[$i]
  $y = $ry + $i * ($rh + 22)
  RoundRect $g $rowBg $rx $y $rw $rh 20
  $rgb = $r.color.Split(',')
  $badge = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, [int]$rgb[0], [int]$rgb[1], [int]$rgb[2]))
  RoundRect $g $badge ($rx + 22) ($y + 26) 68 68 16
  $g.DrawString($r.tag, $fTag, $white, (New-Object System.Drawing.RectangleF ($rx + 110), ($y + 20), ($rw - 130), 24), $sfL)
  $g.DrawString($r.name, $fName, $white, (New-Object System.Drawing.RectangleF ($rx + 110), ($y + 44), ($rw - 130), 40), $sfL)
  $g.DrawString($r.val, $fVal, $sub, (New-Object System.Drawing.RectangleF ($rx + 110), ($y + 84), ($rw - 130), 30), $sfL)
}

# QR
$qy = $ry + 3 * ($rh + 22) + 26
$qp = 240; $qx = [int](($W - $qp)/2)
RoundRect $g $white $qx $qy $qp $qp 18
if ($qr -and (Test-Path $qr)) {
  $qi = [System.Drawing.Image]::FromFile($qr)
  $g.DrawImage($qi, ($qx + 20), ($qy + 20), ($qp - 40), ($qp - 40)); $qi.Dispose()
}
$g.DrawString($t.qrCaption, (New-Object System.Drawing.Font 'Tahoma', 17, ([System.Drawing.FontStyle]::Regular)), $sub, (New-Object System.Drawing.RectangleF 0, ($qy + $qp + 16), $W, 28), $sfC)

$g.DrawString($t.foot, (New-Object System.Drawing.Font 'Tahoma', 20, ([System.Drawing.FontStyle]::Bold)), $goldB, (New-Object System.Drawing.RectangleF 0, ($H - 96), $W, 32), $sfC)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host ("saved $out  ${W}x${H}  " + [math]::Round((Get-Item $out).Length/1KB) + " KB")
