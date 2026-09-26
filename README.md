# McLean

An event generator for deep inelastic scattering, written in Lean 4 and built on
[EpsilonEridani](https://github.com/eic/EpsilonEridani).

## The split

| | EpsilonEridani | McLean |
|---|---|---|
| Answers | what is *true* | what a run *produces* |
| Content | theorems and interfaces over `ℝ` | executable `Float` code with a `main` |
| Evidence | a proof the compiler checks | a measurement compared against an independent prediction |

EpsilonEridani supplies the physics: the `Generator/` modules are general interfaces
supporting event generation, the `HepMC3/` modules are a validated binding to the HepMC3
record format, and the shower content is a theorem — `QFT.Shower.Sudakov` proves that
summing the veto chain over an *overestimated* splitting kernel reproduces the true
Sudakov factor exactly, with no hypotheses at all, resting on the ordered `n`-fold
integral identity in `Mathematics.OrderedSimplexIntegral`.

McLean produces events.

## The gap between them, stated up front

A theorem about `ℝ` does not execute and `Float` code does not prove anything. The
shower's acceptance rule will therefore exist twice — once as a statement in
EpsilonEridani, once as a sampler here — with nothing in Lean connecting them. Some
duplication of EpsilonEridani functionality is expected here at first, and is accepted
deliberately.

The rule that follows is worth stating rather than leaving implicit:

> No `Float` definition in this library may be described as verified on the grounds that a
> corresponding real-valued theorem exists.

The theorem constrains what the sampler ought to do. Measurement is what establishes that
it does.

## What is verified, and how

Three checks run in CI, and the first two are inherited from EpsilonEridani because they
catch things `grep` cannot:

* **`lake exe axioms`** — rejects any axiom outside `{propext, Classical.choice,
  Quot.sound}` for every declaration defined in `McLean`. This is what catches `sorry`
  (which surfaces as `sorryAx`), `native_decide` (as `Lean.ofReduceBool`) and any
  home-rolled `axiom`, *including ones reaching in through imports*.
* **`lake exe module-system`** — reads the compiled `.olean`s and rejects any module that
  did not open with `module`. It inspects the artifact rather than the source text, so a
  comment cannot fool it.
* **`lake build`** — the `lean_lib` glob `McLean.*` is authoritative, so an orphaned or
  broken module still fails the build.

Statistical validation of generated events is not a CI check. It belongs with the change
that introduces the sampler, as a measurement against an independently computed
prediction.

## Building

Not on a workstation. This project's builds run on a cluster or in CI.

Two practical notes for whoever sets up a local checkout:

* `lake-manifest.json` is absent until someone runs `lake update` on a build host. Until
  then the EpsilonEridani dependency resolves against a floating `main` and builds are not
  reproducible. Committing a hand-written manifest is not an option — the pins have to
  come from a real resolution.
* Make `.lake` a **symlink** into a shared build cache rather than a real directory. It is
  git-ignored either way, but a materialized `.lake` holds one git repository per
  dependency, and agent sandboxes have a hard budget on nested git structures — exceeding
  it silently replaces `.git/config` with `/dev/null` and every `git` command in the
  repository then fails in a way that looks unrelated.

## Layout

```
McLean.lean          intentionally empty; the lakefile glob is authoritative
McLean/              the library
generator/Main.lean  the `mclean` executable's entry point, outside the library glob
scripts/             the axiom and module-system audits
```

## Licence

Apache 2.0.
