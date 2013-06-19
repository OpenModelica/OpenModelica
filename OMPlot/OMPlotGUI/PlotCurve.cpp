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
#if QWT_VERSION < 0x060100
#include "qwt_legend_item.h"
#endif
#include "qwt_symbol.h"

using namespace OMPlot;

PlotCurve::PlotCurve(Plot *pParent)
    : mCustomColor(false)
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

const double* PlotCurve::getXAxisVector() const
{
    return mXAxisVector.data();
}

QVector<double> PlotCurve::getXAxisData()
{
  return mXAxisVector;
}

void PlotCurve::setYAxisVector(QVector<double> vector)
{
    mYAxisVector = vector;
}

QVector<double> PlotCurve::getYAxisData()
{
  return mYAxisVector;
}

void PlotCurve::addYAxisValue(double value)
{
    mYAxisVector.push_back(value);
}

const double* PlotCurve::getYAxisVector() const
{
    return mYAxisVector.data();
}

int PlotCurve::getSize()
{
    return mXAxisVector.size();
}

void PlotCurve::setFileName(QString fileName)
{
    mFileName = fileName;
}

QString PlotCurve::getFileName()
{
    return mFileName;
}

void PlotCurve::setXVariable(QString xVariable)
{
    mXVariable = xVariable;
}

QString PlotCurve::getXVariable()
{
    return mXVariable;
}

void PlotCurve::setYVariable(QString yVariable)
{
    mYVariable = yVariable;
}

QString PlotCurve::getYVariable()
{
    return mYVariable;
}

void PlotCurve::setCustomColor(bool value)
{
    mCustomColor = value;
}

bool PlotCurve::hasCustomColor()
{
    return mCustomColor;
}

void PlotCurve::setData(const double* xData, const double* yData, int size)
{
#if QWT_VERSION >= 0x060000
  setRawSamples(xData, yData, size);
#else
  setRawData(xData, yData, size);
#endif
}

#if QWT_VERSION < 0x060000
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
#endif
