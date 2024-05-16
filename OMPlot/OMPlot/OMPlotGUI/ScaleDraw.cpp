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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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

ScaleDraw::ScaleDraw(bool prefixLabel, Plot *pParent)
  : QwtScaleDraw()
{
  mPrefixLabel = prefixLabel;
  mpParentPlot = pParent;
  mUnitPrefix = "";
  mExponent = 0;
}

/*!
 * \brief ScaleDraw::label
 * Override QwtAbstractScaleDraw::label since the default implementation uses 6 as precision value.
 * Fixes Ticket #2696.
 * \param value -  the actual value.
 * \return the display representation of the value.
 */
QwtText ScaleDraw::label(double value) const
{
  mUnitPrefix = "";
  mExponent = 0;

  if (mpParentPlot->getParentPlotWindow()->getPrefixUnits() && mPrefixLabel && !mpParentPlot->getPlotCurvesList().isEmpty()
      && !mpParentPlot->getParentPlotWindow()->isPlotParametric() && !mpParentPlot->getParentPlotWindow()->isPlotArrayParametric()) {
    Plot::getUnitPrefixAndExponent(scaleDiv().lowerBound(), scaleDiv().upperBound(), mUnitPrefix, mExponent);
    value = value / qPow(10, mExponent);
  }
  return QLocale().toString(value, 'g', 4);
}
