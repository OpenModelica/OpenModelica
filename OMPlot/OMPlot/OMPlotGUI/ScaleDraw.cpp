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
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "ScaleDraw.h"

#include <QtMath>

using namespace OMPlot;

ScaleDraw::ScaleDraw(Plot *pParent)
  : QwtScaleDraw()
{
  mpParentPlot = pParent;
  mAxesPrefix = "";
}

QString ScaleDraw::getAxesPrefix() const
{
  return mAxesPrefix;
}

void ScaleDraw::setAxesPrefix(const QString &axesPrefix)
{
  mAxesPrefix = axesPrefix;
}

void ScaleDraw::invalidateCache()
{
  QwtAbstractScaleDraw::invalidateCache();
}

/*!
 * \brief ScaleDraw::label
 * Override QwtAbstractScaleDraw::label since the default implementation uses 6 as precision value.
 * Fixes Tickets #2696 and #5447.
 * \param value -  the actual value.
 * \return the display representation of the value.
 */
QwtText ScaleDraw::label(double value) const
{
  char format = 'g';
  int precision = 4;
  mAxesPrefix = "";

  if (mpParentPlot->getParentPlotWindow()->getPrefixAxes()) {
    QString lowerBound = QLocale().toString(scaleDiv().lowerBound(), format, precision);
    int indexLowerBound = lowerBound.indexOf(QLatin1String("e"));
    QString upperBound = QLocale().toString(scaleDiv().upperBound(), format, precision);
    int indexUpperBound = upperBound.indexOf(QLatin1String("e"));

    if (indexLowerBound > -1 || indexUpperBound > -1) {
      QString bound = "";
      int index = -1;
      if (indexLowerBound > -1) {
        bound = lowerBound;
        index = indexLowerBound;
      } else if (indexUpperBound) {
        bound = upperBound;
        index = indexUpperBound;
      }
      if (index > -1) {
        QString sign = bound.mid(index + 1, 1);
        if (sign.compare(QLatin1String("+")) == 0) {
          int exponent = bound.mid(index + 2).toInt();
          if (exponent >= 3 && exponent < 6) {
            mAxesPrefix = "kilo";
            exponent = 3;
          } else if (exponent >= 6 && exponent < 9) {
            mAxesPrefix = "mega";
            exponent = 6;
          } else if (exponent >= 9) {
            mAxesPrefix = "giga";
            exponent = 9;
          } else {
            mAxesPrefix = "";
          }
          if (!mAxesPrefix.isEmpty()) {
            value = value / qPow(10, exponent);
          }
        } else if (sign.compare(QLatin1String("-")) == 0) {
          int exponent = bound.mid(index + 2).toInt();
          if (exponent >= 3 && exponent < 6) {
            mAxesPrefix = "milli";
            exponent = 3;
          } else if (exponent >= 6 && exponent < 9) {
            mAxesPrefix = "micro";
            exponent = 6;
          } else if (exponent >= 9) {
            mAxesPrefix = "nano";
            exponent = 9;
          } else {
            mAxesPrefix = "";
          }
          if (!mAxesPrefix.isEmpty()) {
            value = value * qPow(10, exponent);
          }
        }
      }
    }
  }

  return QLocale().toString(value, format, precision);
}
