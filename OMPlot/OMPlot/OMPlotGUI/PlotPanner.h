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

#ifndef PLOTPANNER_H
#define PLOTPANNER_H

#include "OMPlot.h"

namespace OMPlot
{
class PlotPanner : public QwtPlotPanner
{
    Q_OBJECT
public:
#if QWT_VERSION >= 0x060100
  PlotPanner(QWidget *pCanvas, Plot *pParent);
#else
  PlotPanner(QwtPlotCanvas *pCanvas, Plot *pParent);
#endif
    ~PlotPanner();
public Q_SLOTS:
    void updateView(int, int);
private:
    Plot *mpParentPlot;
protected:
    virtual void widgetMousePressEvent(QMouseEvent *event);
    virtual void widgetMouseReleaseEvent(QMouseEvent *event);
};
}

#endif // PLOTPANNER_H
