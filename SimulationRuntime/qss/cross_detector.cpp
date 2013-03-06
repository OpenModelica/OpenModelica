#include "cross_detector.h"

CrossDetector::CrossDetector(int ord, double dqm, double dqr)
{
  order=ord;
  dQmin=dqm;
  dQrel=dqr;
}

void CrossDetector::init(Time t, unsigned int i)
{
  sigma=INF;
  sw=0;
  index=i;
}

void CrossDetector::makeStep(Time t)
{
 /* zc[index].advanceTo(t);
  sw=-sw;
  zc[index].setCoeff(0,1e-20*sw);
  sigma=zc[index].minPosRoot();
  if (zc[index].coeff(1)>0) {
      set_condition_to(index,false);
    } else if (zc[index].coeff(1)<0) {
      set_condition_to(index,true);
    } else if (zc[index].coeff(2)>0) {
      set_condition_to(index,false);
    } else {
      set_condition_to(index,true);
    }
    //cout << "ZC(" << index << ") fired at " << t << " setting cond to=" << condition(index) << endl;
    function_updateDepend(t,index);
    */
}

void CrossDetector::update(Time t)
{
  /*
  if (zc[index].value()>0)
    set_condition_to(index,false);
  else
    set_condition_to(index,true);
  */
}

