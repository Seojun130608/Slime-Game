"""Compatibility entry point: build the current game milestone."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name('build_upgrades.py')), run_name='__main__')
