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
 *
 */

#include <iostream>
#include <QtGui>

#include "mainwindow.h"

//! Constructor
MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent), mExitApplication(false)
{
    // Create the OMCProxy object.
    //this->mpOMCProxy = OMCProxy::getInstance();
    this->mpOMCProxy = new OMCProxy(this);
    //Set the name and size of the main window
    this->setObjectName("MainWindow");
    this->setWindowTitle(Helper::applicationName);
    this->setWindowIcon(QIcon("../OMEditGUI/Resources/icons/omeditor.png"));
    this->setMinimumSize(800, 600);
    this->setContentsMargins(1, 1, 1, 1);
    //this->resize(800,600);

    //Create a centralwidget for the main window
    mpCentralwidget = new QWidget(this);
    mpCentralwidget->setObjectName("centralwidget");

    //Create a grid on the centralwidget
    mpCentralgrid = new QGridLayout(mpCentralwidget);
    mpCentralgrid->setContentsMargins(0, 1, 0, 0);

    //Create a dock for the MessageWidget
    messagedock = new QDockWidget(tr(" Messages"), this);
    messagedock->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea | Qt::BottomDockWidgetArea);
    messagedock->setContentsMargins(0, 0, 1, 0);
    mpMessageWidget = new MessageWidget(this);
    mpMessageWidget->setReadOnly(true);
    messagedock->setWidget(mpMessageWidget);
    addDockWidget(Qt::BottomDockWidgetArea, messagedock);
    mpMessageWidget->printGUIMessage("OMEdit, Version: " + Helper::applicationVersion);

    //Create a dock for the componentslibrary
    libdock = new QDockWidget(tr(" Components"), this);
    libdock->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
    mpLibrary = new LibraryWidget(this);
    // Loads and adds the OM Standard Library into the Library Widget.
    mpLibrary->addModelicaStandardLibrary();
    libdock->setWidget(mpLibrary);
    addDockWidget(Qt::LeftDockWidgetArea, libdock);

    //Set dock widget corner owner
    setCorner(Qt::BottomLeftCorner, Qt::LeftDockWidgetArea);

    //Create Actions, Toolbar and Menus
    this->createActions();
    this->createToolbars();
    this->createMenus();

    //Create the main tab container, need at least one tab
    mpProjectTabs = new ProjectTabWidget(this);
    mpProjectTabs->setObjectName("projectTabs");

    //mpCentralgrid->addWidget(mpSimulationSetupWidget,0,0);
    mpBackButton = new QPushButton("Back");
    mpCentralgrid->addWidget(mpBackButton,0,0);
    mpCentralgrid->addWidget(mpProjectTabs,1,0);
    mpBackButton->hide();

    mpCentralwidget->setLayout(mpCentralgrid);

    //Set the centralwidget
    this->setCentralWidget(mpCentralwidget);

    //Create the Statusbar
    statusBar = new QStatusBar();
    statusBar->setObjectName("statusBar");
    this->setStatusBar(statusBar);

    // Create a New Project Widget
    this->mpNewPackage = new NewPackage(this);
    this->mpNewModel = new NewModel(this);

    QMetaObject::connectSlotsByName(this);
}

//! Destructor
MainWindow::~MainWindow()
{
    delete mpProjectTabs;
    delete menubar;
    delete statusBar;
    delete mpNewPackage;
    delete mpNewModel;
}

/*
//! Opens the plot widget.
void MainWindow::plot()
{
    QDockWidget *varPlotDock = new QDockWidget(tr("Plot Variables"), this);
    varPlotDock->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
    VariableListDialog *variableList = new VariableListDialog(this);
    varPlotDock->setWidget(variableList);
    //variableList->show();
    addDockWidget(Qt::RightDockWidgetArea, varPlotDock);

}
*/
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
        event->accept();
    }
    else
    {
        event->ignore();
    }
}

