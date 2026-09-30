# Installation

McLean's own README is explicit about this: **building is not a workstation task.**
Builds run on a cluster or in CI. The instructions below are for a real build host (a CI
runner, a cluster node, or a machine you're prepared to let Lake use fully) -- not a
sandboxed agent environment, which has a hard budget on the nested git checkouts a
materialized `.lake` directory requires (one per dependency: EpsilonEridani, Mathlib,
Physlib, TauCeti, and Mathlib's own transitive dependencies). Exceeding that budget
silently corrupts `.git/config`.

## Toolchain

McLean pins an exact Lean 4 toolchain in `lean-toolchain`. Install [elan](https://github.com/leanprover/elan)
first, then let it pick up the pin:

```sh
git clone https://github.com/eic/McLean
cd McLean
elan toolchain install "$(cat lean-toolchain)"
```

## Dependencies

McLean requires [EpsilonEridani](https://github.com/eic/EpsilonEridani) (`rev = "main"` in
`lakefile.toml`); Mathlib, Physlib and TauCeti arrive transitively through it. There is no
committed `lake-manifest.json` -- one hand-written would be a fabrication, since the real
pins can only come from an actual dependency resolution. `lake update` produces it:

```sh
lake update
```

This is the expensive step: it fetches and compiles Mathlib and EpsilonEridani if no
cache is available. To skip most of that, fetch prebuilt oleans for Mathlib, Physlib and
TauCeti before building:

```sh
lake exe cache get Mathlib Physlib TauCeti
```

(EpsilonEridani itself has no such prebuilt-olean cache available to McLean; its modules
compile from source on a first build.)

## Build

```sh
lake build
```

A `lean_lib` glob (`McLean.*`) is authoritative for what this builds -- an orphaned or
broken module fails here rather than silently not being built.

## Run

```sh
lake exe mclean --help
```

See [Usage](usage.md) for the full command line.

## Verify

```sh
lake exe axioms          # rejects sorry, native_decide, and home-rolled axioms
lake exe module-system   # rejects any module that did not open with `module`
```

## CI as the source of truth

If you'd rather not build locally at all, every push to `main` and every pull request
already runs the steps above (see `.github/workflows/ci.yml`). The resolved
`lake-manifest.json` and the demonstration run's HepMC3 output and performance summary are
uploaded as that workflow's artifacts -- see the repository's Actions tab.
