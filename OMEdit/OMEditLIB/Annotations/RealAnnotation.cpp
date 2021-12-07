#include "RealAnnotation.h"

RealAnnotation::RealAnnotation()
  : mValue(0.0)
{
}

RealAnnotation::RealAnnotation(const QString &str)
  : DynamicAnnotation(str)
{
}

void RealAnnotation::clear()
{
  mValue = 0.0;
}

RealAnnotation& RealAnnotation::operator= (qreal value)
{
  mValue = value;
  setExp();
  return *this;
}

FlatModelica::Expression RealAnnotation::toExp() const
{
  return FlatModelica::Expression(mValue);
}

void RealAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isNumber()) {
    mValue = exp.realValue();
  }
}