//! Defines the actions used by the toolbars
void MainWindow::createActions()
{
    newAction = new QAction(tr("&New"), this);

    newPackageAction = new QAction(tr("&Package"), this);
    newPackageAction->setStatusTip(tr("Create New Package"));
    connect(newPackageAction, SIGNAL(triggered()), this, SLOT(openNewPackage()));

    newModelAction = new QAction(tr("&Model"), this);
    newPackageAction->setStatusTip(tr("Create New Model"));
    connect(newModelAction, SIGNAL(triggered()), this, SLOT(openNewModel()));

    openAction = new QAction(QIcon("../OMEditGUI/Resources/icons/open.png"), tr("&Open"), this);
    openAction->setShortcut(QKeySequence("Ctrl+o"));
    openAction->setStatusTip(tr("Opens Open Modelica file"));

    saveAction = new QAction(QIcon("../OMEditGUI/Resources/icons/save.png"), tr("&Save"), this);
    saveAction->setShortcut(QKeySequence("Ctrl+s"));
    saveAction->setStatusTip(tr("Save a file"));

    saveAsAction = new QAction(QIcon("../OMEditGUI/Resources/icons/saveas.png"), tr("&Save As"), this);
    saveAsAction->setStatusTip(tr("Save As a File"));

    saveAllAction = new QAction(QIcon("../OMEditGUI/Resources/icons/saveall.png"), tr("&Save All"), this);
    saveAllAction->setStatusTip(tr("Save All Files"));

    undoAction = new QAction(QIcon("../OMEditGUI/Resources/icons/undo.png"), tr("&Undo"), this);
    undoAction->setShortcut(QKeySequence("Ctrl+z"));
    undoAction->setStatusTip(tr("Undo Action"));

    redoAction = new QAction(QIcon("../OMEditGUI/Resources/icons/redo.png"), tr("&Redo"), this);
    redoAction->setShortcut(QKeySequence("Ctrl+y"));
    redoAction->setStatusTip(tr("Redo Action"));

    cutAction = new QAction(QIcon("../OMEditGUI/Resources/icons/cut.png"), tr("&Cut"), this);
    cutAction->setShortcut(QKeySequence("Ctrl+x"));

    copyAction = new QAction(QIcon("../OMEditGUI/Resources/icons/copy.png"), tr("&Copy"), this);
    copyAction->setShortcut(QKeySequence("Ctrl+c"));

    pasteAction = new QAction(QIcon("../OMEditGUI/Resources/icons/paste.png"), tr("&Paste"), this);
    pasteAction->setShortcut(QKeySequence("Ctrl+v"));

    resetZoomAction = new QAction(QIcon("../OMEditGUI/Resources/icons/zoom100.png"), tr("&Reset Zoom"), this);
    resetZoomAction->setText("Reset Zoom");

    zoomInAction = new QAction(QIcon("../OMEditGUI/Resources/icons/zoomIn.png"), tr("&Zoom In"), this);
    zoomInAction->setText("Zoom In");

    zoomOutAction = new QAction(QIcon("../OMEditGUI/Resources/icons/zoomOut.png"), tr("&Zoom Out"), this);
    zoomOutAction->setText("Zoom Out");

    omcLoggerAction = new QAction(QIcon("../OMEditGUI/Resources/icons/console.png"), tr("&OMC Logger"), this);
    omcLoggerAction->setStatusTip(tr("Shows OMC Logger Window"));
    connect(omcLoggerAction, SIGNAL(triggered()), this->mpOMCProxy, SLOT(openOMCLogger()));

    openOMShellAction = new QAction(QIcon("../OMEditGUI/Resources/icons/OMS.bmp"), tr("&OMShell"), this);
    openOMShellAction->setStatusTip(tr("Opens Open Modelica Shell (OMShell)"));
    connect(openOMShellAction, SIGNAL(triggered()), this, SLOT(openOMShell()));

    closeAction = new QAction(QIcon("../OMEditGUI/Resources/icons/close.png"), tr("&Close"), this);
    closeAction->setText("Close");
    closeAction->setShortcut(QKeySequence("Ctrl+q"));
    connect(this->closeAction,SIGNAL(triggered()),SLOT(close()));

    gridLinesAction = new QAction(QIcon("../OMEditGUI/Resources/icons/grid.png"), tr("&Grid Lines"), this);
    gridLinesAction->setCheckable(true);
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

    menuTools = new QMenu(menubar);
    menuTools->setTitle("&Tools");

    this->setMenuBar(menubar);

    //Add the actionbuttons to the menues
    menuNew->addAction(newModelAction);
    menuNew->addAction(newPackageAction);

    menuFile->addAction(menuNew->menuAction());
    menuFile->addAction(openAction);
    menuFile->addAction(saveAction);
    menuFile->addAction(saveAsAction);
    menuFile->addAction(saveAllAction);
    menuFile->addSeparator();
    menuFile->addAction(closeAction);

    menuEdit->addAction(undoAction);
    menuEdit->addAction(redoAction);
    menuEdit->addSeparator();
    menuEdit->addAction(cutAction);
    menuEdit->addAction(copyAction);
    menuEdit->addAction(pasteAction);

    menuView->addAction(libdock->toggleViewAction());
    menuView->addAction(messagedock->toggleViewAction());
    menuView->addAction(fileToolBar->toggleViewAction());
    menuView->addAction(editToolBar->toggleViewAction());
    menuView->addAction(gridLinesAction);

    menuTools->addAction(omcLoggerAction);
    menuTools->addAction(openOMShellAction);

    menubar->addAction(menuFile->menuAction());
    menubar->addAction(menuEdit->menuAction());
    menubar->addAction(menuView->menuAction());
    menubar->addAction(menuTools->menuAction());
}

