#include "simulator.h"
#include "qss_signal.h"
#include "simulation_runtime.h"

int functionDAE_output();

class Sampler: public SimulatorQSS
{
public:
  Sampler(long numSteps,double start,double stop);
  ~Sampler();
  virtual void init(Time t, unsigned int i);
  virtual void makeStep(Time t);
  virtual void update(Time t);

private:
  double step;
  double *old_dX;
  double *old_q;
  double *old_alg;
};

