/-
Copyright (c) 2026 Wouter Deconinck. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Wouter Deconinck
-/
module

public import EpsilonEridani.Generator.Config
public import EpsilonEridani.Generator.Event
public import EpsilonEridani.Generator.Kinematics

/-!
# McLean: what this library is, and where its boundary with EpsilonEridani runs

McLean is the event generator. EpsilonEridani is the physics it rests on. The division is
by *role* rather than by subject matter, and the two halves answer different questions.

* **EpsilonEridani** states what is true. Its `Generator/` modules are general interfaces
  supporting event generation and its `HepMC3/` modules are a validated binding to the
  HepMC3 record format. Its shower content is a theorem: `QFT.Shower.Sudakov` proves that
  summing the veto chain over an overestimated kernel reproduces the true Sudakov factor
  exactly, with no hypotheses at all, and `Mathematics.OrderedSimplexIntegral` supplies
  the ordered `n`-fold integral identity that the per-term factorial rests on.
* **McLean** produces events. It is `Float` code with a `main`, and its correctness claims
  are empirical: sampled distributions compared against independently computed
  predictions.

## Why duplication here is expected, and what it costs

A theorem about `ℝ` does not execute, and `Float` code does not prove anything. So the
shower's acceptance rule will exist twice: once as a statement in EpsilonEridani, once as
a sampler here. Nothing in Lean connects the two.

Stating the consequence plainly, because it is easy to elide: **no `Float` definition in
this library may be described as verified on the grounds that a corresponding real-valued
theorem exists.** The theorem constrains what the sampler ought to do; only measurement
establishes that it does. The predecessor implementation was validated exactly that way,
by comparing the measured fraction of events with no emission against a numerically
integrated Sudakov factor computed independently of the Lean code -- and that same
exercise is what exposed a mislabelled observable that agreed perfectly with a
reimplementation sharing its error.

## Status

This module documents the boundary and exercises the dependency on EpsilonEridani. It
deliberately defines no physics: the generator implementation arrives as its own
reviewable change rather than folded into repository scaffolding.
-/

namespace McLean

end McLean
