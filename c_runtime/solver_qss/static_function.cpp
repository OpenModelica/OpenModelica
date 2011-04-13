#include "runtime.h"
#include "static_function.h"

StaticFunction::StaticFunction(int ord, double dqm, double dqr)
{
  order=ord;
  dQmin=dqm;
  dQrel=dqr;
}

StaticFunction::~StaticFunction()
{
  delete []out;
  delete []outdt;
  delete []out_dt;
  if (order>1) {
    delete []out_2dt;
    delete []out2dt;
  }
}

void StaticFunction::init(Time t, unsigned int i)
{
  dt=1e-8;
  index=i;
  sigma=1e-12;
  outVars=1;
       out = new double[outVars];
       outdt = new double[outVars];
        out_dt = new double[outVars];
        if (order>1) {
               out_2dt = new double[outVars]; 
    out2dt = new double[outVars]; 
  }
}
 
void StaticFunction::makeStep(Time t)
{
       function_staticBlocks(index,t,NULL,out);
       derX[0].setCoeff(0,out[0]);
       derX[0].sampledAt(t);
       sigma=INF;
}

void StaticFunction::update(Time t) 
{
       sigma=0;
}
