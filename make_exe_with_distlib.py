import argparse
import distlib.scripts

parser = argparse.ArgumentParser()
parser.add_argument("--outdir", default=".")
parser.add_argument("--shebang", default=r"<launcher_dir>\python\python.exe")
parser.add_argument("--entry", default="myapp = myapp:main")
args = parser.parse_args()

script_maker = distlib.scripts.ScriptMaker(None, args.outdir)
script_maker.executable = args.shebang
script_maker.make(args.entry)
