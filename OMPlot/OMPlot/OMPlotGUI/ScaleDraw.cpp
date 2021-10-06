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

ScaleDraw::ScaleDraw(QwtPlot::Axis axis, Plot *pParent)
  : QwtScaleDraw()
{
  mAxis = axis;
  mpParentPlot = pParent;
  mUnitPrefix = "";
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
  mUnitPrefix = "";

  if (mpParentPlot->getParentPlotWindow()->getPrefixUnits() && ((mAxis == QwtPlot::xBottom && mpParentPlot->getParentPlotWindow()->canUseXPrefixUnits())
                                                                || (mAxis == QwtPlot::yLeft && mpParentPlot->getParentPlotWindow()->canUseYPrefixUnits()))) {
    int exponent = 0;
    // Use lowerBound if upperBound is zero
    /* Since log(1900) returns 3.278 so we need to round down for positive values to make it 3
     * And log(0.0011) return -2.95 so we also need to round down for negative value to make it -3
     * log(0) is undefined so avoid it
     */
    if (qFuzzyCompare(scaleDiv().upperBound(), 0.0)) {
      exponent = qFloor(std::log10(fabs(scaleDiv().lowerBound())));
    } else {
      exponent = qFloor(std::log10(fabs(scaleDiv().upperBound())));
    }

    // We don't do anything for exponent values between -1 and 2.
    if ((exponent < -1) || (exponent > 2)) {
      if (exponent > 2) {
        if (exponent >= 3 && exponent < 6) {
          mUnitPrefix = "k";
          exponent = 3;
        } else if (exponent >= 6 && exponent < 9) {
          mUnitPrefix = "M";
          exponent = 6;
        } else if (exponent >= 9 && exponent < 12) {
          mUnitPrefix = "G";
          exponent = 9;
        } else if (exponent >= 12 && exponent < 15) {
          mUnitPrefix = "T";
          exponent = 12;
        } else {
          mUnitPrefix = "P";
          exponent = 15;
        }
      } else if (exponent < -1) {
        if (exponent <= -2 && exponent > -6) {
          mUnitPrefix = "m";
          exponent = -3;
        } else if (exponent <= -6 && exponent > -9) {
          mUnitPrefix = QChar(0x03BC);
          exponent = -6;
        } else if (exponent <= -9 && exponent > -12) {
          mUnitPrefix = "n";
          exponent = -9;
        } else if (exponent <= -12 && exponent > -15) {
          mUnitPrefix = "p";
          exponent = -12;
        } else {
          mUnitPrefix = "f";
          exponent = -15;
        }
      }
      value = value / qPow(10, exponent);
    }
  }
  return QLocale().toString(value, 'g', 4);
}
