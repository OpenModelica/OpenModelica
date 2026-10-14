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

#include "ScaleDraw.h"
#include "OMPlot.h"
#include "PlotWindow.h"

#include "qwt_scale_map.h"
#include "qwt_text.h"

#include <QLineF>
#include <QPainter>
#include <QPaintEngine>
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

/*!
 * \brief ScaleDraw::drawBackbone
 * Device-pixel-aware reimplementation of QwtScaleDraw::drawBackbone. Qt 6 applies the
 * (possibly fractional) device pixel ratio as a transform that is not visible to Qwt via
 * QPainter::transform(), so Qwt's rounding to integer *logical* pixels lands on fractional
 * device pixels at e.g. 125% scaling. Mirroring Qwt's integer renderer but snapping to
 * device pixels keeps the backbone on a fixed device pixel row/column (see qwt_scale_draw.cpp
 * QwtScaleRendererInt::drawBackbone).
 */
void ScaleDraw::drawBackbone(QPainter *painter) const
{
  const qreal dpr = painter->device()->devicePixelRatio();
  const int pw = qMax(qRound(penWidthF() * dpr), 1);
  /* At a fractional device pixel ratio adjacent widgets can overlap by one device
   * pixel (Qt rounds the device rect of every widget independently), so the boundary
   * row of the scale widget may be covered by the opaque canvas. Shift the backbone
   * one device pixel into the scale widget to keep it clear of that seam. */
  const int inset = (dpr != 1.0) ? 1 : 0;

  const QPointF position = pos();
  const qreal len = length();

  switch (alignment())
  {
    case QwtScaleDraw::LeftScale:
    {
      const qreal x = (qRound(position.x() * dpr) - (pw - 1) / 2 - inset) / dpr;
      const qreal y1 = qRound(position.y() * dpr) / dpr;
      const qreal y2 = qRound((position.y() + len) * dpr) / dpr;
      painter->drawLine(QLineF(x, y1, x, y2));
      break;
    }
    case QwtScaleDraw::RightScale:
    {
      const qreal x = (qRound(position.x() * dpr) + pw / 2 + inset) / dpr;
      const qreal y1 = qRound(position.y() * dpr) / dpr;
      const qreal y2 = qRound((position.y() + len) * dpr) / dpr;
      painter->drawLine(QLineF(x, y1, x, y2));
      break;
    }
    case QwtScaleDraw::TopScale:
    {
      const qreal y = (qRound(position.y() * dpr) - (pw - 1) / 2 - inset) / dpr;
      const qreal x1 = qRound(position.x() * dpr) / dpr;
      const qreal x2 = qRound((position.x() + len) * dpr) / dpr;
      painter->drawLine(QLineF(x1, y, x2, y));
      break;
    }
    case QwtScaleDraw::BottomScale:
    {
      const qreal y = (qRound(position.y() * dpr) + pw / 2 + inset) / dpr;
      const qreal x1 = qRound(position.x() * dpr) / dpr;
      const qreal x2 = qRound((position.x() + len) * dpr) / dpr;
      painter->drawLine(QLineF(x1, y, x2, y));
      break;
    }
  }
}

/*!
 * \brief ScaleDraw::drawTick
 * Device-pixel-aware reimplementation of QwtScaleDraw::drawTick. See drawBackbone() and
 * qwt_scale_draw.cpp QwtScaleRendererInt::drawTick.
 */
void ScaleDraw::drawTick(QPainter *painter, double value, double len) const
{
  if (len <= 0.0) {
    return;
  }

  const qreal dpr = painter->device()->devicePixelRatio();
  const qreal tickPos = qRound(scaleMap().transform(value) * dpr) / dpr;

  /* Keep the tick bases attached to the inset backbone (see drawBackbone()). */
  const int inset = (dpr != 1.0) ? 1 : 0;

  int pw = 0;
  if (hasComponent(QwtAbstractScaleDraw::Backbone)) {
    pw = qMax(qRound(penWidthF() * dpr), 1);
  }

  int devLen = qMax(qRound(len * dpr), 1);
  devLen += pw;
  if (painter->pen().capStyle() == Qt::FlatCap) {
    devLen++; // the end point is not rendered
  }

  qreal off = 0.0;
  if (painter->paintEngine()->type() == QPaintEngine::X11 && pw == 1) {
    // In opposite to raster, X11 paints the end point
    off = 1.0;
  }

  const QPointF position = pos();

  switch (alignment())
  {
    case QwtScaleDraw::LeftScale:
    {
      const int x1 = qRound(position.x() * dpr) + 1 - inset;
      const int x2 = x1 - devLen + 1;
      painter->drawLine(QLineF(x2 / dpr, tickPos, (x1 - off) / dpr, tickPos));
      break;
    }
    case QwtScaleDraw::RightScale:
    {
      const int x1 = qRound(position.x() * dpr) + inset;
      const int x2 = x1 + devLen - 1;
      painter->drawLine(QLineF(x1 / dpr, tickPos, (x2 - off) / dpr, tickPos));
      break;
    }
    case QwtScaleDraw::BottomScale:
    {
      const int y1 = qRound(position.y() * dpr) + inset;
      const int y2 = y1 + devLen - 1;
      painter->drawLine(QLineF(tickPos, y1 / dpr, tickPos, (y2 - off) / dpr));
      break;
    }
    case QwtScaleDraw::TopScale:
    {
      const int y1 = qRound(position.y() * dpr) - inset;
      const int y2 = y1 - devLen + 1;
      painter->drawLine(QLineF(tickPos, (y2 + 1) / dpr, tickPos, (y1 + 1 - off) / dpr));
      break;
    }
  }
}
