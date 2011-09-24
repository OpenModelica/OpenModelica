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
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 * Contributors 2011: Abhinn Kothari
 */

/*
 * HopsanGUI
 * Fluid and Mechatronic Systems, Department of Management and Engineering, Linkoping University
 * Main Authors 2009-2010:  Robert Braun, Bjorn Eriksson, Peter Nordin
 * Contributors 2009-2010:  Mikael Axin, Alessandro Dell'Amico, Karl Pettersson, Ingo Staack
 */

#include <QtGui>
#include <QtSvg/QSvgGenerator>

#include "mainwindow.h"


using namespace OMPlot;

//! Constructor
MainWindow::MainWindow(SplashScreen *splashScreen, QWidget *parent)
    : QMainWindow(parent), mExitApplication(false)
{
    // Create the OMCProxy object.
    splashScreen->showMessage("Connecting to " + Helper::applicationName +" Server", Qt::AlignRight, Qt::white);
    mpOMCProxy = new OMCProxy(this);
    if (mExitApplication)
        return;
    splashScreen->showMessage("Reading Settings", Qt::AlignRight, Qt::white);
    mpOptionsWidget = new OptionsWidget(this);

    //Set the name and size of the main window
    splashScreen->showMessage("Loading Widgets", Qt::AlignRight, Qt::white);
    setObjectName("MainWindow");
    setWindowTitle(Helper::applicationName + " - "  + Helper::applicationIntroText);
    setWindowIcon(QIcon(":/Resources/icons/omeditor.png"));
    setMinimumSize(400, 300);
    resize(800, 600);
    setContentsMargins(1, 1, 1, 1);

    //Create a centralwidget for the main window
    mpCentralwidget = new QWidget(this);
    mpCentralwidget->setObjectName("centralwidget");

    //Create a grid on the centralwidget
    mpCentralgrid = new QGridLayout(mpCentralwidget);
    // since the Tabs are displaed differently on MAC so they occupy more space
    #ifdef Q_OS_UNIX
        mpCentralgrid->setContentsMargins(0, 7, 0, 0);
    #else
        mpCentralgrid->setContentsMargins(0, 1, 0, 0);
    #endif
    //Create a dock for the MessageWidget
    messagedock = new QDockWidget(tr(" Messages"), this);
    messagedock->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea | Qt::BottomDockWidgetArea);
    #ifdef Q_OS_UNIX
        messagedock->setContentsMargins(0, 6, 1, 0);
    #else
        messagedock->setContentsMargins(0, 1, 1, 0);
    #endif
    messagedock->setFeatures(QDockWidget::DockWidgetVerticalTitleBar | QDockWidget::DockWidgetClosable
                             | QDockWidget::DockWidgetMovable | QDockWidget::DockWidgetFloatable);
    mpMessageWidget = new MessageWidget(this);
    messagedock->setWidget(mpMessageWidget);
    addDockWidget(Qt::BottomDockWidgetArea, messagedock);
    mpMessageWidget->printGUIMessage("OMEdit, " + Helper::applicationVersion);
    mpMessageWidget->printGUIMessage("OpenModelica, Version: " + mpOMCProxy->getVersion());
    // load library
    mpLibrary = new LibraryWidget(this);
    // Loads and adds the OM Standard Library into the Library Widget.
    splashScreen->showMessage("Loading Modelica Standard Library", Qt::AlignRight, Qt::white);
    mpLibrary->mpLibraryTree->addModelicaStandardLibrary();
    //Create a dock for the search MSL
    searchMSLdock = new QDockWidget(tr(" Search MSL"), this);
    searchMSLdock->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
    mpSearchMSLWidget = new SearchMSLWidget(this);
    searchMSLdock->setWidget(mpSearchMSLWidget);
    addDockWidget(Qt::LeftDockWidgetArea, searchMSLdock);
    connect(searchMSLdock, SIGNAL(visibilityChanged(bool)), SLOT(focusMSLSearch(bool)));
    searchMSLdock->hide();
    //Create a dock for the componentslibrary
    libdock = new QDockWidget(tr(" Components"), this);
    libdock->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
    libdock->setWidget(mpLibrary);
    addDockWidget(Qt::LeftDockWidgetArea, libdock);
    //create a dock for the model browser
    modelBrowserdock = new QDockWidget(tr("Model Browser"), this);
    modelBrowserdock->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
    mpModelBrowser = new ModelBrowserWidget(this);
    modelBrowserdock->setWidget(mpModelBrowser);
    addDockWidget(Qt::LeftDockWidgetArea, modelBrowserdock);
    //Set dock widget corner owner
    setCorner(Qt::BottomLeftCorner, Qt::LeftDockWidgetArea);
    // Create simulation widget.
    mpSimulationWidget = new SimulationWidget(this);
    // create the plot container widget
    mpPlotWindowContainer = new PlotWindowContainer(this);
    // create the interactive simulation widget
    mpInteractiveSimualtionTabWidget = new InteractiveSimulationTabWidget(this);
    // plot dock
    plotdock = new QDockWidget(tr(" Plot Variables"), this);
    plotdock->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
    plotdock->setContentsMargins(0, 1, 1, 1);
    mpPlotWidget = new PlotWidget(this);
    plotdock->setWidget(mpPlotWidget);
    addDockWidget(Qt::RightDockWidgetArea, plotdock);
    plotdock->hide();
    // plot dock
    documentationdock = new QDockWidget(tr(" Documentation"), this);
    documentationdock->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
    documentationdock->setContentsMargins(0, 1, 1, 1);
    mpDocumentationWidget = new DocumentationWidget(this);
    documentationdock->setWidget(mpDocumentationWidget);
    addDockWidget(Qt::RightDockWidgetArea, documentationdock);
    documentationdock->hide();
    //Create Actions, Toolbar and Menus
    splashScreen->showMessage("Creating Components", Qt::AlignRight, Qt::white);
    this->setAcceptDrops(true);
    this->createActions();
    this->createToolbars();
    this->createMenus();
    //Create the main tab container, need at least one tab
    mpProjectTabs = new ProjectTabWidget(this);
    mpProjectTabs->setObjectName("projectTabs");

    mpBackButton = new QPushButton("Back");
    mpCentralgrid->addWidget(mpBackButton,0,0);
    mpCentralgrid->addWidget(mpProjectTabs,1,0);
    mpCentralgrid->addWidget(mpPlotWindowContainer,1,0);
    mpCentralgrid->addWidget(mpInteractiveSimualtionTabWidget,1,0);
    mpBackButton->hide();

    mpCentralwidget->setLayout(mpCentralgrid);
    //Set the centralwidget
    this->setCentralWidget(mpCentralwidget);
    //Create the Statusbar
    mpStatusBar = new QStatusBar();
    mpStatusBar->setObjectName("statusBar");
    mpStatusBar->setContentsMargins(0, 0, 1, 0);
    mpProgressBar = new QProgressBar;
    mpProgressBar->setMaximumWidth(300);
    mpProgressBar->setTextVisible(false);
    mpProgressBar->setVisible(false);
    mpStatusBar->addPermanentWidget(mpProgressBar);
    this->setStatusBar(mpStatusBar);
    // Create a New Project Widget
    mpModelCreator = new ModelCreator(this);

    connect(this, SIGNAL(fileOpen(QString)), mpProjectTabs, SLOT(openFile(QString)));
    QMetaObject::connectSlotsByName(this);
}

