
Launcher for python application deployment.  Make toplevel directory clean.

myapp/
  myapp.exe             # launcher
  python/               # python embeddable package
  python/Lib/myapp.py   # main program


USAGE:
    # Build exe file.
    > cl /Femyapp.exe main.c

    # Download python embeddable package.
    > py download_python.py --outdir=python --pip --tcltk --embed

    # Write main program.
    > vim python\Lib\myapp.py
    print("hello, myapp")

    # Run myapp.exe.  It runs same name module.
    > .\myapp.exe
    hello, myapp


MEMO:
    # Make exe with distlib.
    > py make_exe_with_distlib.py --entry="myapp = myapp:main"

