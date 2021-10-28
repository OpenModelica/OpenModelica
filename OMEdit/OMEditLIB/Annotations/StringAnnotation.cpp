#include "StringAnnotation.h"

StringAnnotation::StringAnnotation() = default;

StringAnnotation::StringAnnotation(const QString &str)
  : DynamicAnnotation(str)
{
}

void StringAnnotation::clear()
{
  mValue.clear();
}

StringAnnotation& StringAnnotation::operator= (const QString &value)
{
  mValue = value;
  setExp();
  return *this;
}

bool StringAnnotation::contains(const QString &str) const
{
  return mValue.contains(str);
}

int StringAnnotation::length() const
{
  return mValue.length();
}

QString& StringAnnotation::prepend(const QString &str)
{
  return mValue.prepend(str);
}

QString& StringAnnotation::prepend(QChar ch)
{
  return mValue.prepend(ch);
}

QString& StringAnnotation::replace(int position, int n, const QString &after)
{
  return mValue.replace(position, n, after);
}

QString& StringAnnotation::replace(int position, int n, QChar after)
{
  return mValue.replace(position, n, after);
}

QString& StringAnnotation::replace(const QRegExp &rx, const QString &after)
{
  return mValue.replace(rx, after);
}

QString& StringAnnotation::replace(const QRegularExpression &re, const QString &after)
{
  return mValue.replace(re, after);
}

QString StringAnnotation::toLower() const
{
  return mValue.toLower();
}

QString StringAnnotation::toUpper() const
{
  return mValue.toUpper();
}

FlatModelica::Expression StringAnnotation::toExp() const
{
  return FlatModelica::Expression(mValue);
}

void StringAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isString()) {
    mValue = exp.QStringValue();
  } else {
    mValue = exp.toQString();
  }
}
