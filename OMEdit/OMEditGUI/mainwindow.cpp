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
 * Based on HopsanGUI
 * Fluid and Mechatronic Systems, Department of Management and Engineering, Linkoping University
 * Main Authors 2009-2010:  Robert Braun, Bjorn Eriksson, Peter Nordin
 * Contributors 2009-2010:  Mikael Axin, Alessandro Dell'Amico, Karl Pettersson, Ingo Staack
 */

/*
 * RCS: $Id$
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
  splashScreen->showMessage(tr("Connecting to OpenModelica Compiler"), Qt::AlignRight, Qt::white);
  mpOMCProxy = new OMCProxy(this);
  if (mExitApplication)
    return;
  splashScreen->showMessage(tr("Reading Settings"), Qt::AlignRight, Qt::white);
  mpOptionsWidget = new OptionsWidget(this);
  //Set the name and size of the main window
  splashScreen->showMessage(tr("Loading Widgets"), Qt::AlignRight, Qt::white);
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
#ifdef Q_OS_MAC
  mpCentralgrid->setContentsMargins(0, 7, 0, 0);
#else
  mpCentralgrid->setContentsMargins(0, 1, 0, 0);
#endif
  //Create a dock for the MessageWidget
  mpMessageDockWidget = new QDockWidget(tr("Messages"), this);
  mpMessageDockWidget->setObjectName("Messages");
  mpMessageDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea | Qt::BottomDockWidgetArea);
#ifdef Q_OS_MAC
  mpMessageDockWidget->setContentsMargins(0, 6, 1, 0);
#else
  mpMessageDockWidget->setContentsMargins(0, 1, 1, 0);
#endif
  mpMessageDockWidget->setFeatures(QDockWidget::DockWidgetVerticalTitleBar | QDockWidget::DockWidgetClosable
                                   | QDockWidget::DockWidgetMovable | QDockWidget::DockWidgetFloatable);
  mpMessageWidget = new ProblemsWidget(this);
  mpMessageDockWidget->setWidget(mpMessageWidget);
  addDockWidget(Qt::BottomDockWidgetArea, mpMessageDockWidget);
  // load library
  mpLibrary = new LibraryWidget(this);
  // Loads and adds the OM Standard Library into the Library Widget.
  splashScreen->showMessage(tr("Loading Modelica Standard Library"), Qt::AlignRight, Qt::white);
  mpLibrary->mpLibraryTree->addModelicaStandardLibrary();
  //Create a dock for the search MSL
  mpSearchMSLDockWidget = new QDockWidget(tr("Search MSL"), this);
  mpSearchMSLDockWidget->setObjectName("Search MSL");
  mpSearchMSLDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpSearchMSLWidget = new SearchMSLWidget(this);
  mpSearchMSLDockWidget->setWidget(mpSearchMSLWidget);
  addDockWidget(Qt::LeftDockWidgetArea, mpSearchMSLDockWidget);
  connect(mpSearchMSLDockWidget, SIGNAL(visibilityChanged(bool)), SLOT(focusMSLSearch(bool)));
  mpSearchMSLDockWidget->hide();
  //Create a dock for the componentslibrary
  mpLibraryDockWidget = new QDockWidget(tr("Components"), this);
  mpLibraryDockWidget->setObjectName("Components");
  mpLibraryDockWidget->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
  mpLibraryDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpLibraryDockWidget->setWidget(mpLibrary);
  addDockWidget(Qt::LeftDockWidgetArea, mpLibraryDockWidget);
  //create a dock for the model browser
  mpModelBrowserDockWidget = new QDockWidget(tr("Model Browser"), this);
  mpModelBrowserDockWidget->setObjectName("Model Browser");
#ifdef Q_OS_MAC
  mpMessageDockWidget->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Preferred);
#else
  mpModelBrowserDockWidget->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Maximum);
#endif
  mpModelBrowserDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpModelBrowser = new ModelBrowserWidget(this);
  mpModelBrowserDockWidget->setWidget(mpModelBrowser);
  addDockWidget(Qt::LeftDockWidgetArea, mpModelBrowserDockWidget);
  //Set dock widget corner owner
  setCorner(Qt::BottomLeftCorner, Qt::LeftDockWidgetArea);
  // Create simulation widget.
  mpSimulationWidget = new SimulationWidget(this);
  // create the plot container widget
  mpPlotWindowContainer = new PlotWindowContainer(this);
  // create the interactive simulation widget
  mpInteractiveSimualtionTabWidget = new InteractiveSimulationTabWidget(this);
  // plot dock
  mpPlotDockWidget = new QDockWidget(tr("Plot Variables"), this);
  mpPlotDockWidget->setObjectName("Plot Variables");
  mpPlotDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpPlotDockWidget->setContentsMargins(0, 1, 1, 1);
  mpPlotWidget = new PlotWidget(this);
  mpPlotDockWidget->setWidget(mpPlotWidget);
  addDockWidget(Qt::RightDockWidgetArea, mpPlotDockWidget);
  mpPlotDockWidget->hide();
  // plot dock
  mpDocumentationDockWidget = new QDockWidget(tr("Documentation"), this);
  mpDocumentationDockWidget->setObjectName("Documentation");
  mpDocumentationDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpDocumentationDockWidget->setContentsMargins(0, 1, 1, 1);
  mpDocumentationWidget = new DocumentationWidget(this);
  mpDocumentationDockWidget->setWidget(mpDocumentationWidget);
  addDockWidget(Qt::RightDockWidgetArea, mpDocumentationDockWidget);
  mpDocumentationDockWidget->hide();
  //Create Actions, Toolbar and Menus
  splashScreen->showMessage(tr("Creating Components"), Qt::AlignRight, Qt::white);
  setAcceptDrops(true);
  createActions();
  createToolbars();
  createMenus();
  //Create the main tab container, need at least one tab
  mpProjectTabs = new ProjectTabWidget(this);
  mpProjectTabs->setObjectName("projectTabs");
  // create the welcome page
  mpWelcomePageWidget = new WelcomePageWidget(this);
  updateRecentFileActions();
  // set the layout
  mpCentralgrid->addWidget(mpWelcomePageWidget, 0, 0);
  mpCentralgrid->addWidget(mpProjectTabs, 1, 0);
  mpCentralgrid->addWidget(mpPlotWindowContainer, 1, 0);
  mpCentralgrid->addWidget(mpInteractiveSimualtionTabWidget, 1, 0);
  mpCentralwidget->setLayout(mpCentralgrid);
  //Set the centralwidget
  setCentralWidget(mpCentralwidget);
  //Create the Statusbar
  mpStatusBar = new QStatusBar();
  mpStatusBar->setObjectName("statusBar");
  mpStatusBar->setContentsMargins(0, 0, 1, 0);
  mpProgressBar = new QProgressBar;
  mpProgressBar->setMaximumWidth(300);
  mpProgressBar->setTextVisible(false);
  mpProgressBar->setVisible(false);
  mpStatusBar->addPermanentWidget(mpProgressBar);
  setStatusBar(mpStatusBar);
  // Create a New Project Widget
  mpModelCreator = new ModelCreator(this);
  connect(this, SIGNAL(fileOpen(QString)), mpProjectTabs, SLOT(openFile(QString)));
  QMetaObject::connectSlotsByName(this);
  // restore OMEdit widgets state
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omedit");
  if (mpOptionsWidget->mpGeneralSettingsPage->getPreserveUserCustomizations())
  {
    restoreGeometry(settings.value("application/geometry").toByteArray());
    restoreState(settings.value("application/windowState").toByteArray(), Helper::settingsVersion);
  }
}

//! Destructor
MainWindow::~MainWindow()
{
  delete mpProjectTabs;
  delete mpMenuBar;
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
    mpOMCProxy->stopServer();
    delete mpOMCProxy;
    mpProjectTabs->blockSignals(true);
    // save OMEdit widgets state
    if (mpOptionsWidget->mpGeneralSettingsPage->getPreserveUserCustomizations())
    {
      QSettings settings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omedit");
      settings.setValue("application/geometry", saveGeometry());
      settings.setValue("application/windowState", saveState(Helper::settingsVersion));
    }
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
  setFocus();
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
        mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0, message, Helper::scriptingKind, Helper::errorLevel, 0,
                                                       mpMessageWidget->mpProblem));
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
  // File Menu
  // New Model Action
  mpNewModelAction = new QAction(StringHandler::getModelicaClassType(StringHandler::MODEL), this);
  mpNewModelAction->setStatusTip(tr("Create New Model"));
  mpNewModelAction->setShortcut(QKeySequence("Ctrl+n"));
  connect(mpNewModelAction, SIGNAL(triggered()), SLOT(openNewModel()));
  // New Class Action
  mpNewClassAction = new QAction(StringHandler::getModelicaClassType(StringHandler::CLASS), this);
  mpNewClassAction->setStatusTip(tr("Create New Class"));
  connect(mpNewClassAction, SIGNAL(triggered()), SLOT(openNewClass()));
  // New Connector Action
  mpNewConnectorAction = new QAction(StringHandler::getModelicaClassType(StringHandler::CONNECTOR), this);
  mpNewConnectorAction->setStatusTip(tr("Create New Connector"));
  connect(mpNewConnectorAction, SIGNAL(triggered()), SLOT(openNewConnector()));
  // New Record Action
  mpNewRecordAction = new QAction(StringHandler::getModelicaClassType(StringHandler::RECORD), this);
  mpNewRecordAction->setStatusTip(tr("Create New Record"));
  connect(mpNewRecordAction, SIGNAL(triggered()), SLOT(openNewRecord()));
  // New Block Action
  mpNewBlockAction = new QAction(StringHandler::getModelicaClassType(StringHandler::BLOCK), this);
  mpNewBlockAction->setStatusTip(tr("Create New Block"));
  connect(mpNewBlockAction, SIGNAL(triggered()), SLOT(openNewBlock()));
  // New Function Action
  mpNewFunctionAction = new QAction(StringHandler::getModelicaClassType(StringHandler::FUNCTION), this);
  mpNewFunctionAction->setStatusTip(tr("Create New Function"));
  connect(mpNewFunctionAction, SIGNAL(triggered()), SLOT(openNewFunction()));
  // New Package Action
  mpNewPackageAction = new QAction(StringHandler::getModelicaClassType(StringHandler::PACKAGE), this);
  mpNewPackageAction->setStatusTip(tr("Create New Package"));
  mpNewPackageAction->setShortcut(QKeySequence("Ctrl+p"));
  connect(mpNewPackageAction, SIGNAL(triggered()), SLOT(openNewPackage()));
  // Open Action
  mpOpenAction = new QAction(QIcon(":/Resources/icons/open.png"), tr("Open"), this);
  mpOpenAction->setShortcut(QKeySequence("Ctrl+o"));
  mpOpenAction->setStatusTip(tr("Opens Modelica file"));
  // Save Action
  mpSaveAction = new QAction(QIcon(":/Resources/icons/save.png"), Helper::save, this);
  mpSaveAction->setShortcut(QKeySequence("Ctrl+s"));
  mpSaveAction->setStatusTip(tr("Save a file"));
  // SaveAs Action
  mpSaveAsAction = new QAction(QIcon(":/Resources/icons/saveas.png"), tr("Save As"), this);
  mpSaveAsAction->setShortcut(QKeySequence("Ctrl+Shift+s"));
  mpSaveAsAction->setStatusTip(tr("Save As a File"));
  // SaveAll Action
  mpSaveAllAction = new QAction(QIcon(":/Resources/icons/saveall.png"), tr("Save All"), this);
  mpSaveAllAction->setStatusTip(tr("Save All Files"));
  // Recent Files Actions
  for (int i = 0; i < MaxRecentFiles; ++i)
  {
    mpRecentFileActions[i] = new QAction(this);
    mpRecentFileActions[i]->setVisible(false);
    connect(mpRecentFileActions[i], SIGNAL(triggered()), this, SLOT(openRecentFile()));
  }
  // close Action
  mpCloseAction = new QAction(QIcon(":/Resources/icons/close.png"), tr("Close"), this);
  mpCloseAction->setStatusTip(tr("Exits the ").append(Helper::applicationIntroText));
  mpCloseAction->setShortcut(QKeySequence("Ctrl+q"));
  connect(mpCloseAction,SIGNAL(triggered()), SLOT(close()));
  // Edit Menu
  // Undo Action
  mpUndoAction = new QAction(QIcon(":/Resources/icons/undo.png"), tr("Undo"), this);
  mpUndoAction->setShortcut(QKeySequence("Ctrl+z"));
  mpUndoAction->setStatusTip(tr("Undo last activity"));
  // Redo Action
  mpRedoAction = new QAction(QIcon(":/Resources/icons/redo.png"), tr("Redo"), this);
  mpRedoAction->setShortcut(QKeySequence("Ctrl+y"));
  mpRedoAction->setStatusTip(tr("Redo last activity"));
  // Cut Action
  mpCutAction = new QAction(QIcon(":/Resources/icons/cut.png"), tr("Cut"), this);
  mpCutAction->setShortcut(QKeySequence("Ctrl+x"));
  // Copy Action
  mpCopyAction = new QAction(QIcon(":/Resources/icons/copy.png"), Helper::copy, this);
  //copyAction->setShortcut(QKeySequence("Ctrl+c"));
  //! @todo opening this will stop copying data from messages window.
  // Paste Action
  mpPasteAction = new QAction(QIcon(":/Resources/icons/paste.png"), Helper::paste, this);
  mpPasteAction->setShortcut(QKeySequence("Ctrl+v"));
  // View Menu
  // Welcome View Action
  mpWelcomeViewAction = new QAction(tr("Welcome Page"), this);
  mpWelcomeViewAction->setStatusTip(tr("Shows Welcome Page"));
  mpWelcomeViewAction->setCheckable(true);
  mpWelcomeViewAction->setChecked(true);
  connect(mpWelcomeViewAction, SIGNAL(toggled(bool)), SLOT(switchToWelcomeView(bool)));
  // Views Actions Group
  mpViewActionGroup = new QActionGroup(this);
  mpViewActionGroup->setExclusive(true);
  // Modelling View Action
  mpModelingViewAction = new QAction(QIcon(":/Resources/icons/omeditor.png"), tr("Modeling"), mpViewActionGroup);
  mpModelingViewAction->setStatusTip(tr("Shows Modeling View"));
  mpModelingViewAction->setShortcut(QKeySequence("Ctrl+Shift+m"));
  mpModelingViewAction->setCheckable(true);
  connect(mpModelingViewAction, SIGNAL(triggered()), SLOT(switchToModelingView()));
  // Plotting View Action
  mpPlottingViewAction = new QAction(QIcon(":/Resources/icons/omplot.png"), tr("Plotting"), mpViewActionGroup);
  mpPlottingViewAction->setStatusTip(tr("Shows Plotting View"));
  mpPlottingViewAction->setShortcut(QKeySequence("Ctrl+Shift+p"));
  mpPlottingViewAction->setCheckable(true);
  connect(mpPlottingViewAction, SIGNAL(triggered()), SLOT(switchToPlottingView()));
  // Interactive Simulation View Action
  mpInteractiveSimulationViewAction = new QAction(QIcon(":/Resources/icons/interactive-simulation.png"),
                                                  tr("Interactive Simulation"), mpViewActionGroup);
  mpInteractiveSimulationViewAction->setStatusTip(tr("Shows Interactive Simulation View"));
  mpInteractiveSimulationViewAction->setShortcut(QKeySequence("Ctrl+Shift+i"));
  mpInteractiveSimulationViewAction->setCheckable(true);
  mpInteractiveSimulationViewAction->setEnabled(false);
  connect(mpInteractiveSimulationViewAction, SIGNAL(triggered()), SLOT(switchToInteractiveSimulationView()));
  // Grid Lines Action
  mpGridLinesAction = new QAction(QIcon(":/Resources/icons/grid.png"), tr("Grid Lines"), this);
  mpGridLinesAction->setStatusTip(tr("Show/Hide the grid lines"));
  mpGridLinesAction->setCheckable(true);
  // Reset Zoom Action
  mpResetZoomAction = new QAction(QIcon(":/Resources/icons/zoom100.png"), tr("Reset Zoom"), this);
  mpResetZoomAction->setStatusTip(tr("Resets the zoom"));
  mpResetZoomAction->setShortcut(QKeySequence("Ctrl+0"));
  // Zoom In Action
  mpZoomInAction = new QAction(QIcon(":/Resources/icons/zoomIn.png"), tr("Zoom In"), this);
  mpZoomInAction->setShortcut(QKeySequence("Ctrl++"));
  // Zoom Out Action
  mpZoomOutAction = new QAction(QIcon(":/Resources/icons/zoomOut.png"), tr("Zoom Out"), this);
  mpZoomOutAction->setShortcut(QKeySequence("Ctrl+-"));
  // Simulation Menu
  // Simulate Action
  mpSimulationAction = new QAction(QIcon(":/Resources/icons/simulate.png"), Helper::simulate, this);
  mpSimulationAction->setStatusTip(tr("Simulate the Model"));
  connect(mpSimulationAction, SIGNAL(triggered()), SLOT(openSimulation()));
  // Interactive Simulation Action
  mpInteractiveSimulationAction = new QAction(QIcon(":/Resources/icons/interactive-simulation.png"), Helper::interactiveSimulation, this);
  mpInteractiveSimulationAction->setStatusTip(tr("Interactive Simulate the Model"));
  mpInteractiveSimulationAction->setEnabled(false);
  connect(mpInteractiveSimulationAction, SIGNAL(triggered()), SLOT(openInteractiveSimulation()));
  // check Model Action
  mpCheckModelAction = new QAction(QIcon(":/Resources/icons/check.png"), Helper::checkModel, this);
  mpCheckModelAction->setStatusTip(Helper::checkModelTip);
  connect(mpCheckModelAction, SIGNAL(triggered()), SLOT(checkModel()));
  // Instantiate Model Action
  mpFlatModelAction = new QAction(QIcon(":/Resources/icons/flatmodel.png"), Helper::instantiateModel, this);
  mpFlatModelAction->setStatusTip(Helper::instantiateModelTip);
  connect(mpFlatModelAction, SIGNAL(triggered()), SLOT(flatModel()));
  // FMI Menu
  // Export FMI Action
  mpExportFMIAction = new QAction(QIcon(":/Resources/icons/export-fmi.png"), tr("Export FMI"), this);
  mpExportFMIAction->setStatusTip(tr("Exports the model as Functional Mockup Interface (FMI)"));
  mpExportFMIAction->setEnabled(false);
  connect(mpExportFMIAction, SIGNAL(triggered()), SLOT(exportModelFMI()));
  // Import FMI Action
  mpImportFMIAction = new QAction(QIcon(":/Resources/icons/import-fmi.png"), Helper::importFMI, this);
  mpImportFMIAction->setStatusTip(tr("Imports the model from Functional Mockup Interface (FMI)"));
  connect(mpImportFMIAction, SIGNAL(triggered()), SLOT(importModelFMI()));
  // Tools Menu
  // OMC Logger Action
  mpOMCLoggerAction = new QAction(QIcon(":/Resources/icons/console.png"), tr("OMC Logger"), this);
  mpOMCLoggerAction->setStatusTip(tr("Shows OMC Logger Window"));
  connect(mpOMCLoggerAction, SIGNAL(triggered()), mpOMCProxy, SLOT(openOMCLogger()));
  // OMShell Action
  mpOpenOMShellAction = new QAction(QIcon(":/Resources/icons/omshell.svg"), tr("OMShell"), this);
  mpOpenOMShellAction->setStatusTip(tr("Opens OpenModelica Shell (OMShell)"));
  connect(mpOpenOMShellAction, SIGNAL(triggered()), SLOT(openOMShell()));
  // Export OMNotebook Action
  mpExportToOMNotebookAction = new QAction(QIcon(":/Resources/icons/export-omnotebook.png"), Helper::exportToOMNotebook, this);
  mpExportToOMNotebookAction->setStatusTip(tr("Exports the current model to OMNotebook"));
  mpExportToOMNotebookAction->setEnabled(false);
  connect(mpExportToOMNotebookAction, SIGNAL(triggered()), SLOT(exportModelToOMNotebook()));
  // Import OMNotebook Action
  mpImportFromOMNotebookAction = new QAction(QIcon(":/Resources/icons/import-omnotebook.png"), tr("Import from OMNotebook"), this);
  mpImportFromOMNotebookAction->setStatusTip(tr("Imports the models from OMNotebook"));
  connect(mpImportFromOMNotebookAction, SIGNAL(triggered()), SLOT(importModelfromOMNotebook()));
  // Options Action
  mpOpenOptionsAction = new QAction(Helper::options, this);
  mpOpenOptionsAction->setStatusTip(tr("Shows the options window"));
  connect(mpOpenOptionsAction, SIGNAL(triggered()), SLOT(openConfigurationOptions()));
  // Help Menu
  // User Manual Action
  mpUserManualAction = new QAction(tr("User Manual"), this);
  mpUserManualAction->setStatusTip(tr("Opens the User Manual"));
  mpUserManualAction->setShortcut(QKeySequence(Qt::Key_F1));
  connect(mpUserManualAction, SIGNAL(triggered()), SLOT(openUserManual()));
  // About OMEdit Action
  mpAboutOMEditAction = new QAction(tr("About OMEdit"), this);
  mpAboutOMEditAction->setStatusTip(tr("Information about OMEdit"));
  connect(mpAboutOMEditAction, SIGNAL(triggered()), SLOT(openAbout()));
  // Shapes Toolbar Actions
  mpShapesActionGroup = new QActionGroup(this);
  mpShapesActionGroup->setExclusive(false);
  // Line Shape Action
  mpLineAction = new QAction(QIcon(":/Resources/icons/line-shape.png"), tr("Line"), mpShapesActionGroup);
  mpLineAction->setStatusTip(tr("Draws a line."));
  mpLineAction->setCheckable(true);
  connect(mpLineAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // Polygon Shape Action
  mpPolygonAction = new QAction(QIcon(":/Resources/icons/polygon-shape.png"), tr("Polygon"), mpShapesActionGroup);
  mpPolygonAction->setStatusTip(tr("Draws a polygon."));
  mpPolygonAction->setCheckable(true);
  connect(mpPolygonAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // Rectangle Shape Action
  mpRectangleAction = new QAction(QIcon(":/Resources/icons/rectangle-shape.png"), tr("Rectangle"), mpShapesActionGroup);
  mpRectangleAction->setStatusTip(tr("Draws a rectangle."));
  mpRectangleAction->setCheckable(true);
  connect(mpRectangleAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // Ellipse Shape Action
  mpEllipseAction = new QAction(QIcon(":/Resources/icons/ellipse-shape.png"), tr("Ellipse"), mpShapesActionGroup);
  mpEllipseAction->setStatusTip(tr("Draws an Ellipse."));
  mpEllipseAction->setCheckable(true);
  connect(mpEllipseAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // Text Shape Action
  mpTextAction = new QAction(QIcon(":/Resources/icons/text-shape.png"), Helper::text, mpShapesActionGroup);
  mpTextAction->setStatusTip(tr("Draws a Text."));
  mpTextAction->setCheckable(true);
  connect(mpTextAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // Bitmap Shape Action
  mpBitmapAction = new QAction(QIcon(":/Resources/icons/bitmap-shape.png"), tr("Bitmap"), mpShapesActionGroup);
  mpBitmapAction->setStatusTip(tr("Imports a Bitmap."));
  mpBitmapAction->setCheckable(true);
  connect(mpBitmapAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // Connect Action
  mpConnectAction = new QAction(QIcon(":/Resources/icons/connector-icon.png"), tr("Connect Mode"),this);
  mpConnectAction->setStatusTip(tr("Changes to/from connect mode"));
  mpConnectAction->setCheckable(true);
  mpConnectAction->setChecked(true);
  connect(mpConnectAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // Plot Toolbar Actions
  mpNewPlotWindowAction = new QAction(QIcon(":/Resources/icons/plotwindow.png"), tr("New Plot Window"), this);
  mpNewPlotWindowAction->setStatusTip(tr("Inserts new plot window"));
  connect(mpNewPlotWindowAction, SIGNAL(triggered()), SLOT(addNewPlotWindow()));
  mpNewPlotParametricWindowAction = new QAction(QIcon(":/Resources/icons/plotparametricwindow.png"), tr("New Plot Parametric Window"), this);
  mpNewPlotParametricWindowAction->setStatusTip(tr("Inserts new plot parametric window"));
  connect(mpNewPlotParametricWindowAction, SIGNAL(triggered()), SLOT(addNewPlotParametricWindow()));
  // Other Actions
  // Export As Image Action
  mpExportAsImageAction = new QAction(QIcon(":/Resources/icons/bitmap-shape.png"), tr("Export as an Image"), this);
  mpExportAsImageAction->setStatusTip(tr("Exports the current model to Image"));
  mpExportAsImageAction->setEnabled(false);
  connect(mpExportAsImageAction, SIGNAL(triggered()), SLOT(exportModelAsImage()));
}

//! Creates the menus
void MainWindow::createMenus()
{
  //Create the menubar
  mpMenuBar = new QMenuBar();
  mpMenuBar->setGeometry(QRect(0,0,800,25));
  mpMenuBar->setObjectName("menubar");
  // File Menu
  mpFileMenu = new QMenu(mpMenuBar);
  mpFileMenu->setObjectName("menuFile");
  mpFileMenu->setTitle(tr("&File"));
  // File New Menu
  mpFileNewMenu = new QMenu(mpMenuBar);
  mpFileNewMenu->setObjectName("menuNew");
  mpFileNewMenu->setTitle(tr("New"));
  // Add actions to File Menu
  mpFileNewMenu->addAction(mpNewModelAction);
  mpFileNewMenu->addAction(mpNewClassAction);
  mpFileNewMenu->addAction(mpNewConnectorAction);
  mpFileNewMenu->addAction(mpNewRecordAction);
  mpFileNewMenu->addAction(mpNewBlockAction);
  mpFileNewMenu->addAction(mpNewFunctionAction);
  mpFileNewMenu->addAction(mpNewPackageAction);
  mpFileMenu->addAction(mpFileNewMenu->menuAction());
  mpFileMenu->addAction(mpOpenAction);
  mpFileMenu->addAction(mpSaveAction);
  mpFileMenu->addAction(mpSaveAsAction);
  //menuFile->addAction(saveAllAction);
  mpSeparatorAction = mpFileMenu->addSeparator();
  for (int i = 0; i < MaxRecentFiles; ++i)
    mpFileMenu->addAction(mpRecentFileActions[i]);
  mpFileMenu->addSeparator();
  mpFileMenu->addAction(mpCloseAction);
  // Edit Menu
  mpEditMenu = new QMenu(mpMenuBar);
  mpEditMenu->setTitle(tr("&Edit"));
  // Add actions to Edit Menu
  //menuEdit->addAction(undoAction);
  //menuEdit->addAction(redoAction);
  mpEditMenu->addSeparator();
  mpEditMenu->addAction(mpCutAction);
  mpEditMenu->addAction(mpCopyAction);
  mpEditMenu->addAction(mpPasteAction);
  // View Menu
  mpViewMenu = new QMenu(mpMenuBar);
  mpViewMenu->setTitle(tr("&View"));
  // Toolbars View Menu
  mpViewToolbarsMenu = new QMenu(mpMenuBar);
  mpViewToolbarsMenu->setObjectName("ToolbarsViewMenu");
  mpViewToolbarsMenu->setTitle(tr("Toolbars"));
  // Windows View Menu
  mpViewWindowsMenu = new QMenu(mpMenuBar);
  mpViewWindowsMenu->setObjectName("WindowsViewMenu");
  mpViewWindowsMenu->setTitle(tr("Windows"));
  // Perspectives View Menu
  mpViewPerspectivesMenu = new QMenu(mpMenuBar);
  mpViewPerspectivesMenu->setObjectName("PerspectivesViewMenu");
  mpViewPerspectivesMenu->setTitle(tr("Perspectives"));
  // Add actions to View Menu
  // Add Actions to Toolbars View Sub Menu
  mpViewToolbarsMenu->addAction(mpFileToolBar->toggleViewAction());
  //mpToolbarsViewMenu->addAction(editToolBar->toggleViewAction());
  mpViewToolbarsMenu->addAction(mpViewToolBar->toggleViewAction());
  mpViewToolbarsMenu->addAction(mpShapesToolBar->toggleViewAction());
  mpViewToolbarsMenu->addAction(mpSimulationToolBar->toggleViewAction());
  mpViewToolbarsMenu->addAction(mpOMNotebookToolbar->toggleViewAction());
  mpViewToolbarsMenu->addAction(mpPlotToolBar->toggleViewAction());
  mpViewToolbarsMenu->addAction(mpPerspectiveToolBar->toggleViewAction());
  mpViewMenu->addAction(mpViewToolbarsMenu->menuAction());
  // Add Actions to Windows View Sub Menu
  QAction *searchMSLAction = mpSearchMSLDockWidget->toggleViewAction();
  searchMSLAction->setShortcut(QKeySequence("Ctrl+Shift+f"));
  mpViewWindowsMenu->addAction(searchMSLAction);
  mpViewWindowsMenu->addAction(mpLibraryDockWidget->toggleViewAction());
  mpViewWindowsMenu->addAction(mpModelBrowserDockWidget->toggleViewAction());
  mpViewWindowsMenu->addAction(mpMessageDockWidget->toggleViewAction());
  mpViewWindowsMenu->addAction(mpDocumentationDockWidget->toggleViewAction());
  mpViewWindowsMenu->addAction(mpPlotDockWidget->toggleViewAction());
  mpViewMenu->addAction(mpViewWindowsMenu->menuAction());
  // Add Actions to Perspectives View Sub Menu
  mpViewPerspectivesMenu->addAction(mpWelcomeViewAction);
  mpViewPerspectivesMenu->addAction(mpModelingViewAction);
  mpViewPerspectivesMenu->addAction(mpPlottingViewAction);
  // TODO: mpViewPerspectivesMenu->addAction(mpInteractiveSimulationViewAction);
  mpViewMenu->addAction(mpViewPerspectivesMenu->menuAction());
  mpViewMenu->addSeparator();
  mpViewMenu->addAction(mpGridLinesAction);
  mpViewMenu->addAction(mpResetZoomAction);
  mpViewMenu->addAction(mpZoomInAction);
  mpViewMenu->addAction(mpZoomOutAction);
  // Simulation Menu
  mpSimulationMenu = new QMenu(mpMenuBar);
  mpSimulationMenu->setTitle(tr("&Simulation"));
  // Add Actions to Simulation Menu
  mpSimulationMenu->addAction(mpSimulationAction);
  // TODO: mpSimulationMenu->addAction(mpInteractiveSimulationAction);
  mpSimulationMenu->addSeparator();
  mpSimulationMenu->addAction(mpFlatModelAction);
  mpSimulationMenu->addAction(mpCheckModelAction);
  // FMI Menu
  mpFMIMenu = new QMenu(mpMenuBar);
  mpFMIMenu->setTitle(tr("F&MI"));
  // Add Actions to FMI Menu
  mpFMIMenu->addAction(mpExportFMIAction);
  mpFMIMenu->addAction(mpImportFMIAction);
  // Tools Menu
  mpMenuTools = new QMenu(mpMenuBar);
  mpMenuTools->setTitle(tr("&Tools"));
  // Add Actions to Tools Menu
  mpMenuTools->addAction(mpOMCLoggerAction);
  mpMenuTools->addSeparator();
  mpMenuTools->addAction(mpOpenOMShellAction);
  mpMenuTools->addSeparator();
  mpMenuTools->addAction(mpExportToOMNotebookAction);
  mpMenuTools->addAction(mpImportFromOMNotebookAction);
  mpMenuTools->addSeparator();
  mpMenuTools->addAction(mpOpenOptionsAction);
  // Help Menu
  mpHelpMenu = new QMenu(mpMenuBar);
  mpHelpMenu->setTitle(tr("&Help"));
  // Add Actions to Help Menu
  mpHelpMenu->addAction(mpUserManualAction);
  mpHelpMenu->addAction(mpAboutOMEditAction);
  // Add all menus to the menubar
  mpMenuBar->addAction(mpFileMenu->menuAction());
  mpMenuBar->addAction(mpEditMenu->menuAction());
  mpMenuBar->addAction(mpViewMenu->menuAction());
  mpMenuBar->addAction(mpSimulationMenu->menuAction());
  mpMenuBar->addAction(mpFMIMenu->menuAction());
  mpMenuBar->addAction(mpMenuTools->menuAction());
  mpMenuBar->addAction(mpHelpMenu->menuAction());
  // Set the menubar
  setMenuBar(mpMenuBar);
}

//! Creates the toolbars
void MainWindow::createToolbars()
{
  // File Toolbar
  mpFileToolBar = addToolBar(tr("File Toolbar"));
  mpFileToolBar->setObjectName("File Toolbar");
  mpFileToolBar->setAllowedAreas(Qt::TopToolBarArea);
  QToolButton *newMenuButton = new QToolButton(mpFileToolBar);
  QMenu *newMenu = new QMenu(newMenuButton);
  newMenu->addAction(mpNewModelAction);
  newMenu->addAction(mpNewClassAction);
  newMenu->addAction(mpNewConnectorAction);
  newMenu->addAction(mpNewRecordAction);
  newMenu->addAction(mpNewBlockAction);
  newMenu->addAction(mpNewFunctionAction);
  newMenu->addAction(mpNewPackageAction);
  newMenuButton->setMenu(newMenu);
  newMenuButton->setDefaultAction(mpNewModelAction);
  newMenuButton->setPopupMode(QToolButton::MenuButtonPopup);
  newMenuButton->setIcon(QIcon(":/Resources/icons/new.png"));
  mpFileToolBar->addWidget(newMenuButton);
  mpFileToolBar->addAction(mpOpenAction);
  mpFileToolBar->addAction(mpSaveAction);
  mpFileToolBar->addAction(mpSaveAsAction);
  //fileToolBar->addAction(saveAllAction);
  // Edit Toolbar
  //    editToolBar = addToolBar(tr("Clipboard Toolbar"));
  //    editToolBar->setAllowedAreas(Qt::TopToolBarArea);
  //    editToolBar->addAction(undoAction);
  //    editToolBar->addAction(redoAction);
  //    editToolBar->addAction(cutAction);
  //    editToolBar->addAction(copyAction);
  //    editToolBar->addAction(pasteAction);
  // View Toolbar
  mpViewToolBar = addToolBar(tr("View Toolbar"));
  mpViewToolBar->setObjectName("View Toolbar");
  mpViewToolBar->setAllowedAreas(Qt::TopToolBarArea);
  mpViewToolBar->addAction(mpGridLinesAction);
  mpViewToolBar->addSeparator();
  mpViewToolBar->addAction(mpResetZoomAction);
  mpViewToolBar->addAction(mpZoomInAction);
  mpViewToolBar->addAction(mpZoomOutAction);
  // Shapes Toobar
  mpShapesToolBar = addToolBar(tr("Shapes Toolbar"));
  mpShapesToolBar->setObjectName("Shapes Toolbar");
  mpShapesToolBar->setAllowedAreas(Qt::TopToolBarArea);
  mpShapesToolBar->addAction(mpLineAction);
  mpShapesToolBar->addAction(mpPolygonAction);
  mpShapesToolBar->addAction(mpRectangleAction);
  mpShapesToolBar->addAction(mpEllipseAction);
  mpShapesToolBar->addAction(mpTextAction);
  mpShapesToolBar->addAction(mpBitmapAction);
  mpShapesToolBar->addSeparator();
  mpShapesToolBar->addAction(mpConnectAction);
  // Simulation Toolbar
  mpSimulationToolBar = addToolBar(Helper::simulation);
  mpSimulationToolBar->setObjectName("Simulation");
  mpSimulationToolBar->setAllowedAreas(Qt::TopToolBarArea);
  mpSimulationToolBar->addAction(mpSimulationAction);
  // TODO: mpSimulationToolBar->addAction(mpInteractiveSimulationAction);
  mpSimulationToolBar->addSeparator();
  mpSimulationToolBar->addAction(mpFlatModelAction);
  mpSimulationToolBar->addAction(mpCheckModelAction);
  // OMNotebook Toolbar
  mpOMNotebookToolbar = addToolBar(tr("OMNotebook"));
  mpOMNotebookToolbar->setObjectName("OMNotebook");
  mpOMNotebookToolbar->setAllowedAreas(Qt::TopToolBarArea);
  mpOMNotebookToolbar->addAction(mpExportToOMNotebookAction);
  mpOMNotebookToolbar->addAction(mpImportFromOMNotebookAction);
  // Plot Toolbar
  mpPlotToolBar = addToolBar(tr("Plot Toolbar"));
  mpPlotToolBar->setObjectName("Plot Toolbar");
  mpPlotToolBar->setAllowedAreas(Qt::TopToolBarArea);
  mpPlotToolBar->addAction(mpNewPlotWindowAction);
  mpPlotToolBar->addAction(mpNewPlotParametricWindowAction);
  // Perspective Toolbar
  mpPerspectiveToolBar = addToolBar(tr("Perspective Toolbar"));
  mpPerspectiveToolBar->setObjectName("Perspective Toolbar");
  mpPerspectiveToolBar->setAllowedAreas(Qt::TopToolBarArea);
  mpPerspectiveToolBar->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
  mpPerspectiveToolBar->setMovable(false);
  // a trick :: just to move the toolbar to the right
  QWidget *spacerWidget = new QWidget(this);
  spacerWidget->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
  mpPerspectiveToolBar->addWidget(spacerWidget);
  mpPerspectiveToolBar->addAction(mpModelingViewAction);
  mpPerspectiveToolBar->addAction(mpPlottingViewAction);
  // TODO: mpPerspectiveToolBar->addAction(mpInteractiveSimulationViewAction);
}

//! Adds the currently opened file to the recentFileList settings.
void MainWindow::setCurrentFile(const QString &fileName)
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omedit");
  QStringList files = settings.value("recentFileList/files").toStringList();
  files.removeAll(fileName);
  files.prepend(fileName);
  while (files.size() > MaxRecentFiles)
    files.removeLast();

  settings.setValue("recentFileList/files", files);
  updateRecentFileActions();
}

//! Updates the actions of the recent files menu items.
void MainWindow::updateRecentFileActions()
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omedit");
  QStringList files = settings.value("recentFileList/files").toStringList();

  int numRecentFiles = qMin(files.size(), (int)MaxRecentFiles);

  for (int i = 0; i < numRecentFiles; ++i) {
    QString text = QFileInfo(files[i]).fileName();
    mpRecentFileActions[i]->setText(text);
    mpRecentFileActions[i]->setData(files[i]);
    mpRecentFileActions[i]->setVisible(true);
  }
  for (int j = numRecentFiles; j < MaxRecentFiles; ++j)
    mpRecentFileActions[j]->setVisible(false);

  mpSeparatorAction->setVisible(numRecentFiles > 0);
  mpWelcomePageWidget->addListItems();
}

//! Open Simulation Window
void MainWindow::openSimulation()
{
  mpSimulationWidget->show(false);
}

//! Open Interactive Simulation Window
void MainWindow::openInteractiveSimulation()
{
  mpSimulationWidget->show(true);
}

//! Opens the new model widget.
void MainWindow::openNewModel()
{
  mpModelCreator->show(StringHandler::MODEL);
}

//! Opens the new class widget.
void MainWindow::openNewClass()
{
  mpModelCreator->show(StringHandler::CLASS);
}

//! Opens the new connector widget.
void MainWindow::openNewConnector()
{
  mpModelCreator->show(StringHandler::CONNECTOR);
}

//! Opens the new record widget.
void MainWindow::openNewRecord()
{
  mpModelCreator->show(StringHandler::RECORD);
}

//! Opens the new block widget.
void MainWindow::openNewBlock()
{
  mpModelCreator->show(StringHandler::BLOCK);
}

//! Opens the new function widget.
void MainWindow::openNewFunction()
{
  mpModelCreator->show(StringHandler::FUNCTION);
}

//! Opens the new package widget.
void MainWindow::openNewPackage()
{
  mpModelCreator->show(StringHandler::PACKAGE);
}

//! Opens the new model widget.
void MainWindow::openOMShell()
{
  QString omShellPath (Helper::OpenModelicaHome);

  if (omShellPath.isEmpty())
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::OPENMODELICAHOME_NOT_FOUND), Helper::ok);
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

    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), msg, Helper::ok);
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

    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), msg, Helper::ok);
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
  QString omnotebookFileName = StringHandler::getSaveFileName(this, Helper::exportToOMNotebook, NULL, Helper::omnotebookFileTypes, NULL, "onb", &pCurrentTab->mModelName);
  // if user cancels the operation. or closes the export dialog box.
  if (omnotebookFileName.isEmpty())
    return;
  // create a progress bar
  int endtime = 6;    // since in total we do six things while exporting to OMNotebook
  int value = 1;
  // show the progressbar and set the message in status bar
  mpStatusBar->showMessage(tr("Exporting model to OMNotebook"));
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
  ruleElement.appendChild(xmlDocument.createTextNode("Center"));
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
  outputElement.appendChild(xmlDocument.createTextNode(""));
  textCellElement.appendChild(outputElement);
}

//! Imports the models from OMNotebook.
//! @see exportModelToOMNotebook();
void MainWindow::importModelfromOMNotebook()
{
  QString fileName = StringHandler::getOpenFileName(this, Helper::chooseFile, NULL, Helper::omnotebookFileTypes);
  if (fileName.isEmpty())
    return;
  // create a progress bar
  int endtime = 3;    // since in total we do three things while exporting to OMNotebook
  int value = 1;
  // show the progressbar and set the message in status bar
  mpStatusBar->showMessage(tr("Importing model from OMNotebook"));
  mpProgressBar->setRange(0, endtime);
  showProgressBar();
  // open the xml file
  QFile file(fileName);
  if (!file.open(QIODevice::ReadOnly))
  {
    mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                   GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(fileName),
                                                   Helper::scriptingKind, Helper::errorLevel, 0, mpMessageWidget->mpProblem));
    hideProgressBar();
    return;
  }
  mpProgressBar->setValue(value++);

  // create the xml from the omnotebook file.
  QDomDocument xmlDocument;
  if (!xmlDocument.setContent(&file))
  {
    mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0, tr("Error reading the xml file"), Helper::scriptingKind,
                                                   Helper::errorLevel, 0, mpMessageWidget->mpProblem));
    hideProgressBar();
    return;
  }
  mpProgressBar->setValue(value++);
  // read the file
  QDomNodeList nodes = xmlDocument.elementsByTagName("Input");
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
  file.close();
  // hide the progressbar and clear the message in status bar
  mpStatusBar->clearMessage();
  hideProgressBar();
}

//! Exports the current model as image
void MainWindow::exportModelAsImage()
{
  bool oldSkipDrawBackground;
  // get the current tab
  ProjectTab *pCurrentTab = mpProjectTabs->getCurrentTab();
  QString fileName = StringHandler::getSaveFileName(this, tr("Export as Image"), NULL, Helper::imageFileTypes, NULL, "png", &pCurrentTab->mModelName);
  // if user cancels the operation. or closes the export dialog box.
  if (fileName.isEmpty())
    return;
  // show the progressbar and set the message in status bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  mpStatusBar->showMessage(tr("Exporting model as an Image"));
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
    QRect bbox = graphicsView->iconBoundingRect().toAlignedRect();
    QSize bigSize = graphicsView->viewport()->size();
    svgGenerator.setTitle(QString(Helper::applicationName).append(" - ").append(Helper::applicationIntroText));
    svgGenerator.setDescription(tr("Generated by OpenModelica Connection Editor Tool"));
    svgGenerator.setSize(bigSize);
    svgGenerator.setViewBox(bbox);
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
  if (!fileName.endsWith(".svg")) {
    if (graphicsView->mIconType == StringHandler::DIAGRAM)
      painter.fillRect(painter.viewport(), graphicsView->palette().background());
    else
      painter.fillRect(painter.viewport(), Qt::white);
  }
  // paint all the items
  oldSkipDrawBackground = graphicsView->mSkipBackground;
  if (fileName.endsWith(".svg")) {
    graphicsView->mSkipBackground = true;
  }
  graphicsView->render(&painter);
  painter.end();
  graphicsView->mSkipBackground = oldSkipDrawBackground;

  if (!fileName.endsWith(".svg"))
  {
    if (!modelImage.save(fileName))
      mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0, tr("Error saving the image file"), Helper::scriptingKind,
                                                     Helper::errorLevel, 0, mpMessageWidget->mpProblem));
  }
  // hide the progressbar and clear the message in status bar
  mpStatusBar->clearMessage();
  hideProgressBar();
}

void MainWindow::openConfigurationOptions()
{
  mpOptionsWidget->show();
}

void MainWindow::checkModel()
{
  ProjectTab *pCurrentTab = mpProjectTabs->getCurrentTab();
  if (pCurrentTab)
  {
    // validate the modelica text before checking the model
    if (pCurrentTab->mpModelicaEditor->validateText())
    {
      CheckModelWidget *widget = new CheckModelWidget(pCurrentTab->mModelName, pCurrentTab->mModelNameStructure, this);
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
      FlatModelWidget *widget = new FlatModelWidget(pCurrentTab->mModelName, pCurrentTab->mModelNameStructure, this);
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
      .append(tr("Connected to OpenModelica ")).append(OMCVersion).append("\n\n")
      .append(tr("Copyright Open Source Modelica Consortium (OSMC).\n"
              "Distributed under OSMC-PL and GPL, see www.openmodelica.org.\n\n"
              "Created by Adeel Asghar and Sonia Tariq as part of their final thesis."));

  QMessageBox::about(this, QString("About ").append(Helper::applicationName), aboutText);
}

void MainWindow::toggleShapesButton()
{
  QAction *clickedAction = qobject_cast<QAction*>(const_cast<QObject*>(sender()));

  QList<QAction*> shapeActions = mpShapesActionGroup->actions();
  foreach (QAction *shapeAction, shapeActions)
  {
    if (shapeAction != clickedAction)
    {
      shapeAction->setChecked(false);
    }
  }
}

//! Sets the focus on the MSL search text box when the MSL Search dock window is shown
//! Connected to searchMSLdock signal visibilitychanged.
void MainWindow::focusMSLSearch(bool visible)
{
  if (visible)
    mpSearchMSLWidget->getMSLSearchTextBox()->setFocus();
}

void MainWindow::switchToWelcomeView(bool show)
{
  if (show)
  {
    mpModelingViewAction->setChecked(false);
    mpPlottingViewAction->setChecked(false);
    mpInteractiveSimulationViewAction->setChecked(false);
    mpWelcomePageWidget->setVisible(true);
    mpProjectTabs->setVisible(false);
    mpInteractiveSimualtionTabWidget->setVisible(false);
    mpPlotWindowContainer->setVisible(false);
  }
  else
  {
    mpWelcomePageWidget->setVisible(false);
  }
}

void MainWindow::switchToModelingView()
{
  mpModelingViewAction->setChecked(true);
  mpProjectTabs->setVisible(true);
  mpWelcomePageWidget->setVisible(false);
  mpWelcomeViewAction->setChecked(false);
  mpInteractiveSimualtionTabWidget->setVisible(false);
  mpPlotWindowContainer->setVisible(false);
}

void MainWindow::switchToPlottingView()
{
  // if not plotwindow is opened then open one for user
  if (mpPlotWindowContainer->subWindowList().size() == 0)
    mpPlotWindowContainer->addPlotWindow();

  mpPlottingViewAction->setChecked(true);
  mpWelcomePageWidget->setVisible(false);
  mpWelcomeViewAction->setChecked(false);
  mpProjectTabs->setVisible(false);
  mpInteractiveSimualtionTabWidget->setVisible(false);
  mpPlotWindowContainer->setVisible(true);
}

void MainWindow::switchToInteractiveSimulationView()
{
  mpInteractiveSimulationViewAction->setChecked(true);
  mpWelcomePageWidget->setVisible(false);
  mpWelcomeViewAction->setChecked(false);
  mpProjectTabs->setVisible(false);
  mpInteractiveSimualtionTabWidget->setVisible(true);
  mpPlotWindowContainer->setVisible(false);
}

void MainWindow::addNewPlotWindow()
{
  mpPlotWindowContainer->addPlotWindow();
}

void MainWindow::addNewPlotParametricWindow()
{
  mpPlotWindowContainer->addPlotParametricWindow();
}

//! Opens the recent file.
void MainWindow::openRecentFile()
{
  QAction *action = qobject_cast<QAction*>(sender());
  if (action)
  {
    mpProjectTabs->openFile(action->data().toString());
  }
}

//! Exports the current model to FMI
void MainWindow::exportModelFMI()
{
  ProjectTab *pCurrentTab = mpProjectTabs->getCurrentTab();
  if (!pCurrentTab)
  {
    mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                   GUIMessages::getMessage(GUIMessages::NO_OPEN_MODEL).arg(tr("make FMU")),
                                                   Helper::scriptingKind, Helper::warningLevel, 0, mpMessageWidget->mpProblem));
    return;
  }
  // set the status message.
  mpStatusBar->showMessage(tr("Exporting model as FMI"));
  // show the progress bar
  showProgressBar();
  if (mpOMCProxy->translateModelFMU(pCurrentTab->mModelNameStructure))
  {
    mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::FMI_GENERATED)
                                                   .arg(mpOMCProxy->changeDirectory()).arg(pCurrentTab->mModelNameStructure),
                                                   Helper::scriptingKind, Helper::notificationLevel, 0, mpMessageWidget->mpProblem));
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

//! Imports the model from FMI
void MainWindow::importModelFMI()
{
  ImportFMIWidget *pImportFMIWidget = new ImportFMIWidget(this);
  pImportFMIWidget->show();
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
