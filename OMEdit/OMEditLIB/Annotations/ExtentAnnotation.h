#ifndef EXTENTANNOTATION_H
#define EXTENTANNOTATION_H

#include <QPointF>
#include <QVector>
#include "DynamicAnnotation.h"

class ExtentAnnotation : public DynamicAnnotation
{
  public:
    ExtentAnnotation();

    void clear() override;

    operator const QVector<QPointF>&() const { return mValue; }
    ExtentAnnotation& operator= (const QVector<QPointF> &value);
    bool operator== (const ExtentAnnotation &extent) const;

    const QPointF& at(int i) const { return mValue.at(i); }
    int size() const { return mValue.size(); }
    void replace(int i, const QPointF &value) { mValue.replace(i, value); setExp(); }

    auto begin()       { return mValue.begin(); }
    auto begin() const { return mValue.begin(); }
    auto end()         { return mValue.end(); }
    auto end() const   { return mValue.end(); }

    FlatModelica::Expression toExp() const override;

  private:
    void fromExp(const FlatModelica::Expression &exp) override;

  private:
    QVector<QPointF> mValue = QVector<QPointF>(2);
};

#endif /* EXTENTANNOTATION_H */
