#include "PointAnnotation.h"

PointAnnotation::PointAnnotation() = default;

PointAnnotation::PointAnnotation(const QString &str)
  : DynamicAnnotation(str)
{
}

void PointAnnotation::clear()
{
  mValue = QPointF(0.0, 0.0);
}

PointAnnotation& PointAnnotation::operator= (const QPointF &value)
{
  mValue = value;
  setExp();
  return *this;
}

bool PointAnnotation::operator== (const QPointF &c) const
{
  return mValue == c;
}

bool PointAnnotation::operator!= (const QPointF &c) const
{
  return mValue != c;
}

FlatModelica::Expression PointAnnotation::toExp() const
{
  std::vector<FlatModelica::Expression> elems;
  elems.emplace_back(mValue.x());
  elems.emplace_back(mValue.y());
  return FlatModelica::Expression(std::move(elems));
}

void PointAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isArray()) {
    auto &elems = exp.elements();

    if (elems.size() >= 2) {
      mValue.setX(elems[0].isNumber() ? elems[0].realValue() : 0.0);
      mValue.setY(elems[1].isNumber() ? elems[1].realValue() : 0.0);
    }
  }
}

