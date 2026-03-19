#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


TOP_LEVEL_REQUIRED = {
    "schema_version": str,
    "generated_at": str,
    "records": list,
}

RECORD_REQUIRED = {
    "id": str,
    "fqname": str,
    "kind": str,
    "package": str,
    "module": str,
    "display": str,
    "signature": str,
    "summary_md": str,
    "params": list,
    "deprecated": bool,
    "aliases": list,
}

CALLABLE_KINDS = {"function", "method", "constructor"}


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def validate_type(name: str, value, expected):
    if not isinstance(value, expected):
        raise ValueError(f"{name} must be {expected.__name__}, got {type(value).__name__}")


def validate_top_level(payload: dict):
    validate_type("document", payload, dict)
    for key, expected in TOP_LEVEL_REQUIRED.items():
        if key not in payload:
            raise ValueError(f"missing top-level field: {key}")
        validate_type(key, payload[key], expected)


def validate_record(record: dict, index: int, seen_ids: set[str]):
    validate_type(f"records[{index}]", record, dict)
    for key, expected in RECORD_REQUIRED.items():
        if key not in record:
            raise ValueError(f"records[{index}] missing required field: {key}")
        validate_type(f"records[{index}].{key}", record[key], expected)

    record_id = record["id"]
    if record_id in seen_ids:
        raise ValueError(f"duplicate record id: {record_id}")
    seen_ids.add(record_id)

    if not record["id"].strip():
        raise ValueError(f"records[{index}].id must not be empty")
    if not record["fqname"].strip():
        raise ValueError(f"records[{index}].fqname must not be empty")
    if record["kind"] in CALLABLE_KINDS and not str(record.get("name", "")).strip():
        raise ValueError(f"records[{index}] callable kinds must include non-empty name")

    if "source" in record and record["source"] is not None:
        source = record["source"]
        validate_type(f"records[{index}].source", source, dict)
        for key in ("file", "line", "column"):
            if key not in source:
                raise ValueError(f"records[{index}].source missing field: {key}")
        validate_type(f"records[{index}].source.file", source["file"], str)
        validate_type(f"records[{index}].source.line", source["line"], int)
        validate_type(f"records[{index}].source.column", source["column"], int)

    for param_index, param in enumerate(record["params"]):
        validate_type(f"records[{index}].params[{param_index}]", param, dict)
        if "label" not in param:
            raise ValueError(f"records[{index}].params[{param_index}] missing label")
        validate_type(f"records[{index}].params[{param_index}].label", param["label"], str)


def validate_payload(payload: dict):
    validate_top_level(payload)
    seen_ids: set[str] = set()
    for index, record in enumerate(payload["records"]):
        validate_record(record, index, seen_ids)


def main():
    parser = argparse.ArgumentParser(description="Build and validate docs-index.json")
    parser.add_argument(
        "--source",
        default="docs/cangjie-doc-index.example.json",
        help="Source JSON file that contains the docs index payload.",
    )
    parser.add_argument(
        "--output",
        default="dist/docs-index.json",
        help="Output path for the generated docs index.",
    )
    args = parser.parse_args()

    source = Path(args.source)
    output = Path(args.output)

    payload = load_json(source)
    validate_payload(payload)

    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"generated {output} from {source} ({len(payload['records'])} records)")


if __name__ == "__main__":
    main()
