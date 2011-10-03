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

PlotWindowContainer::PlotWindowContainer(MainWindow *pParent)
    : QMdiArea(pParent)
{
    mpParentMainWindow = pParent;
    setActivationOrder(QMdiArea::CreationOrder);
    setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    if (mpParentMainWindow->mpOptionsWidget->mpGeneralSettingsPage->getViewMode().compare("SubWindow") == 0)
        setViewMode(QMdiArea::SubWindowView);
    else
        setViewMode(QMdiArea::TabbedView);
    // dont show this widget at startup
    setVisible(false);
}

MainWindow* PlotWindowContainer::getMainWindow()
{
    return mpParentMainWindow;
}

QString PlotWindowContainer::getUniqueName(QString name, int number)
{
    QString newName;
    newName = name + QString::number(number);

    foreach (QMdiSubWindow *pWindow, subWindowList())
    {
        if (pWindow->widget()->windowTitle().compare(newName) == 0)
        {
            newName = getUniqueName(name, ++number);
            break;
        }
    }
    return newName;
}

PlotWindow* PlotWindowContainer::getCurrentWindow()
{
    if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0)
        return 0;
    else
        return qobject_cast<PlotWindow*>(subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget());
}

bool PlotWindowContainer::eventFilter(QObject *pObject, QEvent *event)
{
    PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pObject);
    if (!pPlotWindow)
        return false;

    if (event->type() == QEvent::Paint)
    {
        QPainter painter (pPlotWindow);
        painter.setPen(Qt::gray);
        QRect rectangle = pPlotWindow->rect();
        rectangle.setWidth(pPlotWindow->rect().width() - 2);
        rectangle.setHeight(pPlotWindow->rect().height() - 2);
        painter.drawRect(rectangle);
        return true;
    }

    return false;
}

PlotWindow* PlotWindowContainer::addPlotWindow()
{
    try
    {
        PlotWindow *pPlotWindow = new PlotWindow();
        pPlotWindow->setPlotType(PlotWindow::PLOT);
        pPlotWindow->setWindowTitle(getUniqueName(tr("Plot : ")));
        pPlotWindow->setTitle(tr(""));
        pPlotWindow->installEventFilter(this);
        QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
        pSubWindow->setWindowIcon(QIcon(":/Resources/icons/plotwindow.png"));
        setActiveSubWindow(pSubWindow);
        if (viewMode() == QMdiArea::TabbedView)
            pPlotWindow->showMaximized();
        else
            pPlotWindow->show();
        return pPlotWindow;
    }
    catch (PlotException &e)
    {
        getMainWindow()->mpMessageWidget->printGUIErrorMessage(e.what());
    }
}

PlotWindow* PlotWindowContainer::addPlotParametricWindow()
{
    try
    {
        PlotWindow *pPlotWindow = new PlotWindow();
        pPlotWindow->setPlotType(PlotWindow::PLOTPARAMETRIC);
        pPlotWindow->setWindowTitle(getUniqueName(tr("Plot Parametric : ")));
        pPlotWindow->setTitle(tr(""));
        pPlotWindow->installEventFilter(this);
        QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
        pSubWindow->setWindowIcon(QIcon(":/Resources/icons/plotparametricwindow.png"));
        setActiveSubWindow(pSubWindow);
        if (viewMode() == QMdiArea::TabbedView)
            pPlotWindow->showMaximized();
        else
            pPlotWindow->show();
        return pPlotWindow;
    }
    catch (PlotException &e)
    {
        getMainWindow()->mpMessageWidget->printGUIErrorMessage(e.what());
    }
}

void PlotWindowContainer::updatePlotWindows(PlotTreeItem *item)
{
    foreach (QMdiSubWindow *pSubWindow, subWindowList())
    {
        PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pSubWindow->widget());
        foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
        {
            if (item->getNameStructure().compare(pPlotCurve->getFileName()) == 0)
            {
                pPlotWindow->getPlot()->removeCurve(pPlotCurve);
                pPlotCurve->detach();
                pPlotWindow->fitInView();
                pPlotWindow->getPlot()->updateGeometry();
            }
        }
    }
}
