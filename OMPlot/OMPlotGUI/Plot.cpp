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

#include "PlotWindow.h"
#include "qwt_plot_canvas.h"
#if QWT_VERSION < 0x060100
#include "qwt_legend_item.h"
#endif

using namespace OMPlot;

Plot::Plot(PlotWindow *pParent)
  : QwtPlot(pParent)
{
  setAutoReplot(false);
  mpParentPlotWindow = pParent;
  // create an instance of legend
  mpLegend = new Legend(this);
  insertLegend(mpLegend, QwtPlot::TopLegend);
  // create an instance of grid
  mpPlotGrid = new PlotGrid(this);
  // create an instance of zoomer
  mpPlotZoomer = new PlotZoomer(QwtPlot::xBottom, QwtPlot::yLeft, canvas());
  // create an instance of panner
  mpPlotPanner = new PlotPanner(canvas(), this);
  // create an instance of picker
  mpPlotPicker = new QwtPlotPicker(canvas());
  mpPlotPicker->setTrackerPen(QPen(Qt::black));
  mpPlotPicker->setRubberBandPen(QPen(Qt::black));
  mpPlotPicker->setTrackerMode(QwtPicker::AlwaysOn);
  // set canvas arrow
  QwtPlotCanvas *pPlotCanvas = static_cast<QwtPlotCanvas*>(canvas());
  pPlotCanvas->setFrameStyle(QFrame::NoFrame);
  canvas()->setCursor(Qt::ArrowCursor);
  setCanvasBackground(Qt::white);
  setContentsMargins(10, 10, 10, 10);
  // fill colors list
  fillColorsList();
  setAutoReplot(true);
}

Plot::~Plot()
{

}

void Plot::fillColorsList()
{
  mColorsList.append(QColor(Qt::red));
  mColorsList.append(QColor(Qt::blue));
  mColorsList.append(QColor(Qt::green));
  mColorsList.append(QColor(Qt::cyan));
  mColorsList.append(QColor(Qt::magenta));
  mColorsList.append(QColor(Qt::yellow));
  mColorsList.append(QColor(Qt::darkRed));
  mColorsList.append(QColor(Qt::darkBlue));
  mColorsList.append(QColor(Qt::darkGreen));
  mColorsList.append(QColor(Qt::darkCyan));
  mColorsList.append(QColor(Qt::darkMagenta));
  mColorsList.append(QColor(Qt::darkYellow));
}

PlotWindow* Plot::getParentPlotWindow()
{
  return mpParentPlotWindow;
}

void Plot::setLegend(Legend *pLegend)
{
  mpLegend = pLegend;
}

Legend* Plot::getLegend()
{
  return mpLegend;
}

QwtPlotPicker* Plot::getPlotPicker()
{
  return mpPlotPicker;
}

PlotGrid* Plot::getPlotGrid()
{
  return mpPlotGrid;
}

PlotZoomer* Plot::getPlotZoomer()
{
  return mpPlotZoomer;
}

PlotPanner* Plot::getPlotPanner()
{
  return mpPlotPanner;
}

QList<PlotCurve*> Plot::getPlotCurvesList()
{
  return mPlotCurvesList;
}

void Plot::addPlotCurve(PlotCurve *pCurve)
{
  mPlotCurvesList.append(pCurve);
}

void Plot::removeCurve(PlotCurve *pCurve)
{
  mPlotCurvesList.removeOne(pCurve);
}

QColor Plot::getUniqueColor(int index, int total)
{
  if (mColorsList.size() < total)
    return QColor::fromHsvF(index/(total + 1.0), 1, 1);
  else
    return mColorsList.at(index);
}

// just overloaded this function to get colors for curves.
void Plot::replot()
{
  for (int i = 0 ; i < mPlotCurvesList.length() ; i++)
  {
    // if user has set the custom color for the curve then dont get automatic color for it
    if (!mPlotCurvesList[i]->hasCustomColor())
    {
      QPen pen = mPlotCurvesList[i]->pen();
      pen.setColor(getUniqueColor(i, mPlotCurvesList.length()));
      mPlotCurvesList[i]->setPen(pen);
    }
  }

  QwtPlot::replot();
}
