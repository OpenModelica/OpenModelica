#include "runtime.h"

class CrossDetector: public Simulator
{

public:
  CrossDetector(int ord, double dqm, double dqr);
  virtual void init(Time t, unsigned int i);
  virtual void makeStep(Time t);
  virtual void update(Time t);

private:
  double dQmin,dQrel,dQ;
  unsigned int index;
  int order;
  int sw;
};
