# FMI Simulator

A browser master for FMI 3.0 wasm FMUs following the [FMI Layered Standard
WebAssembly](https://github.com/modelica/fmi-ls-wasm) draft: open an `.fmu`
whose binary is a WebAssembly component, simulate it, plot the results. Both
Co-Simulation and Model Exchange are driven. Nothing is uploaded anywhere and no
server is involved — the FMU is unpacked, compiled and run inside the page.

## What runs the FMU

The masters are OpenModelica's own, in Rust: `openmodelica_fmi_driver`, built for
`wasm32-wasip1` as `openmodelica_fmi_web.wasm`. Model Exchange integrates with
the same solvers a compiled Modelica model runs under (`openmodelica_solvers`:
DASSL, gbode, the fixed-step ones, and CVODE/IDA where the module was linked
against SUNDIALS), so an FMU is stepped, error-controlled and root-searched
exactly like a model; Co-Simulation drives `fmi3DoStep` and takes the FMU up on
early return, handling each event at the time the FMU stopped at rather than at
the next communication point.

The page's solver chooser is built from the list the module reports, so it can
never offer one that build does not have.

A run is one call into that module and cannot be interrupted, so it happens in a
worker (`fmi-worker.js`); the Cancel button drops the worker, after which the
FMU has to be opened again.

## How it reaches the FMU

FMI-LS-WASM FMUs ship a Component Model binary
(`binaries/wasm32-wasip2/*.wasm`), which browsers cannot instantiate directly:
`WebAssembly.instantiate` only takes core modules. Hosts normally transpile the
component to JS ahead of time with [jco](https://github.com/bytecodealliance/jco),
but that would restrict the page to FMUs known at build time. Instead the page
runs jco's transpiler *itself* — `js-component-bindgen` is distributed as a wasm
component with a pre-transpiled JS wrapper, so it runs in the browser.

The wrappers jco generates are not what the run calls, though: each costs about
4 µs, which a solver taking millions of steps cannot pay. `fmu-core.js` patches
the generated module with one extra export that hands out its internals, and the
driver's FMI calls then go straight to the component's *core* exports — 238 ns
for `fmi3SetTime` instead of 7684. What each call's lowering looks like is read
out of jco's own wrappers, so the two cannot drift.

## Files

| file | |
| --- | --- |
| `index.html` | the page: the FMU's variables, the run options, the plots |
| `session.js` | the page's side of the worker |
| `fmi-worker.js` | owns the driver and the FMU for the length of a run |
| `driver.js` | the driver module, and the FMI calls it imports |
| `fmu-core.js` | jco transpilation, and the core exports past its glue |
| `fmu.js` | the ZIP and `modelDescription.xml`, for what the page displays |
| `wasi.js` | a WASI preview1 host, so the result file is written like any other |
| `selftest.html` | `?fmu=<url>&interface=me|cs&solver=<name>` — the whole path, headless |

`vendor/` holds the transpiler and the WASI preview2 shim. It is not in git: the
CMake web target downloads both pinned npm tarballs (see
`Compiler/.cmake/rust_omc.cmake`) and stages them next to the page. To work on
the page without a full web build, serve this directory with `vendor/` populated
the same way, and put a built `openmodelica_fmi_web.wasm` beside it.

The launcher's sidebar icon (`../icons/fmi.svg`) is the Modelica Association's
FMI logo, copied unmodified from
[MA-Logos](https://github.com/modelica/MA-Logos) (`HighRes/FMI_bare.svg`). Its
usage terms forbid altering it and ask for a white background, which is why the
launcher gives that one icon a white chip instead of recolouring the artwork.

## Results

Samples are recorded for every numeric variable that can change. The download
button in the header writes the usual OpenModelica `.mat` through WASI and hands
it over — the same file OMPlot and `omc-diff` read for a simulated model. It is
written when asked for rather than after every run, since serialising the whole
result is the expensive part and most runs are only ever plotted.

Inputs are expressions in `t` (`sin(2*PI*t)`, `t < 1 ? 0 : 1`) evaluated by the
driver wherever the solver asks for a value; parameters are constants applied
during initialization, which is the only mode FMI allows them to be set in.

## Gaps

* Scheduled Execution is not driven; such an FMU is reported as unsupported.
* String and binary variables are shown but cannot be set.
* `fmi3GetFMUState`/`fmi3SetFMUState` are unused: no rollback, so a
  Co-Simulation FMU that discards a step fails the run rather than retrying it
  smaller.
* `intermediate-update` always declines early return; the FMU's own early
  returns are honoured.
* Samples arrive only when the run ends — the progress line moves, the plot does
  not.
* ZIP64 archives are rejected.

## For the OpenModelica FMI export

To be loadable here, an exported FMU needs `modelDescription.xml` (FMI 3.0, with
`instantiationToken` and a `<CoSimulation>` or `<ModelExchange>` element) and a
component at `binaries/wasm32-wasip2/<modelIdentifier>.wasm` implementing the
`fmi:fmi3/world.co-simulation-fmu` or `model-exchange-fmu` world. The page
reports which imports an FMU asks for that the host does not provide, which is
the first thing to check when a fresh export will not instantiate.
