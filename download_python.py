# Download python

import argparse
import shutil
from pathlib import Path
from tempfile import mkdtemp
from urllib.request import urlopen
from subprocess import run

args: argparse.Namespace
ftp = "https://www.python.org/ftp/python"
getpip = "https://bootstrap.pypa.io/get-pip.py"


def download_temporary(url: str) -> Path:
    tmpdir = Path(mkdtemp())
    name = Path(url).name
    outfile = tmpdir / name
    with urlopen(url) as r:
        outfile.write_bytes(r.read())
    return outfile


def expand_msi(msifile: Path, outdir: Path) -> None:
    print(f"Expand msi {msifile} {outdir}")
    msifile_abs = msifile.absolute()
    outdir_abs = outdir.absolute()
    run(["msiexec.exe", "/a", msifile_abs, f"targetdir={outdir_abs}", "/qn"], check=True)


def install_msi(url: str) -> None:
    print(f"Install {url}")
    msifile = download_temporary(url)
    expand_msi(msifile, args.outdir)
    (args.outdir / msifile.name).unlink()
    shutil.rmtree(msifile.parent)


def install_pip() -> None:
    print("Install pip")
    getpip_py = download_temporary(getpip)
    run([args.outdir / "python.exe", getpip_py], check=True)
    shutil.rmtree(getpip_py.parent)


def get_python_version_majorminor() -> str:
    return "".join(args.version.split(".")[0:2])


def install_pth() -> None:
    majorminor = get_python_version_majorminor()
    pth = [f"python{majorminor}.zip", "DLLs", "Lib", args.libdir, "import site"]
    print(f"Install pth {pth}")
    (args.outdir / f"python{majorminor}._pth").write_text("\n".join(pth))


def install_zip(url: str) -> None:
    print(f"Install {url}")
    zipfile = download_temporary(url)
    shutil.unpack_archive(zipfile, args.outdir)
    shutil.rmtree(zipfile.parent)


def install_python_msi() -> None:
    args.outdir.mkdir()
    install_msi(f"{ftp}/{args.version}/{args.arch}/core.msi")
    install_msi(f"{ftp}/{args.version}/{args.arch}/exe.msi")
    install_msi(f"{ftp}/{args.version}/{args.arch}/lib.msi")
    install_pth()
    if args.tcltk:
        install_msi(f"{ftp}/{args.version}/{args.arch}/tcltk.msi")
    if args.pip:
        install_pip()


def install_python_embed() -> None:
    install_zip(f"{ftp}/{args.version}/python-{args.version}-embed-{args.arch}.zip")
    (args.outdir / "DLLs").mkdir()
    (args.outdir / "Lib").mkdir()
    install_pth()
    if args.tcltk:
        install_msi(f"{ftp}/{args.version}/{args.arch}/tcltk.msi")
    if args.pip:
        install_pip()


def main() -> None:
    global args
    parser = argparse.ArgumentParser(description="Download python.")
    parser.add_argument("--version", default="3.11.5")
    parser.add_argument("--arch", default="amd64")
    parser.add_argument("--outdir", default="python", type=Path)
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
