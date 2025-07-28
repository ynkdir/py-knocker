use anyhow::Result;
use py_knocker::core::{get_local_pydll_path, launch};

fn main() -> Result<()> {
    let pydll_path = get_local_pydll_path()?;
    launch(&pydll_path)
}
