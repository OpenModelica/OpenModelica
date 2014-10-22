/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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
#include "TransformationsWidget.h"
#include "LibraryTreeWidget.h"
#include "DocumentationWidget.h"
//#include "SimulationBrowserWidget.h"
#include "SimulationDialog.h"
#include "Plotting/PlotWindowContainer.h"
#include "ModelWidgetContainer.h"
#include "FindReplaceDialog.h"
#include "DebuggerMainWindow.h"
#include "ImportFMUDialog.h"
#include "NotificationsDialog.h"

class OMCProxy;
class OptionsDialog;
class MessagesWidget;
class TransformationsWidget;
class SearchClassWidget;
class LibraryTreeWidget;
class DocumentationWidget;
//class SimulationBrowserWidget;
class VariablesWidget;
class SimulationDialog;
class PlotWindowContainer;
class ModelWidgetContainer;
class DebuggerMainWindow;
class InfoBar;
class WelcomePageWidget;
class AboutOMEditWidget;
class FindReplaceDialog;

class MainWindow : public QMainWindow
{
  Q_OBJECT
public:
  enum { MaxRecentFiles = 8 };
  MainWindow(QSplashScreen *pSplashScreen, QWidget *parent = 0);
  OMCProxy* getOMCProxy();
  void setExitApplicationStatus(bool status);
  bool getExitApplicationStatus();
  void setDebugApplication(bool debug);
  bool getDebugApplication();
  OptionsDialog* getOptionsDialog();
  MessagesWidget* getMessagesWidget();
  LibraryTreeWidget* getLibraryTreeWidget();
  DocumentationWidget* getDocumentationWidget();
  QDockWidget* getDocumentationDockWidget();
//  SimulationBrowserWidget* getSimulationBrowserWidget() {return mpSimulationBrowserWidget;}
  VariablesWidget* getVariablesWidget();
  QDockWidget* getVariablesDockWidget();
  SimulationDialog* getSimulationDialog();
  PlotWindowContainer* getPlotWindowContainer();
  //InteractiveSimulationTabWidget* getInteractiveSimulationTabWidget();
  ModelWidgetContainer* getModelWidgetContainer();
  DebuggerMainWindow* getDebuggerMainWindow() {return mpDebuggerMainWindow;}
  WelcomePageWidget* getWelcomePageWidget();
  InfoBar* getInfoBar();
  QStatusBar* getStatusBar();
  QProgressBar* getProgressBar();
  Label* getPointerXPositionLabel();
  Label* getPointerYPositionLabel();
  QTabBar* getPerspectiveTabBar();
  QAction* getSaveAction();
  QAction* getSaveAsAction();
  QAction* getSaveTotalModelAction() {return mpSaveTotalModelAction;}
  QAction* getPrintModelAction();
  QAction* getSaveAllAction();
  QAction* getShowGridLinesAction();
  QAction* getResetZoomAction();
  QAction* getZoomInAction();
  QAction* getZoomOutAction();
  QAction* getSimulateModelAction();
  QAction* getSimulateWithAlgorithmicDebuggerAction() {return mpSimulateWithAlgorithmicDebuggerAction;}
  QAction* getSimulationSetupAction();
  QAction* getInstantiateModelAction();
  QAction* getCheckModelAction();
  QAction* getCheckAllModelsAction() {return mpCheckAllModelsAction;}
  QAction* getExportFMUAction();
  QAction* getExportXMLAction();
  QAction* getExportFigaroAction();
  QAction* getLineShapeAction();
  QAction* getPolygonShapeAction();
  QAction* getRectangleShapeAction();
  QAction* getEllipseShapeAction();
  QAction* getTextShapeAction();
  QAction* getBitmapShapeAction();
  QAction* getExportAsImageAction();
  QAction* getExportToOMNotebookAction();
  QAction* getImportFromOMNotebookAction();
  QAction* getImportNgspiceNetlistAction();
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
  void simulateWithAlgorithmicDebugger(LibraryTreeNode *pLibraryTreeNode);
  void simulationSetup(LibraryTreeNode *pLibraryTreeNode);
  void instantiatesModel(LibraryTreeNode *pLibraryTreeNode);
  void checkModel(LibraryTreeNode *pLibraryTreeNode);
  void checkAllModels(LibraryTreeNode *pLibraryTreeNode);
  void exportModelFMU(LibraryTreeNode *pLibraryTreeNode);
  void exportModelXML(LibraryTreeNode *pLibraryTreeNode);
  void exportModelFigaro(LibraryTreeNode *pLibraryTreeNode);
  void exportModelToOMNotebook(LibraryTreeNode *pLibraryTreeNode);
  void createOMNotebookTitleCell(LibraryTreeNode *pLibraryTreeNode, QDomDocument xmlDocument, QDomElement domElement);
  void createOMNotebookImageCell(LibraryTreeNode *pLibraryTreeNode, QDomDocument xmlDocument, QDomElement domElement, QString filePath);
  void createOMNotebookCodeCell(LibraryTreeNode *pLibraryTreeNode, QDomDocument xmlDocument, QDomElement domElement);
  TransformationsWidget* showTransformationsWidget(QString fileName);
private:
  OMCProxy *mpOMCProxy;
  bool mExitApplicationStatus;
  bool mDebugApplication;
  OptionsDialog *mpOptionsDialog;
  MessagesWidget *mpMessagesWidget;
  QDockWidget *mpMessagesDockWidget;
  SearchClassWidget *mpSearchClassWidget;
  QDockWidget *mpSearchClassDockWidget;
  LibraryTreeWidget *mpLibraryTreeWidget;
  QDockWidget *mpLibraryTreeDockWidget;
  DocumentationWidget *mpDocumentationWidget;
  QDockWidget *mpDocumentationDockWidget;
//  SimulationBrowserWidget *mpSimulationBrowserWidget;
//  QDockWidget *mpSimulationDockWidget;
  VariablesWidget *mpVariablesWidget;
  QDockWidget *mpVariablesDockWidget;
  FindReplaceDialog *mpFindReplaceDialog;
  SimulationDialog *mpSimulationDialog;
  PlotWindowContainer *mpPlotWindowContainer;
  //InteractiveSimulationTabWidget *mpInteractiveSimualtionTabWidget;
  ModelWidgetContainer *mpModelWidgetContainer;
  DebuggerMainWindow *mpDebuggerMainWindow;
  WelcomePageWidget *mpWelcomePageWidget;
  AboutOMEditWidget *mpAboutOMEditDialog;
  InfoBar *mpInfoBar;
  QStackedWidget *mpCentralStackedWidget;
  QStatusBar *mpStatusBar;
  QProgressBar *mpProgressBar;
  Label *mpPointerXPositionLabel;
  Label *mpPointerYPositionLabel;
  QTabBar *mpPerspectiveTabbar;
  QTimer *mpAutoSaveTimer;
  // File Menu
  QAction *mpNewModelicaClassAction;
  QAction *mpNewTLMFileAction;
  QAction *mpOpenModelicaFileAction;
  QAction *mpOpenModelicaFileWithEncodingAction;
  QAction *mpLoadModelicaLibraryAction;
  QAction *mpOpenResultFileAction;
  QAction *mpOpenTransformationFileAction;
  QAction *mpSaveAction;
  QAction *mpSaveAsAction;
  QAction *mpSaveAllAction;
  QAction *mpSaveTotalModelAction;
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
  QAction *mpShowAlgorithmicDebuggerAction;
  // Simulation Menu
  QAction *mpInstantiateModelAction;
  QAction *mpCheckModelAction;
  QAction *mpCheckAllModelsAction;
  QAction *mpSimulateModelAction;
  QAction *mpSimulateWithAlgorithmicDebuggerAction;
  QAction *mpSimulationSetupAction;
  // FMI Menu
  QAction *mpExportFMUAction;
  QAction *mpImportFMUAction;
  // Export Menu
  QAction *mpExportXMLAction;
  QAction *mpExportFigaroAction;
  // Tools Menu
  QAction *mpShowOMCLoggerWidgetAction;
  QAction *mpExportToOMNotebookAction;
  QAction *mpImportFromOMNotebookAction;
  QAction *mpImportNgspiceNetlistAction;
  QAction *mpOptionsAction;
  // Help Menu
  QAction *mpUsersGuideAction;
  QAction *mpSystemDocumentationAction;
  QAction *mpOpenModelicaScriptingAction;
  QAction *mpModelicaDocumentationAction;
  QAction *mpModelicaByExampleAction;
  QAction *mpModelicaWebReferenceAction;
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
  QAction *mpReSimulateModelAction;
  QAction *mpNewPlotWindowAction;
  QAction *mpNewParametricPlotWindowAction;
  QAction *mpClearPlotWindowAction;
  // Other Actions
  QAction *mpExportAsImageAction;
  // Toolbars
  QMenu *mpRecentFilesMenu;
  QMenu *mpLibrariesMenu;
  QToolBar *mpFileToolBar;
  QToolBar *mpEditToolBar;
  QToolBar *mpViewToolBar;
  QToolBar *mpShapesToolBar;
  QToolBar *mpSimulationToolBar;
  QToolBar *mpModelSwitcherToolBar;
  QToolButton *mpModelSwitcherToolButton;
  QMenu *mpModelSwitcherMenu;
  QToolBar *mpPlotToolBar;
  QHash<QString, TransformationsWidget*> mTransformationsWidgetHash;
public slots:
  void createNewModelicaClass();
  void createNewTLMFile();
  void openModelicaFile();
  void showOpenModelicaFileDialog();
  void loadModelicaLibrary();
  void showOpenResultFileDialog();
  void showOpenTransformationFileDialog();
  void loadSystemLibrary();
  void focusSearchClassWidget(bool visible);
  void openRecentFile();
  void clearRecentFilesList();
  void clearFindReplaceTexts();
  void setShowGridLines(bool On);
  void resetZoom();
  void zoomIn();
  void zoomOut();
  void showAlgorithmicDebugger();
  void instantiatesModel();
  void checkModel();
  void checkAllModels();
  void simulateModel();
  void simulateModelWithAlgorithmicDebugger();
  void openSimulationDialog();
  void openInteractiveSimulation();
  void showFindReplaceDialog();
  void showGotoLineNumberDialog();
  void exportModelFMU();
  void importModelFMU();
  void exportModelXML();
  void exportModelFigaro();
  void exportModelToOMNotebook();
  void importModelfromOMNotebook();
  void importNgspiceNetlist();
  void exportModelAsImage();
  void openConfigurationOptions();
  void openUsersGuide();
  void openSystemDocumentation();
  void openOpenModelicaScriptingDocumentation();
  void openModelicaDocumentation();
  void openModelicaByExample();
  void openModelicaWebReference();
  void openAboutOMEdit();
  void toggleShapesButton();
  void openRecentModelWidget();
  void reSimulateModel();
  void addNewPlotWindow();
  void addNewParametricPlotWindow();
  void clearPlotWindow();
  void showProgressBar();
  void hideProgressBar();
  void updateModelSwitcherMenu(QMdiSubWindow *pSubWindow);
  void toggleAutoSave();
private slots:
  void perspectiveTabChanged(int tabIndex);
  void autoSave();
private:
  void createActions();
  void createToolbars();
  void createMenus();
  void switchToWelcomePerspective();
  void switchToModelingPerspective();
  void switchToPlottingPerspective();
  void switchToInteractiveSimulationPerspective();
protected:
  virtual void dragEnterEvent(QDragEnterEvent *event);
  virtual void dragMoveEvent(QDragMoveEvent *event);
  virtual void dropEvent(QDropEvent *event);
  virtual void resizeEvent(QResizeEvent *event);
};

class InfoBar : public QFrame
{
public:
  InfoBar(QWidget *pParent);
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
