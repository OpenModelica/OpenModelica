#ifndef STRINGANNOTATION_H
#define STRINGANNOTATION_H

#include "DynamicAnnotation.h"

class StringAnnotation : public DynamicAnnotation
{
  public:
    StringAnnotation();
    explicit StringAnnotation(const QString &str);

    void clear() override;

    operator const QString&() const { return mValue; }
    StringAnnotation& operator= (const QString &value);

    bool contains(const QString &str) const;
    int length() const;
    QString& prepend(const QString &str);
    QString& prepend(QChar ch);
    QString& replace(int position, int n, const QString &after);
    QString& replace(int position, int n, QChar after);
    QString& replace(const QRegExp &rx, const QString &after);
    QString& replace(const QRegularExpression &re, const QString &after);
    QString toLower() const;
    QString toUpper() const;

    FlatModelica::Expression toExp() const override;

  private:
    void fromExp(const FlatModelica::Expression &exp) override;

  private:
    QString mValue;
};

#endif /* STRINGANNOTATION_H */