//! Destructor
MainWindow::~MainWindow()
{
    delete mpProjectTabs;
    delete menubar;
    delete mpStatusBar;
    delete mpModelCreator;
    delete mpLibrary;
    delete mpDocumentationWidget;
}

//! Event triggered re-implemented method that closes the main window.
//! First all tabs (models) are closed, if the user do not push Cancel
//! (closeAllProjectTabs then returns 'false') the event is accepted and
//! the main window is closed.
//! @param event contains information of the closing operation.
void MainWindow::closeEvent(QCloseEvent *event)
{
    if (mpProjectTabs->closeAllProjectTabs())
    {
        // Close the OMC Connection
        this->mpOMCProxy->stopServer();
        delete mpOMCProxy;
        mpProjectTabs->blockSignals(true);
        event->accept();
    }
    else
    {
        event->ignore();
    }
}
//when the dragged object enters the main window
//! @param event contains information of the drag operation.
void MainWindow::dragEnterEvent(QDragEnterEvent *event)
{
   event->setDropAction(Qt::CopyAction);
   event->accept();
}


//! Defines what happens when moving an object in the MainWindow.
//! @param event contains information of the drag operation.
void MainWindow::dragMoveEvent(QDragMoveEvent *event)
{
   if(event->mimeData()->hasFormat("text/uri-list"))
   {
       event->setDropAction(Qt::CopyAction);
       event->accept();
   }
   else
   {
       event->ignore();
   }
}

//! Defines what happens when drop a file in a Main Window.
//! @param event contains information of the drop operation.
void MainWindow::dropEvent(QDropEvent *event)
{
    this->setFocus();
    if (!event->mimeData()->hasFormat("text/uri-list"))
    {
        event->ignore();
        return;
    }
    //retrieves the filenames of all the dragged files in list and opens the valid files.
    else
    {
        bool fileOpened = false;
        foreach (QUrl fileUrl, event->mimeData()->urls())
        {
            QFileInfo fileInfo(fileUrl.toLocalFile());
            if (fileInfo.suffix().compare("mo", Qt::CaseInsensitive) == 0)
            {
                emit fileOpen(fileInfo.absoluteFilePath());
                fileOpened = true;
            }
            else
            {
                QString message = QString(GUIMessages::getMessage(GUIMessages::FILE_FORMAT_NOT_SUPPORTED).arg(fileInfo.fileName()));
                mpMessageWidget->printGUIErrorMessage(message);
            }
        }
        // if one file is valid and opened then accept the event
        if (fileOpened)
        {
            event->accept();
            return;
        }
        // if all files are invalid Modelica files ignore the event.
        else
        {
            event->ignore();
            return;
        }
    }
}

