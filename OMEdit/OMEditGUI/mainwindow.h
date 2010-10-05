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

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QComboBox>
#include <QSplashScreen>
#include <QProgressBar>

#include "OMCProxy.h"
#include "ModelWidget.h"
#include "MessageWidget.h"
#include "LibraryWidget.h"
#include "ProjectTabWidget.h"
#include "StringHandler.h"
#include "Helper.h"

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
class NewProject;
class NewPackage;
class NewModel;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = 0);
    ~MainWindow();

    QWidget *mpCentralwidget;
    QGridLayout *mpCentralgrid;
    ProjectTabWidget *mpProjectTabs;
    QGridLayout *mpTabgrid;
    LibraryWidget *mpLibrary;
    NewProject *mpNewProject;
    NewPackage *mpNewPackage;
    NewModel *mpNewModel;
    OMCProxy *mpOMCProxy;
    QMenuBar *menubar;
    QMenu *menuFile;
    QMenu *menuNew;
    QMenu *menuEdit;
    QMenu *menuView;
    QMenu *menuTools;
    MessageWidget *mpMessageWidget;
    QStatusBar *statusBar;
    QPushButton *mpBackButton;
    QAction *newAction;
    QAction *newPackageAction;
    QAction *newModelAction;
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
    QAction *resetZoomAction;
    QAction *zoomInAction;
    QAction *zoomOutAction;
    QAction *closeAction;
    QAction *gridLinesAction;

    QToolBar *fileToolBar;
    QToolBar *editToolBar;
    QToolBar *viewToolBar;

    bool mExitApplication;

    void closeEvent(QCloseEvent *event);
private slots:
    void openNewPackage();
    void openNewModel();
    void openOMShell();
private:
    void createActions();
    void createMenus();
    void createToolbars();
    QDockWidget *messagedock;
    QDockWidget *libdock;
};

#endif // MAINWINDOW_H
