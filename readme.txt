
Launcher for python application deployment.  Make toplevel directory clean.

myapp/
  myapp.exe             # launcher
  python/               # python embeddable package
  python/Lib/myapp.py   # main program


USAGE:
    # Build exe file.
    > cl /Femain_stub.exe main.c
    > py -m zipapp bootstrap
    > cmd /c "copy /b main_stub.exe + bootstrap.pyz myapp.exe"

    # Download python embeddable package.
    > py download_python.py --outdir=python --pip --tcltk --embed

    # Write main program.
    > vim python\Lib\myapp.py
    def main():
        print("hello, myapp")
    if __name__ == "__main__":
        main()

    # Run myapp.exe.  It runs same name module.
    > .\myapp.exe
    hello, myapp


MEMO:
    # Make exe with distlib.
    > py make_exe_with_distlib.py --entry="myapp = myapp:main"

