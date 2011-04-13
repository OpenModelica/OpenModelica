#include "simulator.h"
#include "qss_signal.h"
#include "simulation_runtime.h"
#include "sampler.h"
#include "runtime.h"

Sampler::Sampler(long numSteps,double start,double stop)
{
       if (numSteps==0)
              numSteps=2000;
       step=(stop-start)/numSteps;
}

Sampler::~Sampler()
{
}

void Sampler::init(Time t, unsigned int i)
{
  sigma=0;
}

void Sampler::makeStep(Time t)
{
  sigma=step;
  // Update globalData for emit
  for (int i=0;i<globalData->nStates;i++) {
    globalData->states[i]=q[i].valueAt(t);
    globalData->statesDerivatives[i]=derX[i].valueAt(t);
  }
       // Emit this timestep
  sim_result->emit();

  sigma=step;
}

void Sampler::update(Time t) {
       sigma=0;
}
