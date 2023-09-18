# Download python

Param(
    [String]$Version = "3.11.5",
    [String]$Arch = "amd64",
    [String]$OutDir = "python",
    [String]$LibDir = "",
    [switch]$Tcltk,
    [switch]$Pip,
    [switch]$Embed
)

$ftp = "https://www.python.org/ftp/python"
$getpip = "https://bootstrap.pypa.io/get-pip.py"

function Write-Info($msg) {
    Write-Host $msg -ForegroundColor Green
}

function New-TemporaryFolder() {
    $tmpfile = New-TemporaryFile
    Remove-Item $tmpfile
    return New-Item -Path $tmpfile.FullName -ItemType directory
}

function Get-AbsolutePath($path) {
    try {
        return (Get-Item $path -ErrorAction Stop).FullName
    } catch {
        # When path does not exist.
        return $_.TargetObject
    }
}

function Download-Temporary($url) {
    $tmpdir = New-TemporaryFolder
    $filename = Split-Path -Path $url -Leaf
    Invoke-WebRequest $url -OutFile $tmpdir/$filename
    return Get-Item $tmpdir/$filename
}

function Expand-Msi($msifile, $outdir) {
    Write-Info "Expand-Msi $msifile $outdir"
    # msiexec.exe requires absolute path
    $msifile_abs = Get-AbsolutePath $msifile
    $outdir_abs = Get-AbsolutePath $outdir
    Start-Process msiexec.exe "/a $msifile_abs targetdir=`"$outdir_abs`" /qn" -Wait
}

function Install-Msi($url, $outdir) {
    Write-Info "Install $url"
    $msifile = Download-Temporary $url
    Expand-Msi $msifile $outdir
    Remove-Item $outdir\$($msifile.Name)
}

function Install-Pip() {
    Write-Info "Install pip."
    (Invoke-WebRequest $getpip).Content | & $OutDir\python.exe
}

function Get-Python-Version-MajorMinor() {
    return $Version.split(".")[0..1] -join ""
}

# Note: _pth file enables isolated mode.
function Install-Pth() {
    $majorminor = Get-Python-Version-MajorMinor
    $pth = @("python$majorminor.zip", "DLLs", "Lib", $LibDir, "import site")
    Write-Info "Install Pth $pth"
    Set-Content -Path $OutDir\python$majorminor._pth -Value $pth
}

function Install-Embed() {
    $url = "$ftp/$Version/python-$Version-embed-$Arch.zip"
    Write-Info "Install $url"
    $zipfile = Download-Temporary $url
    Expand-Archive $zipfile -DestinationPath $OutDir
}

function Install-Python-Msi() {
    New-Item -Path $OutDir -ItemType directory
    Install-Msi "$ftp/$Version/$Arch/core.msi" $OutDir
    Install-Msi "$ftp/$Version/$Arch/exe.msi" $OutDir
    Install-Msi "$ftp/$Version/$Arch/lib.msi" $OutDir
    Install-Pth
    if ($Tcltk) {
        Install-Msi "$ftp/$Version/$Arch/tcltk.msi" $OutDir
    }
    if ($Pip) {
        Install-Pip
    }
}

function Install-Python-Embed() {
    Install-Embed
    New-Item -Path $OutDir\DLLs -ItemType directory
    New-Item -Path $OutDir\Lib -ItemType directory
    Install-Pth
    if ($Tcltk) {
        Install-Msi "$ftp/$Version/$Arch/tcltk.msi" $OutDir
    }
    if ($Pip) {
        Install-Pip
    }
}

if ($Embed) {
    Install-Python-Embed
} else {
    Install-Python-Msi
}

