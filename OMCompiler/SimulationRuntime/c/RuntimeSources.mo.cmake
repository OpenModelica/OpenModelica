encapsulated package RuntimeSources
  constant list<String> commonFiles={@COMMON_FILES@};
  constant list<String> commonHeaders={@COMMON_HEADERS@};
  constant list<String> fmi1Files={"fmi-export/fmu1_model_interface.c.inc","fmi-export/fmu1_model_interface.h"};
  constant list<String> fmi2Files={"fmi-export/fmu2_model_interface.c.inc","fmi-export/fmu2_model_interface.h", "fmi-export/fmu_read_flags.c.inc", "fmi-export/fmu_read_flags.h"};
  constant list<String> defaultFileSuffixes={".c", "_functions.c", "_records.c", "_01exo.c", "_02nls.c", "_03lsy.c", "_04set.c", "_05evt.c", "_06inz.c", "_07dly.c", "_08bnd.c", "_09alg.c", "_10asr.c", "_11mix.c", "_12jac.c", "_13opt.c", "_14lnz.c", "_15syn.c", "_16dae.c", "_17inl.c", "_18spd.c", "_init_fmu.c", "_FMU.c"};
  constant list<String> cvodeFiles={"sundials/cvode/cvode.h", "sundials/cvode/cvode_band.h", "sundials/cvode/cvode_bandpre.h", "sundials/cvode/cvode_bbdpre.h", "sundials/cvode/cvode_dense.h", "sundials/cvode/cvode_diag.h", "sundials/cvode/cvode_direct.h", "sundials/cvode/cvode_impl.h", "sundials/cvode/cvode_klu.h", "sundials/cvode/cvode_lapack.h", "sundials/cvode/cvode_sparse.h", "sundials/cvode/cvode_spbcgs.h", "sundials/cvode/cvode_spgmr.h", "sundials/cvode/cvode_spils.h", "sundials/cvode/cvode_sptfqmr.h"};
  constant list<String> sundialsFlies={"sundials/sundials/sundials_band.h", "sundials/sundials/sundials_config.h", "sundials/sundials/sundials_dense.h", "sundials/sundials/sundials_direct.h", "sundials/sundials/sundials_fnvector.h", "sundials/sundials/sundials_iterative.h", "sundials/sundials/sundials_lapack.h", "sundials/sundials/sundials_math.h", "sundials/sundials/sundials_nvector.h", "sundials/sundials/sundials_pcg.h", "sundials/sundials/sundials_sparse.h", "sundials/sundials/sundials_spbcgs.h", "sundials/sundials/sundials_spfgmr.h", "sundials/sundials/sundials_spgmr.h", "sundials/sundials/sundials_sptfqmr.h", "sundials/sundials/sundials_types.h"};
  constant list<String> nvectorFiles={"sundials/nvector/nvector_serial.h"};
  constant list<String> external3rdPartyFiles=listAppend(listAppend(cvodeFiles,sundialsFlies), nvectorFiles);
  constant list<String> dgesvFiles={@DGESV_FILES@, "./external_solvers/blaswrap.h", "./external_solvers/clapack.h", "./external_solvers/f2c.h"};
  constant list<String> cvodeRuntimeFiles={"./simulation/solver/cvode_solver.c"};
  constant list<String> lsFiles={@LS_FILES@};
  constant list<String> nlsFiles={@NLS_FILESCMINPACK_FILES@, "./external_solvers/cminpack.h", "./external_solvers/minpack.h"};
  constant list<String> mixedFiles={@MIXED_FILES@};
annotation(__OpenModelica_Interface="backend");
end RuntimeSources;

