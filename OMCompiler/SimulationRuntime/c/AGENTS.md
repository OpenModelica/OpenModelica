# Instructions for coding agents: the C simulation runtime

See also the top-level [AGENTS.md](../../../AGENTS.md).

## Adding a source file

- Add it, and its header, to the source lists in `simulation/CMakeLists.txt`
  (or the `CMakeLists.txt` of the directory it is in).
- If generated code or FMUs need it, also add it to
  `cmake/source_code_fmu_config.cmake`. It generates `RuntimeSources.mo`,
  which is git-ignored; never edit that file. It lists the sources `omc`
  copies into source-code FMUs and into `<SourceFiles>` of their
  `modelDescription.xml`; a missing header shows up as a failing FMU build.
- A new file in that list changes the expected output of the FMI 2.0 tests
  in `testsuite/openmodelica/fmi/ModelExchange/2.0/` that print
  `<SourceFiles>`. Update them in the same commit.
