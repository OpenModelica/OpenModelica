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
  setExp();
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

FlatModelica::Expression ColorAnnotation::toExp() const
{
  std::vector<FlatModelica::Expression> elems;
  elems.reserve(3);
  elems.emplace_back(FlatModelica::Expression(mValue.red()));
  elems.emplace_back(FlatModelica::Expression(mValue.green()));
  elems.emplace_back(FlatModelica::Expression(mValue.blue()));
  return FlatModelica::Expression(std::move(elems));
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
