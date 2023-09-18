# Download python

import argparse
from pathlib import Path
from tempfile import mkdtemp
from urllib.request import urlopen
from zipfile import ZipFile
from subprocess import run

args = None
ftp = "https://www.python.org/ftp/python"
getpip = "https://bootstrap.pypa.io/get-pip.py"


def download_temporary(url):
    tmpdir = mkdtemp()
    filename = Path(url).name
    f = Path(tmpdir) / filename
    with urlopen(url) as r:
        f.write_bytes(r.read())
    return f


def expand_msi(msifile, outdir):
    print(f"Expand msi {msifile} {outdir}")
    msifile_abs = Path(msifile).absolute()
    outdir_abs = Path(outdir).absolute()
    run(["msiexec.exe", "/a", msifile_abs, f"targetdir={outdir_abs}", "/qn"], check=True)


def install_msi(url, outdir):
    print(f"Install {url}")
    msifile = download_temporary(url)
    expand_msi(msifile, outdir)
    (Path(outdir) / msifile.name).unlink()


def install_pip():
    print("Install pip")
    getpip_py = download_temporary(getpip)
    run([Path(args.outdir) / "python.exe", getpip_py], check=True)


def get_python_version_majorminor():
    return "".join(args.version.split(".")[0:2])


def install_pth():
    majorminor = get_python_version_majorminor()
    pth = [f"python{majorminor}.zip", "DLLs", "Lib", args.libdir, "import site"]
    print(f"Install pth {pth}")
    (Path(args.outdir) / f"python{majorminor}._pth").write_text("\n".join(pth))


def install_embed():
    url = f"{ftp}/{args.version}/python-{args.version}-embed-{args.arch}.zip"
    print(f"Install {url}")
    zipfile = download_temporary(url)
    with ZipFile(zipfile) as z:
        z.extractall(args.outdir)


def install_python_msi():
    Path(args.outdir).mkdir()
    install_msi(f"{ftp}/{args.version}/{args.arch}/core.msi", args.outdir)
    install_msi(f"{ftp}/{args.version}/{args.arch}/exe.msi", args.outdir)
    install_msi(f"{ftp}/{args.version}/{args.arch}/lib.msi", args.outdir)
    install_pth()
    if args.tcltk:
        install_msi(f"{ftp}/{args.version}/{args.arch}/tcltk.msi", args.outdir)
    if args.pip:
        install_pip()


def install_python_embed():
    install_embed()
    (Path(args.outdir) / "DLLs").mkdir()
    (Path(args.outdir) / "Lib").mkdir()
    install_pth()
    if args.tcltk:
        install_msi(f"{ftp}/{args.version}/{args.arch}/tcltk.msi", args.outdir)
    if args.pip:
        install_pip()


def main():
    global args
    parser = argparse.ArgumentParser(description="Download python.")
    parser.add_argument("--version", default="3.11.5")
    parser.add_argument("--arch", default="amd64")
    parser.add_argument("--outdir", default="python")
    parser.add_argument("--libdir", default="")
    parser.add_argument("--tcltk", action="store_true")
    parser.add_argument("--pip", action="store_true")
    parser.add_argument("--embed", action="store_true")
    args = parser.parse_args()
    if args.embed:
        install_python_embed()
    else:
        install_python_msi()


if __name__ == "__main__":
    main()
