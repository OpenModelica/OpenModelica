#include "qss_signal.h"
#include "simulator.h"
void function_staticBlocks(int,double,double*,double*);
double minposroot(double *coeff, int order);

extern QssSignal *X,*q,*derX,*alg,*zc;
extern char *updateMatrix;
extern char *computesMatrix;
