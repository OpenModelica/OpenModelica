#include <algorithm>
#include <QDebug>

#include "Element/Element.h"
#include "Plotting/VariablesWidget.h"
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
  return *this;
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
