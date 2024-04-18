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
#ifndef EXTENTANNOTATION_H
#define EXTENTANNOTATION_H

#include "DynamicAnnotation.h"

#include <QPointF>
#include <QVector>

class ExtentAnnotation : public DynamicAnnotation
{
  public:
    ExtentAnnotation();
    ExtentAnnotation(const QVector<QPointF> &value);

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
