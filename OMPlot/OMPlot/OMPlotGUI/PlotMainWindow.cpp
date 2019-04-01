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

#include "PlotMainWindow.h"

using namespace OMPlot;

PlotMainWindow::PlotMainWindow(QWidget *pParent)
    : QMainWindow(pParent)
{
    mpPlotWindowContainer = new PlotWindowContainer(this);

    setWindowTitle(tr("OMPlot - OpenModelica Plot"));
    setWindowIcon(QIcon(":/Resources/icons/omplot.png"));

    createActions();
    createMenus();

    //Create the Statusbar
    mpStatusBar = new QStatusBar();
    mpStatusBar->setObjectName("statusBar");
    setStatusBar(mpStatusBar);
    // set plotwindowcontainer as central widget
    setCentralWidget(mpPlotWindowContainer);
}

PlotWindowContainer* PlotMainWindow::getPlotWindowContainer()
{
    return mpPlotWindowContainer;
}

void PlotMainWindow::addPlotWindow(QStringList arguments)
{
    mpPlotWindowContainer->addPlotWindow(arguments);
}

void PlotMainWindow::createActions()
{
    mpCloseAction = new QAction(tr("Close"), this);
    mpCloseAction->setShortcut(QKeySequence("Ctrl+q"));
    connect(mpCloseAction, SIGNAL(triggered()), SLOT(close()));

    mpTabViewAction = new QAction(tr("Tab View"), this);
    mpTabViewAction->setCheckable(true);
    mpTabViewAction->setChecked(true);
    connect(mpTabViewAction, SIGNAL(triggered(bool)), SLOT(switchWindowsView(bool)));
}

void PlotMainWindow::createMenus()
{
    //Create the menubar
    mpMenuBar = new QMenuBar();
    mpMenuBar->setGeometry(QRect(0,0,800,25));
    mpMenuBar->setObjectName("menubar");

    //Create the File menu
    mpMenuFile = new QMenu(mpMenuBar);
    mpMenuFile->setObjectName("menuFile");
    mpMenuFile->setTitle(tr("&File"));
    //Add the actions to file menu
    mpMenuFile->addAction(mpCloseAction);
    // add file menu to menubar
    mpMenuBar->addAction(mpMenuFile->menuAction());
    //Create the Options menu
    mpMenuOptions = new QMenu(mpMenuBar);
    mpMenuOptions->setObjectName("menuFile");
    mpMenuOptions->setTitle(tr("&Options"));
    //Add the actions to Options menu
    mpMenuOptions->addAction(mpTabViewAction);
    // add options menu to menubar
    mpMenuBar->addAction(mpMenuOptions->menuAction());
    // add menubar to mainwindow
    setMenuBar(mpMenuBar);
}

void PlotMainWindow::switchWindowsView(bool mode)
{
    if (mode)
    {
        getPlotWindowContainer()->setViewMode(QMdiArea::TabbedView);
    }
    else
    {
        getPlotWindowContainer()->setViewMode(QMdiArea::SubWindowView);
        getPlotWindowContainer()->getCurrentWindow()->show();
    }
}
