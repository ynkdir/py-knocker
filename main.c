#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlwapi.h>
#include <stdlib.h>
#include <string.h>
#pragma comment(lib, "onecore.lib")

#define PYTHON_DLL_PATH L"python\\python3.dll"

typedef int (*PY_MAIN)(int, wchar_t**);

int wmain(int argc, wchar_t **argv) {
    // Prevent DLL preloading attack.
    if (SetDllDirectoryW(L"") == 0)
        return EXIT_FAILURE;

    wchar_t path[MAX_PATH];
    if (GetModuleFileNameW(NULL, path, MAX_PATH) == 0)
        return EXIT_FAILURE;

    PathRemoveFileSpecW(path);
    PathAppendW(path, PYTHON_DLL_PATH);

    // Functions in python3.dll is forwarded to python3xx.dll.
    // GetProcAddress() fails if python3xx.dll is not in search path
    // even if it is in the same directory with python3.dll.
    // LOAD_WITH_ALTERED_SEARCH_PATH seems to affect following GetProcAddress().
    HMODULE pydll = LoadLibraryExW(path, NULL, LOAD_WITH_ALTERED_SEARCH_PATH);
    if (pydll == NULL)
        return EXIT_FAILURE;

    PY_MAIN Py_Main = (PY_MAIN)GetProcAddress(pydll, "Py_Main");
    if (Py_Main == NULL)
        return EXIT_FAILURE;

    // Workaround for multiprocessing.
    // FIXME: or myargv[0] = "path\\to\\python.exe"?
    for (int i = 1; i < argc; ++i)
        if (wcscmp(argv[i], L"--multiprocessing-fork") == 0)
            return Py_Main(argc, argv);

    wchar_t **myargv = _alloca((argc + 2) * sizeof(wchar_t*));
    myargv[0] = argv[0];
    myargv[1] = L"-I";  // isolated mode
    memcpy(myargv + 2, argv, argc * sizeof(wchar_t *));
    return Py_Main(argc + 2, myargv);
}

