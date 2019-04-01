/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Author 2011: Adeel Asghar
 *
 */

#include "PlotPanner.h"
#include "iostream"

using namespace OMPlot;

#if QWT_VERSION >= 0x060100
PlotPanner::PlotPanner(QWidget *pCanvas, Plot *pParent)
  : QwtPlotPanner(pCanvas)
{
#else
PlotPanner::PlotPanner(QwtPlotCanvas *pCanvas, Plot *pParent)
  : QwtPlotPanner(pCanvas)
{
#endif
  setMouseButton(Qt::LeftButton, Qt::ControlModifier);
  connect(this, SIGNAL(moved(int,int)), SLOT(updateView(int, int)));
  mpParentPlot = pParent;

}

PlotPanner::~PlotPanner()
{

}

void PlotPanner::updateView(int dx, int dy)
{
  Q_UNUSED(dx);
  Q_UNUSED(dy);
  plot()->updateAxes();
//  moveCanvas(dx - pos().x(), dy - pos().y());
//  plot()->setAxisAutoScale(QwtPlot::xBottom);
//  plot()->setAxisAutoScale(QwtPlot::yLeft);
//  canvas()->update();
//  plot()->updateAxes();
  plot()->updateLayout();
  canvas()->updateGeometry();
  canvas()->update();
  plot()->replot();
}

void PlotPanner::widgetMousePressEvent(QMouseEvent *event)
{
  if (QApplication::keyboardModifiers() == Qt::ControlModifier) {
    mpParentPlot->canvas()->setCursor(Qt::ClosedHandCursor);
  }
  QwtPlotPanner::widgetMousePressEvent(event);
}

void PlotPanner::widgetMouseReleaseEvent(QMouseEvent *event)
{
  mpParentPlot->canvas()->setCursor(Qt::CrossCursor);
  QwtPlotPanner::widgetMouseReleaseEvent(event);
}
