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

#include "PlotCurve.h"
#include "qwt_legend_item.h"
#include "qwt_symbol.h"

using namespace OMPlot;

PlotCurve::PlotCurve(Plot *pParent)
{   
    mpParentPlot = pParent;
}

PlotCurve::~PlotCurve()
{

}

void PlotCurve::setXAxisVector(QVector<double> vector)
{
    mXAxisVector = vector;
}

void PlotCurve::addXAxisValue(double value)
{
    mXAxisVector.push_back(value);
}

QVector<double> PlotCurve::getXAxisVector()
{
    return mXAxisVector;
}

void PlotCurve::setYAxisVector(QVector<double> vector)
{
    mYAxisVector = vector;
}

void PlotCurve::addYAxisValue(double value)
{
    mYAxisVector.push_back(value);
}

QVector<double> PlotCurve::getYAxisVector()
{
    return mYAxisVector;
}

void PlotCurve::updateLegend(QwtLegend *legend) const
{
    QwtPlotCurve::updateLegend(legend);
    QwtLegendItem *lgdItem = dynamic_cast<QwtLegendItem*>(legend->find(this));
    if (lgdItem)
    {
        lgdItem->setIdentifierMode(QwtLegendItem::ShowSymbol | QwtLegendItem::ShowText);
        lgdItem->setSymbol(QwtSymbol(QwtSymbol::Rect, QBrush(pen().color()), QPen(Qt::black),QSize(20,20)));
    }

    QwtPlotItem::updateLegend(legend);
}

QColor PlotCurve::getUniqueColor(QColor color)
{
    foreach (PlotCurve *pPlotCurve, mpParentPlot->getPlotCurvesList())
    {
        if (pPlotCurve->pen().color() == color)
        {
            color = getUniqueColor(QColor(rand()%255, rand()%255, rand()%255));
            break;
        }
    }
    return color;
}
