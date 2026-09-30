# McLean

An event generator for deep inelastic scattering, written in Lean 4 and built on
[EpsilonEridani](https://github.com/eic/EpsilonEridani).

## The split

|          | EpsilonEridani                    | McLean                                    |
|----------|------------------------------------|--------------------------------------------|
| Answers  | what is *true*                    | what a run *produces*                      |
| Content  | theorems and interfaces over `ℝ`  | executable `Float` code with a `main`      |
| Evidence | a proof the compiler checks       | a measurement compared against an independent prediction |

EpsilonEridani supplies the physics: the `Generator/` modules are general interfaces
supporting event generation, and the `HepMC3/` modules are a validated binding to the
HepMC3 record format. McLean produces events -- right now by calling EpsilonEridani's
existing `Generator.loRun`/`Generator.showerRun` directly. See [Usage](usage.md) for the
`mclean` command line, or [Installation](installation.md) to build it yourself.

## The gap, stated up front

A theorem about `ℝ` does not execute and `Float` code does not prove anything. **No
`Float` definition in this library may be described as verified on the grounds that a
corresponding real-valued theorem exists.** The theorem constrains what the sampler ought
to do; measurement is what establishes that it does. McLean's own
independently-implemented and independently-validated sampler/shower -- distinct from the
EpsilonEridani code `mclean` currently calls -- is future work, not something this site
claims already exists.

## What is verified, and how

Every push to `main` and every pull request runs:

* **`lake build`** -- the library glob is authoritative, so an orphaned or broken module
  fails the build.
* **`lake exe axioms`** -- rejects any axiom outside `{propext, Classical.choice,
  Quot.sound}` for every declaration in `McLean`, catching `sorry`, `native_decide`, and
  home-rolled axioms reaching in through imports.
* **`lake exe module-system`** -- rejects any module that did not open with `module`,
  read from the compiled `.olean` rather than the source text.
* A **demonstration run** -- `mclean` generates a batch of DIS events and the run is
  sanity-checked (event count, kinematic bounds) before its HepMC3 output and a
  performance summary are uploaded as CI artifacts.

Statistical validation of generated events against an independently derived prediction is
not (yet) a CI check; see `AGENTS.md` in the repository.

## Source

<https://github.com/eic/McLean>, Apache 2.0.
