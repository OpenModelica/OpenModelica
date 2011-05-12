#include "simulator.h"
#include "runtime.h"
#include "simulation_runtime.h"


class IntegratorQSS: public Simulator
{
public:
  IntegratorQSS(double dqm, double dqr);
  virtual void init(Time t, unsigned int i);
  virtual void makeStep(Time t);
  virtual void update(Time t);
private:
  unsigned int state;
  unsigned int index;
  double dQmin;
  double dQrel;
  double dQ;
  int order;
};

class IntegratorQSS2: public Simulator
{
public:
  IntegratorQSS2(double dqm, double dqr);
  virtual void init(Time t, unsigned int i);
  virtual void makeStep(Time t);
  virtual void update(Time t);
private:
  unsigned int state;
  unsigned int index;
  double dQmin;
  double dQrel;
  double dQ;
  int order;
};

