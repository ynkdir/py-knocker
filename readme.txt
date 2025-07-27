Launcher for python application deployment.  Make toplevel directory clean.
This program directly calls python3.dll insted of forking python.exe.

myapp/
  myapp.exe             # launcher
  python/               # python embeddable package
  python/Lib/myapp.py   # main program


USAGE:
    # Build exe file.
    > cargo build
    > copy target\debug\main.exe myapp.exe

    # Download python embeddable package.
    > py download_python.py --outdir=python --pip --tcltk --embed

    # Write main program.
    > vim python\Lib\myapp.py
    print("hello, myapp")

    # Run myapp.exe.  It runs same name module.
    > .\myapp.exe
    hello, myapp


Usage with venv:

    > py -m venv venv
    > vim venv\Lib\site-packages\myapp.py
    print("hello, myapp")
    > cargo build
    > copy target\debug\main.exe venv\Scripts\myapp.exe
    > .\venv\Scripts\myapp.exe
    hello, myapp

