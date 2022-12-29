from pathlib import Path
from runpy import run_module
run_module(Path(__file__).parent.stem, run_name="__main__", alter_sys=True)
