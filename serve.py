import sys
import subprocess

import livereload

def rebuild():
    subprocess.run([sys.executable, "build.py"])

yeeter = livereload.Server()
yeeter.setHeader("Cache-Control", "no-store")
yeeter.watch("stuff/**/*", rebuild)
yeeter.watch("templates/**/*", rebuild)
yeeter.watch("*.py", rebuild)

yeeter.serve(root = "docs")
