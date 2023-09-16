# Download python

Param(
    [String]$Version = "3.11.5",
    [String]$Arch = "amd64",
    [String]$OutDir = "python",
    [String]$LibDir = "",
    [switch]$Embed
)

$ftp = "https://www.python.org/ftp/python"
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

function Get-Python-Version() {
    & "$OutDir\python.exe" -c "import sys; print(f'{sys.version_info.major}{sys.version_info.minor}')"
}

function Install-Pth($libdir) {
    Write-Info "Install Pth $libdir"
    $ver = Get-Python-Version
    $pth = @"
DLLs
Lib
$libdir
import site
"@
    Set-Content -Path "$OutDir\python$ver._pth" -NoNewLine -Value $pth
}

function Install-Pth-Embed($libdir) {
    $ver = Get-Python-Version
    $pth = @"
python$ver.zip
Lib
$libdir
import site
"@
    Set-Content -Path "$OutDir\python$ver._pth" -NoNewLine -Value $pth
}

function Install-Embed() {
    $url = "$ftp/$Version/python-$Version-embed-$Arch.zip"
    Write-Info "Install $url"
    $t = New-TemporaryFolder
    Invoke-WebRequest $url -OutFile "$t/python.zip"
    Expand-Archive "$t/python.zip" -DestinationPath $OutDir
}

function Install-Tkinter() {
    $t = New-TemporaryFolder
    Install-Msi "$ftp/$Version/$Arch/tcltk.msi" $t
    Move-Item $t\DLLs\* $OutDir\
    Move-Item $t\Lib\* $OutDir\Lib\
    Move-Item $t\tcl $OutDir\
}

function Install-Python-Msi() {
    New-Item -Path $OutDir -ItemType directory
    Install-Msi "$ftp/$Version/$Arch/core.msi" $OutDir
    Install-Msi "$ftp/$Version/$Arch/exe.msi" $OutDir
    Install-Msi "$ftp/$Version/$Arch/lib.msi" $OutDir
    Install-Msi "$ftp/$Version/$Arch/tcltk.msi" $OutDir
    Install-Pth $LibDir
    Install-Pip
}

function Install-Python-Embed() {
    Install-Embed
    Install-Pth-Embed $LibDir
    Install-Tkinter
    Install-Pip
}

if ($Embed) {
    Install-Python-Embed
} else {
    Install-Python-Msi
}

