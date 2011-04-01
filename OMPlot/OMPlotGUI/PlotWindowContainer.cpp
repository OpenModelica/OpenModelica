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

#include "PlotWindowContainer.h"

using namespace OMPlot;

PlotWindowContainer::PlotWindowContainer(PlotMainWindow *pParent)
    : QMdiArea(pParent)
{
    mpPlotMainWindow = pParent;
    setActivationOrder(QMdiArea::CreationOrder);
    setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    setViewMode(QMdiArea::TabbedView);
}

PlotMainWindow* PlotWindowContainer::getPlotMainWindow()
{
    return mpPlotMainWindow;
}

QString PlotWindowContainer::getUniqueName(QString name, int number)
{
    QString newName;
    newName = name + QString::number(number);

    foreach (QMdiSubWindow *pWindow, subWindowList())
    {
        PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pWindow->widget());
        if (pPlotWindow->windowTitle().compare(newName) == 0)
        {
            newName = getUniqueName(name, ++number);
            break;
        }
    }
    return newName;
}

PlotWindow* PlotWindowContainer::getCurrentWindow()
{
    return qobject_cast<PlotWindow*>(currentSubWindow()->widget());
}

void PlotWindowContainer::addPlotWindow(QStringList arguments)
{
    PlotWindow *pPlotWindow = new PlotWindow(arguments, this);
    pPlotWindow->setWindowTitle(getUniqueName());
    connect(pPlotWindow, SIGNAL(closingDown()), SLOT(checkSubWindows()));
    setActiveSubWindow(addSubWindow(pPlotWindow));
    if (viewMode() == QMdiArea::TabbedView)
        pPlotWindow->showMaximized();
    else
        pPlotWindow->show();
}

void PlotWindowContainer::updateCurrentWindow(QStringList arguments)
{
    getCurrentWindow()->receiveMessage(arguments);
}

void PlotWindowContainer::checkSubWindows()
{
    if (subWindowList().size() < 2)
        getPlotMainWindow()->close();
}
