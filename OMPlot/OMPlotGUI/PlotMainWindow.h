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

#ifndef PLOTMAINWINDOW_H
#define PLOTMAINWINDOW_H

#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#include <QPrinter>
#include <QPrintDialog>
#else
#include <QtGui>
#endif
#include <QtCore>

#include "PlotWindowContainer.h"

namespace OMPlot
{
class PlotWindowContainer;

class PlotMainWindow : public QMainWindow
{
    Q_OBJECT
public:
    PlotMainWindow(QWidget *pParent = 0);

    PlotWindowContainer* getPlotWindowContainer();
    void addPlotWindow(QStringList arguments);
private:
    PlotWindowContainer *mpPlotWindowContainer;
    QStatusBar *mpStatusBar;
    QMenuBar *mpMenuBar;
    QMenu *mpMenuFile;
    QMenu *mpMenuOptions;
    QAction *mpCloseAction;
    QAction *mpTabViewAction;

    void createActions();
    void createMenus();
public slots:
    void switchWindowsView(bool mode);
};
}

#endif // PLOTMAINWINDOW_H
