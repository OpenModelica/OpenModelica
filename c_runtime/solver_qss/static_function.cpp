#include "runtime.h"
#include "static_function.h"

StaticFunction::StaticFunction(int ord, double dqm, double dqr,int in)
{
  order=ord;
  dQmin=dqm;
  dQrel=dqr;
  devsIndex=in;
  for (int i=0;i<inputRows;i++)
  {
    if (inputMatrix[i*2]==devsIndex) {
      cout << "Block " << devsIndex << " has as input var " << inputMatrix[i*2+1] <<endl;
      inputs.push_back(inputMatrix[i*2+1]);
    }
  }
  for (int i=0;i<outputRows;i++)
  {
    if (outputMatrix[i*2]==devsIndex) {
      cout << "Block " << devsIndex << " has as output var " << outputMatrix[i*2+1] <<endl;
      computes.push_back(outputMatrix[i*2+1]);
    }
  }
}

StaticFunction::~StaticFunction()
{
  delete []inp;
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
  inp = new double[outVars];
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
  function_staticBlocks(index,t,inp,out);
  derX[0].setCoeff(0,out[0]);
  derX[0].sampledAt(t);

  if (order>1) 
  {
    advanceInputs(t-dt);
    function_staticBlocks(index,t,inp,out_dt);

    advanceInputs(t+dt);
    function_staticBlocks(index,t+dt,inp,outdt);
    
  }

  writeOutputs(t);
  sigma=INF;
  // Take back the time
  globalData->timeValue=t;
}

void StaticFunction::update(Time t) 
{
  sigma=0;
}

void StaticFunction::writeOutputs(Time t)
{
  std::list<int>::iterator it=computes.begin();
  int i=0;
  for (;it!=computes.end();it++,i++)
  {
    if (*it<globalData->nStates) {
      derX[*it].sampledAt(t);  
      derX[*it].setCoeff(0,out[i]);
      // If order>1...
    }
  } 
}

void StaticFunction::advanceInputs(Time t)
{
  std::list<int>::iterator it=inputs.begin();
  for (; it!=inputs.end();it++)
  {
    if (*it<globalData->nStates) 
    {
      inp[*it] = q[*it].valueAt(t);
    }
  }
}
