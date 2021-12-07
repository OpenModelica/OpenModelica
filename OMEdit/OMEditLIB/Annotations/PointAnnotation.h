#ifndef POINTANNOTATION_H
#define POINTANNOTATION_H

#include <QPointF>
#include "DynamicAnnotation.h"

class Element;

class PointAnnotation : public DynamicAnnotation
{
  public:
    PointAnnotation();
    explicit PointAnnotation(const QString &str);

    void clear() override;

    operator const QPointF&() const { return mValue; }
    PointAnnotation& operator= (const QPointF &value);

    qreal x() const { return mValue.x(); }
    qreal y() const { return mValue.y(); }

    bool operator== (const QPointF &c) const;
    bool operator!= (const QPointF &c) const;

    FlatModelica::Expression toExp() const override;

  private:
    void fromExp(const FlatModelica::Expression &exp) override;

  private:
    QPointF mValue;
};

#endif /* POINTANNOTATION_H */
