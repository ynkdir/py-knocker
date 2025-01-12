cl /nologo /W4 /O2 /MD /Femain.exe main.c
cl /nologo /W4 /O2 /MD /Femainw.exe main.c /link /SUBSYSTEM:WINDOWS /ENTRY:wmainCRTStartup

rem example using resource
rc /nologo main.rc
cl /nologo /W4 /O2 /MD /Femain_with_resource.exe main.c main.res
cl /nologo /W4 /O2 /MD /Femainw_with_resource.exe main.c main.res /link /SUBSYSTEM:WINDOWS /ENTRY:wmainCRTStartup
