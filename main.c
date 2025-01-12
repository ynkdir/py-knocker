#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlwapi.h>
#include <pathcch.h>
#include <stdlib.h>
#include <string.h>
#pragma comment(lib, "onecore.lib")

#ifndef PYTHON_DLL_PATH
# define PYTHON_DLL_PATH L"..\\python\\python3.dll"
#endif

typedef int (*PY_MAIN)(int, wchar_t**);

wchar_t *GetModuleName() {
    wchar_t path[MAX_PATH];
    if (GetModuleFileNameW(NULL, path, MAX_PATH) == 0)
        return NULL;

    wchar_t *filename = PathFindFileNameW(path);
    if (filename == path)
        return NULL;

    wchar_t *ext;
    if (FAILED(PathCchFindExtension(path, MAX_PATH, &ext)))
        return NULL;

    *ext = 0;

    return _wcsdup(filename);
}

int wmain(int argc, wchar_t **argv) {
    // https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-security
    if (SetDllDirectoryW(L"") == 0)
        return EXIT_FAILURE;

    wchar_t path[MAX_PATH] = PYTHON_DLL_PATH;
    // Optimizer may drop this block for absolute PYTHON_DLL_PATH.
    if (PYTHON_DLL_PATH[0] == L'.') {
        if (GetModuleFileNameW(NULL, path, MAX_PATH) == 0)
            return EXIT_FAILURE;
        if (FAILED(PathCchCombine(path, MAX_PATH, path, PYTHON_DLL_PATH)))
            return EXIT_FAILURE;
    }

    HMODULE pydll = LoadLibraryExW(path, NULL, LOAD_LIBRARY_SEARCH_DEFAULT_DIRS|LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR);
    if (!pydll)
        return EXIT_FAILURE;

    PY_MAIN Py_Main = (PY_MAIN)GetProcAddress(pydll, "Py_Main");
    if (!Py_Main)
        return EXIT_FAILURE;

    wchar_t *module = GetModuleName();
    if (!module)
        return EXIT_FAILURE;

    // Workaround for multiprocessing.
    // FIXME: or myargv[0] = "path\\to\\python.exe"?
    for (int i = 1; i < argc; ++i)
        if (wcscmp(argv[i], L"--multiprocessing-fork") == 0)
            return Py_Main(argc, argv);

    wchar_t **myargv = _alloca((argc + 3) * sizeof(wchar_t*));
    myargv[0] = argv[0];
    myargv[1] = L"-I";  // isolated mode
    myargv[2] = L"-m";
    myargv[3] = module;
    memcpy(myargv + 4, argv + 1, (argc - 1) * sizeof(wchar_t *));
    return Py_Main(argc + 3, myargv);
}

