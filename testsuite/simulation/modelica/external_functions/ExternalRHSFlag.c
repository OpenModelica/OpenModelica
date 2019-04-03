#include <stdio.h>

extern int RHSFinalFlag;
//#include "ExternalRHSFlag.h"

double ExternalRHSFunc(double x)
{
  double res;
  res = (x-1.0)*(x+2.0);

  if (RHSFinalFlag){
    puts("RHSFinlaFlag set!");
  }
  else{
    puts("RHSFinlaFlag NOT set!");
  }
  return res;
}