//! Defines the actions used by the toolbars
void MainWindow::createActions()
{
    newAction = new QAction(tr("New"), this);

    newModelAction = new QAction(tr("Model"), this);
    newModelAction->setStatusTip(tr("Create New Model"));
    newModelAction->setShortcut(QKeySequence("Ctrl+n"));
    connect(newModelAction, SIGNAL(triggered()), SLOT(openNewModel()));

    newClassAction = new QAction(tr("Class"), this);
    newClassAction->setStatusTip(tr("Create New Class"));
    connect(newClassAction, SIGNAL(triggered()), SLOT(openNewClass()));

    newConnectorAction = new QAction(tr("Connector"), this);
    newConnectorAction->setStatusTip(tr("Create New Connector"));
    connect(newConnectorAction, SIGNAL(triggered()), SLOT(openNewConnector()));

    newRecordAction = new QAction(tr("Record"), this);
    newRecordAction->setStatusTip(tr("Create New Record"));
    connect(newRecordAction, SIGNAL(triggered()), SLOT(openNewRecord()));

    newBlockAction = new QAction(tr("Block"), this);
    newBlockAction->setStatusTip(tr("Create New Block"));
    connect(newBlockAction, SIGNAL(triggered()), SLOT(openNewBlock()));

    newFunctionAction = new QAction(tr("Function"), this);
    newFunctionAction->setStatusTip(tr("Create New Function"));
    connect(newFunctionAction, SIGNAL(triggered()), SLOT(openNewFunction()));

    newPackageAction = new QAction(tr("Package"), this);
    newPackageAction->setStatusTip(tr("Create New Package"));
    newPackageAction->setShortcut(QKeySequence("Ctrl+p"));
    connect(newPackageAction, SIGNAL(triggered()), SLOT(openNewPackage()));

    openAction = new QAction(QIcon(":/Resources/icons/open.png"), tr("Open"), this);
    openAction->setShortcut(QKeySequence("Ctrl+o"));
    openAction->setStatusTip(tr("Opens OpenModelica file"));

    saveAction = new QAction(QIcon(":/Resources/icons/save.png"), tr("Save"), this);
    saveAction->setShortcut(QKeySequence("Ctrl+s"));
    saveAction->setStatusTip(tr("Save a file"));

    saveAsAction = new QAction(QIcon(":/Resources/icons/saveas.png"), tr("Save As"), this);
    saveAsAction->setShortcut(QKeySequence("Ctrl+Shift+s"));
    saveAsAction->setStatusTip(tr("Save As a File"));

    saveAllAction = new QAction(QIcon(":/Resources/icons/saveall.png"), tr("Save All"), this);
    saveAllAction->setStatusTip(tr("Save All Files"));

    undoAction = new QAction(QIcon(":/Resources/icons/undo.png"), tr("Undo"), this);
    undoAction->setShortcut(QKeySequence("Ctrl+z"));
    undoAction->setStatusTip(tr("Undo last activity"));

    redoAction = new QAction(QIcon(":/Resources/icons/redo.png"), tr("Redo"), this);
    redoAction->setShortcut(QKeySequence("Ctrl+y"));
    redoAction->setStatusTip(tr("Redo last activity"));

    cutAction = new QAction(QIcon(":/Resources/icons/cut.png"), tr("Cut"), this);
    cutAction->setShortcut(QKeySequence("Ctrl+x"));

    copyAction = new QAction(QIcon(":/Resources/icons/copy.png"), tr("Copy"), this);
    //copyAction->setShortcut(QKeySequence("Ctrl+c"));
    //! @todo opening this will stop copying data from messages window.

    pasteAction = new QAction(QIcon(":/Resources/icons/paste.png"), tr("Paste"), this);
    pasteAction->setShortcut(QKeySequence("Ctrl+v"));

    gridLinesAction = new QAction(QIcon(":/Resources/icons/grid.png"), tr("Grid Lines"), this);
    gridLinesAction->setStatusTip(tr("Show/Hide the grid lines"));
    gridLinesAction->setCheckable(true);

    resetZoomAction = new QAction(QIcon(":/Resources/icons/zoom100.png"), tr("Reset Zoom"), this);
    resetZoomAction->setStatusTip(tr("Resets the zoom"));
    resetZoomAction->setShortcut(QKeySequence("Ctrl+0"));

    zoomInAction = new QAction(QIcon(":/Resources/icons/zoomIn.png"), tr("Zoom In"), this);
    zoomInAction->setStatusTip(tr("Zoom in"));
    zoomInAction->setShortcut(QKeySequence("Ctrl++"));

    zoomOutAction = new QAction(QIcon(":/Resources/icons/zoomOut.png"), tr("Zoom Out"), this);
    zoomOutAction->setStatusTip(tr("Zoom out"));
    zoomOutAction->setShortcut(QKeySequence("Ctrl+-"));

    checkModelAction = new QAction(QIcon(":/Resources/icons/check.png"), tr("Check Model"), this);
    checkModelAction->setStatusTip(tr("Check the modelica model"));
    connect(checkModelAction, SIGNAL(triggered()), SLOT(checkModel()));

    flatModelAction = new QAction(QIcon(":/Resources/icons/flatmodel.png"), tr("Instantiate Model"), this);
    flatModelAction->setStatusTip(tr("Instantiates/Flatten the modelica model"));
    connect(flatModelAction, SIGNAL(triggered()), SLOT(flatModel()));

    omcLoggerAction = new QAction(QIcon(":/Resources/icons/console.png"), tr("OMC Logger"), this);
    omcLoggerAction->setStatusTip(tr("Shows OMC Logger Window"));
    connect(omcLoggerAction, SIGNAL(triggered()), this->mpOMCProxy, SLOT(openOMCLogger()));

    openOMShellAction = new QAction(QIcon(":/Resources/icons/omshell.svg"), tr("OMShell"), this);
    openOMShellAction->setStatusTip(tr("Opens OpenModelica Shell (OMShell)"));
    connect(openOMShellAction, SIGNAL(triggered()), SLOT(openOMShell()));

    exportToOMNotebookAction = new QAction(QIcon(":/Resources/icons/export-omnotebook.png"), tr("Export to OMNotebook"), this);
    exportToOMNotebookAction->setStatusTip(tr("Exports the current model to OMNotebook"));
    exportToOMNotebookAction->setEnabled(false);
    connect(exportToOMNotebookAction, SIGNAL(triggered()), SLOT(exportModelToOMNotebook()));

    importFromOMNotebookAction = new QAction(QIcon(":/Resources/icons/import-omnotebook.png"), tr("Import from OMNotebook"), this);
    importFromOMNotebookAction->setStatusTip(tr("Imports the models from OMNotebook"));
    connect(importFromOMNotebookAction, SIGNAL(triggered()), SLOT(importModelfromOMNotebook()));

    exportAsImageAction = new QAction(QIcon(":/Resources/icons/bitmap-shape.png"), tr("Export as an Image"), this);
    exportAsImageAction->setStatusTip(tr("Exports the current model to Image"));
    exportAsImageAction->setEnabled(false);
    connect(exportAsImageAction, SIGNAL(triggered()), SLOT(exportModelAsImage()));

    openOptions = new QAction(tr("Options"), this);
    openOptions->setStatusTip(tr("Shows the options window"));
    connect(openOptions, SIGNAL(triggered()), SLOT(openConfigurationOptions()));

    closeAction = new QAction(QIcon(":/Resources/icons/close.png"), tr("Close"), this);
    closeAction->setStatusTip(tr("Exits the ").append(Helper::applicationIntroText));
    closeAction->setShortcut(QKeySequence("Ctrl+q"));
    connect(this->closeAction,SIGNAL(triggered()), SLOT(close()));

    simulationAction = new QAction(QIcon(":/Resources/icons/simulate.png"), tr("Simulate"), this);
    simulationAction->setStatusTip(tr("Simulate the Model"));
    connect(simulationAction, SIGNAL(triggered()), SLOT(openSimulation()));

    plotAction = plotdock->toggleViewAction();
    plotAction->setStatusTip(tr("Show/Hide the plot variables window"));
    plotAction->setIcon(QIcon(":/Resources/icons/plot.png"));
    plotAction->setText(tr("Plot Variables"));

    interactiveSimulationAction = new QAction(QIcon(":/Resources/icons/interactive-simulation.png"), tr("Interactive Simulation"), this);
    interactiveSimulationAction->setStatusTip(tr("Interactive Simulate the Model"));
    connect(interactiveSimulationAction, SIGNAL(triggered()), SLOT(openInteractiveSimulation()));

    documentationAction = documentationdock->toggleViewAction();
    documentationAction->setStatusTip(tr("Show/Hide the documentation window"));
    documentationAction->setIcon(QIcon(":/Resources/icons/info-icon.png"));
    documentationAction->setText(tr("View Documentation"));

    userManualAction = new QAction(tr("User Manual"), this);
    userManualAction->setStatusTip(tr("Opens the User Manual"));
    userManualAction->setShortcut(QKeySequence(Qt::Key_F1));
    connect(userManualAction, SIGNAL(triggered()), SLOT(openUserManual()));

    aboutAction = new QAction(tr("About OMEdit"), this);
    aboutAction->setStatusTip(tr("Information about OMEdit"));
    connect(aboutAction, SIGNAL(triggered()), SLOT(openAbout()));

    shapesActionGroup = new QActionGroup(this);
    shapesActionGroup->setExclusive(false);

    lineAction = new QAction(QIcon(":/Resources/icons/line-shape.png"), tr("Line"), shapesActionGroup);
    lineAction->setStatusTip(tr("Draws a line."));
    lineAction->setCheckable(true);
    connect(lineAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));

    polygonAction = new QAction(QIcon(":/Resources/icons/polygon-shape.png"), tr("Polygon"), shapesActionGroup);
    polygonAction->setStatusTip(tr("Draws a polygon."));
    polygonAction->setCheckable(true);
    connect(polygonAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));

    rectangleAction = new QAction(QIcon(":/Resources/icons/rectangle-shape.png"), tr("Rectangle"), shapesActionGroup);
    rectangleAction->setStatusTip(tr("Draws a rectangle."));
    rectangleAction->setCheckable(true);
    connect(rectangleAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));

    ellipseAction = new QAction(QIcon(":/Resources/icons/ellipse-shape.png"), tr("Ellipse"), shapesActionGroup);
    ellipseAction->setStatusTip(tr("Draws an Ellipse."));
    ellipseAction->setCheckable(true);
    connect(ellipseAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));

    textAction = new QAction(QIcon(":/Resources/icons/text-shape.png"), tr("Text"), shapesActionGroup);
    textAction->setStatusTip(tr("Draws a Text."));
    textAction->setCheckable(true);
    connect(textAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));

    // Add the bitmap picture
    bitmapAction = new QAction(QIcon(":/Resources/icons/bitmap-shape.png"), tr("Bitmap"), shapesActionGroup);
    bitmapAction->setStatusTip(tr("Imports a Bitmap."));
    bitmapAction->setCheckable(true);
    connect(bitmapAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));

    connectAction = new QAction(QIcon(":/Resources/icons/connector-icon.png"), tr("Connect/Unconnect Mode"),this);
    connectAction->setStatusTip(tr("Changes to/from connect mode"));
    connectAction->setCheckable(true);
    connectAction->setChecked(true);
    connect(connectAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));

    viewActionGroup = new QActionGroup(this);
    viewActionGroup->setExclusive(true);

    modelingViewAction = new QAction(QIcon(":/Resources/icons/omeditor.png"), tr("Modeling"), viewActionGroup);
    modelingViewAction->setStatusTip(tr("Shows Modeling View"));
    modelingViewAction->setShortcut(QKeySequence("Ctrl+Shift+m"));
    modelingViewAction->setCheckable(true);
    modelingViewAction->setChecked(true);
    connect(modelingViewAction, SIGNAL(triggered()), SLOT(switchToModelingView()));

    plottingViewAction = new QAction(QIcon(":/Resources/icons/omplot.png"), tr("Plotting"), viewActionGroup);
    plottingViewAction->setStatusTip(tr("Shows Plotting View"));
    plottingViewAction->setShortcut(QKeySequence("Ctrl+Shift+p"));
    plottingViewAction->setCheckable(true);
    connect(plottingViewAction, SIGNAL(triggered()), SLOT(switchToPlottingView()));

    interactiveSimulationViewAction = new QAction(QIcon(":/Resources/icons/interactive-simulation.png"),
                                                  tr("Interactive Simulation"), viewActionGroup);
    interactiveSimulationViewAction->setStatusTip(tr("Shows Interactive Simulation View"));
    interactiveSimulationViewAction->setShortcut(QKeySequence("Ctrl+Shift+i"));
    interactiveSimulationViewAction->setCheckable(true);
    connect(interactiveSimulationViewAction, SIGNAL(triggered()), SLOT(switchToInteractiveSimulationView()));

    newPlotWindowAction = new QAction(QIcon(":/Resources/icons/plotwindow.png"), tr("New Plot Window"), this);
    newPlotWindowAction->setStatusTip(tr("Inserts new plot window"));
    connect(newPlotWindowAction, SIGNAL(triggered()), SLOT(addNewPlotWindow()));

    newPlotParametricWindowAction = new QAction(QIcon(":/Resources/icons/plotparametricwindow.png"), tr("New Plot Parametric Window"), this);
    newPlotParametricWindowAction->setStatusTip(tr("Inserts new plot parametric window"));
    connect(newPlotParametricWindowAction, SIGNAL(triggered()), SLOT(addNewPlotParametricWindow()));
}

