from common import config_path, load_config, run
from runtime import locked_runtime


def main(payload):
    load_config(payload)
    with locked_runtime(payload) as state:
        return {"config": str(config_path(payload)), "entries": state["entries"]}


if __name__ == "__main__":
    run(main)
