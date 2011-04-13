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

#ifndef PLOTWINDOWCONTAINER_H
#define PLOTWINDOWCONTAINER_H

#include "mainwindow.h"
#include "PlotWindow.h"

class MainWindow;
class PlotTreeItem;

class PlotWindowContainer : public QMdiArea
{
    Q_OBJECT
public:
    PlotWindowContainer(MainWindow *pParent);

    MainWindow* getMainWindow();
    QString getUniqueName(QString name = QString("Plot"), int number = 1);
    OMPlot::PlotWindow* getCurrentWindow();
    bool eventFilter(QObject *pObject, QEvent *event);
private:
    MainWindow *mpParentMainWindow;
public slots:
    OMPlot::PlotWindow* addPlotWindow();
    OMPlot::PlotWindow* addPlotParametricWindow();
    void updatePlotWindows(PlotTreeItem *item);
};

#endif // PLOTWINDOWCONTAINER_H
