#!/usr/bin/env python3

from pathlib import Path
import sys


def check_file(path: Path) -> bool:
    lines = [
        line.strip()
        for line in path.read_text().splitlines()
        if line.strip()
    ]

    expected_count = int(path.stem.split("_")[1])

    if len(lines) != expected_count:
        print(
            f"FAIL {path}: expected {expected_count} results, "
            f"got {len(lines)}"
        )
        return False

    entries = []

    for line_number, line in enumerate(lines, start=1):
        fields = line.split()

        if len(fields) != 3 or fields[0] != "POP_RESULT":
            print(
                f"FAIL {path}: malformed line {line_number}: {line}"
            )
            return False

        try:
            priority = int(fields[1])
            value = int(fields[2])
        except ValueError:
            print(
                f"FAIL {path}: non-integer result "
                f"at line {line_number}: {line}"
            )
            return False

        entries.append((priority, value))

    priorities = [priority for priority, _ in entries]
    values = [value for _, value in entries]

    if any(
        priorities[i] > priorities[i + 1]
        for i in range(len(priorities) - 1)
    ):
        print(f"FAIL {path}: priorities are not ordered")
        return False

    if len(set(values)) != len(values):
        print(f"FAIL {path}: duplicate values detected")
        return False

    expected_values = set(range(expected_count))

    if set(values) != expected_values:
        missing = sorted(expected_values - set(values))
        extra = sorted(set(values) - expected_values)

        print(f"FAIL {path}: value coverage mismatch")

        if missing:
            print(f"  missing: {missing}")

        if extra:
            print(f"  unexpected: {extra}")

        return False

    print(f"PASS {path}: {expected_count} entries")
    return True


def main() -> int:
    baseline_dir = Path("analysis/baseline")

    files = sorted(
        baseline_dir.glob("baseline_*_seed12345.txt"),
        key=lambda path: int(path.stem.split("_")[1]),
    )

    if not files:
        print("FAIL: no baseline files found")
        return 1

    success = True

    for path in files:
        if not check_file(path):
            success = False

    if success:
        print("ALL BASELINE CHECKS PASSED")
        return 0

    print("BASELINE CHECK FAILED")
    return 1


if __name__ == "__main__":
    sys.exit(main())
