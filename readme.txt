
Python embeddable package launcher.

This is used for deploying python application with the following package configuration.

myapp/
  python/       # python embeddable package
  lib/myapp.py # main program
  myapp.exe     # launcher


USAGE:
    # Compile main.c with your application name.
    > cl /Femyapp.exe main.c

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

