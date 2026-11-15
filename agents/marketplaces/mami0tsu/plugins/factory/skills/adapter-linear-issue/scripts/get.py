"""Run one adapter operation through the two-phase MCP contract."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "scripts"), str(ROOT / "scripts/providers")]
from mcp import resource_module, serve
resource = resource_module(Path(__file__).resolve().parents[1].name)

if __name__ == "__main__":
    serve(resource, "get")
