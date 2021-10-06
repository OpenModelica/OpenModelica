#include "BooleanAnnotation.h"

BooleanAnnotation::BooleanAnnotation()
  : mValue(true)
{
}

BooleanAnnotation::BooleanAnnotation(const QString &str)
  : DynamicAnnotation(str)
{
}

void BooleanAnnotation::clear()
{
  mValue = true;
}

BooleanAnnotation& BooleanAnnotation::operator= (bool value)
{
  mValue = value;
  return *this;
}

void BooleanAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isBooleanish()) {
    mValue = exp.boolValue();
  }
}
