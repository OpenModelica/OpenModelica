#include "integrator.h"
#include "qss_signal.h"
#include "simulation_runtime.h"


IntegratorQSS::IntegratorQSS(double dqm, double dqr)
{
  order=1;
  dQmin=dqm;
  dQrel=dqr;
}

void IntegratorQSS::init(Time t, unsigned int i)
{
	index=i;
  sigma=0;
  X[index].setCoeff(0,globalData->states[index]);
  q[index].setOrder(order-1);
  X[index].setOrder(order);
  derX[index].setOrder(order);
  q[index].setCoeff(0,X[index].value()); 
  X[index].sampledAt(t);
  q[index].sampledAt(t);
  dQ = fabs(X[index].value())*dQrel;
  if (dQ<dQmin)
    dQ = dQmin;
}

void IntegratorQSS::makeStep(Time t)
{
  X[index].advanceBy(sigma);
  X[index].sampledAt(t);
  q[index].sampledAt(t);
  q[index].setCoeff(0,X[index].value()); 
  dQ = fabs(X[index].value())*dQrel;
  if (dQ<dQmin)
    dQ = dQmin;
  if (X[index].coeff(1)==0.0)
    sigma = INF;
  else 
    sigma = fabs(dQ/X[index].coeff(1));
}

void IntegratorQSS::update(Time t) {
  X[index].advanceTo(t);
  X[index].setCoeff(1,derX[index].coeff(0));
  QssSignal diff = q[index]- X[index];
  if (sigma>0) {
    if (X[index].coeff(1)==0) {
      sigma=INF;
      return;
    }
  	const double sigmaUpper = diff.offsetBy(dQ).minPosRoot();
  	const double sigmaLower = diff.offsetBy(-dQ).minPosRoot();
  	sigma=std::min(sigmaUpper,sigmaLower);
  	if (fabs(X[index].value()-q[index].value())>dQ)
    	sigma=0.0;
  }
	X[index].sampledAt(t);
}
