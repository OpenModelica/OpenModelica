# Simulation and re-compilation of OpenModelica FMUs with FMPy

Build FMUs from [../FmuExportCrossCompile/](../FmuExportCrossCompile):

```bash
make compile_FMUs
```

Simulate each FMU with FMPy:

```bash
make test
```

The FMUs from `FmuExportCrossCompile` link the Rust simulation runtime, which
FMPy cannot compile, so they are simulated with the binaries OpenModelica built.
`TableTest.fmu` (`make fmpy-fmus`) is exported with `--simCodeTarget=C.old`,
whose sources are plain C: its binaries are removed and FMPy re-compiles it
before simulating.
