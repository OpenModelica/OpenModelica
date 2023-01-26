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
  mExponent = 0;
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
  mExponent = 0;

  if (mpParentPlot->getParentPlotWindow()->getPrefixUnits() && ((mAxis == QwtPlot::xBottom && mpParentPlot->getParentPlotWindow()->canUseXPrefixUnits())
                                                                || (mAxis == QwtPlot::yLeft && mpParentPlot->getParentPlotWindow()->canUseYPrefixUnits()))) {
    // Use lowerBound if upperBound is zero
    /* Since log(1900) returns 3.278 so we need to round down for positive values to make it 3
     * And log(0.0011) return -2.95 so we also need to round down for negative value to make it -3
     * log(0) is undefined so avoid it
     */
    if (qFuzzyCompare(scaleDiv().upperBound(), 0.0)) {
      mExponent = qFloor(std::log10(fabs(scaleDiv().lowerBound())));
    } else {
      mExponent = qFloor(std::log10(fabs(scaleDiv().upperBound())));
    }

    // We don't do anything for exponent values between -1 and 2.
    if ((mExponent < -1) || (mExponent > 2)) {
      if (mExponent > 2) {
        if (mExponent >= 3 && mExponent < 6) {
          mUnitPrefix = "k";
          mExponent = 3;
        } else if (mExponent >= 6 && mExponent < 9) {
          mUnitPrefix = "M";
          mExponent = 6;
        } else if (mExponent >= 9 && mExponent < 12) {
          mUnitPrefix = "G";
          mExponent = 9;
        } else if (mExponent >= 12 && mExponent < 15) {
          mUnitPrefix = "T";
          mExponent = 12;
        } else {
          mUnitPrefix = "P";
          mExponent = 15;
        }
      } else if (mExponent < -1) {
        if (mExponent <= -2 && mExponent > -6) {
          mUnitPrefix = "m";
          mExponent = -3;
        } else if (mExponent <= -6 && mExponent > -9) {
          mUnitPrefix = QChar(0x03BC);
          mExponent = -6;
        } else if (mExponent <= -9 && mExponent > -12) {
          mUnitPrefix = "n";
          mExponent = -9;
        } else if (mExponent <= -12 && mExponent > -15) {
          mUnitPrefix = "p";
          mExponent = -12;
        } else {
          mUnitPrefix = "f";
          mExponent = -15;
        }
      }
      value = value / qPow(10, mExponent);
    } else {
      mExponent = 0;
    }
  }
  return QLocale().toString(value, 'g', 4);
}
