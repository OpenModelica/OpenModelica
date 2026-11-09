# OMCompiler.jl

Experimental. Loads the Rust port of omc (`libOpenModelicaCompiler`) into Julia, runs its
frontend and reads the flat model straight from omc's values. OMBackend.jl lowers such a
model to OMJLIR when this package is loaded (its `OMBackendOMCompilerExt` extension).

## Building

The library is only built by the Rust port of omc:

```sh
cmake -S . -B build_cmake -DCMAKE_BUILD_TYPE=Release -DOM_ENABLE_GUI_CLIENTS=OFF -DOM_OMC_ENABLE_RUST=ON
cmake --build build_cmake --target install --parallel <N>
```

Use the library from the install tree (`build_cmake/install_cmake`): omc locates its
builtin files relative to the library.

## Use

```julia
import Pkg
Pkg.develop(path = "OMCompiler/Compiler/OpenModelica.rs/OMCompiler.jl")

import OMCompiler
OMCompiler.init(omhome = "build_cmake/install_cmake")
OMCompiler.evaluate("loadModel(Modelica, {\"4.1.0\"})")
(model, functions) = OMCompiler.instantiate("Modelica.Mechanics.Rotational.Examples.First")
model.variables[1].name           # an NFComponentRef node
OMCompiler.apply("ComponentRef.toString", model.variables[1].name)
```

With OMBackend.jl:

```julia
import OMBackend
OMBackend.translate(OMBackend.lowerOMCFlatModel(model, functions))
sol = OMBackend.simulateModel("Modelica.Mechanics.Rotational.Examples.First"; tspan = (0.0, 1.0))
```

## Tests

`Pkg.test("OMCompiler")` with `OPENMODELICAHOME` set to an install tree of the Rust port.
