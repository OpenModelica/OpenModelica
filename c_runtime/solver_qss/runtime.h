#ifndef QSS_RUNTIME
#define QSS_RUNTIME
#include "simulation_runtime.h"
#include "simulation_input.h"
#include "simulation_init.h"
#include "simulation_events.h"
#include "simulation_result.h"
#include "simulation_result_empty.h"
#include "simulation_result_plt.h"
#include "simulation_result_csv.h"
#include "simulation_result_mat.h"


#include "qss_signal.h"
#include "simulator.h"
void function_staticBlocks(int,double,double*,double*);
double minposroot(double *coeff, int order);

extern QssSignal *X,*q,*derX,*alg,*zc;
extern char incidenceMatrix[];
extern int staticBlocks;
extern char inputMatrix[];
extern char outputMatrix[];

extern bool interactiveSimuation;
int
startInteractiveSimulation(int, char**);
int
startNonInteractiveSimulation(int, char**);
int
initRuntimeAndSimulation(int, char**);
void initializeOutputFilter(DATA* data, string variableFilter);
int initRuntimeAndSimulation(int, char**);
#endif

