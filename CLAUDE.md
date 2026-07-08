# OpenModelica

## Key Directories

* C Simulation Runtime: `OMCompiler/SimulationRuntime/c`
* Templates: `OMCompiler/Compiler/Template`

## Building OpenModelica Compiler

* Use the CMake build of OpenModelica. CMake configurations are saved in
  [.vscode/settings.json](.vscode/settings.json) in `"cmake.configureArgs"`.

  ```bash
  cmake --build build_cmake --config Debug --target install -j 28
  ```

## Standards

* When asked for a commit message always add co-authored-by line at the end with
  the used version of CLAUDE.
* Always skip GPG signing when creating commits (`--no-gpg-sign`).