//! Creates the menus
void MainWindow::createMenus()
{
    //Create the menubar
    menubar = new QMenuBar();
    menubar->setGeometry(QRect(0,0,800,25));
    menubar->setObjectName("menubar");

    //Create the menues
    menuFile = new QMenu(menubar);
    menuFile->setObjectName("menuFile");
    menuFile->setTitle("&File");

    menuNew = new QMenu(menubar);
    menuNew->setObjectName("menuNew");
    menuNew->setTitle("New");

    menuEdit = new QMenu(menubar);
    menuEdit->setTitle("&Edit");

    menuView = new QMenu(menubar);
    menuView->setTitle("&View");

    menuSimulation = new QMenu(menubar);
    menuSimulation->setTitle("&Simulation");

    menuTools = new QMenu(menubar);
    menuTools->setTitle("&Tools");

    menuHelp = new QMenu(menubar);
    menuHelp->setTitle("&Help");

    this->setMenuBar(menubar);

    //Add the actionbuttons to the menues
    menuNew->addAction(newModelAction);
    menuNew->addAction(newClassAction);
    menuNew->addAction(newConnectorAction);
    menuNew->addAction(newRecordAction);
    menuNew->addAction(newBlockAction);
    menuNew->addAction(newFunctionAction);
    menuNew->addAction(newPackageAction);

    menuFile->addAction(menuNew->menuAction());
    menuFile->addAction(openAction);
    menuFile->addAction(saveAction);
    menuFile->addAction(saveAsAction);
    //menuFile->addAction(saveAllAction);
    menuFile->addSeparator();
    menuFile->addAction(closeAction);

    //menuEdit->addAction(undoAction);
    //menuEdit->addAction(redoAction);
    menuEdit->addSeparator();
    menuEdit->addAction(cutAction);
    menuEdit->addAction(copyAction);
    menuEdit->addAction(pasteAction);

    QAction *searchMSLAction = searchMSLdock->toggleViewAction();
    searchMSLAction->setText(tr("Search MSL"));
    searchMSLAction->setShortcut(QKeySequence("Ctrl+Shift+f"));
    searchMSLAction->setIcon(QIcon(":/Resources/icons/search.png"));
    QAction *libAction = libdock->toggleViewAction();
    libAction->setText(tr("Components"));
    QAction *modelBrowserAction = modelBrowserdock->toggleViewAction();
    modelBrowserAction->setText(tr("Model Browser"));
    QAction *messageAction = messagedock->toggleViewAction();
    messageAction->setText(tr("Messages"));

    menuView->addAction(searchMSLAction);
    menuView->addAction(libAction);
    menuView->addAction(modelBrowserAction);
    menuView->addAction(messageAction);
    //menuView->addAction(fileToolBar->toggleViewAction());
    //menuView->addAction(editToolBar->toggleViewAction());
    //menuView->addAction(documentationAction);
    menuView->addSeparator();
    menuView->addAction(gridLinesAction);
    menuView->addAction(resetZoomAction);
    menuView->addAction(zoomInAction);
    menuView->addAction(zoomOutAction);
    menuView->addSeparator();
    menuView->addAction(flatModelAction);
    menuView->addAction(checkModelAction);
    menuView->addSeparator();
    menuView->addAction(modelingViewAction);
    menuView->addAction(plottingViewAction);
    menuView->addAction(interactiveSimulationViewAction);

    menuSimulation->addAction(simulationAction);
    menuSimulation->addAction(interactiveSimulationAction);
    menuSimulation->addAction(plotAction);

    menuTools->addAction(omcLoggerAction);
    menuTools->addSeparator();
    menuTools->addAction(openOMShellAction);
    menuTools->addSeparator();
    menuTools->addAction(exportToOMNotebookAction);
    menuTools->addAction(importFromOMNotebookAction);
    menuTools->addSeparator();
    menuTools->addAction(openOptions);

    menuHelp->addAction(userManualAction);
    menuHelp->addAction(aboutAction);

    menubar->addAction(menuFile->menuAction());
    menubar->addAction(menuEdit->menuAction());
    menubar->addAction(menuView->menuAction());
    menubar->addAction(menuSimulation->menuAction());
    menubar->addAction(menuTools->menuAction());
    menubar->addAction(menuHelp->menuAction());
}

