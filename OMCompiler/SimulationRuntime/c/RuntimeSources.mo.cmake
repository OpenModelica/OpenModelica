encapsulated package RuntimeSources
  constant String fmu_sources_dir = "/@SOURCE_FMU_SOURCES_DIR@";

  constant list<String> commonFiles={@SOURCE_FMU_COMMON_FILES@};

  constant list<String> commonHeaders={@SOURCE_FMU_COMMON_HEADERS@};

  constant list<String> fmi1Files={"fmi-export/fmu1_model_interface.c.inc","fmi-export/fmu1_model_interface.h"};
  constant list<String> fmi2Files={"fmi-export/fmu2_model_interface.c.inc","fmi-export/fmu2_model_interface.h", "fmi-export/fmu_read_flags.c.inc", "fmi-export/fmu_read_flags.h"};

  constant list<String> defaultFileSuffixes={".c", "_functions.c", "_records.c", "_01exo.c", "_02nls.c", "_03lsy.c", "_04set.c", "_05evt.c", "_06inz.c", "_07dly.c", "_08bnd.c", "_09alg.c", "_10asr.c", "_11mix.c", "_12jac.c", "_13opt.c", "_14lnz.c", "_15syn.c", "_16dae.c", "_17inl.c", "_18spd.c", "_init_fmu.c", "_FMU.c"};

  constant list<String> cvodeFiles={"sundials/cvode/cvode_ls.h",
                                    "sundials/cvode/cvode_proj.h",
                                    "sundials/cvode/cvode.h"};

  constant list<String> sundialsFiles={"sundials/sundials/sundials_config.h",
                                       "sundials/sundials/sundials_dense.h",
                                       "sundials/sundials/sundials_direct.h",
                                       "sundials/sundials/sundials_iterative.h",
                                       "sundials/sundials/sundials_linearsolver.h",
                                       "sundials/sundials/sundials_matrix.h",
                                       "sundials/sundials/sundials_nonlinearsolver.h",
                                       "sundials/sundials/sundials_types.h",
                                       "sundials/sunlinsol/sunlinsol_dense.h",
                                       "sundials/sunmatrix/sunmatrix_dense.h",
                                       "sundials/sunnonlinsol/sunnonlinsol_fixedpoint.h"};

  constant list<String> nvectorFiles={"sundials/nvector/nvector_serial.h",
                                      "sundials/sundials/sundials_nvector.h"};

  constant list<String> external3rdPartyFiles=listAppend(listAppend(cvodeFiles,sundialsFiles), nvectorFiles);

  constant list<String> dgesvFiles={@SOURCE_FMU_DGESV_FILES@};

  constant list<String> cvodeRuntimeFiles={"simulation/solver/cvode_solver.c",
                                           "simulation/solver/sundials_error.c"};

  constant list<String> lsFiles={@SOURCE_FMU_LS_FILES@};

  constant list<String> nlsFiles={@SOURCE_FMU_CMINPACK_FILES@, @SOURCE_FMU_NLS_FILES@};

  constant list<String> mixedFiles={@SOURCE_FMU_MIXED_FILES@};

annotation(__OpenModelica_Interface="backend");
end RuntimeSources;

