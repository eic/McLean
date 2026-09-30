/-
Copyright (c) 2026 Wouter Deconinck. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Wouter Deconinck
-/
import McLean.CLI

/-!
# The `mclean` executable

The entry point delegates immediately to `McLean.CLI.run`, which parses arguments, runs
EpsilonEridani's existing LO DIS generator (or its showered variant, with `--shower`), and
writes the resulting events as HepMC3 ASCII. See `McLean/CLI.lean` for the argument
parsing and run loop, and `McLean/Basic.lean` for the boundary between this repository and
the physics it depends on.
-/

def main (args : List String) : IO UInt32 := McLean.CLI.run args