//! Creates the toolbars
void MainWindow::createToolbars()
{
    fileToolBar = addToolBar(tr("File Toolbar"));
    fileToolBar->setAllowedAreas(Qt::TopToolBarArea);

    QToolButton *newMenuButton = new QToolButton(fileToolBar);
    QMenu *newMenu = new QMenu(newMenuButton);
    newMenu->addAction(newModelAction);
    newMenu->addAction(newClassAction);
    newMenu->addAction(newConnectorAction);
    newMenu->addAction(newRecordAction);
    newMenu->addAction(newBlockAction);
    newMenu->addAction(newFunctionAction);
    newMenu->addAction(newPackageAction);

    newMenuButton->setMenu(newMenu);
    newMenuButton->setDefaultAction(newModelAction);
    newMenuButton->setPopupMode(QToolButton::MenuButtonPopup);
    newMenuButton->setIcon(QIcon(":/Resources/icons/new.png"));

    fileToolBar->addWidget(newMenuButton);
    fileToolBar->addAction(openAction);
    fileToolBar->addAction(saveAction);
    fileToolBar->addAction(saveAsAction);
    //fileToolBar->addAction(saveAllAction);

//    editToolBar = addToolBar(tr("Clipboard Toolbar"));
//    editToolBar->setAllowedAreas(Qt::TopToolBarArea);
    //editToolBar->addAction(undoAction);
    //editToolBar->addAction(redoAction);
//    editToolBar->addAction(cutAction);
//    editToolBar->addAction(copyAction);
//    editToolBar->addAction(pasteAction);

    viewToolBar = addToolBar(tr("View Toolbar"));
    viewToolBar->setAllowedAreas(Qt::TopToolBarArea);
    viewToolBar->addAction(gridLinesAction);
    viewToolBar->addSeparator();
    viewToolBar->addAction(resetZoomAction);
    viewToolBar->addAction(zoomInAction);
    viewToolBar->addAction(zoomOutAction);
    viewToolBar->addSeparator();
    viewToolBar->addAction(flatModelAction);
    viewToolBar->addAction(checkModelAction);

    shapesToolBar = addToolBar(tr("Shapes Toolbar"));
    shapesToolBar->setAllowedAreas(Qt::TopToolBarArea);
    shapesToolBar->addAction(lineAction);
    shapesToolBar->addAction(polygonAction);
    shapesToolBar->addAction(rectangleAction);
    shapesToolBar->addAction(ellipseAction);
    shapesToolBar->addAction(textAction);

    //ADD bitmapaction HK
    shapesToolBar->addAction(bitmapAction);
    shapesToolBar->addSeparator();
    shapesToolBar->addAction(connectAction);

    simulationToolBar = addToolBar(tr("Simulation"));
    simulationToolBar->setAllowedAreas(Qt::TopToolBarArea);
    simulationToolBar->addAction(simulationAction);
    simulationToolBar->addAction(interactiveSimulationAction);
    simulationToolBar->addAction(plotAction);

    omnotebookToolbar = addToolBar(tr("OMNotebook"));
    omnotebookToolbar->setAllowedAreas(Qt::TopToolBarArea);
    omnotebookToolbar->addAction(exportToOMNotebookAction);
    omnotebookToolbar->addAction(importFromOMNotebookAction);

    plotToolBar = addToolBar(tr("Plot Toolbar"));
    plotToolBar->setAllowedAreas(Qt::TopToolBarArea);
    plotToolBar->setVisible(false);
    plotToolBar->addAction(newPlotWindowAction);
    plotToolBar->addAction(newPlotParametricWindowAction);

    perspectiveToolBar = addToolBar(tr("Perspective Toolbar"));
    perspectiveToolBar->setAllowedAreas(Qt::TopToolBarArea);
    perspectiveToolBar->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    perspectiveToolBar->setMovable(false);

    // a trick :: just to move the toolbar to the right
    QWidget *spacerWidget = new QWidget(this);
    spacerWidget->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
    spacerWidget->setVisible(true);
    perspectiveToolBar->addWidget(spacerWidget);

    perspectiveToolBar->addAction(modelingViewAction);
    perspectiveToolBar->addAction(plottingViewAction);
    perspectiveToolBar->addAction(interactiveSimulationViewAction);
}

