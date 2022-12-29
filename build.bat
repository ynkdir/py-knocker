cl /nologo /W4 /O2 /MD /Femain_stub.exe main.c
cl /nologo /W4 /O2 /MD /Femainw_stub.exe main.c /link /SUBSYSTEM:WINDOWS /ENTRY:wmainCRTStartup
py -m zipapp bootstrap
copy /b main_stub.exe + bootstrap.pyz main.exe
copy /b mainw_stub.exe + bootstrap.pyz mainw.exe
