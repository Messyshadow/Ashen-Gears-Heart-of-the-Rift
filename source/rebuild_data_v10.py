"""Deterministic data rebuild; leaves models, animations, runtime code and saves intact."""
import runpy
from pathlib import Path
ROOT=Path(__file__).resolve().parent
for name in ['skills_v10.py','content_v10.py','quests_v10.py','finalize_data_v10.py']:
 runpy.run_path(str(ROOT/name),run_name='__main__')