//! Open Simulation Window
void MainWindow::openSimulation()
{
    this->mpSimulationWidget->show(false);
}

//! Open Interactive Simulation Window
void MainWindow::openInteractiveSimulation()
{
    this->mpSimulationWidget->show(true);
}

//! Opens the new model widget.
void MainWindow::openNewModel()
{
    this->mpModelCreator->show(StringHandler::MODEL);
}

//! Opens the new class widget.
void MainWindow::openNewClass()
{
    this->mpModelCreator->show(StringHandler::CLASS);
}

//! Opens the new connector widget.
void MainWindow::openNewConnector()
{
    this->mpModelCreator->show(StringHandler::CONNECTOR);
}

//! Opens the new record widget.
void MainWindow::openNewRecord()
{
    this->mpModelCreator->show(StringHandler::RECORD);
}

//! Opens the new block widget.
void MainWindow::openNewBlock()
{
    this->mpModelCreator->show(StringHandler::BLOCK);
}

//! Opens the new function widget.
void MainWindow::openNewFunction()
{
    this->mpModelCreator->show(StringHandler::FUNCTION);
}

//! Opens the new package widget.
void MainWindow::openNewPackage()
{
    this->mpModelCreator->show(StringHandler::PACKAGE);
}

//! Opens the new model widget.
void MainWindow::openOMShell()
{
    QString omShellPath (Helper::OpenModelicaHome);

    if (omShellPath.isEmpty())
    {
        QMessageBox::warning( this, "Error", GUIMessages::getMessage(GUIMessages::OPEN_MODELICA_HOME_NOT_FOUND), "OK");
        return;
    }

    QDir dir;
    QString msg;

    #ifdef WIN32
        if( dir.exists( omShellPath + "\\bin\\OMShell.exe" ) )
                omShellPath += "\\bin\\";
        else if( dir.exists( omShellPath + "\\OMShell.exe" ) )
                omShellPath += "";
        else
        {
            msg = "Unable to find OMShell, searched in:\n" +
                    omShellPath + "\\bin\\\n" +
                    omShellPath + "\n" +
                    dir.absolutePath();

            QMessageBox::warning( this, "Error", msg, "OK" );
            return;
        }
        omShellPath = omShellPath + "OMShell.exe";
    #else /* unix */
        if( dir.exists( omShellPath + "/bin/OMShell" ) )
                omShellPath += "/bin/";
        else if( dir.exists( omShellPath + "/OMShell" ) )
                omShellPath += "";
        else
        {
            msg = "Unable to find OMShell, searched in:\n" +
              omShellPath + "/bin/\n" +
              omShellPath + "\n" +
              dir.absolutePath();

            QMessageBox::warning( this, "Error", msg, "OK" );
            return;
        }
        omShellPath = omShellPath + "OMShell";
    #endif

    QProcess *process = new QProcess();
    process->start(omShellPath);
}

//! Exports the current model to OMNotebook.
//! Creates a new onb file and add the model text and model image in it.
//! @see importModelfromOMNotebook();
void MainWindow::exportModelToOMNotebook()
{
    // get the current tab
    ProjectTab *pCurrentTab = mpProjectTabs->getCurrentTab();
    QString omnotebookFileName = StringHandler::getSaveFileName(this, tr("Export to OMNotebook"), NULL, Helper::omnotebookFileTypes, NULL, "onb", &pCurrentTab->mModelName);

    // if user cancels the operation. or closes the export dialog box.
    if (omnotebookFileName.isEmpty())
        return;

    // create a progress bar
    int endtime = 6;    // since in total we do six things while exporting to OMNotebook
    int value = 1;
    // show the progressbar and set the message in status bar
    mpStatusBar->showMessage(Helper::exportToOMNotebook);
    mpProgressBar->setRange(0, endtime);
    showProgressBar();
    // create the xml for the omnotebook file.
    QDomDocument xmlDocument;
    // create Notebook element
    QDomElement notebookElement = xmlDocument.createElement("Notebook");
    xmlDocument.appendChild(notebookElement);
    mpProgressBar->setValue(value++);
    // create title cell
    createOMNotebookTitleCell(xmlDocument, notebookElement);
    mpProgressBar->setValue(value++);
    // create image cell
    QStringList pathList = omnotebookFileName.split('/');
    pathList.removeLast();
    QString modelImagePath(pathList.join("/"));
    createOMNotebookImageCell(xmlDocument, notebookElement, modelImagePath);
    mpProgressBar->setValue(value++);
    // create a code cell
    createOMNotebookCodeCell(xmlDocument, notebookElement);
    mpProgressBar->setValue(value++);

    // create a file object and write the xml in it.
    QFile omnotebookFile(omnotebookFileName);
    omnotebookFile.open(QIODevice::WriteOnly);
    QTextStream textStream(&omnotebookFile);
    textStream << xmlDocument.toString();
    omnotebookFile.close();
    mpProgressBar->setValue(value++);
    // hide the progressbar and clear the message in status bar
    mpStatusBar->clearMessage();
    hideProgressBar();
}

