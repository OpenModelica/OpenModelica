/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */
#ifndef POINTARRAYANNOTATION_H
#define POINTARRAYANNOTATION_H

#include "DynamicAnnotation.h"

#include <QPointF>
#include <QVector>

class PointArrayAnnotation : public DynamicAnnotation
{
  public:
    PointArrayAnnotation();

    void clear() override;

    operator const QVector<QPointF>&() const { return mValue; }
    PointArrayAnnotation& operator= (const QVector<QPointF> &value);
    const QPointF& operator[] (int i) const;
    void setPoint(int i, const QPointF &value);
    bool operator== (const PointArrayAnnotation &pointArray) const;

    void append(const QPointF &value) { mValue.append(value); setExp(); }
    void insert(int index, const QPointF &value) { mValue.insert(index, value); setExp(); }
    const QPointF& at(int i) const { return mValue.at(i); }
    void removeAt(int index) { mValue.removeAt(index); setExp(); }
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
    QVector<QPointF> mValue;
};

#endif // POINTARRAYANNOTATION_H
