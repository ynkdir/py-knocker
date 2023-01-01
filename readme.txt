
Python embeddable package launcher.

This is used for deploying python application with the following package configuration.

myapp/
  python/       # python embeddable package
  lib/myapp.py # main program
  myapp.exe     # launcher


USAGE:
    # Build exe file.
    > cl /Femain_stub.exe main.c
    > py -m zipapp bootstrap
    > cmd /c "copy /b main_stub.exe + bootstrap.pyz myapp.exe"

    # Download python embeddable package.
    > curl.exe -O https://www.python.org/ftp/python/3.11.0/python-3.11.0-embed-amd64.zip
    > mkdir python
    > tar.exe -C python -xf python-3.11.0-embed-amd64.zip

    # Write main program.
    > vim python\myapp.py
    print("hello, world")

    # Run myapp.exe.  It runs same name module.
    > .\myapp.exe
    hello, world

    # Install library with pip using system installed python.
    # (see https://github.com/pypa/get-pip to install pip into embeddable package)
    > mkdir python\Lib\site-packages
    > vim python\python311._pth
    uncomment "import site" line
    > py -m pip install -t python\Lib\site-packages requests

    # Separate your program from python directory.
    > mkdir lib
    > move python\myapp.py lib
    > vim python\python311._pth
    add "..\lib" line
    > .\myapp.exe
    hello, world


MEMO:
    How to create exe file to launch system installed python like $PYTHONHOME\Scripts\*.exe.

    > type shebang.txt
    #!C:\path\to\Python\python.exe

    > type myapp\__main__.py
    print("hello, myapp.exe")

    > py -m zipapp myapp    # generate myapp.pyz

    > copy $PYTHONHOME\Lib\site-packages\pip\_vendor\distlib\t64.exe .    # w64.exe for noconsole

    > cmd /c "copy /b t64.exe + shebang.txt + myapp.pyz myapp.exe"

    # distlib's launcher also support relative path and arguments.
    > type shebang_relative.txt
    #!<launcher_dir>\python\python.exe -I

