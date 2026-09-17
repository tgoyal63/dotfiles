#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
MODIFIERS = {"alt", "cmd", "ctrl", "shift"}
SKHD_KEY_ALIASES = {
    "0x18": "equal",
    "0x1b": "minus",
    "0x1e": "rightsquarebracket",
    "0x21": "leftsquarebracket",
    "0x29": "semicolon",
    "0x2b": "comma",
    "0x2c": "slash",
    "0x32": "backtick",
    "escape": "esc",
    "next": "f9",
    "play": "f8",
    "previous": "f7",
    "return": "enter",
    "sound_down": "f11",
    "sound_up": "f12",
    "mute": "f10",
}


def canonical_key(parts: list[str], key: str) -> str:
    modifiers = sorted(part.lower() for part in parts if part.lower() in MODIFIERS)
    normalized_key = SKHD_KEY_ALIASES.get(key.lower(), key.lower())
    return "+".join([*modifiers, normalized_key])


def parse_aerospace() -> dict[str, set[str]]:
    with (REPO / "aerospace.toml").open("rb") as file:
        config = tomllib.load(file)

    result: dict[str, set[str]] = {}
    for mode in ("main", "resize", "launch", "service"):
        bindings = config["mode"][mode]["binding"]
        normalized: set[str] = set()
        for binding in bindings:
            parts = binding.split("-")
            modifiers: list[str] = []
            while parts and parts[0].lower() in MODIFIERS:
                modifiers.append(parts.pop(0))
            normalized.add(canonical_key(modifiers, "-".join(parts)))
        result[mode] = normalized
    return result


def parse_skhd() -> dict[str, set[str]]:
    result = {mode: set() for mode in ("main", "resize", "launch", "service")}
    binding_pattern = re.compile(
        r"^(?:(resize|launch|service)\s*<\s*)?(.+?)\s+(?::|;)\s+"
    )

    for raw_line in (REPO / "skhdrc").read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or line.startswith("::"):
            continue
        match = binding_pattern.match(line)
        if not match:
            continue
        mode = match.group(1) or "main"
        key_expression = match.group(2).strip()
        if " - " in key_expression:
            modifier_expression, key = key_expression.rsplit(" - ", 1)
            modifiers = [part.strip() for part in modifier_expression.split("+")]
        else:
            modifiers = []
            key = key_expression
        result[mode].add(canonical_key(modifiers, key))
    return result


def main() -> int:
    expected = parse_aerospace()
    actual = parse_skhd()
    failed = False

    for mode in expected:
        missing = sorted(expected[mode] - actual[mode])
        extra = sorted(actual[mode] - expected[mode])
        if not missing and not extra:
            continue
        failed = True
        print(f"{mode} mode differs:", file=sys.stderr)
        for binding in missing:
            print(f"  missing {binding}", file=sys.stderr)
        for binding in extra:
            print(f"  extra   {binding}", file=sys.stderr)

    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
