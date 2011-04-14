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
  advanceInputs(t);
  function_staticBlocks(index,t,NULL,out);
  writeOutputs(t);
  sigma=INF;
}

void StaticFunction::update(Time t) 
{
  sigma=0;
}

void StaticFunction::writeOutputs(Time t)
{
  for (int i=0; i<globalData->nStates;i++)
  {
    if (outputMatrix[(globalData->nStates+index)*globalData->nStates +i])
    {
      derX[i].setCoeff(0,globalData->statesDerivatives[i]);
      derX[i].sampledAt(t);
    }
  }
}

void StaticFunction::advanceInputs(Time t)
{
  for (int i=0; i<globalData->nStates;i++)
  {
    if (inputMatrix[(globalData->nStates+index)*globalData->nStates +i])
    {
      globalData->states[i] = q[i].valueAt(t);
    }
  }
}
