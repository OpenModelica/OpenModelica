encapsulated package RuntimeSources
  constant list<String> commonFiles={COMMON_FILES};
  constant list<String> commonHeaders={COMMON_HEADERS};
  constant list<String> fmi1Files={"fmi-export/fmu1_model_interface.c.inc","fmi-export/fmu1_model_interface.h"};
  constant list<String> fmi2Files={"fmi-export/fmu2_model_interface.c.inc","fmi-export/fmu2_model_interface.h"};
  constant list<String> defaultFileSuffixes={".c", "_functions.c", "_records.c", "_01exo.c", "_02nls.c", "_03lsy.c", "_04set.c", "_05evt.c", "_06inz.c", "_07dly.c", "_08bnd.c", "_09alg.c", "_10asr.c", "_11mix.c", "_12jac.c", "_13opt.c", "_14lnz.c", "_15syn.c", "_16dae.c", "_17inl.c", "_init_fmu.c", "_FMU.c"};
  constant list<String> dgesvFiles={DGESV_FILES, "./external_solvers/blaswrap.h", "./external_solvers/clapack.h", "./external_solvers/f2c.h"};
  constant list<String> lsFiles={LS_FILES};
  constant list<String> nlsFiles={NLS_FILESCMINPACK_FILES, "./external_solvers/cminpack.h", "./external_solvers/minpack.h"};
  constant list<String> mixedFiles={MIXED_FILES};
annotation(__OpenModelica_Interface="backend");
end RuntimeSources;

