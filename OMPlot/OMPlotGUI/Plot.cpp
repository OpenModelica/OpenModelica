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

using namespace OMPlot;

Plot::Plot(PlotWindow *pParent)
    : QwtPlot(pParent)
{
    mpParentPlotWindow = pParent;

    setTitle(tr("Plot by OpenModelica"));
    setCanvasBackground(Qt::white);
    // create an instance of legend
    mpLegend = new Legend(this);
    insertLegend(mpLegend, QwtPlot::RightLegend);
    // create an instance of picker
    mpPlotPicker = new PlotPicker(QwtPlot::xBottom, QwtPlot::yLeft, canvas());
    // create an instance of grid
    mpPlotGrid = new PlotGrid(this);
    // create an instance of zoomer
    mpPlotZoomer = new PlotZoomer(QwtPlot::xBottom, QwtPlot::yLeft, canvas());
    // create an instance of panner
    mpPlotPanner = new PlotPanner(canvas());
    // create an instance of canvas we use it to capture events of canvas()
    mpPlotCanvas = new PlotCanvas(this);
    canvas()->installEventFilter(mpPlotCanvas);
}

Plot::~Plot()
{

}

PlotWindow* Plot::getParentPlotWindow()
{
    return mpParentPlotWindow;
}

Legend* Plot::getLegend()
{
    return mpLegend;
}

PlotPicker* Plot::getPlotPicker()
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

PlotCanvas* Plot::getPlotCanvas()
{
    return mpPlotCanvas;
}

void Plot::addPlotCurve(PlotCurve *pCurve)
{
    mPlotCurvesList.append(pCurve);
}

void Plot::removeCurve(PlotCurve *pCurve)
{
    mPlotCurvesList.removeOne(pCurve);
}
