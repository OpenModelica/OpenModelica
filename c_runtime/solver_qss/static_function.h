#include <iostream>
#include <list>
#include "runtime.h"
#include "simulation_runtime.h"

class StaticFunction: public Simulator
{
public:
  StaticFunction(int ord, double dqm, double dqr, int devsIndex);
  ~StaticFunction();
  virtual void init(Time t, unsigned int i);
  virtual void makeStep(Time t);
  virtual void update(Time t);
  void setCrossing(int i)
  {
    crossFunction=true;
    indexCrossing=i;
  }

private:
  void advanceInputs(Time t);
  void writeOutputs(Time t);

  double dQmin,dQrel,dQ;
  double *out,*outdt,*out_dt,*out2dt,*out_2dt,*inp;
  unsigned int index;
  int order;
  unsigned int outVars;
  list<int> inputs;
  list<int> computes;
  double dt;
  int devsIndex;
  bool crossFunction;
  int indexCrossing;
};
