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

#include "LogScaleEngine.h"
#include "LinearScaleEngine.h"

#include "qwt_math.h"

using namespace OMPlot;

static inline double qwtLog( double base, double value )
{
  return log( value ) / log( base );
}

static inline QwtInterval qwtLogInterval( double base, const QwtInterval &interval )
{
  return QwtInterval( qwtLog( base, interval.minValue() ),
                      qwtLog( base, interval.maxValue() ) );
}

/*!
 * \brief LogScaleEngine::LogScaleEngine
 * \param base
 */
LogScaleEngine::LogScaleEngine(uint base)
  : QwtLogScaleEngine(base)
{

}

/*!
 * \brief LogScaleEngine::autoScale
 * Reimplementation of QwtLogScaleEngine::autoScale
 * Calculates the interval for practically constant variables.
 * \param maxNumSteps
 * \param x1
 * \param x2
 * \param stepSize
 */
void LogScaleEngine::autoScale(int maxNumSteps, double &x1, double &x2, double &stepSize) const
{
  if ( x1 > x2 )
    qSwap( x1, x2 );

  const double logBase = base();

  QwtInterval interval( x1 / qPow( logBase, lowerMargin() ),
                        x2 * qPow( logBase, upperMargin() ) );

  if ( interval.maxValue() / interval.minValue() < logBase )
  {
    // scale width is less than one step -> try to build a linear scale

    LinearScaleEngine linearScaler;
    linearScaler.setAttributes( attributes() );
    linearScaler.setReference( reference() );
    linearScaler.setMargins( lowerMargin(), upperMargin() );

    linearScaler.autoScale( maxNumSteps, x1, x2, stepSize );

    QwtInterval linearInterval = QwtInterval( x1, x2 ).normalized();
    linearInterval = linearInterval.limited( LOG_MIN, LOG_MAX );

    if ( linearInterval.maxValue() / linearInterval.minValue() < logBase )
    {
      // the aligned scale is still less than one step

#if 1
      // this code doesn't make any sense, but for compatibility
      // reasons we keep it until 6.2. But it will be ignored
      // in divideScale

      if ( stepSize < 0.0 )
        stepSize = -qwtLog( logBase, qAbs( stepSize ) );
      else
        stepSize = qwtLog( logBase, stepSize );
#endif
      return;
    }
  }

  double logRef = 1.0;
  if ( reference() > LOG_MIN / 2 )
    logRef = qMin( reference(), LOG_MAX / 2 );

  if ( testAttribute( QwtScaleEngine::Symmetric ) )
  {
    const double delta = qMax( interval.maxValue() / logRef, logRef / interval.minValue() );
    interval.setInterval( logRef / delta, logRef * delta );
  }

  if ( testAttribute( QwtScaleEngine::IncludeReference ) )
    interval = interval.extend( logRef );

  interval = interval.limited( LOG_MIN, LOG_MAX );

  if ( interval.width() == 0.0 || LinearScaleEngine::fuzzyCompare(interval.minValue(), interval.maxValue()) ) {
    interval = buildInterval( interval.minValue() );
  }

  stepSize = divideInterval( qwtLogInterval( logBase, interval ).width(), qMax( maxNumSteps, 1 ) );
  if ( stepSize < 1.0 )
    stepSize = 1.0;

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
