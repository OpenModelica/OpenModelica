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

#include "LinearScaleEngine.h"
#include "qwt_interval.h"

#include "qwt_interval.h"
#if QWT_VERSION >= 0x060200
#define LOG_MIN QwtLogTransform::LogMin
#define LOG_MAX QwtLogTransform::LogMax
#endif

using namespace OMPlot;

/*!
 * \brief LinearScaleEngine::LinearScaleEngine
 * \param base
 */
LinearScaleEngine::LinearScaleEngine(uint base)
  : QwtLinearScaleEngine(base)
{

}

/*!
 * \brief LinearScaleEngine::fuzzyCompare
 * Compare if two values are almost equal or not.
 * \param p1
 * \param p2
 * \return
 */
bool LinearScaleEngine::fuzzyCompare(double p1, double p2)
{
  return (qAbs(p1 - p2) <= 1e-5*qMax(qAbs(p1), qAbs(p2)));
}

/*!
 * \brief LinearScaleEngine::autoScale
 * Reimplementation of QwtLinearScaleEngine::autoScale
 * Calculates the interval for practically constant variables.
 * \param maxNumSteps
 * \param x1
 * \param x2
 * \param stepSize
 */
void LinearScaleEngine::autoScale(int maxNumSteps, double &x1, double &x2, double &stepSize) const
{
  QwtInterval interval( x1, x2 );
  interval = interval.normalized();

  interval.setMinValue( interval.minValue() - lowerMargin() );
  interval.setMaxValue( interval.maxValue() + upperMargin() );

  if ( testAttribute( QwtScaleEngine::Symmetric ) )
    interval = interval.symmetrize( reference() );

  if ( testAttribute( QwtScaleEngine::IncludeReference ) )
    interval = interval.extend( reference() );

  if ( interval.width() == 0.0 || LinearScaleEngine::fuzzyCompare(interval.minValue(), interval.maxValue()) )
    interval = buildInterval( interval.minValue() );

  stepSize = QwtScaleArithmetic::divideInterval( interval.width(), qMax( maxNumSteps, 1 ), base() );

  if ( !testAttribute( QwtScaleEngine::Floating ) )
    interval = align( interval, stepSize );

  x1 = interval.minValue();
  x2 = interval.maxValue();

  if ( testAttribute( QwtScaleEngine::Inverted ) )
  {
    qSwap( x1, x2 );
    stepSize = -stepSize;
  }
}
