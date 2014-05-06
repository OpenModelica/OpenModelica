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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "ScaleDraw.h"
#if QWT_VERSION >= 0x060100

#include "qwt_painter.h"
#include "qwt_scale_map.h"

using namespace OMPlot;

ScaleDraw::ScaleDraw()
  : QwtScaleDraw()
{

}

void ScaleDraw::drawBackbone( QPainter *painter ) const
{
  const bool doAlign = QwtPainter::roundingAlignment( painter );

  const QPointF &position = pos();
  const double len = length();
  const int pw = qMax( penWidth(), 1 );

  // pos indicates a border not the center of the backbone line
  // so we need to shift its position depending on the pen width
  // and the alignment of the scale

  double off;
  if ( doAlign )
  {
    if ( alignment() == LeftScale || alignment() == TopScale )
      off = ( pw - 1 ) / 2;
    else
      off = pw / 2;
  }
  else
  {
    off = 0.5 * penWidth();
  }

  switch ( alignment() )
  {
    case LeftScale:
    {
      double x = position.x() - off;
      if ( doAlign )
        x = qRound( x );

      QwtPainter::drawLine( painter, x + 2, position.y(), x + 2, position.y() + len + 6 );
      break;
    }
    case RightScale:
    {
      double x = position.x() + off;
      if ( doAlign )
        x = qRound( x );

      QwtPainter::drawLine( painter, x, position.y(), x, position.y() + len );
      break;
    }
    case TopScale:
    {
      double y = position.y() - off;
      if ( doAlign )
        y = qRound( y );

      QwtPainter::drawLine( painter, position.x(), y, position.x() + len, y );
      break;
    }
    case BottomScale:
    {
      double y = position.y() + off;
      if ( doAlign )
        y = qRound( y );

      QwtPainter::drawLine( painter, position.x(), y  - 2, position.x() + len, y - 2 );
      break;
    }
  }
}

void ScaleDraw::drawTick( QPainter *painter, double value, double len ) const
{
  if ( len <= 0 )
    return;

  const bool roundingAlignment = QwtPainter::roundingAlignment( painter );

  QPointF position = pos();

  double tval = scaleMap().transform( value );
  if ( roundingAlignment )
    tval = qRound( tval );

  const int pw = penWidth();
  int a = 0;
  if ( pw > 1 && roundingAlignment )
    a = 1;

  switch ( alignment() )
  {
    case LeftScale:
    {
      double x1 = position.x() + a;
      double x2 = position.x() + a - pw - len;
      if ( roundingAlignment )
      {
        x1 = qRound( x1 );
        x2 = qRound( x2 );
      }

      QwtPainter::drawLine( painter, x1 + 2, tval, x2 + 2, tval );
      break;
    }

    case RightScale:
    {
      double x1 = position.x();
      double x2 = position.x() + pw + len;
      if ( roundingAlignment )
      {
        x1 = qRound( x1 );
        x2 = qRound( x2 );
      }

      QwtPainter::drawLine( painter, x1, tval, x2, tval );
      break;
    }

    case BottomScale:
    {
      double y1 = position.y();
      double y2 = position.y() + pw + len;
      if ( roundingAlignment )
      {
        y1 = qRound( y1 );
        y2 = qRound( y2 );
      }

      QwtPainter::drawLine( painter, tval, y1 - 2, tval, y2 - 2);
      break;
    }

    case TopScale:
    {
      double y1 = position.y() + a;
      double y2 = position.y() - pw - len + a;
      if ( roundingAlignment )
      {
        y1 = qRound( y1 );
        y2 = qRound( y2 );
      }

      QwtPainter::drawLine( painter, tval, y1, tval, y2 );
      break;
    }
  }
}

#endif // #if QWT_VERSION >= 0x060100
