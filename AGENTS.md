# Working in McLean

McLean is the event generator. The physics it rests on lives in
[EpsilonEridani](https://github.com/eic/EpsilonEridani); read `README.md` for how the two
divide. This file adds the contract for agents working here.

## The one rule that matters most

**Nothing is claimed as working until a compiler says so.** Not "this should compile", not
"the logic is straightforward", not an exit code from a command that may have compiled
nothing. A precisely narrowed failure is a better outcome than a speculative fix, and is
reported as such.

Two specific traps, both of which have cost this programme real time:

* `lake build` can exit 0 having compiled **nothing** — a cache hit, or a source tree the
  build never reached. Exit 0 alone is not evidence. Require a `✔ [i/n] Built <module>`
  line, or use `lake env lean <file>`, which always elaborates and cannot no-op.
* Deleting an `.olean` to force a rebuild does **not** work as evidence either: Lake
  restores it from its content-addressed cache without recompiling.

## The second rule

**Discharging an assumption outranks adding new surface, and fixing a statement that does
not say what its name claims outranks proving a new theorem.**

A structure field of type `Prop` with a placeholder witness asserts nothing while looking
like a hypothesis. If something is unproved, say so in the module docstring as a named
gap — do not encode it as a field that makes the obligation invisible.

## Correctness claims about generated events

An event generator's output is validated by measurement, not by inspection, and not by
comparison against your own reimplementation of the same idea. That last one is a specific
failure mode worth naming: a resolution-scale observable in the predecessor implementation
was cross-checked against an independent Python implementation and agreed to *zero*
deviation — because both used the same wrong array index. The agreement was real and
covered the wrong quantity.

So: state which population a number describes, compare against a prediction derived
independently of the code under test, and when a check passes, say what it establishes
rather than what you hoped it would.

## Conventions

* Every file under `McLean/` opens with `module` and the Apache header (`Copyright`,
  `Released under`, `Authors:`). The audits enforce both.
* Use `lemma` unless the result is well known in the physics literature; reserve `theorem`
  for named results. The upstream repository runs roughly 200 `theorem` to 7700 `lemma`.
* The root `McLean.lean` is intentionally empty. Adding a module does not require editing
  it.
* Do not run `git add -A`, `git add .`, or `git commit -a`. Agent sandboxes mask protected
  configuration paths, which makes files such as `.vscode/settings.json` appear deleted
  when they are not; any of those commands would commit that phantom deletion. Stage
  explicit paths.

## Pull requests

Describe what was measured or compiled, and name the limits that travel with the result:
what was not built, what was not checked, which population a statistic describes. A result
whose coverage is unstated is not yet a finding.
