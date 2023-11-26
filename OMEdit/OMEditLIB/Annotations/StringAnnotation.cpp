/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
#include "StringAnnotation.h"

StringAnnotation::StringAnnotation(const QString &str)
  : mValue(str)
{
  setExp();
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

bool StringAnnotation::isEmpty() const
{
  return mValue.isEmpty();
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
#if (QT_VERSION >= QT_VERSION_CHECK(6, 0, 0))
  mValue = rx.replaceIn(mValue, after);
#else
  mValue.replace(rx, after);
#endif
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

int StringAnnotation::compare(const QString &other, Qt::CaseSensitivity cs) const
{
  return mValue.compare(other, cs);
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
