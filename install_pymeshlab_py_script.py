import subprocess
import sys

print('importing pymeshlab')
subprocess.check_call([sys.executable, "-m", "pip", "install", "pymeshlab"])
