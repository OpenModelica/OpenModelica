# Re-compilation and simulation of OpenModelica FMUs with FMPy

Build FMUs from [../FmuExportCrossCompile/](../FmuExportCrossCompile):

```bash
make compile_FMUs
```

Remove binaries from FMU, re-compile each FMU with FMPy and simulate it:

```bash
make test
```
