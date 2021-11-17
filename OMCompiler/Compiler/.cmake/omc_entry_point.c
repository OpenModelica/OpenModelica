/* This is an automatically generated entry point to a MetaModelica function */

#if defined(__cplusplus)
extern "C" {
#endif

#include <meta/meta_modelica.h>
#include <stdio.h>

// CMake will define this on the compile command line if we
// are building a shared library.
// While dllexport and dllimport usually need more care (like a proper
// header to use for importing ...), this is
// enough for us. The library OpenModelicaCompiler is used by us only
// and mingw does not require corresponding dllimports. We will revisit
// it for Visual Studio later.
#if defined(OpenModelicaCompiler_EXPORTS) && defined(WIN32)
#  define OPENMODELICACOMPILER_EXPORT __declspec(dllexport)
#else
#  define OPENMODELICACOMPILER_EXPORT
#endif




extern void
#if defined(OMC_GENERATE_RELOCATABLE_CODE)
(*omc_Main_main)
#else
omc_Main_main
#endif
(threadData_t*,modelica_metatype);

#ifdef _OPENMP
#include<omp.h>
/* Hack to make gcc-4.8 link in the OpenMP runtime if -fopenmp is given */
int (*force_link_omp)(void) = omp_get_num_threads;
#endif

static int rml_execution_failed()
{
  fflush(NULL);
  fprintf(stderr, "Execution failed!\n");
  fflush(NULL);
  return 1;
}

OPENMODELICACOMPILER_EXPORT int __omc_main(int argc, char **argv)
{
  MMC_INIT(0);
  {
  void *lst = mmc_mk_nil();
  int i = 0;

  for (i=argc-1; i>0; i--) {
    lst = mmc_mk_cons(mmc_mk_scon(argv[i]), lst);
  }

  {
    MMC_TRY_TOP()

    MMC_TRY_STACK()

    omc_Main_main(threadData, lst);

    MMC_ELSE()
    rml_execution_failed();
    fprintf(stderr, "Stack overflow detected and was not caught.\nSend us a bug report at https://trac.openmodelica.org/OpenModelica/newticket\n    Include the following trace:\n");
    printStacktraceMessages();
    fflush(NULL);
    return 1;
    MMC_CATCH_STACK()

    MMC_CATCH_TOP(return rml_execution_failed());
  }
  }

  fflush(NULL);
  EXIT(0);
  return 0;
}

#if defined(__cplusplus)
} /* end extern "C" */
#endif

