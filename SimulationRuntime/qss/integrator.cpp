#include "integrator.h"
#include "qss_signal.h"

IntegratorQSS::IntegratorQSS(double dqm, double dqr)
{
  order=1;
  dQmin=dqm;
  dQrel=dqr;
}

void IntegratorQSS::init(Time t, unsigned int i)
{
  index=i;
  for (int j=0;j<inputRows;j++)
  {
    if (inputMatrix[j*2]==index) {
      //cout << "Integrator " << index << " computes state " << stateNumber(inputMatrix[j*2+1]) <<endl;
      state = stateNumber(inputMatrix[j*2+1]);
      break;
    }
  }

  sigma=0;
  X[state].setCoeff(0,globalData->states[state]);
  q[state].setOrder(order-1);
  X[state].setOrder(order);
  derX[state].setOrder(order);
  q[state].setCoeff(0,X[state].value());
  X[state].sampledAt(t);
  q[state].sampledAt(t);
  dQ = fabs(X[state].value())*dQrel;
  if (dQ<dQmin)
    dQ = dQmin;
}

void IntegratorQSS::makeStep(Time t)
{
  X[state].advanceBy(sigma);
  X[state].sampledAt(t);
  q[state].sampledAt(t);
  q[state].setCoeff(0,X[state].value());
  dQ = fabs(X[state].value())*dQrel;
  if (dQ<dQmin)
    dQ = dQmin;
  if (X[state].coeff(1)==0.0)
    sigma = INF;
  else
    sigma = fabs(dQ/X[state].coeff(1));
}

void IntegratorQSS::update(Time t) {
  X[state].advanceTo(t);
  X[state].setCoeff(1,derX[state].coeff(0));
  QssSignal diff = q[state]- X[state];
  if (sigma>0) {
    if (X[state].coeff(1)==0) {
      sigma=INF;
      return;
    }
    const double sigmaUpper = diff.offsetBy(dQ).minPosRoot();
    const double sigmaLower = diff.offsetBy(-dQ).minPosRoot();
    sigma=std::min(sigmaUpper,sigmaLower);
    if (fabs(X[state].value()-q[state].value())>dQ)
      sigma=0.0;
  }
  X[state].sampledAt(t);
}


/// QSS 2
IntegratorQSS2::IntegratorQSS2(double dqm, double dqr)
{
  order=2;
  dQmin=dqm;
  dQrel=dqr;
}

void IntegratorQSS2::init(Time t, unsigned int i)
{
  index=i;
  for (int j=0;j<inputRows;j++)
  {
    if (inputMatrix[j*2]==index) {
      cout << "Integrator " << index << " computes state " << stateNumber(inputMatrix[j*2+1]) <<endl;
      state = stateNumber(inputMatrix[j*2+1]);
      break;
    }
  }

  sigma=0;
  X[state].setCoeff(0,globalData->states[state]);
  q[state].setOrder(order-1);
  X[state].setOrder(order);
  derX[state].setOrder(order);
  q[state].setCoeff(0,X[state].value());
  X[state].sampledAt(t);
  q[state].sampledAt(t);
  dQ = fabs(X[state].value())*dQrel;
  if (dQ<dQmin)
    dQ = dQmin;
}

void IntegratorQSS2::makeStep(Time t)
{
  X[state].advanceBy(sigma);
  X[state].sampledAt(t);
  q[state].sampledAt(t);
  q[state].setCoeff(0,X[state].value());
  q[state].setCoeff(1,X[state].coeff(1));
  dQ = fabs(X[state].value())*dQrel;
  if (dQ<dQmin)
    dQ = dQmin;
  if (X[state].coeff(2)==0.0)
    sigma = INF;
  else
    sigma = sqrt(fabs(dQ/X[state].coeff(2)));
}

void IntegratorQSS2::update(Time t) {
  X[state].advanceTo(t);
  X[state].setCoeff(1,derX[state].coeff(0));
  X[state].setCoeff(2,derX[state].coeff(1)/2);
  if (sigma>0) {
    q[state].advanceTo(t);
    q[state].sampledAt(t);
    QssSignal diff = q[state]- X[state];
    const double sigmaUpper = diff.offsetBy(dQ).minPosRoot();
    const double sigmaLower = diff.offsetBy(-dQ).minPosRoot();
    sigma=std::min(sigmaUpper,sigmaLower);
    if (fabs(X[state].value()-q[state].value())>dQ)
      sigma=0.0;
  }
  X[state].sampledAt(t);
}


