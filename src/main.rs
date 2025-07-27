use anyhow::{Context, Result};
use std::env;
use std::iter;
use windows::Win32::System::LibraryLoader::{
    GetProcAddress, LOAD_LIBRARY_SEARCH_DEFAULT_DIRS, LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR,
    LoadLibraryExW, SetDllDirectoryW,
};
use windows::core::{HSTRING, PCSTR, w};

type PyMain = extern "C" fn(i32, *const *const u16) -> i32;

fn encode_utf16(s: &str) -> *const u16 {
    Box::into_raw(s.encode_utf16().chain(iter::once(0)).collect()) as *const u16
}

fn make_cargs(args: &Vec<String>) -> (i32, *const *const u16) {
    let argc = args.len() as i32;
    let argv = Box::into_raw(
        args.iter()
            .map(|x| encode_utf16(&x))
            .chain(iter::once(std::ptr::null()))
            .collect(),
    ) as *const *const u16;
    (argc, argv)
}

fn get_module_name() -> Result<String> {
    Ok(env::current_exe()?
        .file_stem()
        .context("Cannot get stem")?
        .to_str()
        .context("Cannot get str")?
        .to_string())
}

fn get_pydll_path() -> Result<String> {
    Ok(env::current_exe()?
        .parent()
        .context("Cannot get parent")?
        .join("python\\python3.dll")
        .to_str()
        .context("Cannot get str")?
        .to_string())
}

fn as_cstr(s: &str) -> String {
    format!("{}\0", s)
}

fn set_dll_directory_secure() -> Result<()> {
    unsafe { SetDllDirectoryW(w!("")).context("Cannot set dll directory to ''") }
}

fn delay_load<T>(library: &str, function: &str) -> Result<T> {
    unsafe {
        let handle = LoadLibraryExW(
            &HSTRING::from(library),
            None,
            LOAD_LIBRARY_SEARCH_DEFAULT_DIRS | LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR,
        )
        .with_context(|| format!("Cannot load library '{}'", library))?;
        let address = GetProcAddress(handle, PCSTR(as_cstr(function).as_ptr()))
            .ok_or_else(|| windows::core::Error::from_win32())
            .with_context(|| format!("Cannot get procedure '{}'", function))?;
        Ok(std::mem::transmute_copy(&address))
    }
}

fn main() -> Result<()> {
    set_dll_directory_secure()?;

    let pydll_path = get_pydll_path()?;
    let py_main = delay_load::<PyMain>(&pydll_path, "Py_Main")?;

    let mut args: Vec<String> = env::args().collect();

    if !args.iter().any(|x| x == "--multiprocessing-fork") {
        let module_name = get_module_name()?;
        args.insert(1, String::from("-I"));
        args.insert(2, String::from("-m"));
        args.insert(3, module_name);
    }

    let (argc, argv) = make_cargs(&args);

    std::process::exit(py_main(argc, argv));
}
