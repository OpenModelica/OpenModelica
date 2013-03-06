#ifndef SIMULATOR_H
#define SIMULATOR_H

typedef double Time;
/*! \brief This class represents a DEVS atomic model. */
class SimulatorQSS
{
public:
       Time e;
       Time tl;
       Time tn;
  double sigma;
       virtual void makeStep(Time)=0;
       virtual void update(Time)=0;
       virtual void init(Time, unsigned int i)=0;
       double ta(){return sigma;};
};

#endif

