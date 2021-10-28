#ifndef REALANNOTATION_H
#define REALANNOTATION_H

#include "DynamicAnnotation.h"

class RealAnnotation : public DynamicAnnotation
{
  public:
    RealAnnotation();
    explicit RealAnnotation(const QString &str);

    void clear() override;

    operator qreal() const { return mValue; }
    RealAnnotation& operator= (qreal value);

    FlatModelica::Expression toExp() const override;

  private:
    void fromExp(const FlatModelica::Expression &exp) override;

  private:
    qreal mValue;
};

#endif /* REALANNOTATION_H */