//! creates a title cell in omnotebook xml file
void MainWindow::createOMNotebookTitleCell(QDomDocument xmlDocument, QDomElement pDomElement)
{
    QDomElement textCellElement = xmlDocument.createElement("TextCell");
    textCellElement.setAttribute("style", "Text");
    pDomElement.appendChild(textCellElement);

    ProjectTab *pCurrentTab = mpProjectTabs->getCurrentTab();
    // create text Element
    QDomElement textElement = xmlDocument.createElement("Text");
    textElement.appendChild(xmlDocument.createTextNode("<html><head><meta name=\"qrichtext\" content=\"1\" /><head><body style=\"white-space: pre-wrap; font-family:MS Shell Dlg; font-size:8.25pt; font-weight:400; font-style:normal; text-decoration:none;\"><p style=\"margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px; font-family:Arial; font-size:38pt; font-weight:600; color:#000000;\">" + pCurrentTab->mModelName + "</p></body></html>"));
    textCellElement.appendChild(textElement);
}

//! creates a image cell in omnotebook xml file
void MainWindow::createOMNotebookImageCell(QDomDocument xmlDocument, QDomElement pDomElement, QString filePath)
{
    ProjectTab *pCurrentTab = mpProjectTabs->getCurrentTab();
    QPixmap modelImage(pCurrentTab->mpDiagramGraphicsView->viewport()->size());
    modelImage.fill(QColor(Qt::transparent));
    QPainter painter(&modelImage);
    painter.setWindow(pCurrentTab->mpDiagramGraphicsView->viewport()->rect());
    // paint the background color first
    painter.fillRect(modelImage.rect(), pCurrentTab->mpDiagramGraphicsView->palette().background());
    // paint all the items
    pCurrentTab->mpDiagramGraphicsView->render(&painter, QRectF(painter.viewport()), pCurrentTab->mpDiagramGraphicsView->viewport()->rect());
    painter.end();

    // create textcell element
    QDomElement textCellElement = xmlDocument.createElement("TextCell");
    pDomElement.appendChild(textCellElement);

    // create text Element
    QDomElement textElement = xmlDocument.createElement("Text");
    textElement.appendChild(xmlDocument.createTextNode("<img src=\""+QString(filePath).append("/OMNotebook_tempfiles/1.png")+"\" />"));
    textCellElement.appendChild(textElement);
    // create rule Element
    QDomElement ruleElement = xmlDocument.createElement("Rule");
    ruleElement.setAttribute("name", "TextAlignment");
    ruleElement.appendChild(xmlDocument.createTextNode(tr("Center")));
    textCellElement.appendChild(ruleElement);
    // create image Element
    QDomElement imageElement = xmlDocument.createElement("Image");
    imageElement.setAttribute("name", QString(filePath).append("/OMNotebook_tempfiles/1.png"));

    // get the base64 encoding of image
    QBuffer imageBuffer;
    imageBuffer.open( QBuffer::WriteOnly );
    QDataStream out( &imageBuffer );
    out << modelImage;
    imageBuffer.close();

    imageElement.appendChild(xmlDocument.createTextNode(imageBuffer.buffer().toBase64()));
    textCellElement.appendChild(imageElement);
}

//! creates a code cell in omnotebook xml file
void MainWindow::createOMNotebookCodeCell(QDomDocument xmlDocument, QDomElement pDomElement)
{
    QDomElement textCellElement = xmlDocument.createElement("InputCell");
    pDomElement.appendChild(textCellElement);

    ProjectTab *pCurrentTab = mpProjectTabs->getCurrentTab();
    // create input Element
    QDomElement inputElement = xmlDocument.createElement("Input");
    inputElement.appendChild(xmlDocument.createTextNode(mpOMCProxy->list(pCurrentTab->mModelNameStructure)));
    textCellElement.appendChild(inputElement);
    // create output Element
    QDomElement outputElement = xmlDocument.createElement("Output");
    outputElement.appendChild(xmlDocument.createTextNode(tr("")));
    textCellElement.appendChild(outputElement);
}

//! Imports the models from OMNotebook.
//! @see exportModelToOMNotebook();
void MainWindow::importModelfromOMNotebook()
{
    QString fileName = StringHandler::getOpenFileName(this, tr("Choose File"), NULL, Helper::omnotebookFileTypes);
    if (fileName.isEmpty())
        return;

    // create a progress bar
    int endtime = 3;    // since in total we do three things while exporting to OMNotebook
    int value = 1;
    // show the progressbar and set the message in status bar
    mpStatusBar->showMessage(Helper::importFromOMNotebook);
    mpProgressBar->setRange(0, endtime);
    showProgressBar();
    // open the xml file
    QFile file(fileName);
    if (!file.open(QIODevice::ReadOnly))
    {
        mpMessageWidget->printGUIErrorMessage(tr("Error opening the file"));
        hideProgressBar();
        return;
    }
    mpProgressBar->setValue(value++);

    // create the xml from the omnotebook file.
    QDomDocument xmlDocument;
    if (!xmlDocument.setContent(&file))
    {
        mpMessageWidget->printGUIErrorMessage(tr("Error reading the xml file."));
        hideProgressBar();
        return;
    }
    mpProgressBar->setValue(value++);
    // read the file
    QDomNodeList nodes = xmlDocument.elementsByTagName(tr("Input"));
    endtime = endtime + nodes.size();
    mpProgressBar->setMaximum(endtime);
    for (int i = 0; i < nodes.size(); i++)
    {
        if (nodes.at(i).toElement().text().toLower().startsWith("model"))
        {
            mpProjectTabs->openModel(nodes.at(i).toElement().text());
        }
        mpProgressBar->setValue(value++);
    }
    // hide the progressbar and clear the message in status bar
    mpStatusBar->clearMessage();
    hideProgressBar();
}

