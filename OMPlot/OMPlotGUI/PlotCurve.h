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

#ifndef PLOTCURVE_H
#define PLOTCURVE_H

#include "Plot.h"

namespace OMPlot
{
class PlotCurve : public QwtPlotCurve
{
private:
    QwtArray<double> mXAxisVector;
    QwtArray<double> mYAxisVector;
    QString mFileName;
    QString mXVariable;
    QString mYVariable;
    bool mCustomColor;

    Plot *mpParentPlot;
public:
    PlotCurve(Plot *pParent);
    ~PlotCurve();

    void setXAxisVector(QVector<double> vector);
    void addXAxisValue(double value);
    const double* getXAxisVector() const;
    QVector<double> getXAxisData();
    void setYAxisVector(QVector<double> vector);
    QVector<double> getYAxisData();
    void addYAxisValue(double value);
    const double* getYAxisVector() const;
    int getSize();
    void setFileName(QString fileName);
    QString getFileName();
    void setXVariable(QString xVariable);
    QString getXVariable();
    void setYVariable(QString yVariable);
    QString getYVariable();
    void setCustomColor(bool value);
    bool hasCustomColor();
    void setData(const double* xData, const double* yData, int size);
    virtual void updateLegend(QwtLegend *legend) const;
};
}

#endif // PLOTCURVE_H
