/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR 
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2. 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE. 
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * 
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QtCore>
#include <QtGui>
#include <QDomDocument>


#if (QT_VERSION < QT_VERSION_CHECK(4, 6, 0))
#error "OMEdit requires Qt 4.6.0 or newer"
#endif

#include "OMCProxy.h"
#include "OptionsDialog.h"
#include "ModelicaClassDialog.h"
#include "StringHandler.h"
#include "MessagesWidget.h"
#include "LibraryTreeWidget.h"
#include "DocumentationWidget.h"
#include "VariablesWidget.h"
#include "SimulationDialog.h"
#include "GUI/Containers/PlotWindowContainer.h"
#include "ModelWidgetContainer.h"
#include "ImportFMUDialog.h"
#include "NotificationsDialog.h"


class OMCProxy;
class OptionsDialog;
class MessagesWidget;
class SearchClassWidget;
class LibraryTreeWidget;
class DocumentationWidget;
class VariablesWidget;
class SimulationDialog;
class PlotWindowContainer;
class ModelWidgetContainer;
class InfoBar;
class WelcomePageWidget;
class AboutOMEditWidget;
class FindReplaceDialog;
class MainWindow;

class MainWindow : public QMainWindow
{
  Q_OBJECT
public:
  enum { MaxRecentFiles = 8 };
  MainWindow(QSplashScreen *pSplashScreen, QWidget *parent = 0);
  OMCProxy* getOMCProxy();
  void setExitApplicationStatus(bool status);
  bool getExitApplicationStatus();
  OptionsDialog* getOptionsDialog();
  MessagesWidget* getMessagesWidget();
  LibraryTreeWidget* getLibraryTreeWidget();
  DocumentationWidget* getDocumentationWidget();
  QDockWidget* getDocumentationDockWidget();
  VariablesWidget* getVariablesWidget();
  QDockWidget* getVariablesDockWidget();
  PlotWindowContainer* getPlotWindowContainer();
  //InteractiveSimulationTabWidget* getInteractiveSimulationTabWidget();
  ModelWidgetContainer* getModelWidgetContainer();
  InfoBar* getInfoBar();
  QStatusBar* getStatusBar();
  QProgressBar* getProgressBar();
  Label* getPointerXPositionLabel();
  Label* getPointerYPositionLabel();
  QAction* getSaveAction();
  QAction* getSaveAsAction();
  QAction* getPrintModelAction();
  QAction* getSaveAllAction();
  QAction* getShowGridLinesAction();
  QAction* getResetZoomAction();
  QAction* getZoomInAction();
  QAction* getZoomOutAction();
  QAction* getSimulationAction();
  QAction* getInstantiateModelAction();
  QAction* getCheckModelAction();
  QAction* getExportFMUAction();
  QAction* getExportXMLAction();
  QAction* getLineShapeAction();
  QAction* getPolygonShapeAction();
  QAction* getRectangleShapeAction();
  QAction* getEllipseShapeAction();
  QAction* getTextShapeAction();
  QAction* getBitmapShapeAction();
  QAction* getExportAsImageAction();
  QAction* getExportToOMNotebookAction();
  QAction* getImportFromOMNotebookAction();
  QAction* getConnectModeAction();
  QAction* getFindReplaceAction();
  QAction* getClearFindReplaceTextsAction();
  QAction* getGotoLineNumberAction();
  void addRecentFile(const QString &fileName, const QString &encoding);
  void updateRecentFileActions();
  void closeEvent(QCloseEvent *event);
  int askForExit();
  void beforeClosingMainWindow();
  void openDroppedFile(QDropEvent *event);
  void openResultFiles(QStringList fileNames);
  void simulate(LibraryTreeNode *pLibraryTreeNode);
  void instantiatesModel(LibraryTreeNode *pLibraryTreeNode);
  void checkModel(LibraryTreeNode *pLibraryTreeNode);
  void exportModelFMU(LibraryTreeNode *pLibraryTreeNode);
  void exportModelXML(LibraryTreeNode *pLibraryTreeNode);
  void exportModelToOMNotebook(LibraryTreeNode *pLibraryTreeNode);
  void createOMNotebookTitleCell(LibraryTreeNode *pLibraryTreeNode, QDomDocument xmlDocument, QDomElement domElement);
  void createOMNotebookImageCell(LibraryTreeNode *pLibraryTreeNode, QDomDocument xmlDocument, QDomElement domElement, QString filePath);
  void createOMNotebookCodeCell(LibraryTreeNode *pLibraryTreeNode, QDomDocument xmlDocument, QDomElement domElement);
  void switchToWelcomeView();
  void switchToModelingView();
  void switchToPlottingView();
  void switchToInteractiveSimulationView();
private:
  OMCProxy *mpOMCProxy;
  bool mExitApplicationStatus;
  OptionsDialog *mpOptionsDialog;
  MessagesWidget *mpMessagesWidget;
  QDockWidget *mpMessagesDockWidget;
  SearchClassWidget *mpSearchClassWidget;
  QDockWidget *mpSearchClassDockWidget;
  LibraryTreeWidget *mpLibraryTreeWidget;
  QDockWidget *mpLibraryTreeDockWidget;
  DocumentationWidget *mpDocumentationWidget;
  QDockWidget *mpDocumentationDockWidget;
  VariablesWidget *mpVariablesWidget;
  QDockWidget *mpVariablesDockWidget;
  FindReplaceDialog *mpFindReplaceDialog;
  SimulationDialog *mpSimulationDialog;
  PlotWindowContainer *mpPlotWindowContainer;
  //InteractiveSimulationTabWidget *mpInteractiveSimualtionTabWidget;
  ModelWidgetContainer *mpModelWidgetContainer;
  WelcomePageWidget *mpWelcomePageWidget;
  AboutOMEditWidget *mpAboutOMEditDialog;
  InfoBar *mpInfoBar;
  QStatusBar *mpStatusBar;
  QProgressBar *mpProgressBar;
  Label *mpPointerXPositionLabel;
  Label *mpPointerYPositionLabel;
  QTabBar *mpPerspectiveTabbar;
  // File Menu
  QAction *mpNewModelicaClassAction;
  QAction *mpOpenModelicaFileAction;
  QAction *mpOpenResultFileAction;
  QAction *mpSaveAction;
  QAction *mpSaveAsAction;
  QAction *mpSaveAllAction;
  QAction *mpRecentFileActions[MaxRecentFiles];
  QAction *mpClearRecentFilesAction;
  QAction *mpPrintModelAction;
  QAction *mpQuitAction;
  // Edit Menu
  QAction *mpCutAction;
  QAction *mpCopyAction;
  QAction *mpPasteAction;
  QAction *mpFindReplaceAction;
  QAction *mpClearFindReplaceTextsAction;
  QAction *mpGotoLineNumberAction;
  // View Menu
  QAction *mpShowGridLinesAction;
  QAction *mpResetZoomAction;
  QAction *mpZoomInAction;
  QAction *mpZoomOutAction;
  // Simulation Menu
  QAction *mpSimulationAction;
  QAction *mpInstantiateModelAction;
  QAction *mpCheckModelAction;
  // FMI Menu
  QAction *mpExportFMUAction;
  QAction *mpImportFMUAction;
  // XML Menu
  QAction *mpExportXMLAction;
  // Tools Menu
  QAction *mpOmcLoggerAction;
  QAction *mpExportToOMNotebookAction;
  QAction *mpImportFromOMNotebookAction;
  QAction *mpOptionsAction;
  // Help Menu
  QAction *mpUsersGuideAction;
  QAction *mpSystemDocumentationAction;
  QAction *mpAboutOMEditAction;
  // Toolbar Actions
  // Shapes Toolbar Actions
  QActionGroup *mpShapesActionGroup;
  QAction *mpLineShapeAction;
  QAction *mpPolygonShapeAction;
  QAction *mpRectangleShapeAction;
  QAction *mpEllipseShapeAction;
  QAction *mpTextShapeAction;
  QAction *mpBitmapShapeAction;
  QAction *mpConnectModeAction;
  // Model Switcher Toolbar Actions
  QAction *mpModelSwitcherActions[MaxRecentFiles];
  // Plot Toolbar Actions
  QAction *mpNewPlotWindowAction;
  QAction *mpNewPlotParametricWindowAction;
  QAction *mpClearPlotWindowAction;
  // Other Actions
  QAction *mpExportAsImageAction;
  // Toolbars
  QMenu *mpRecentFilesMenu;
  QToolBar *mpFileToolBar;
  QToolBar *mpEditToolBar;
  QToolBar *mpViewToolBar;
  QToolBar *mpShapesToolBar;
  QToolBar *mpSimulationToolBar;
  QToolBar *mpModelSwitcherToolBar;
  QToolButton *mpModelSwitcherToolButton;
  QMenu *mpModelSwitcherMenu;
  QToolBar *mpPlotToolBar;
public slots:
  void createNewModelicaClass();
  void showOpenModelicaFileDialog();
  void showOpenResultFileDialog();
  void focusSearchClassWidget(bool visible);
  void openRecentFile();
  void clearRecentFilesList();
  void clearFindReplaceTexts();
  void setShowGridLines(bool On);
  void resetZoom();
  void zoomIn();
  void zoomOut();
  void instantiatesModel();
  void checkModel();
  void perspectiveTabChanged(int tabIndex);
  void openSimulationDialog();
  void openInteractiveSimulation();
  void showFindReplaceDialog();
  void showGotoLineNumberDialog();
  void exportModelFMU();
  void importModelFMU();
  void exportModelXML();
  void exportModelToOMNotebook();
  void importModelfromOMNotebook();
  void exportModelAsImage();
  void openConfigurationOptions();
  void openUsersGuide();
  void openSystemDocumentation();
  void openAboutOMEdit();
  void toggleShapesButton();
  void openRecentModelWidget();
  void addNewPlotWindow();
  void addNewPlotParametricWindow();
  void clearPlotWindow();
  void showProgressBar();
  void hideProgressBar();
  void updateModelSwitcherMenu(QMdiSubWindow *pSubWindow);
private:
  void createActions();
  void createToolbars();
  void createMenus();
protected:
  virtual void dragEnterEvent(QDragEnterEvent *event);
  virtual void dragMoveEvent(QDragMoveEvent *event);
  virtual void dropEvent(QDropEvent *event);
  virtual void resizeEvent(QResizeEvent *event);
};

class InfoBar : public QFrame
{
public:
  InfoBar(MainWindow *pParent);
  void showMessage(QString message);
private:
  Label *mpInfoLabel;
  QToolButton *mpCloseButton;
};

class AboutOMEditWidget : public QWidget
{
  Q_OBJECT
public:
  AboutOMEditWidget(MainWindow *pMainWindow);
  void paintEvent(QPaintEvent *pEvent);
private:
  QPixmap mBackgroundPixmap;
protected:
  virtual void keyPressEvent(QKeyEvent *pEvent);
};

#endif // MAINWINDOW_H
