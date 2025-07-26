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

fn get_module_name() -> String {
    String::from(
        env::current_exe()
            .unwrap()
            .file_stem()
            .unwrap()
            .to_str()
            .unwrap(),
    )
}

fn get_pydll_path() -> String {
    env::current_exe()
        .unwrap()
        .parent()
        .unwrap()
        .join("python\\python3.dll")
        .to_str()
        .unwrap()
        .to_string()
}

fn as_cstr(s: &str) -> String {
    format!("{}\0", s)
}

fn set_dll_directory_secure() -> windows::core::Result<()> {
    unsafe { SetDllDirectoryW(w!("")) }
}

fn delay_load<T>(library: &str, function: &str) -> windows::core::Result<T> {
    unsafe {
        let handle = LoadLibraryExW(
            &HSTRING::from(library),
            None,
            LOAD_LIBRARY_SEARCH_DEFAULT_DIRS | LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR,
        )?;
        let address = GetProcAddress(handle, PCSTR(as_cstr(function).as_ptr()))
            .ok_or_else(|| windows::core::Error::from_win32())?;
        Ok(std::mem::transmute_copy(&address))
    }
}

fn main() {
    set_dll_directory_secure().unwrap();

    let py_main = delay_load::<PyMain>(&get_pydll_path(), "Py_Main").unwrap();

    let mut args: Vec<String> = env::args().collect();

    if !args.iter().any(|x| x == "--multiprocessing-fork") {
        args.insert(1, String::from("-I"));
        args.insert(2, String::from("-m"));
        args.insert(3, get_module_name());
    }

    let (argc, argv) = make_cargs(&args);

    py_main(argc, argv);
}
