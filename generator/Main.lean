/-
Copyright (c) 2026 Wouter Deconinck. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Wouter Deconinck
-/
import EpsilonEridani.Generator.Event
import McLean.Basic

/-!
# The `mclean` executable

A deliberate placeholder. It exists so an executable target is wired, built and linked
from the first commit rather than discovered to be broken once there is real code behind
it: in the predecessor repository the equivalent source file is attached to no Lake target
and therefore never builds at all.

It prints usage and exits 0. When the generator is ported here, this is where its argument
parsing and run loop belong.
-/

def usage : String :=
  "mclean - an event generator built on EpsilonEridani\n\n" ++
  "  No generator is wired up yet. This binary exists so the executable target is built\n" ++
  "  and linked by CI from the start. See McLean/Basic.lean for the boundary between\n" ++
  "  this repository and the physics it depends on.\n"

def main (_args : List String) : IO UInt32 := do
  IO.println usage
  return 0
