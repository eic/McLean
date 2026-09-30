#!/usr/bin/env python3
"""Sanity-checks an mclean HepMC3 ASCII output: event count and kinematic bounds.

This is a structural check, not a physics validation -- it establishes that the
generator produced the requested number of events and that every event's xBj/Q2
attributes lie within the domain `mclean` was configured to sample, nothing more. A real
measurement against an independently derived prediction (see AGENTS.md's "Correctness
claims about generated events") is deferred to a follow-up change, as the McLean plan
records.

The HepMC3 Asciiv3 format parsed here is documented and produced by
EpsilonEridani/HepMC3/Ascii.lean: an event starts with an "E <number> <vertices>
<particles>" line, and each of its "A <target> <name> <value>" lines attaches one named
attribute to the vertex/particle numbered <target> (0 denotes the event itself).
"""

import argparse
import sys


def check_event(index: int, attrs: dict[str, float], q2_min: float) -> list[str]:
    problems = []
    x = attrs.get("xBj")
    q2 = attrs.get("Q2")
    if x is None or q2 is None:
        problems.append(f"event {index}: missing xBj/Q2 attribute (found {sorted(attrs)})")
        return problems
    if not (0.0 < x < 1.0):
        problems.append(f"event {index}: xBj={x} outside (0, 1)")
    if not (q2 >= q2_min):
        problems.append(f"event {index}: Q2={q2} below configured q2min={q2_min}")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("hepmc3_path")
    parser.add_argument("--events", type=int, required=True, help="expected event count")
    parser.add_argument("--q2min", type=float, required=True, help="the run's configured q2Min")
    args = parser.parse_args()

    n_events = 0
    current_attrs: dict[str, float] = {}
    problems: list[str] = []

    def finish_event() -> None:
        nonlocal problems
        problems.extend(check_event(n_events, current_attrs, args.q2min))

    with open(args.hepmc3_path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if line.startswith("E "):
                if n_events > 0:
                    finish_event()
                n_events += 1
                current_attrs = {}
            elif line.startswith("A "):
                parts = line.split(" ", 3)
                if len(parts) == 4:
                    _, target, name, value = parts
                    if target == "0" and name in ("xBj", "Q2"):
                        try:
                            current_attrs[name] = float(value)
                        except ValueError:
                            problems.append(
                                f"event {n_events}: attribute {name} has a non-numeric "
                                f"value '{value}'"
                            )
        if n_events > 0:
            finish_event()

    ok = True
    if n_events != args.events:
        print(f"FAIL: expected {args.events} events, found {n_events}", file=sys.stderr)
        ok = False

    if problems:
        ok = False
        shown, extra = problems[:20], problems[20:]
        for p in shown:
            print(f"FAIL: {p}", file=sys.stderr)
        if extra:
            print(f"... and {len(extra)} more", file=sys.stderr)

    if ok:
        print(f"OK: {n_events} events, all xBj/Q2 attributes within the configured bounds")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