//! Exports the current model as image
void MainWindow::exportModelAsImage()
{
    // get the current tab
    ProjectTab *pCurrentTab = mpProjectTabs->getCurrentTab();
    QString fileName = StringHandler::getSaveFileName(this, tr("Export as Image"), NULL, Helper::imageFileTypes, NULL, "png", &pCurrentTab->mModelName);

    // if user cancels the operation. or closes the export dialog box.
    if (fileName.isEmpty())
        return;

    // show the progressbar and set the message in status bar
    mpProgressBar->setRange(0, 0);
    showProgressBar();
    mpStatusBar->showMessage(Helper::exportAsImage);
    QPainter painter;
    QSvgGenerator svgGenerator;
    QPixmap modelImage(pCurrentTab->mpDiagramGraphicsView->viewport()->size());
    GraphicsView *graphicsView;
    if (pCurrentTab->mpIconGraphicsView->isVisible())
         graphicsView = pCurrentTab->mpIconGraphicsView;
    else
        graphicsView = pCurrentTab->mpDiagramGraphicsView;

    // export svg
    if (fileName.endsWith(".svg"))
    {
        svgGenerator.setTitle(tr("OMEdit - OpenModelica Connection Editor"));
        svgGenerator.setDescription(tr("Generated by OpenModelica Connection Editor Tool"));
        svgGenerator.setSize(graphicsView->viewport()->size());
        svgGenerator.setViewBox(graphicsView->viewport()->rect());
        svgGenerator.setFileName(fileName);
        painter.begin(&svgGenerator);
    }
    else
    {
        modelImage.fill(QColor(Qt::transparent));
        painter.begin(&modelImage);
    }

    painter.setWindow(graphicsView->viewport()->rect());
    // paint the background color first
    if (graphicsView->mIconType == StringHandler::DIAGRAM)
        painter.fillRect(painter.viewport(), graphicsView->palette().background());
    else
        painter.fillRect(painter.viewport(), Qt::white);
    // paint all the items
    graphicsView->render(&painter);
    painter.end();

    if (!fileName.endsWith(".svg"))
    {
        if (!modelImage.save(fileName))
            mpMessageWidget->printGUIErrorMessage("Error saving the image file.");
    }
    // hide the progressbar and clear the message in status bar
    mpStatusBar->clearMessage();
    hideProgressBar();
}

void MainWindow::openConfigurationOptions()
{
    this->mpOptionsWidget->show();
}

void MainWindow::checkModel()
{
    ProjectTab *pCurrentTab = mpProjectTabs->getCurrentTab();
    if (pCurrentTab)
    {
        // validate the modelica text before checking the model
        if (pCurrentTab->mpModelicaEditor->validateText())
        {
            CheckModelWidget *widget = new CheckModelWidget(pCurrentTab->mModelName, pCurrentTab->mModelNameStructure,
                                                            this);
            widget->show();
        }
    }
}

void MainWindow::flatModel()
{
    ProjectTab *pCurrentTab = mpProjectTabs->getCurrentTab();
    if (pCurrentTab)
    {
        // validate the modelica text before instantiating the model
        if (pCurrentTab->mpModelicaEditor->validateText())
        {
            FlatModelWidget *widget = new FlatModelWidget(pCurrentTab->mModelName, pCurrentTab->mModelNameStructure,
                                                          this);
            widget->show();
        }
    }
}

void MainWindow::openUserManual()
{
    QUrl userManualPath (QString("file:///").append(Helper::OpenModelicaHome.replace("\\", "/"))
                        .append("/share/doc/omedit/OMEdit-UserManual.pdf"));
    QDesktopServices::openUrl(userManualPath);
}

void MainWindow::openAbout()
{
    const char* dateStr = __DATE__; // "Mmm dd yyyy", so dateStr+7 = "yyyy"
    QString OMCVersion = mpOMCProxy->getVersion();
    QString aboutText = QString("OMEdit - ").append(Helper::applicationIntroText).append(" ")
                        .append(Helper::applicationVersion).append("\n")
                        .append("Connected to OpenModelica ").append(OMCVersion).append("\n\n")
                        .append("Copyright ").append(dateStr + 7)
                        .append(" Link").append(QChar(246, 0)).append("ping University.\n")
                        .append("Distributed under OSMC-PL and GPL, see www.openmodelica.org.\n\n")
                        .append("Created by Adeel Asghar and Sonia Tariq as part of their final thesis.");

    QMessageBox::about(this, QString("About ").append(Helper::applicationName), aboutText);
}

void MainWindow::toggleShapesButton()
{
    QAction *clickedAction = qobject_cast<QAction*>(const_cast<QObject*>(sender()));

    QList<QAction*> shapeActions = shapesActionGroup->actions();
    foreach (QAction *shapeAction, shapeActions)
    {
        if (shapeAction != clickedAction)
        {
            shapeAction->setChecked(false);
        }
    }
}

void MainWindow::changeConnectMode()
{

}

//! Sets the focus on the MSL search text box when the MSL Search dock window is shown
//! Connected to searchMSLdock signal visibilitychanged.
void MainWindow::focusMSLSearch(bool visible)
{
    if (visible)
        mpSearchMSLWidget->getMSLSearchTextBox()->setFocus();
}

void MainWindow::switchToModelingView()
{
    modelingViewAction->setChecked(true);
    mpProjectTabs->setVisible(true);
    mpInteractiveSimualtionTabWidget->setVisible(false);
    mpPlotWindowContainer->setVisible(false);
    plotToolBar->setVisible(false);
}

void MainWindow::switchToPlottingView()
{
    // if not plotwindow is opened then open one for user
    if (mpPlotWindowContainer->subWindowList().size() == 0)
        mpPlotWindowContainer->addPlotWindow();

    plottingViewAction->setChecked(true);
    mpProjectTabs->setVisible(false);
    mpInteractiveSimualtionTabWidget->setVisible(false);
    mpPlotWindowContainer->setVisible(true);
    plotToolBar->setVisible(true);
}

void MainWindow::switchToInteractiveSimulationView()
{
    interactiveSimulationViewAction->setChecked(true);
    mpProjectTabs->setVisible(false);
    mpInteractiveSimualtionTabWidget->setVisible(true);
    mpPlotWindowContainer->setVisible(false);
    plotToolBar->setVisible(false);
}

void MainWindow::addNewPlotWindow()
{
    mpPlotWindowContainer->addPlotWindow();
}

void MainWindow::addNewPlotParametricWindow()
{
    mpPlotWindowContainer->addPlotParametricWindow();
}

//! shows the progress bar contained inside the status bar
//! @see hideProgressBar()
void MainWindow::showProgressBar()
{
    mpProgressBar->setVisible(true);
}

//! hides the progress bar contained inside the status bar
//! @see hideProgressBar()
void MainWindow::hideProgressBar()
{
    mpProgressBar->setVisible(false);
}
