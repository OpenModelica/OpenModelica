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
  mValue.prepend(str);
  setExp();
  return mValue;
}

QString& StringAnnotation::prepend(QChar ch)
{
  mValue.prepend(ch);
  setExp();
  return mValue;
}

QString& StringAnnotation::replace(int position, int n, const QString &after)
{
  mValue.replace(position, n, after);
  setExp();
  return mValue;
}

QString& StringAnnotation::replace(int position, int n, QChar after)
{
  mValue.replace(position, n, after);
  setExp();
  return mValue;
}

QString& StringAnnotation::replace(const QRegExp &rx, const QString &after)
{
  mValue.replace(rx, after);
  setExp();
  return mValue;
}

QString& StringAnnotation::replace(const QRegularExpression &re, const QString &after)
{
  mValue.replace(re, after);
  setExp();
  return mValue;
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
