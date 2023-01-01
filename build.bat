cl /nologo /W4 /O2 /MD /Femain_stub.exe main.c
cl /nologo /W4 /O2 /MD /Femainw_stub.exe main.c /link /SUBSYSTEM:WINDOWS /ENTRY:wmainCRTStartup
py -m zipapp bootstrap
copy /b main_stub.exe + bootstrap.pyz main.exe
copy /b mainw_stub.exe + bootstrap.pyz mainw.exe

rem example using resource
rc /nologo main.rc
cl /nologo /W4 /O2 /MD /Femain_with_resource.exe main.c main.res
cl /nologo /W4 /O2 /MD /Femainw_with_resource.exe main.c main.res /link /SUBSYSTEM:WINDOWS /ENTRY:wmainCRTStartup
