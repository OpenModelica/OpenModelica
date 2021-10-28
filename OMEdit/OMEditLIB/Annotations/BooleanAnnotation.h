#ifndef BOOLEANANNOTATION_H
#define BOOLEANANNOTATION_H

#include "DynamicAnnotation.h"

class BooleanAnnotation : public DynamicAnnotation
{
  public:
    BooleanAnnotation();
    explicit BooleanAnnotation(const QString &str);

    void clear() override;

    operator bool() const { return mValue; }
    BooleanAnnotation& operator= (bool value);

    FlatModelica::Expression toExp() const override;

  private:
    void fromExp(const FlatModelica::Expression &exp) override;

  private:
    bool mValue;
};

#endif /* BOOLEANANNOTATION_H */
