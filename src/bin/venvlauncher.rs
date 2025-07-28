use anyhow::Result;
use py_knocker::{get_venv_pydll_path, launch};

fn main() -> Result<()> {
    let pydll_path = get_venv_pydll_path()?;
    launch(&pydll_path)
}
