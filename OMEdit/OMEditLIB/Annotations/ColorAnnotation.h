#ifndef COLORANNOTATION_H
#define COLORANNOTATION_H

#include <QColor>
#include "DynamicAnnotation.h"

class ColorAnnotation : public DynamicAnnotation
{
  public:
    ColorAnnotation();
    explicit ColorAnnotation(const QString &str);

    void clear() override;

    operator const QColor&() const { return mValue; }
    ColorAnnotation& operator= (const QColor &value);

    int red()   const { return mValue.red(); }
    int green() const { return mValue.green(); }
    int blue()  const { return mValue.blue(); }

    bool operator== (const QColor &c) const;
    bool operator!= (const QColor &c) const;

    FlatModelica::Expression toExp() const override;

  private:
    void fromExp(const FlatModelica::Expression &exp) override;

  private:
    QColor mValue;
};

#endif /* COLORANNOTATION_H */
