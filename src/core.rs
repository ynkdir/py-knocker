use anyhow::{Context, Result, bail};
use std::env;
use std::iter;
use windows::Win32::Foundation::HMODULE;
use windows::Win32::System::LibraryLoader::{
    GetProcAddress, LOAD_LIBRARY_SEARCH_DEFAULT_DIRS, LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR,
    LoadLibraryExW, SetDllDirectoryW,
};
use windows::core::{HSTRING, PCSTR, w};

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

pub fn get_local_pydll_path() -> Result<String> {
    Ok(env::current_exe()?
        .parent()
        .context("Cannot get parent")?
        .join("python\\python3.dll")
        .to_str()
        .context("Cannot get str")?
        .to_string())
}

pub fn get_venv_pydll_path() -> Result<String> {
    let venv_cfg = get_venv_cfg_path()?;
    let home = read_venv_cfg_home(&venv_cfg)?;
    Ok(std::path::Path::new(&home)
        .join("python3.dll")
        .to_str()
        .context("Cannot get str")?
        .to_string())
}

fn read_venv_cfg_home(venv_cfg_path: &str) -> Result<String> {
    for line in std::fs::read_to_string(&venv_cfg_path)?.lines() {
        if line.starts_with("home = ") {
            return Ok(String::from(
                line.strip_prefix("home = ").context("never happen")?,
            ));
        }
    }
    bail!("Cannot find 'home' in pyvenv.cfg");
}

fn get_venv_cfg_path() -> Result<String> {
    Ok(env::current_exe()?
        .parent()
        .context("Cannot get parent")?
        .parent()
        .context("Cannot get parent")?
        .join("pyvenv.cfg")
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

fn load_library(library: &str) -> Result<HMODULE> {
    unsafe {
        LoadLibraryExW(
            &HSTRING::from(library),
            None,
            LOAD_LIBRARY_SEARCH_DEFAULT_DIRS | LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR,
        )
        .with_context(|| format!("Cannot load library '{}'", library))
    }
}

fn get_function<T>(handle: HMODULE, function: &str) -> Result<T> {
    unsafe {
        let address = GetProcAddress(handle, PCSTR(as_cstr(function).as_ptr()))
            .ok_or_else(|| windows::core::Error::from_win32())
            .with_context(|| format!("Cannot get function '{}'", function))?;
        Ok(std::mem::transmute_copy(&address))
    }
}

pub fn launch(pydll_path: &str) -> Result<()> {
    set_dll_directory_secure()?;

    let pydll = load_library(pydll_path)?;
    let py_main = get_function::<extern "C" fn(i32, *const *const u16) -> i32>(pydll, "Py_Main")?;

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
