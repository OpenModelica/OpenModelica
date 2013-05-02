#ifndef QSS_SIGNAL
#define QSS_SIGNAL
#include <math.h>
#define INF 1e20

double minposroot(double *,int);
class QssSignal
{
  public:
  QssSignal()
  {
    _order=0;
    for (int i=0;i<10;++i)
      _coeff[i]=0.0;
  }
  QssSignal(unsigned int order,double c0)
  {
    _order = 1;
    _coeff[0]=c0;
  };
  QssSignal(double c0,double c1)
  {
    _order = 2;
    _coeff[0]=c0;
    _coeff[1]=c1;
  };
  QssSignal(double c0,double c1,double c2)
  {
    _order = 3;
    _coeff[0]=c0;
    _coeff[1]=c1;
    _coeff[2]=c2;
  };
  QssSignal(unsigned int ord)
  {
    for (int i=0;i<10;++i)
      _coeff[i]=0.0;
    _order = ord;
  }
  void advanceBy(double dt) {
    _coeff[0]=_coeff[0]+dt*_coeff[1]+dt*dt*_coeff[2]+dt*dt*dt*_coeff[3];
    _coeff[1]=_coeff[1]+2*_coeff[2]*dt+3*_coeff[3]*dt*dt;
    _coeff[2]=_coeff[2]+3*_coeff[3]*dt;
  };
  double value() {
    return _coeff[0];
  }
  void setCoeff(unsigned int c, double v)
  {
    _coeff[c] = v;
  }
  inline double coeff(unsigned int c) const
  {
    return _coeff[c];
  }
  QssSignal offsetBy(double offset) const {
    QssSignal res(*this);
    res.setCoeff(0,res.coeff(0)+offset);
    return res;
  }
  QssSignal operator -(const QssSignal &qs) const
  {
    unsigned max_order = (qs.order() > order() ? qs.order() : order());
    QssSignal res(max_order);
    for (unsigned int i=0;i<=max_order;++i)
      res.setCoeff(i,coeff(i)-qs.coeff(i));
    return res;
  }
  double minPosRoot()
  {
    return minposroot(_coeff,_order);
  }
  unsigned int order() const { return _order; };
  void setOrder(unsigned int ord) { _order = ord; };
  QssSignal & operator =(const QssSignal &other)
  {
    if (this != &other)
      for (unsigned int i=0;i<=_order;++i)
  _coeff[i] = other.coeff(i);
    return *this;
  }
  void sampledAt(double t)
  {
    _sampledAt = t;
  }
  void advanceTo(double t)
  {
    advanceBy(t-_sampledAt);
  }
  double valueAt(double t)
  {
    const double dt=t-_sampledAt;
    if (_order<=1)
      return _coeff[0];
    if (_order==2)
      return _coeff[0] + _coeff[1]*dt;
    if (_order==3)
      return _coeff[0] + _coeff[1]*dt + _coeff[2]*dt*dt ;
    if (_order==4)
      return _coeff[0] + _coeff[1]*dt + _coeff[2]*dt*dt + _coeff[3]*dt*dt*dt;
  }
  /*
  void dump()
  {
    printf("{");
    for (int i=0;i<_order;++i)
      printf("%g%s",coeff(i),(i+1==_order ? "" : ","));
    printf("}\n");
  }
  */
  private:
    double _coeff[10];
    unsigned int _order;
    double _sampledAt;
};
#endif
