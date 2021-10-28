#include <algorithm>
#include <QDebug>

#include "ExtentAnnotation.h"

ExtentAnnotation::ExtentAnnotation() = default;

ExtentAnnotation::ExtentAnnotation(const QString &str)
  : DynamicAnnotation(str)
{
}

void ExtentAnnotation::clear()
{
  mValue.clear();
}

ExtentAnnotation& ExtentAnnotation::operator= (const QList<QPointF> &value)
{
  mValue = value;
  setExp();
  return *this;
}

FlatModelica::Expression ExtentAnnotation::toExp() const
{
  std::vector<FlatModelica::Expression> elems;

  for (auto &p: mValue) {
    std::vector<FlatModelica::Expression> point;
    point.emplace_back(p.x());
    point.emplace_back(p.y());
    elems.emplace_back(std::move(point));
  }

  return FlatModelica::Expression(std::move(elems));
}

void ExtentAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isArray()) {
    auto &elems = exp.elements();

    for (size_t i = 0u; i < std::min(elems.size(), decltype(elems.size()){2}); ++i) {
      auto &point = elems[i].elements();

      if (point.size() >= 2) {
        mValue.replace(i, QPointF(
          point[0].isNumber() ? point[0].realValue() : 0.0,
          point[1].isNumber() ? point[1].realValue() : 0.0
        ));
      }
    }
  }
}
