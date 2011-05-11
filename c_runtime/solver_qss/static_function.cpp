#include "runtime.h"
#include "static_function.h"

StaticFunction::StaticFunction(int ord, double dqm, double dqr,int in)
{
  order=ord;
  dQmin=dqm;
  dQrel=dqr;
  devsIndex=in;
  crossFunction=false;
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
  if (crossFunction)
  {
    zc[indexCrossing].sampledAt(t);
    zc[indexCrossing].setCoeff(0,out[0]);
    return;
  }
  for (;it!=computes.end();it++,i++)
  {
    if (isState(*it))
    {
      cout << "Block " << devsIndex << " writes der " << stateNumber(*it) << endl;
      derX[stateNumber(*it)].sampledAt(t);
      derX[stateNumber(*it)].setCoeff(0,out[i]);
      // If order>1...
    } else {
      cout << "Block " << devsIndex << " writes algebraic " << algNumber(*it) << endl;
      alg[algNumber(*it)].sampledAt(t);
      alg[algNumber(*it)].setCoeff(0,out[i]);
    }
  } 
}

void StaticFunction::advanceInputs(Time t)
{
  int i=0;
  std::list<int>::iterator it=inputs.begin();
  for (;it!=inputs.end();it++,i++)
  {
    if (isState(*it))
    {
      cout << "Block " << devsIndex << " uses state " << stateNumber(*it) << endl;
      inp[i] = q[stateNumber(*it)].valueAt(t);
    } else {
      cout << "Block " << devsIndex << " uses state " << algNumber(*it) << endl;
      inp[i] = alg[algNumber(*it)].valueAt(t);
    }
  }
}
