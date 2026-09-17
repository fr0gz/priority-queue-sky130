import sys
from pathlib import Path


def read_results(path):
    results = []

    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            parts = line.split()

            if len(parts) != 3 or parts[0] != "POP_RESULT":
                raise ValueError(
                    f"Malformed result in {path}: {line}"
                )

            priority = int(parts[1])
            value = int(parts[2])

            results.append((priority, value))

    return results


def main():
    if len(sys.argv) != 3:
        print(
            f"usage: {sys.argv[0]} <expected> <actual>",
            file=sys.stderr,
        )
        return 1

    expected_path = Path(sys.argv[1])
    actual_path = Path(sys.argv[2])

    expected = read_results(expected_path)
    actual = read_results(actual_path)

    if expected == actual:
        print(f"PASS: {actual_path}")
        print(f"  entries: {len(actual)}")
        return 0

    print(f"FAIL: {actual_path}")
    print(f"  expected entries: {len(expected)}")
    print(f"  actual entries:   {len(actual)}")

    limit = min(len(expected), len(actual))

    for i in range(limit):
        if expected[i] != actual[i]:
            print(f"  first mismatch at entry {i}")
            print(f"    expected: {expected[i]}")
            print(f"    actual:   {actual[i]}")
            return 1

    if len(expected) != len(actual):
        print(f"  output length mismatch")

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
