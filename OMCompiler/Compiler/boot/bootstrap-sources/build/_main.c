#if defined(__cplusplus)
extern "C" {
#endif
#if defined(OMC_ENTRYPOINT_STATIC)
#include <stdio.h>
#include <openmodelica.h>
DLLImport extern int __omc_main(int argc, char **argv);
int main(int argc, char **argv)
{
return __omc_main(argc, argv);
}
#else
#include <meta/meta_modelica.h>
#include <stdio.h>
extern void
#if defined(OMC_GENERATE_RELOCATABLE_CODE)
(*omc_Main_main)
#else
omc_Main_main
#endif
(threadData_t*,modelica_metatype);
void (*omc_assert)(threadData_t*,FILE_INFO info,const char *msg,...) __attribute__((noreturn)) = omc_assert_function;
void (*omc_assert_warning)(FILE_INFO info,const char *msg,...) = omc_assert_warning_function;
void (*omc_terminate)(FILE_INFO info,const char *msg,...) = omc_terminate_function;
void (*omc_throw)(threadData_t*) __attribute__ ((noreturn)) = omc_throw_function;
#ifdef _OPENMP
#include<omp.h>
int (*force_link_omp)(void) = omp_get_num_threads;
#endif
static int rml_execution_failed()
{
fflush(NULL);
fprintf(stderr, "Execution failed!\n");
fflush(NULL);
return 1;
}
DLLExport int __omc_main(int argc, char **argv)
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
#endif
#if defined(__cplusplus)
}
#endif
