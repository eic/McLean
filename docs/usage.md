# Usage

`mclean` parses its arguments into a run configuration, generates DIS events by calling
EpsilonEridani's `Generator.loRun` (or `Generator.showerRun`, with `--shower`) directly,
and writes the result as HepMC3 ASCII. It defines no physics of its own -- see
[the split](README.md#the-split).

```
mclean [OPTIONS] - an event generator built on EpsilonEridani

  --events N          number of events to generate (default 10)
  --seed S             RNG seed (default 0)
  --output PATH        HepMC3 ASCII output path (default events.hepmc3)
  --lepton-energy E    lepton beam energy in GeV (default 9.0)
  --hadron-energy E    hadron beam energy in GeV (default 100.0)
  --q2min Q            minimum Q^2 in GeV^2 (default 1.0)
  --shower             run the final-state parton shower (default: LO only)
  --perf-output PATH   also write a JSON performance summary to PATH
  --help               print this message
```

An unrecognised flag or a malformed value (e.g. `--events abc`) is a hard error: `mclean`
prints the problem and this usage text to stderr and exits with status 1, rather than
silently ignoring it.

## Examples

Generate 10 LO (unshowered) events with the defaults:

```sh
lake exe mclean
```

Generate 2000 showered events at a fixed seed, with a performance summary:

```sh
lake exe mclean -- \
  --events 2000 --seed 42 --shower \
  --output events.hepmc3 --perf-output perf.json
```

Decimal flags (`--lepton-energy`, `--hadron-energy`, `--q2min`) accept plain decimal
literals such as `9`, `9.0` or `-1.5` -- no scientific notation.

## Output

**`events.hepmc3`** -- the generated events in [HepMC3](https://gitlab.cern.ch/hepmc/HepMC3)
Asciiv3 format, written by EpsilonEridani's `HepMC3.Ascii.writeFile`. Each event carries
`xBj` and `Q2` attributes (`A 0 xBj <value>` / `A 0 Q2 <value>` lines) alongside its
particle and vertex records.

**`perf.json`** (with `--perf-output`) -- a small run summary:

```json
{
  "eventsRequested": 2000,
  "eventsProduced": 2000,
  "trials": 5312,
  "shower": true,
  "seed": 42,
  "wallMs": 842,
  "eventsPerSec": 2375.3,
  "acceptanceEfficiency": 0.3765,
  "output": "events.hepmc3"
}
```

`trials`/`acceptanceEfficiency` describe the acceptance-rejection sampler's cost, not the
physical cross section -- see [the split](README.md#the-split) for what that number does
and does not establish.

## What this does not yet validate

`mclean`'s output is structurally checked in CI (event count, `xBj`/`Q2` bounds), not
statistically validated against an independently derived prediction. See `AGENTS.md` in
the repository for why that distinction matters and what a real measurement looks like.
