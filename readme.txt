Python application launcher.

Make toplevel directory clean.
Call python3.dll directly instead of forking python.exe.

App Launcher:
    myapp/
      myapp.exe                             # launcher
      python/                               # python embeddable package
      python/Lib/site-packages/myapp.py     # main program

    # Build exe file.
    > cargo build
    > copy target\debug\applauncher.exe myapp.exe

    # Download python embeddable package.
    > py download_python.py --outdir=python --pip --tcltk --embed

    # Write main program.
    > vim python\Lib\site-packages\myapp.py
    print("hello, myapp")

    # Run myapp.exe.  It runs same name module.
    > .\myapp.exe
    hello, myapp


Venv Launcher:
    venv/
      Scripts/myapp.exe             # launcher
      Lib/site-packages/myapp.py    # main program

    > py -m venv venv
    > vim venv\Lib\site-packages\myapp.py
    print("hello, myapp")
    > cargo build
    > copy target\debug\venvlauncher.exe venv\Scripts\myapp.exe
    > .\venv\Scripts\myapp.exe
    hello, myapp
