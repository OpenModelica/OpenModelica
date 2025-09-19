encapsulated package RuntimeSources
  constant String fmu_sources_dir = "/include/omc/c/";
  constant list<String> simrt_c_sources={COMMON_FILES};
  constant list<String> simrt_c_headers={COMMON_HEADERS};
  constant list<String> fmi1Files={"fmi-export/fmu1_model_interface.c.inc","fmi-export/fmu1_model_interface.h"};
  constant list<String> fmi2Files={"fmi-export/fmu2_model_interface.c.inc","fmi-export/fmu2_model_interface.h", "fmi-export/fmu_read_flags.c.inc", "fmi-export/fmu_read_flags.h"};
  constant list<String> defaultFileSuffixes={".c", "_functions.c", "_records.c", "_01exo.c", "_02nls.c", "_03lsy.c", "_04set.c", "_05evt.c", "_06inz.c", "_07dly.c", "_08bnd.c", "_09alg.c", "_10asr.c", "_11mix.c", "_12jac.c", "_13opt.c", "_14lnz.c", "_15syn.c", "_16dae.c", "_17inl.c", "_18spd.c", "_init_fmu.c", "_FMU.c"};

  constant list<String> sundials_headers={"sundials/cvode/cvode_ls.h",
                                         "sundials/cvode/cvode_proj.h",
                                         "sundials/cvode/cvode.h",
                                         "sundials/sundials/sundials_config.h",
                                         "sundials/sundials/sundials_dense.h",
                                         "sundials/sundials/sundials_direct.h",
                                         "sundials/sundials/sundials_iterative.h",
                                         "sundials/sundials/sundials_linearsolver.h",
                                         "sundials/sundials/sundials_matrix.h",
                                         "sundials/sundials/sundials_nonlinearsolver.h",
                                         "sundials/sundials/sundials_types.h",
                                         "sundials/sunlinsol/sunlinsol_dense.h",
                                         "sundials/sunmatrix/sunmatrix_dense.h",
                                         "sundials/sunnonlinsol/sunnonlinsol_fixedpoint.h",
                                         "sundials/nvector/nvector_serial.h",
                                         "sundials/sundials/sundials_nvector.h"};

  constant list<String> simrt_c_sundials_sources={"simulation/solver/cvode_solver.c",
                                                  "simulation/solver/sundials_error.c"};

  constant list<String> modelica_external_c_sources={"ModelicaStandardTables.c",
                                                     "ModelicaMatIO.c",
                                                     "ModelicaIO.c",
                                                     "ModelicaStandardTablesDummyUsertab.c",
                                                     "snprintf.c"};

  constant list<String> modelica_external_c_headers={"ModelicaStandardTables.h",
                                                     "ModelicaMatIO.h",
                                                     "ModelicaIO.h",
                                                     "safe-math.h",
                                                     "read_data_impl.h"};

  constant list<String> dgesv_headers={"./external_solvers/blaswrap.h", "./external_solvers/clapack.h", "./external_solvers/f2c.h"};
  constant list<String> dgesv_sources={DGESV_FILES};

  constant list<String> cminpack_headers = {"./external_solvers/cminpack.h", "./external_solvers/minpack.h", "./external_solvers/minpackP.h"};
  constant list<String> cminpack_sources = {CMINPACK_FILES};

  constant list<String> simrt_linear_solver_sources={LS_FILES};
  constant list<String> simrt_non_linear_solver_sources={NLS_FILES};
  constant list<String> simrt_mixed_solver_sources={MIXED_FILES};
annotation(__OpenModelica_Interface="backend");
end RuntimeSources;
