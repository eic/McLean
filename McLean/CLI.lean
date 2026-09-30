/-
Copyright (c) 2026 Wouter Deconinck. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Wouter Deconinck
-/
module

public import EpsilonEridani.Generator.Config
public import EpsilonEridani.Generator.DISEvent
public import EpsilonEridani.HepMC3.Ascii

/-!
# The `mclean` command line

Parses the `mclean` executable's arguments into an `EpsilonEridani.Generator.RunConfig`,
runs EpsilonEridani's existing LO DIS generator (`Generator.loRun`) or its showered
variant (`Generator.showerRun`) directly, and writes the resulting events as HepMC3
ASCII-v3 through `EpsilonEridani.HepMC3.Ascii.writeFile`.

This module defines no physics of its own: the sampler, the parton shower, and the toy
structure-function shape it samples against are all EpsilonEridani's `Generator/*` code,
called here unmodified. Per the boundary in `README.md`, McLean's own
independently-implemented and independently-validated sampler/shower is future work, not
this module.
-/

namespace McLean
namespace CLI

open EpsilonEridani.Generator
open EpsilonEridani.HepMC3

@[expose] public section

/-- Parsed command-line options for the `mclean` executable. -/
structure Options where
  events : Nat := 10
  seed : Nat := 0
  output : System.FilePath := "events.hepmc3"
  leptonEnergy : Float := 9.0
  hadronEnergy : Float := 100.0
  q2Min : Float := 1.0
  shower : Bool := false
  perfOutput : Option System.FilePath := none
deriving Repr, Inhabited

/-- `mclean`'s usage text, printed on `--help` or an unrecognised flag. -/
def usage : String :=
  "mclean [OPTIONS] - an event generator built on EpsilonEridani\n\n" ++
  "  --events N          number of events to generate (default 10)\n" ++
  "  --seed S            RNG seed (default 0)\n" ++
  "  --output PATH       HepMC3 ASCII output path (default events.hepmc3)\n" ++
  "  --lepton-energy E   lepton beam energy in GeV (default 9.0)\n" ++
  "  --hadron-energy E   hadron beam energy in GeV (default 100.0)\n" ++
  "  --q2min Q           minimum Q^2 in GeV^2 (default 1.0)\n" ++
  "  --shower            run the final-state parton shower (default: LO only)\n" ++
  "  --perf-output PATH  also write a JSON performance summary to PATH\n" ++
  "  --help              print this message\n"

/-- Parses a plain decimal literal such as `9`, `9.0` or `-1.5` into a `Float`. Accepts no
scientific notation; every default value above is written in the form this parser
accepts, and that is the only form `mclean --help` promises. -/
def parseDecimal (s : String) : Option Float :=
  let neg := s.startsWith "-"
  let s : String := if neg then (s.drop 1).toString else s
  let apply (f : Float) : Float := if neg then -f else f
  match s.splitOn "." with
  | [whole] => (whole.toNat?).map (fun n => apply n.toFloat)
  | [whole, frac] =>
    match whole.toNat?, frac.toNat? with
    | some w, some f =>
      let scale := (10 : Nat) ^ frac.length
      some (apply (w.toFloat + f.toFloat / scale.toFloat))
    | _, _ => none
  | _ => none

/-- The result of parsing `mclean`'s arguments. -/
inductive ParseResult
  | ok (opts : Options)
  | help
  | error (msg : String)

instance : Inhabited ParseResult := ⟨.help⟩

