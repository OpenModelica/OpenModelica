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

/*
 * HopsanGUI
 * Fluid and Mechatronic Systems, Department of Management and Engineering, Linkoping University
 * Main Authors 2009-2010:  Robert Braun, Bjorn Eriksson, Peter Nordin
 * Contributors 2009-2010:  Mikael Axin, Alessandro Dell'Amico, Karl Pettersson, Ingo Staack
 */

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QComboBox>
#include <QSplashScreen>
#include <QProgressBar>

#if (QT_VERSION < QT_VERSION_CHECK(4, 7, 0))
    #error "OMEdit requires Qt 4.7.0 or newer"
#endif

#include "OMCProxy.h"
#include "ModelWidget.h"
#include "MessageWidget.h"
#include "LibraryWidget.h"
#include "ProjectTabWidget.h"
#include "StringHandler.h"
#include "Helper.h"
#include "SimulationWidget.h"
#include "PlotWidget.h"
#include "SplashScreen.h"
#include "DocumentationWidget.h"
#include "OptionsWidget.h"

class QGridLayout;
class QHBoxLayout;
class QMenuBar;
class QMenu;
class QStatusBar;
class QAction;
class QString;
class QPlainTextEdit;
class OMCProxy;
class ProjectTabWidget;
class GraphicsView;
class GraphicsScene;
class LibraryWidget;
class ModelCreator;
class SimulationWidget;
class PlotWidget;
class DocumentationWidget;
class OptionsWidget;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(SplashScreen *splashScreen, QWidget *parent = 0);
    ~MainWindow();

    QWidget *mpCentralwidget;
    QGridLayout *mpCentralgrid;
    ProjectTabWidget *mpProjectTabs;
    QGridLayout *mpTabgrid;
    LibraryWidget *mpLibrary;
    SimulationWidget *mpSimulationWidget;
    PlotWidget *mpPlotWidget;
    ModelCreator *mpModelCreator;
    OMCProxy *mpOMCProxy;
    DocumentationWidget *mpDocumentationWidget;
    OptionsWidget *mpOptionsWidget;
    QMenuBar *menubar;
    QMenu *menuFile;
    QMenu *menuNew;
    QMenu *menuEdit;
    QMenu *menuView;
    QMenu *menuTools;
    QMenu *menuSimulation;
    QMenu *menuHelp;
    MessageWidget *mpMessageWidget;
    QStatusBar *statusBar;
    QPushButton *mpBackButton;
    QAction *newAction;
    QAction *newModelAction;
    QAction *newClassAction;
    QAction *newConnectorAction;
    QAction *newRecordAction;
    QAction *newBlockAction;
    QAction *newFunctionAction;
    QAction *newPackageAction;
    QAction *openAction;
    QAction *saveAction;
    QAction *saveAsAction;
    QAction *saveAllAction;
    QAction *undoAction;
    QAction *redoAction;
    QAction *cutAction;
    QAction *copyAction;
    QAction *pasteAction;
    QAction *omcLoggerAction;
    QAction *openOMShellAction;
    QAction *openOptions;
    QAction *gridLinesAction;
    QAction *resetZoomAction;
    QAction *zoomInAction;
    QAction *zoomOutAction;
    QAction *checkModelAction;
    QAction *closeAction;
    QAction *simulationAction;
    QAction *plotAction;
    QAction *documentationAction;
    QAction *userManualAction;
    QAction *aboutAction;
    QActionGroup *shapesActionGroup;
    QAction *lineAction;
    QAction *rectangleAction;
    QAction *ellipseAction;
    QAction *polygonAction;
    QAction *textAction;
    QAction *bitmapAction;

    QToolBar *fileToolBar;
    QToolBar *editToolBar;
    QToolBar *viewToolBar;
    QToolBar *shapesToolBar;
    QToolBar *simulationToolBar;

    QDockWidget *plotdock;
    QDockWidget *documentationdock;

    bool mExitApplication;

    void closeEvent(QCloseEvent *event);
private slots:
    void openSimulation(); 
    void openNewModel();
    void openNewClass();
    void openNewConnector();
    void openNewRecord();
    void openNewBlock();
    void openNewFunction();
    void openNewPackage();
    void openOMShell();
    void openConfiguratonOptions();
    void checkModel();
    void openUserManual();
    void openAbout();
    void toggleShapesButton();
private:
    void createActions();
    void createMenus();
    void createToolbars();
    QDockWidget *messagedock;
    QDockWidget *libdock;
};

#endif // MAINWINDOW_H
