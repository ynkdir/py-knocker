#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlwapi.h>
#include <stdlib.h>
#include <string.h>
#pragma comment(lib, "onecore.lib")

#define PYTHON_DLL_PATH L"python\\python3.dll"

typedef int (*PY_MAIN)(int, wchar_t**);

int wmain(int argc, wchar_t **argv) {
    wchar_t path[MAX_PATH];
    if (GetModuleFileNameW(NULL, path, MAX_PATH) == 0)
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

    // Workaround for multiprocessing.
    // FIXME: or myargv[0] = "path\\to\\python.exe"?
    for (int i = 1; i < argc; ++i)
        if (wcscmp(argv[i], L"--multiprocessing-fork") == 0)
            return Py_Main(argc, argv);

    wchar_t **myargv = _alloca((argc + 1) * sizeof(wchar_t*));
    myargv[0] = argv[0];
    memcpy(myargv + 1, argv, argc * sizeof(wchar_t *));
    return Py_Main(argc+1, myargv);
}

