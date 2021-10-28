#ifndef EXTENTANNOTATION_H
#define EXTENTANNOTATION_H

#include <QPointF>
#include <QList>
#include "DynamicAnnotation.h"

class ExtentAnnotation : public DynamicAnnotation
{
  public:
    ExtentAnnotation();
    explicit ExtentAnnotation(const QString &str);

    void clear() override;

    operator const QList<QPointF>&() const { return mValue; }
    ExtentAnnotation& operator= (const QList<QPointF> &value);

    const QPointF& at(int i) const { return mValue.at(i); }
    int size() const { return mValue.size(); }
    void append(const QPointF &value) { mValue.append(value); }
    void replace(int i, const QPointF &value) { mValue.replace(i, value); }

    auto begin()       { return mValue.begin(); }
    auto begin() const { return mValue.begin(); }
    auto end()         { return mValue.end(); }
    auto end() const   { return mValue.end(); }

    FlatModelica::Expression toExp() const override;

  private:
    void fromExp(const FlatModelica::Expression &exp) override;

  private:
    QList<QPointF> mValue;
};

#endif /* EXTENTANNOTATION_H */
