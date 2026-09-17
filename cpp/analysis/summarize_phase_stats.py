from pathlib import Path
import re

files = sorted(Path("analysis/baseline/stats").rglob("*.txt"))

fields = [
    "pushes",
    "pops",
    "push_comparisons",
    "push_swaps",
    "pop_comparisons",
    "pop_swaps",
    "total_comparisons",
    "total_swaps",
]

print(
    "file,"
    + ",".join(fields)
)

for path in files:
    values = {}

    for line in path.read_text().splitlines():
        match = re.match(r"^([a-z_]+)=(\d+)$", line.strip())

        if match:
            key, value = match.groups()
            values[key] = int(value)

    if not all(field in values for field in fields):
        continue

    print(
        str(path)
        + ","
        + ",".join(str(values[field]) for field in fields)
    )
