$ErrorActionPreference='Stop'
# Rebuild _deploy/ (externalized, image files) from index.html (embedded).
# Portable: uses this script's own folder. Run:  powershell -ExecutionPolicy Bypass -File build.ps1
$root = $PSScriptRoot
$p    = Join-Path $root 'index.html'
$img  = Join-Path $root 'images'
$U    = New-Object System.Text.UTF8Encoding($false)

Copy-Item (Join-Path $root 'logo.png') (Join-Path $img 'crest.png') -Force

$map=@{
 'logo'='images/crest.png'
 '01'='images/01_monk_pharaachwachirasasanawiwet.jpg'; '02'='images/02_coach_thani.jpg'; '03'='images/03_coach_sakulchai.jpg'
 '04'='images/04_coach_aun.jpg'; '05'='images/05_coach_captain.jpg'; '06'='images/06_kunlathon.jpg'
 '07'='images/07_mayor_somjit.jpg'; '08'='images/08_kamnan_tawee.jpg'; '09'='images/09_huad_phetlert.jpg'
 '10'='images/10_coach_tom.jpg'; '11'='images/11_sonthaya.jpg'; '12'='images/12_sunisa.jpg'
 'S1'='images/sponsor_1_atong.jpg'; 'S2'='images/sponsor_2_agsport.jpg'; 'S3'='images/sponsor_3_kwinday.jpg'; 'S4'='images/sponsor_4_arn.jpg'
 'S5'='images/sponsor_5_masika.jpg'; 'S6'='images/sponsor_6_ps8.jpg'; 'S7'='images/sponsor_7_an.jpg'; 'S8'='images/sponsor_8_chokwasana.jpg'
 'NKS'='images/nks.png'; 'BLA'='images/bla_logo.jpg'; 'KRL'='images/krasang_logo.jpg'
 'H1'='images/hist_H1.jpg'; 'H2'='images/hist_H2.jpg'; 'H3'='images/hist_H3.jpg'
 'H4'='images/hist_H4.jpg'; 'H5'='images/hist_H5.jpg'; 'H6'='images/hist_H6.jpg'
 'FDR'='images/hist_founder.jpg'
 'RS1'='images/result_1_sawaisor.jpg'; 'RS2'='images/result_2_taram.jpg'; 'RSP'='images/pitch_panorama.jpg'
 'JRS'='images/jersey_2026.jpg'; 'HERO'='images/hero_pitch.jpg'; 'CUP'='images/cup_poster.jpg'
 'W3A'='images/result_w3_nongpluang.jpg'; 'W3B'='images/result_w3_nongkhon.jpg'
}

$assets=[System.IO.File]::ReadAllText((Join-Path $root 'assets.json'),$U) | ConvertFrom-Json
$c=[System.IO.File]::ReadAllText($p,$U)
$before=$c.Length
foreach($k in $map.Keys){
  $uri=$assets.$k
  if(-not $uri){ Write-Host "  ! no asset for $k"; continue }
  $path=Join-Path $img (Split-Path $map[$k] -Leaf)
  if(-not (Test-Path $path)){ Write-Host "  ! missing file: $path"; continue }
  $n=([regex]::Matches($c,[regex]::Escape($uri))).Count
  if($n -eq 0){ continue }
  $c=$c.Replace($uri,$map[$k])
}
$remain=([regex]::Matches($c,'data:image/[a-z]+;base64,')).Count
Write-Host ("before=$([int]($before/1024))KB  after=$([int]($c.Length/1024))KB  embedded left=$remain")

$dep=Join-Path $root '_deploy'
if(Test-Path $dep){ Remove-Item $dep -Recurse -Force }
New-Item -ItemType Directory -Path $dep | Out-Null
[System.IO.File]::WriteAllText((Join-Path $dep 'index.html'),$c,$U)
Copy-Item $img (Join-Path $dep 'images') -Recurse

# externalize any base64 blobs still inline (Node-free; was: node externalize-inline.js)
& (Join-Path $root 'externalize-inline.ps1')

# keep single-file copy fresh too
$nu = Join-Path $root 'netlify-upload'
if(-not (Test-Path $nu)){ New-Item -ItemType Directory -Path $nu | Out-Null }
Copy-Item $p (Join-Path $nu 'index.html') -Force
Write-Host ("_deploy rebuilt: index.html + images/ (" + (Get-ChildItem (Join-Path $dep 'images') -File).Count + " files)")
