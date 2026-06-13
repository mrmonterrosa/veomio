Add-Type -AssemblyName System.Drawing

$logoPath = "C:\Users\cgonz\.gemini\antigravity\brain\ed7992bd-89e8-4838-a215-8b09998ec7fa\media__1781325791325.jpg"
$bannerPath = "C:\Users\cgonz\.gemini\antigravity\brain\ed7992bd-89e8-4838-a215-8b09998ec7fa\media__1781325791369.png"

# Create assets dir
New-Item -ItemType Directory -Force -Path "assets/images" | Out-Null
Copy-Item $logoPath "assets/images/logo.jpg" -Force
Copy-Item $bannerPath "assets/images/banner.png" -Force

# Create drawable dir
New-Item -ItemType Directory -Force -Path "android/app/src/main/res/drawable-xhdpi" | Out-Null

# Resize and save banner (320x180)
$bannerImg = [System.Drawing.Image]::FromFile($bannerPath)
$bannerBmp = New-Object System.Drawing.Bitmap(320, 180)
$graph = [System.Drawing.Graphics]::FromImage($bannerBmp)
$graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graph.DrawImage($bannerImg, 0, 0, 320, 180)
$bannerBmp.Save("android/app/src/main/res/drawable-xhdpi/banner.png", [System.Drawing.Imaging.ImageFormat]::Png)
$graph.Dispose()
$bannerBmp.Dispose()
$bannerImg.Dispose()

# Resize and save launcher icons
$logoImg = [System.Drawing.Image]::FromFile($logoPath)
$sizes = @{
    "mdpi" = 48
    "hdpi" = 72
    "xhdpi" = 96
    "xxhdpi" = 144
    "xxxhdpi" = 192
}

foreach ($kv in $sizes.GetEnumerator()) {
    $folder = "android/app/src/main/res/mipmap-$($kv.Key)"
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $bmp = New-Object System.Drawing.Bitmap($kv.Value, $kv.Value)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($logoImg, 0, 0, $kv.Value, $kv.Value)
    $bmp.Save("$folder/ic_launcher.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}
$logoImg.Dispose()

Write-Output "Images processed and copied."
