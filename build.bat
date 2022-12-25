cl /nologo /W4 /O2 /MD main.c
cl /nologo /W4 /O2 /MD /Femainw.exe main.c /link /SUBSYSTEM:WINDOWS /ENTRY:wmainCRTStartup
