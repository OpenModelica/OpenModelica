#include "BooleanAnnotation.h"

BooleanAnnotation::BooleanAnnotation()
{
  clear();
}

void BooleanAnnotation::clear()
{
  mValue = true;
}

BooleanAnnotation& BooleanAnnotation::operator= (bool value)
{
  mValue = value;
  setExp();
  return *this;
}

FlatModelica::Expression BooleanAnnotation::toExp() const
{
  return FlatModelica::Expression(mValue);
}

void BooleanAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isBooleanish()) {
    mValue = exp.boolValue();
  }
}
