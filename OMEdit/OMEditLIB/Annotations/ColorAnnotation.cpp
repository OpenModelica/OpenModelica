#include "ColorAnnotation.h"

ColorAnnotation::ColorAnnotation()
  : mValue(0, 0, 0)
{
}

ColorAnnotation::ColorAnnotation(const QString &str)
  : DynamicAnnotation(str)
{
}

void ColorAnnotation::clear()
{
  mValue.setRgb(0, 0, 0);
}

ColorAnnotation& ColorAnnotation::operator= (const QColor &value)
{
  mValue = value;
  return *this;
}

bool ColorAnnotation::operator== (const QColor &c) const
{
  return mValue == c;
}

bool ColorAnnotation::operator!= (const QColor &c) const
{
  return mValue != c;
}

void ColorAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isArray()) {
    auto &elems = exp.elements();

    if (elems.size() == 3) {
      int c[3];

      for (int i = 0; i < 3; ++i) {
        c[i] = elems[i].isNumber() ? elems[i].intValue() : 0;
      }

      mValue.setRgb(c[0], c[1], c[2]);
    }
  }
}
