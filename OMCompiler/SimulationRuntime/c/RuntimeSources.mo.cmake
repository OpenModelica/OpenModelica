encapsulated package RuntimeSources
  constant String fmu_sources_dir = "/@SOURCE_FMU_SOURCES_DIR@";

  // The Rust crates a --simCodeTarget=C+Rust source FMU carries, in the checkout's
  // own layout: the manifests reach openmodelica_lapack by a relative path.
  // Installed by SimulationRuntime/rust/CMakeLists.txt.
  constant String fmu_rust_sources_dir = "/@SOURCE_FMU_RUST_SOURCES_DIR@";
  constant String fmu_rust_manifest = "SimulationRuntime/rust/Cargo.toml";

  constant list<String> simrt_c_sources={@SOURCE_FMU_COMMON_FILES@};

  // The libOpenModelicaRuntimeC half of simrt_c_sources: what a
  // --simCodeTarget=C+Rust FMU still compiles from C, because the Rust runtime
  // replaces only what libSimulationRuntimeC covers.
  constant list<String> simrt_c_runtime_sources={@SOURCE_FMU_RUNTIME_C_FILES@};

  constant list<String> simrt_c_headers={@SOURCE_FMU_COMMON_HEADERS@};

  constant list<String> fmi1Files={"fmi-export/fmu1_model_interface.c.inc",
                                   "fmi-export/fmu1_model_interface.h"};
  constant list<String> fmi1_rust_headers={"fmi-export/fmu1_model_interface.h",
                                           "fmi-export/fmu1_rust_interface.c.inc"};
  // fmu_model_interface.c.inc is the model interface that FMI 2.0 and 3.0 share.
  constant list<String> fmi2_headers={"fmi-export/fmu2_model_interface.h",
                                      "fmi-export/fmu2_rust_interface.c.inc",
                                      "fmi-export/fmu_model_interface.c.inc"};
  constant list<String> fmi2_sources={"fmi-export/fmu2_model_interface.c"};
  constant list<String> fmi3_headers={"fmi-export/fmu3_model_interface.h",
                                      "fmi-export/fmu3_rust_interface.c.inc",
                                      "fmi-export/fmu_model_interface.c.inc"};
  constant list<String> fmi3_sources={"fmi-export/fmu3_model_interface.c"};

  constant list<String> defaultFileSuffixes={".c",
                                             "_functions.c",
                                             "_records.c",
                                             "_01exo.c",
                                             "_02nls.c",
                                             "_03lsy.c",
                                             "_04set.c",
                                             "_05evt.c",
                                             "_06inz.c",
                                             "_07dly.c",
                                             "_08bnd.c",
                                             "_09alg.c",
                                             "_10asr.c",
                                             "_11mix.c",
                                             "_12jac.c",
                                             "_13opt.c",
                                             "_14lnz.c",
                                             "_15syn.c",
                                             "_16dae.c",
                                             "_18spd.c",
                                             "_init_fmu.c",
                                             "_FMU.c"};


  constant list<String> simrt_c_sundials_sources={@SOURCE_FMU_SUNDIALS_FILES@};

  constant list<String> simrt_c_cvode_sources={@SOURCE_FMU_CVODE_RUNTIME_FILES@};

  constant list<String> solver_library_files={@SOURCE_FMU_SOLVER_LIBRARY_FILES@};

  constant list<String> solver_library_sources={@SOURCE_FMU_SOLVER_LIBRARY_SOURCES@};

  constant list<String> modelica_external_c_sources={"ModelicaExternalC/ModelicaFFT.c",
                                                     "ModelicaExternalC/ModelicaInternal.c",
                                                     "ModelicaExternalC/ModelicaRandom.c",
                                                     "ModelicaExternalC/ModelicaStrings.c",
                                                     "ModelicaExternalC/ModelicaStandardTables.c",
                                                     "ModelicaExternalC/ModelicaMatIO.c",
                                                     "ModelicaExternalC/ModelicaIO.c",
                                                     "ModelicaExternalC/ModelicaStandardTablesDummyUsertab.c",
                                                     "ModelicaExternalC/snprintf.c",
                                                     "ModelicaExternalC/win32_dirent.c"};

  constant list<String> modelica_external_c_headers={"ModelicaExternalC/gconstructor.h",
                                                     "ModelicaExternalC/read_data_impl.h",
                                                     "ModelicaExternalC/safe-math.h",
                                                     "ModelicaExternalC/stdint_msvc.h",
                                                     "ModelicaExternalC/stdint_wrap.h",
                                                     "ModelicaExternalC/uthash.h",
                                                     "ModelicaExternalC/win32_dirent.h"};

  // The headers of the MSL that a model includes: in sources/, which an importer
  // has on its include path, rather than beside the C files.
  constant list<String> modelica_external_c_api_headers={"ModelicaFFT.h",
                                                         "ModelicaInternal.h",
                                                         "ModelicaIO.h",
                                                         "ModelicaMatIO.h",
                                                         "ModelicaRandom.h",
                                                         "ModelicaStandardTables.h",
                                                         "ModelicaStrings.h"};

  constant list<String> dgesv_headers={"./external_solvers/blaswrap.h",
                                       "./external_solvers/clapack.h",
                                       "./external_solvers/f2c.h"};

  constant list<String> dgesv_sources={@SOURCE_FMU_DGESV_FILES@};

  constant list<String> cminpack_headers = {"./external_solvers/cminpack.h",
                                            "./external_solvers/minpack.h",
                                            "./external_solvers/minpackP.h"};

  constant list<String> cminpack_sources = {@SOURCE_FMU_CMINPACK_FILES@};

  constant list<String> simrt_linear_solver_sources={@SOURCE_FMU_LS_FILES@};

  constant list<String> simrt_non_linear_solver_sources={@SOURCE_FMU_NLS_FILES@};

  constant list<String> simrt_mixed_solver_sources={@SOURCE_FMU_MIXED_FILES@};

annotation(__OpenModelica_Interface="backend");
end RuntimeSources;
