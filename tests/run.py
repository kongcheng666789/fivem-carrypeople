from pathlib import Path
import os

from lupa import LuaRuntime


root = Path(__file__).resolve().parent.parent
os.chdir(root)

for name in ("server_spec.lua", "client_spec.lua"):
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.execute((root / "tests" / name).read_text(encoding="utf-8"))

print("Offline Lua checks passed")
