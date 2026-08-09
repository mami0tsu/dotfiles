#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages (pythonPackages: [ pythonPackages.jsonschema pythonPackages.pyyaml ])"

import argparse
import json
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--schema-only", action="store_true")
    parser.add_argument("document", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    skill_dir = Path(__file__).resolve().parent.parent
    schema_path = skill_dir / "assets" / "retrospective.schema.json"
    document_path = args.document.resolve()

    with schema_path.open(encoding="utf-8") as schema_file:
        schema = json.load(schema_file)

    with document_path.open(encoding="utf-8") as document_file:
        document = yaml.safe_load(document_file)

    errors = sorted(
        Draft202012Validator(schema).iter_errors(document),
        key=lambda error: [str(part) for part in error.absolute_path],
    )
    if errors:
        for error in errors:
            location = ".".join(str(part) for part in error.absolute_path) or "<root>"
            print(f"{location}: {error.message}")
        return 1

    if not args.schema_only:
        output_directory = document_path.parent
        repository_root = output_directory.parent.parent
        if (
            output_directory.name != "retrospectives"
            or output_directory.parent.name != ".agent"
            or not (repository_root / ".git").exists()
        ):
            print("document must be directly under a repository .agent/retrospectives directory")
            return 1

        expected_name = f'{document["ticket_id"]}.yaml'
        if document_path.name != expected_name:
            print(f"document name must be {expected_name}")
            return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
