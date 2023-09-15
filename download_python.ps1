# Download python

Param(
    [String]$Version = "3.11.5",
    [String]$Arch = "amd64",
    [String]$OutDir = "python",
    [String]$LibDir = ""
)

$ftp = "https://www.python.org/ftp/python/$Version/$Arch"
$getpip = "https://bootstrap.pypa.io/get-pip.py"

function Write-Info($msg) {
    Write-Host $msg -ForegroundColor Green
}

function New-TemporaryPath() {
    $t = New-TemporaryFile
    Remove-Item $t
    return $t.FullName
}

function New-TemporaryFolder() {
    return New-Item -Path (New-TemporaryPath) -ItemType directory
}

function Expand-Msi($msifile, $outdir) {
    Write-Info "Expand-Msi $msifile $outdir"
    Start-Process msiexec.exe "/a $msifile targetdir=`"$outdir`" /qn" -Wait
}

function Install-Pip() {
    Write-Info "Install pip."
    $t = New-TemporaryPath
    Invoke-WebRequest $getpip -OutFile $t
    & $OutDir\python.exe $t
}

function Install-Msi($url, $outdir) {
    Write-Info "Install $url"
    $msi = ([uri]$url).Segments[-1]
    $tmsi = "$(New-TemporaryFolder)\$msi"
    Invoke-WebRequest $url -OutFile $tmsi
    Expand-Msi $tmsi (Get-Item $outdir).FullName
    Remove-Item "$OutDir\$msi"
}

function Install-Pth($libdir) {
    Write-Info "Install Pth $libdir"
    $pth = @"
.\DLLs
.\Lib
..\$libdir
import site
"@
    $ver = (&"$OutDir\python.exe" -c "import sys; print(f'{sys.version_info.major}{sys.version_info.minor}')")
    Set-Content -Path "$OutDir\python$ver._pth" -NoNewLine -Value $pth
}

if (-not (Test-Path $OutDir)) {
    New-Item -Path $OutDir -ItemType directory
}

Install-Msi "$ftp/core.msi" $OutDir
Install-Msi "$ftp/exe.msi" $OutDir
Install-Msi "$ftp/lib.msi" $OutDir
Install-Msi "$ftp/tcltk.msi" $OutDir
Install-Pip
if ($LibDir -ne "") {
    Install-Pth $LibDir
}

