#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlwapi.h>
#include <shellapi.h>
#include <stdlib.h>
#pragma comment(lib, "onecore.lib")

#define PYTHON_DLL_PATH L"python\\python3.dll"
#define MAIN_MODULE L"main"

typedef int (*PY_MAIN)(int, wchar_t**);

int wmain(int argc, wchar_t **argv) {
    wchar_t path[_MAX_PATH];
    if (GetModuleFileNameW(NULL, path, _MAX_PATH) == 0)
        return EXIT_FAILURE;
    PathRemoveFileSpecW(path);
    PathAppendW(path, PYTHON_DLL_PATH);

    HMODULE pydll = LoadLibraryW(path);
    if (pydll == NULL)
        return EXIT_FAILURE;

    // Function in python3.dll is forwarded to python3xx.dll.
    // Set PATH to resolve forwarding.
    // Or load python3xx.dll directly.
    PathRemoveFileSpecW(path);
    if (SetDllDirectoryW(path) == 0)
        return EXIT_FAILURE;
    PY_MAIN Py_Main = (PY_MAIN)GetProcAddress(pydll, "Py_Main");
    if (Py_Main == NULL)
        return EXIT_FAILURE;
    if (SetDllDirectoryW(NULL) == 0)
        return EXIT_FAILURE;

    int pyargc = argc + 2;
    wchar_t **pyargv = malloc(sizeof(wchar_t*) * (pyargc + 1));
    if (pyargv == NULL)
        return EXIT_FAILURE;
    pyargv[0] = argv[0];
    pyargv[1] = (wchar_t*)L"-m";
    pyargv[2] = (wchar_t*)MAIN_MODULE;
    for (int i = 1; i < argc; ++i)
        pyargv[i + 2] = argv[i];
    pyargv[pyargc] = NULL;

    return Py_Main(pyargc, pyargv);
}

