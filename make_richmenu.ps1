param([string]$textJson, [string]$logo, [string]$out)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$GP = 'System.Drawing.Drawing2D'

$t = [System.IO.File]::ReadAllText($textJson, [Text.Encoding]::UTF8) | ConvertFrom-Json

$W = 2500; $H = 1686
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.TextRenderingHint = 'ClearTypeGridFit'
$g.InterpolationMode = 'HighQualityBicubic'

$rectF = New-Object System.Drawing.RectangleF 0, 0, $W, $H
$c1 = [System.Drawing.Color]::FromArgb(255, 8, 22, 52)
$c2 = [System.Drawing.Color]::FromArgb(255, 14, 40, 92)
$bg = New-Object "$GP.LinearGradientBrush" $rectF, $c1, $c2, 55.0
$g.FillRectangle($bg, 0, 0, $W, $H)

$gold  = [System.Drawing.Color]::FromArgb(255, 228, 161, 27)
$goldB = New-Object System.Drawing.SolidBrush $gold
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$goldFaint = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(34, 228, 161, 27))
$panelBr = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, 255, 255, 255))
$sub   = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(180, 200, 216, 250))

# faint logo watermark centre
if ($logo -and (Test-Path $logo)) {
  $lg = [System.Drawing.Image]::FromFile($logo)
  $lw = 760; $lh = [int]($lg.Height * $lw / $lg.Width)
  $ia = New-Object System.Drawing.Imaging.ImageAttributes
  $cm = New-Object System.Drawing.Imaging.ColorMatrix
  $cm.Matrix33 = 0.05
  $ia.SetColorMatrix($cm)
  $dst = New-Object System.Drawing.Rectangle ([int](($W-$lw)/2)), ([int](($H-$lh)/2)), $lw, $lh
  $g.DrawImage($lg, $dst, 0, 0, $lg.Width, $lg.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
  $lg.Dispose()
}

$cols = 3; $rows = 2
$cw = $W / $cols; $ch = $H / $rows
$pad = 44

# rounded tap-zone panel per cell
function RoundRect($gr, $br, $x, $y, $w, $h, $rad) {
  $gpath = New-Object "$GP.GraphicsPath"
  $d = $rad * 2
  $gpath.AddArc($x, $y, $d, $d, 180, 90)
  $gpath.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $gpath.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $gpath.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $gpath.CloseFigure()
  $gr.FillPath($br, $gpath)
  $gpath.Dispose()
}

$penGold = New-Object System.Drawing.Pen $gold, 3
for ($i = 1; $i -lt $cols; $i++) { $x = [int]($i * $cw); $g.DrawLine($penGold, $x, 80, $x, $H - 80) }
$g.DrawLine($penGold, 80, [int]$ch, $W - 80, [int]$ch)
$g.FillRectangle($goldB, 0, 0, $W, 12)
$g.FillRectangle($goldB, 0, $H - 12, $W, 12)

$fHead = New-Object System.Drawing.Font 'Tahoma', 20, ([System.Drawing.FontStyle]::Bold)
$fEn   = New-Object System.Drawing.Font 'Tahoma', 21, ([System.Drawing.FontStyle]::Bold)
$fTh   = New-Object System.Drawing.Font 'Tahoma', 47, ([System.Drawing.FontStyle]::Bold)
$fIdx  = New-Object System.Drawing.Font 'Tahoma', 140, ([System.Drawing.FontStyle]::Bold)

$sfC = New-Object System.Drawing.StringFormat
$sfC.Alignment = 'Center'; $sfC.LineAlignment = 'Center'

for ($r = 0; $r -lt $rows; $r++) {
  for ($cIdx = 0; $cIdx -lt $cols; $cIdx++) {
    $n = $r * $cols + $cIdx
    $cell = $t.cells[$n]
    $cx = $cIdx * $cw; $cy = $r * $ch

    RoundRect $g $panelBr ($cx + $pad) ($cy + $pad) ($cw - 2*$pad) ($ch - 2*$pad) 26

    $g.DrawString([string]($n + 1), $fIdx, $goldFaint, ($cx + 60), ($cy + $ch - 210))

    $rEn = New-Object System.Drawing.RectangleF $cx, ($cy + $ch/2 - 86), $cw, 38
    $g.DrawString($cell.en, $fEn, $goldB, $rEn, $sfC)
    $rTh = New-Object System.Drawing.RectangleF $cx, ($cy + $ch/2 - 34), $cw, 92
    $g.DrawString($cell.th, $fTh, $white, $rTh, $sfC)
  }
}

# headline centred on the middle divider, on a solid navy pill
$hlW = 1180; $hlH = 54
$hx = [int](($W - $hlW)/2); $hy = [int]($ch - $hlH/2)
RoundRect $g (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 8, 20, 48))) $hx $hy $hlW $hlH 27
$rH = New-Object System.Drawing.RectangleF $hx, $hy, $hlW, $hlH
$g.DrawString($t.headline, $fHead, $sub, $rH, $sfC)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host ("saved $out  ${W}x${H}  " + [math]::Round((Get-Item $out).Length/1KB) + " KB")
