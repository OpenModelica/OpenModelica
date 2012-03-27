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

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QComboBox>
#include <QSplashScreen>
#include <QProgressBar>
#include <QDomDocument>

#if (QT_VERSION < QT_VERSION_CHECK(4, 6, 0))
    #error "OMEdit requires Qt 4.6.0 or newer"
#endif

#include "OMCProxy.h"
#include "ModelWidget.h"
#include "LibraryWidget.h"
#include "ProjectTabWidget.h"
#include "StringHandler.h"
#include "ProblemsWidget.h"
#include "Helper.h"
#include "SimulationWidget.h"
#include "PlotWindowContainer.h"
#include "InteractiveSimulationTabWidget.h"
#include "PlotWidget.h"
#include "SplashScreen.h"
#include "DocumentationWidget.h"
#include "OptionsWidget.h"
#include "FMIWidget.h"

class QGridLayout;
class QHBoxLayout;
class QMenuBar;
class QMenu;
class QStatusBar;
class QAction;
class QString;
class QPlainTextEdit;
class OMCProxy;
class WelcomePageWidget;
class ProjectTabWidget;
class GraphicsView;
class GraphicsScene;
class SearchMSLWidget;
class LibraryWidget;
class ModelBrowserWidget;
class ModelCreator;
class SimulationWidget;
class PlotWindowContainer;
class InteractiveSimulationTabWidget;
class PlotWidget;
class DocumentationWidget;
class OptionsWidget;
class ImportFMIWidget;
class ProblemsWidget;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(SplashScreen *splashScreen, QWidget *parent = 0);
    ~MainWindow();
    void setCurrentFile(const QString &fileName);

    QWidget *mpCentralwidget;
    QGridLayout *mpCentralgrid;
    WelcomePageWidget *mpWelcomePageWidget;
    ProjectTabWidget *mpProjectTabs;
    QGridLayout *mpTabgrid;
    SearchMSLWidget *mpSearchMSLWidget;
    LibraryWidget *mpLibrary;
    ModelBrowserWidget *mpModelBrowser;
    SimulationWidget *mpSimulationWidget;
    PlotWindowContainer *mpPlotWindowContainer;
    InteractiveSimulationTabWidget *mpInteractiveSimualtionTabWidget;
    PlotWidget *mpPlotWidget;
    ModelCreator *mpModelCreator;
    OMCProxy *mpOMCProxy;
    DocumentationWidget *mpDocumentationWidget;
    OptionsWidget *mpOptionsWidget;
    QMenuBar *mpMenuBar;
    // File menu
    QMenu *mpFileMenu;
    QMenu *mpFileNewMenu;
    QAction *mpNewModelAction;
    QAction *mpNewClassAction;
    QAction *mpNewConnectorAction;
    QAction *mpNewRecordAction;
    QAction *mpNewBlockAction;
    QAction *mpNewFunctionAction;
    QAction *mpNewPackageAction;
    QAction *mpOpenAction;
    QAction *mpSaveAction;
    QAction *mpSaveAsAction;
    QAction *mpSaveAllAction;
    QAction *mpSeparatorAction;
    enum { MaxRecentFiles = 5 };
    QAction *mpRecentFileActions[MaxRecentFiles];
    QAction *mpCloseAction;
    // Edit Menu
    QMenu *mpEditMenu;
    QAction *mpUndoAction;
    QAction *mpRedoAction;
    QAction *mpCutAction;
    QAction *mpCopyAction;
    QAction *mpPasteAction;
    // View Menu
    QMenu *mpViewMenu;
    QMenu *mpViewToolbarsMenu;
    QMenu *mpViewWindowsMenu;
    QMenu *mpViewPerspectivesMenu;
    QAction *mpGridLinesAction;
    QAction *mpResetZoomAction;
    QAction *mpZoomInAction;
    QAction *mpZoomOutAction;
    QAction *mpWelcomeViewAction;
    QActionGroup *mpViewActionGroup;
    QAction *mpModelingViewAction;
    QAction *mpPlottingViewAction;
    QAction *mpInteractiveSimulationViewAction;
    // Simulation Menu
    QMenu *mpSimulationMenu;
    QAction *mpSimulationAction;
    QAction *mpInteractiveSimulationAction;
    QAction *mpCheckModelAction;
    QAction *mpFlatModelAction;
    // FMI Menu
    QMenu *mpFMIMenu;
    QAction *mpExportFMIAction;
    QAction *mpImportFMIAction;
    // Tools Menu
    QMenu *mpMenuTools;
    QAction *mpOMCLoggerAction;
    QAction *mpOpenOMShellAction;
    QAction *mpExportToOMNotebookAction;
    QAction *mpImportFromOMNotebookAction;
    QAction *mpOpenOptionsAction;
    // Help Menu
    QMenu *mpHelpMenu;
    QAction *mpUserManualAction;
    QAction *mpAboutOMEditAction;
    // Toolbars
    QToolBar *mpFileToolBar;
    QToolBar *mpEditToolBar;
    QToolBar *mpViewToolBar;
    QToolBar *mpShapesToolBar;
    QActionGroup *mpShapesActionGroup;
    QAction *mpLineAction;
    QAction *mpRectangleAction;
    QAction *mpEllipseAction;
    QAction *mpPolygonAction;
    QAction *mpTextAction;
    QAction *mpBitmapAction;
    QAction *mpConnectAction;
    QToolBar *mpSimulationToolBar;
    QToolBar *mpOMNotebookToolbar;
    QToolBar *mpPlotToolBar;
    QAction *mpNewPlotWindowAction;
    QAction *mpNewPlotParametricWindowAction;
    QToolBar *mpPerspectiveToolBar;
    QAction *mpExportAsImageAction;
    ProblemsWidget *mpMessageWidget;
    QStatusBar *mpStatusBar;
    QProgressBar *mpProgressBar;
    QDockWidget *mpPlotDockWidget;
    QDockWidget *mpDocumentationDockWidget;
    QDockWidget *mpSearchMSLDockWidget;
    QDockWidget *mpModelBrowserDockWidget;
    bool mExitApplication;
    void closeEvent(QCloseEvent *event);
