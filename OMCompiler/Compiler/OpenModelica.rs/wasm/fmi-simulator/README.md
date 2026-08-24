# FMI Simulator

A browser FMI 3.0 master for wasm FMUs following the [FMI Layered Standard
WebAssembly](https://github.com/modelica/fmi-ls-wasm) draft: open an `.fmu`
whose binary is a WebAssembly component, simulate it, plot the results. Both
Co-Simulation and Model Exchange are driven. Nothing is uploaded anywhere and no
server is involved — the FMU is unpacked, compiled and run inside the page.

## How it runs a component

FMI-LS-WASM FMUs ship a Component Model binary (`binaries/wasm32-wasip2/*.wasm`),
which browsers cannot instantiate directly: `WebAssembly.instantiate` only takes
core modules. Hosts normally transpile the component to JS ahead of time with
[jco](https://github.com/bytecodealliance/jco), but that would restrict the page
to FMUs known at build time.

Instead the page runs jco's transpiler *itself* — `js-component-bindgen` is
distributed as a wasm component with a pre-transpiled JS wrapper, so it runs in
the browser. Loading an FMU therefore means:

1. `fmu.js` unpacks the ZIP (central directory + `DecompressionStream`) and parses
   `modelDescription.xml` with `DOMParser`.
2. `js-component-bindgen` transpiles the FMU component to JS plus core modules,
   in `instantiation: async` mode so the page supplies the imports and compiles
   the cores itself.
3. The generated JS is imported from a blob URL and instantiated with the WASI
   preview2 shim, the `fmi:fmi3/callbacks` imports, and the FMU's own
   `resources/` directory mounted as the guest filesystem.

Each run instantiates the component afresh, so a second run cannot inherit the
first one's state.

`vendor/` holds the transpiler and the WASI shim. It is not in git: the CMake web
target downloads both pinned npm tarballs (see `Compiler/.cmake/rust_omc.cmake`)
and stages them next to the page, which `install(DIRECTORY web/)` then installs
along with the rest of the bundle. To work on the page without a full web build,
serve this directory with `vendor/` populated the same way.

The launcher's sidebar icon (`../icons/fmi.svg`) is the Modelica Association's
FMI logo, copied unmodified from
[MA-Logos](https://github.com/modelica/MA-Logos) (`HighRes/FMI_bare.svg`). Its
usage terms forbid altering it and ask for a white background, which is why the
launcher gives that one icon a white chip instead of recolouring the artwork.

## Masters

`master.js` has no DOM dependency and drives the instance API jco generates from
the WIT worlds.

* **Co-Simulation** — `do-step` to the stop time, feeding inputs at each
  communication point. When the model description sets `hasEventMode`, event
  handling runs the `enter-event-mode` / `update-discrete-states` /
  `enter-step-mode` cycle.
* **Model Exchange** — Dormand-Prince 5(4) with tolerance-driven step size.
  State events are found by bisecting the step until the event indicators change
  sign, then stepping exactly onto the crossing; time events land on
  `next-event-time` exactly. Zeno models (the bouncing ball is the classic one)
  stop with a warning once events keep arriving with no time between them,
  keeping the samples collected up to that point.

Inputs are expressions in `t` (`sin(2*PI*t)`, `t < 1 ? 0 : 1`) evaluated at every
time point; parameters are constants applied during initialization only, which is
the only mode FMI allows them to be set in.

## Verified against

* `adder-rust-fmu` and `adder-wat-fmu` from fmi-ls-wasm `examples/`, in Chrome:
  load, transpile, instantiate, Co-Simulation run, plot.
* The Model Exchange master, against a JS mock of the instance API (bouncing
  ball, harmonic oscillator): event location, step adaptivity and the Zeno guard.
  **It has not yet run against a real Model Exchange wasm FMU** — no example
  exists upstream; every fmi-ls-wasm example is a Co-Simulation adder.

## Gaps

* Scheduled Execution is not driven; such an FMU is reported as unsupported.
* `get-fmu-state` / `set-fmu-state` are unused: no rollback, so a Co-Simulation
  FMU that discards a step fails the run rather than retrying it smaller.
* `intermediate-update` always declines early return.
* The layered-standard manifest (`extra/org.modelica.fmi-ls-wasm/manifest.xml`)
  is not required — the upstream example archives do not ship one.
* ZIP64 archives are rejected.

## For the OpenModelica FMI export

To be loadable here, an exported FMU needs `modelDescription.xml` (FMI 3.0, with
`instantiationToken` and a `<CoSimulation>` or `<ModelExchange>` element) and a
component at `binaries/wasm32-wasip2/<modelIdentifier>.wasm` implementing the
`fmi:fmi3/world.co-simulation-fmu` or `model-exchange-fmu` world. The page
reports which imports an FMU asks for that the host does not provide, which is
the first thing to check when a fresh export will not instantiate.
