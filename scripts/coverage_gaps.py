#!/usr/bin/env python3
"""List per-file uncovered lines from Flutter's lcov.info."""
import os
import sys

LCOV = os.path.join(os.path.dirname(__file__), "..", "coverage", "lcov.info")


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else LCOV
    files = []
    cur = None
    with open(path) as f:
        for line in f:
            if line.startswith("SF:"):
                cur = {"sf": line[3:].strip(), "missed": [], "found": 0, "hit": 0}
                files.append(cur)
            elif line.startswith("DA:"):
                lineno, hits = line[3:].strip().split(",")
                hits = int(hits)
                if hits == 0:
                    cur["missed"].append(int(lineno))
                cur["found"] += 1
                cur["hit"] += hits > 0
            elif line.startswith("LF:"):
                cur["found"] = int(line[3:])
            elif line.startswith("LH:"):
                cur["hit"] = int(line[3:])

    total_found = sum(f["found"] for f in files)
    total_hit = sum(f["hit"] for f in files)
    bad = [f for f in files if f["hit"] < f["found"]]
    for f in sorted(bad, key=lambda f: f["missed"][0] if f["missed"] else 0):
        rel = f["sf"]
        pct = 100 * f["hit"] / f["found"] if f["found"] else 100.0
        print(f"{rel}  {f['hit']}/{f['found']} ({pct:.1f}%)")
        print(f"  missed: {f['missed']}")
    print(f"\nTOTAL: {total_hit}/{total_found} = {100 * total_hit / total_found:.2f}%")


if __name__ == "__main__":
    main()
