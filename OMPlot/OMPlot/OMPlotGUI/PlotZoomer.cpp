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

#include "PlotZoomer.h"

#include "qwt_plot.h"

#include <QPen>

using namespace OMPlot;

#if QWT_VERSION >= 0x060100
PlotZoomer::PlotZoomer(int xAxis, int yAxis, QWidget *pParent)
  : QwtPlotZoomer(xAxis, yAxis, pParent)
{
#else
PlotZoomer::PlotZoomer(int xAxis, int yAxis, QwtPlotCanvas *pParent)
  : QwtPlotZoomer(xAxis, yAxis, pParent)
{
#if QWT_VERSION < 0x060000
  setSelectionFlags(QwtPicker::DragSelection | QwtPicker::CornerToCorner);
#endif
#endif
  setTrackerMode(QwtPicker::AlwaysOff);
  setRubberBand(QwtPicker::RectRubberBand);
  setRubberBandPen(QPen(Qt::black, 1.0, Qt::DashLine));

  // RightButton: zoom out by 1
  // Ctrl+RightButton: zoom out to full size
  setMousePattern(QwtEventPattern::MouseSelect2, Qt::RightButton, Qt::ControlModifier);
  setMousePattern(QwtEventPattern::MouseSelect3, Qt::RightButton);
  connect(this, SIGNAL(zoomed(QRectF)), plot(), SLOT(replot()));
}

PlotZoomer::~PlotZoomer()
{

}