//! Creates the toolbars
void MainWindow::createToolbars()
{
    fileToolBar = addToolBar(tr("File Toolbar"));
    fileToolBar->setAllowedAreas(Qt::TopToolBarArea);

    QToolButton *newMenuButton = new QToolButton(fileToolBar);
    QMenu *newMenu = new QMenu(newMenuButton);
    newMenu->addAction(newModelAction);
    newMenu->addAction(newPackageAction);

    newMenuButton->setMenu(newMenu);
    newMenuButton->setDefaultAction(newModelAction);
    newMenuButton->setPopupMode(QToolButton::MenuButtonPopup);
    newMenuButton->setIcon(QIcon("../OMEditGUI/Resources/icons/new.png"));

    fileToolBar->addWidget(newMenuButton);
    fileToolBar->addAction(openAction);
    fileToolBar->addAction(saveAction);
    fileToolBar->addAction(saveAsAction);
    fileToolBar->addAction(saveAllAction);

    editToolBar = addToolBar(tr("Clipboard Toolbar"));
    editToolBar->setAllowedAreas(Qt::TopToolBarArea);
    editToolBar->addAction(undoAction);
    editToolBar->addAction(redoAction);
    editToolBar->addAction(cutAction);
    editToolBar->addAction(copyAction);
    editToolBar->addAction(pasteAction);

    viewToolBar = addToolBar(tr("View Toolbar"));
    viewToolBar->setAllowedAreas(Qt::TopToolBarArea);
    viewToolBar->addAction(gridLinesAction);
    viewToolBar->addAction(resetZoomAction);
    viewToolBar->addAction(zoomInAction);
    viewToolBar->addAction(zoomOutAction);
}

//! Opens the new package widget.
void MainWindow::openNewPackage()
{
    this->mpNewPackage->show();
}

//! Opens the new model widget.
void MainWindow::openNewModel()
{
    this->mpNewModel->show();
}

//! Opens the new model widget.
void MainWindow::openOMShell()
{
    QString omShellPath (getenv("OPENMODELICAHOME"));

    if (omShellPath.isEmpty())
    {
        QMessageBox::warning( this, "Error", "Could not find environment variable OPENMODELICAHOME. Please make sure OpenModelica is installed properly.", "OK" );
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

/*
//! Opens the new project widget.
void MainWindow::openNewProject()
{
    this->mpNewProject->show();
}

void MainWindow::incrementProjectsCounter()
{
    this->mProjectsCounter += this->mProjectsCounter;
    emit projectCreated();
}

void MainWindow::projectCreatedSlot()
{
    this->newPackageAction->setEnabled(true);
    this->newModelAction->setEnabled(true);
    this->closeProjectAction->setEnabled(true);
    this->newProjectAction->setEnabled(false);
    this->openProjectAction->setEnabled(false);
}

void MainWindow::projectClosedSlot()
{
    this->mProjectsCounter -= this->mProjectsCounter;
    if (this->mProjectsCounter == 0)
    {
        this->newPackageAction->setEnabled(false);
        this->newModelAction->setEnabled(false);
        this->closeProjectAction->setEnabled(false);
        this->newProjectAction->setEnabled(true);
        this->openProjectAction->setEnabled(true);
    }
    this->mpLibrary->removeProject();
}

void MainWindow::projectOpenSlot()
{
    QString path = QFileDialog::getExistingDirectory(this, tr("Choose Location"),
                                                     QDir::currentPath() + tr("/ModelicaProjects"),
                                                     QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks);

    if (path.isEmpty())
    {
        return;
    }

    this->newPackageAction->setEnabled(true);
    this->newModelAction->setEnabled(true);
    this->closeProjectAction->setEnabled(true);
    this->newProjectAction->setEnabled(false);
    this->openProjectAction->setEnabled(false);

    this->mpLibrary->openProject(path);
}
*/