/-- Consumes `args` left to right, folding recognised flags into `opts`. Stops and
reports an error on the first unrecognised flag or malformed value, rather than silently
ignoring it. -/
partial def parseArgsAux : List String → Options → ParseResult
  | [], opts => .ok opts
  | "--help" :: _, _ => .help
  | "--events" :: v :: rest, opts =>
    match v.toNat? with
    | some n => parseArgsAux rest { opts with events := n }
    | none => .error s!"--events expects a natural number, got '{v}'"
  | "--seed" :: v :: rest, opts =>
    match v.toNat? with
    | some n => parseArgsAux rest { opts with seed := n }
    | none => .error s!"--seed expects a natural number, got '{v}'"
  | "--output" :: v :: rest, opts =>
    parseArgsAux rest { opts with output := v }
  | "--lepton-energy" :: v :: rest, opts =>
    match parseDecimal v with
    | some f => parseArgsAux rest { opts with leptonEnergy := f }
    | none => .error s!"--lepton-energy expects a decimal number, got '{v}'"
  | "--hadron-energy" :: v :: rest, opts =>
    match parseDecimal v with
    | some f => parseArgsAux rest { opts with hadronEnergy := f }
    | none => .error s!"--hadron-energy expects a decimal number, got '{v}'"
  | "--q2min" :: v :: rest, opts =>
    match parseDecimal v with
    | some f => parseArgsAux rest { opts with q2Min := f }
    | none => .error s!"--q2min expects a decimal number, got '{v}'"
  | "--shower" :: rest, opts =>
    parseArgsAux rest { opts with shower := true }
  | "--perf-output" :: v :: rest, opts =>
    parseArgsAux rest { opts with perfOutput := some v }
  | flag :: _, _ =>
    .error s!"unrecognised option '{flag}'"

/-- Parses `mclean`'s command-line arguments, starting from `Options`'s defaults. -/
def parseArgs (args : List String) : ParseResult :=
  parseArgsAux args {}

/-- Builds the `RunConfig` EpsilonEridani's generator expects from parsed CLI options. -/
def Options.toRunConfig (o : Options) : RunConfig :=
  { lepton := electronBeam o.leptonEnergy
    hadron := protonBeam o.hadronEnergy
    nEvents := o.events
    seed := o.seed
    output := o.output
    q2Min := o.q2Min }

/-- Escapes a string for embedding in a hand-written JSON literal. Only the two
characters that can appear in the paths this module writes (`"` and `\`) need escaping;
there is no untrusted input here to justify a general-purpose JSON writer. -/
def jsonEscape (s : String) : String :=
  (s.replace "\\" "\\\\").replace "\"" "\\\""

/-- Writes a small, machine-readable performance summary: how many events were produced,
how many sampler trials that took, and how long the run took. -/
def writePerf (path : System.FilePath) (o : Options) (produced trials : Nat)
    (wallMs : Nat) : IO Unit := do
  let eventsPerSec : Float :=
    if wallMs == 0 then 0.0 else o.events.toFloat / (wallMs.toFloat / 1000.0)
  let acceptance : Float :=
    if trials == 0 then 0.0 else produced.toFloat / trials.toFloat
  let json :=
    "{\n" ++
    s!"  \"eventsRequested\": {o.events},\n" ++
    s!"  \"eventsProduced\": {produced},\n" ++
    s!"  \"trials\": {trials},\n" ++
    s!"  \"shower\": {if o.shower then "true" else "false"},\n" ++
    s!"  \"seed\": {o.seed},\n" ++
    s!"  \"wallMs\": {wallMs},\n" ++
    s!"  \"eventsPerSec\": {eventsPerSec},\n" ++
    s!"  \"acceptanceEfficiency\": {acceptance},\n" ++
    s!"  \"output\": \"{jsonEscape o.output.toString}\"\n" ++
    "}\n"
  IO.FS.writeFile path json

/-- Runs the generator `mclean`'s arguments describe: samples LO DIS events (or, with
`--shower`, showers them too), writes the resulting HepMC3 ASCII output, and optionally a
JSON performance summary. Returns the process exit code. -/
def run (args : List String) : IO UInt32 := do
  match parseArgs args with
  | .help =>
    IO.println usage
    return 0
  | .error msg =>
    IO.eprintln s!"mclean: {msg}\n\n{usage}"
    return 1
  | .ok opts =>
    let config := opts.toRunConfig
    let startMs ← IO.monoMsNow
    let (events, produced, trials) ←
      if opts.shower then do
        let (events, stats, _emissions, _exhausted) ← showerRun config
        pure (events, stats.accepted, stats.trials)
      else do
        let (events, stats) ← loRun config
        pure (events, stats.accepted, stats.trials)
    let endMs ← IO.monoMsNow
    Ascii.writeFile opts.output config.runInfo events
    match opts.perfOutput with
    | some perfPath => writePerf perfPath opts produced trials (endMs - startMs)
    | none => pure ()
    IO.println
      s!"mclean: wrote {events.length} events ({produced}/{trials} sampler trials \
         accepted) to {opts.output} in {endMs - startMs}ms"
    return 0

end

end CLI
end McLean