private slots:
    void openSimulation();
    void openInteractiveSimulation();
    void openNewClass();
    void openNewConnector();
    void openNewRecord();
    void openNewBlock();
    void openNewFunction();
    void openNewPackage();
    void openOMShell();
    void exportModelToOMNotebook();
    void createOMNotebookTitleCell(QDomDocument xmlDocument, QDomElement pDomElement);
    void createOMNotebookImageCell(QDomDocument xmlDocument, QDomElement pDomElement, QString filePath);
    void createOMNotebookCodeCell(QDomDocument xmlDocument, QDomElement pDomElement);
    void importModelfromOMNotebook();
    void exportModelAsImage();
    void openConfigurationOptions();
    void flatModel();
    void checkModel();
    void openUserManual();
    void openAbout();
    void toggleShapesButton();
    void changeConnectMode();
    void focusMSLSearch(bool visible);
    void switchToWelcomeView(bool show);
    void switchToPlottingView();
    void switchToInteractiveSimulationView();
    void addNewPlotWindow();
    void addNewPlotParametricWindow();
    void openRecentFile();
    void exportModelFMI();
    void importModelFMI();
public slots:
    void openNewModel();
    void switchToModelingView();
    void showProgressBar();
    void hideProgressBar();
private:
    void createActions();
    void createMenus();
    void createToolbars();
    void updateRecentFileActions();
    QDockWidget *mpMessageDockWidget;
    QDockWidget *mpLibraryDockWidget;
protected:
    virtual void dragEnterEvent(QDragEnterEvent *event);
    virtual void dragMoveEvent(QDragMoveEvent *event);
    virtual void dropEvent(QDropEvent *event);
signals:
     void fileOpen(QString filename);
};

#endif // MAINWINDOW_H
