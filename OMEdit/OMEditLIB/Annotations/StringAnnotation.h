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
#ifndef STRINGANNOTATION_H
#define STRINGANNOTATION_H

#include <QRegExp>

#include "DynamicAnnotation.h"

class StringAnnotation : public DynamicAnnotation
{
  public:
    StringAnnotation() = default;
    StringAnnotation(const QString &str);

    void clear() override;

    operator const QString&() const { return mValue; }
    StringAnnotation& operator= (const QString &value);

    bool contains(const QString &str) const;
    bool isEmpty() const;
    int length() const;
    QString& prepend(const QString &str);
    QString& prepend(QChar ch);
    QString& replace(int position, int n, const QString &after);
    QString& replace(int position, int n, QChar after);
    QString& replace(const QRegExp &rx, const QString &after);
    QString& replace(const QRegularExpression &re, const QString &after);
    QString toLower() const;
    QString toUpper() const;
    int compare(const QString &other, Qt::CaseSensitivity cs = Qt::CaseSensitive) const;

    FlatModelica::Expression toExp() const override;

  private:
    void fromExp(const FlatModelica::Expression &exp) override;

  private:
    QString mValue;
};

#endif /* STRINGANNOTATION_H */
