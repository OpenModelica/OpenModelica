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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#undef smooth

/* Keep PlotWindowContainer on top to include OSG first */
#include "Plotting/PlotWindowContainer.h"

#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#include <QPrinter>
#include <QPrintDialog>
#include <QtWebKitWidgets>
#include <QTextCodec>
#include <QUrlQuery>
#include <QItemDelegate>
#include <QDomDocument>
#else
#include <QDir>
#include <QtGui>
#include <QtWebKit>
#include <QtCore>
#include <QDomDocument>
#endif

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
#include "SimulationDialog.h"
#include "TLMCoSimulationDialog.h"
#include "ModelWidgetContainer.h"
#include "GDBAdapter.h"
#include "StackFramesWidget.h"
#include "LocalsWidget.h"
#include "ImportFMUDialog.h"
#include "NotificationsDialog.h"

class OMCProxy;
class OptionsDialog;
class MessagesWidget;
class TransformationsWidget;
class LibraryWidget;
class DocumentationWidget;
class VariablesWidget;
class GDBAdapter;
class StackFramesWidget;
class LocalsWidget;
class BreakpointsWidget;
class TargetOutputWidget;
class GDBLoggerWidget;
class SimulationDialog;
class TLMCoSimulationDialog;
class PlotWindowContainer;
class ModelWidgetContainer;
class InfoBar;
class WelcomePageWidget;
class AboutOMEditWidget;

class MainWindow : public QMainWindow
{
  Q_OBJECT
public:
  enum { MaxRecentFiles = 8 };
  MainWindow(QSplashScreen *pSplashScreen, bool debug, QWidget *parent = 0);
  bool isDebug() {return mDebug;}
  OMCProxy* getOMCProxy() {return mpOMCProxy;}
  void setExitApplicationStatus(bool status) {mExitApplicationStatus = status;}
  bool getExitApplicationStatus() {return mExitApplicationStatus;}
  OptionsDialog* getOptionsDialog() {return mpOptionsDialog;}
  MessagesWidget* getMessagesWidget() {return mpMessagesWidget;}
  LibraryWidget* getLibraryWidget() {return mpLibraryWidget;}
  GDBAdapter* getGDBAdapter() {return mpGDBAdapter;}
  StackFramesWidget* getStackFramesWidget() {return mpStackFramesWidget;}
  BreakpointsWidget* getBreakpointsWidget() {return mpBreakpointsWidget;}
  LocalsWidget* getLocalsWidget() {return mpLocalsWidget;}
  TargetOutputWidget* getTargetOutputWidget() {return mpTargetOutputWidget;}
  GDBLoggerWidget* getGDBLoggerWidget() {return mpGDBLoggerWidget;}
  DocumentationWidget* getDocumentationWidget() {return mpDocumentationWidget;}
  QDockWidget* getDocumentationDockWidget() {return mpDocumentationDockWidget;}
  VariablesWidget* getVariablesWidget() {return mpVariablesWidget;}
  QDockWidget* getVariablesDockWidget() {return mpVariablesDockWidget;}
  SimulationDialog* getSimulationDialog() {return mpSimulationDialog;}
  TLMCoSimulationDialog* getTLMCoSimulationDialog() {return mpTLMCoSimulationDialog;}
  PlotWindowContainer* getPlotWindowContainer() {return mpPlotWindowContainer;}
  ModelWidgetContainer* getModelWidgetContainer() {return mpModelWidgetContainer;}
  WelcomePageWidget* getWelcomePageWidget() {return mpWelcomePageWidget;}
  InfoBar* getInfoBar() {return mpInfoBar;}
  QStatusBar* getStatusBar() {return mpStatusBar;}
  QProgressBar* getProgressBar() {return mpProgressBar;}
  void showProgressBar() {mpProgressBar->setVisible(true);}
  void hideProgressBar() {mpProgressBar->setVisible(false);}
  Label* getPointerXPositionLabel() {return mpPointerXPositionLabel;}
  Label* getPointerYPositionLabel() {return mpPointerYPositionLabel;}
  QTabBar* getPerspectiveTabBar() {return mpPerspectiveTabbar;}
  QToolBar* getPlotToolBar() {return mpPlotToolBar;}
  QTimer* getAutoSaveTimer() {return mpAutoSaveTimer;}
  QAction* getSaveAction() {return mpSaveAction;}
  QAction* getSaveAsAction() {return mpSaveAsAction;}
  QAction* getSaveTotalAction() {return mpSaveTotalAction;}
  QAction* getPrintModelAction() {return mpPrintModelAction;}
  QAction* getSaveAllAction() {return mpSaveAllAction;}
  QAction* getUndoAction() {return mpUndoAction;}
  QAction* getRedoAction() {return mpRedoAction;}
  QAction* getShowGridLinesAction() {return mpShowGridLinesAction;}
  QAction* getResetZoomAction() {return mpResetZoomAction;}
  QAction* getZoomInAction() {return mpZoomInAction;}
  QAction* getZoomOutAction() {return mpZoomOutAction;}
  QAction* getSimulateModelAction() {return mpSimulateModelAction;}
  QAction* getSimulateWithTransformationalDebuggerAction() {return mpSimulateWithTransformationalDebuggerAction;}
  QAction* getSimulateWithAlgorithmicDebuggerAction() {return mpSimulateWithAlgorithmicDebuggerAction;}
#if !defined(WITHOUT_OSG)
  QAction* getSimulateWithAnimationAction() {return mpSimulateWithAnimationAction;}
#endif
  QAction* getSimulationSetupAction() {return mpSimulationSetupAction;}
  QAction* getInstantiateModelAction() {return mpInstantiateModelAction;}
  QAction* getCheckModelAction() {return mpCheckModelAction;}
  QAction* getCheckAllModelsAction() {return mpCheckAllModelsAction;}
  QAction* getExportFMUAction() {return mpExportFMUAction;}
  QAction* getExportXMLAction() {return mpExportXMLAction;}
  QAction* getExportFigaroAction() {return mpExportFigaroAction;}
  QAction* getLineShapeAction() {return mpLineShapeAction;}
  QAction* getPolygonShapeAction() {return mpPolygonShapeAction;}
  QAction* getRectangleShapeAction() {return mpRectangleShapeAction;}
  QAction* getEllipseShapeAction() {return mpEllipseShapeAction;}
  QAction* getTextShapeAction() {return mpTextShapeAction;}
  QAction* getBitmapShapeAction() {return mpBitmapShapeAction;}
  QAction* getExportAsImageAction() {return mpExportAsImageAction;}
  QAction* getExportToClipboardAction() {return mpExportToClipboardAction;}
  QAction* getExportToOMNotebookAction() {return mpExportToOMNotebookAction;}
  QAction* getImportFromOMNotebookAction() {return mpImportFromOMNotebookAction;}
  QAction* getImportNgspiceNetlistAction() {return mpImportNgspiceNetlistAction;}
  QAction* getConnectModeAction() {return mpConnectModeAction;}
  QAction* getReSimulateModelAction() {return mpReSimulateModelAction;}
  QAction* getReSimulateSetupAction() {return mpReSimulateSetupAction;}
  QAction* getSimulationParamsAction() {return mpSimulationParamsAction;}
  QAction* getFetchInterfaceDataAction() {return mpFetchInterfaceDataAction;}
  QAction* getAlignInterfacesAction() {return mpAlignInterfacesAction;}
  QAction* getTLMSimulationAction() {return mpTLMCoSimulationAction;}
  void addRecentFile(const QString &fileName, const QString &encoding);
  void updateRecentFileActions();
  void closeEvent(QCloseEvent *event);
  int askForExit();
  void beforeClosingMainWindow();
  void openDroppedFile(QDropEvent *event);
  void openResultFiles(QStringList fileNames);
  void simulate(LibraryTreeItem *pLibraryTreeItem);
  void simulateWithTransformationalDebugger(LibraryTreeItem *pLibraryTreeItem);
  void simulateWithAlgorithmicDebugger(LibraryTreeItem *pLibraryTreeItem);
#if !defined(WITHOUT_OSG)
  void simulateWithAnimation(LibraryTreeItem *pLibraryTreeItem);
#endif
  void simulationSetup(LibraryTreeItem *pLibraryTreeItem);
  void instantiateModel(LibraryTreeItem *pLibraryTreeItem);
  void checkModel(LibraryTreeItem *pLibraryTreeItem);
  void checkAllModels(LibraryTreeItem *pLibraryTreeItem);
  void exportModelFMU(LibraryTreeItem *pLibraryTreeItem);
  void exportModelXML(LibraryTreeItem *pLibraryTreeItem);
  void exportModelFigaro(LibraryTreeItem *pLibraryTreeItem);
  void fetchInterfaceData(LibraryTreeItem *pLibraryTreeItem);
  void TLMSimulate(LibraryTreeItem *pLibraryTreeItem);
  void exportModelToOMNotebook(LibraryTreeItem *pLibraryTreeItem);
  void createOMNotebookTitleCell(LibraryTreeItem *pLibraryTreeItem, QDomDocument xmlDocument, QDomElement domElement);
  void createOMNotebookImageCell(LibraryTreeItem *pLibraryTreeItem, QDomDocument xmlDocument, QDomElement domElement, QString filePath);
  void createOMNotebookCodeCell(LibraryTreeItem *pLibraryTreeItem, QDomDocument xmlDocument, QDomElement domElement);
  TransformationsWidget* showTransformationsWidget(QString fileName);
  void findFileAndGoToLine(QString fileName, QString lineNumber);
  static void PlotCallbackFunction(void *p, int externalWindow, const char* filename, const char* title, const char* grid,
                                   const char* plotType, const char* logX, const char* logY, const char* xLabel, const char* yLabel,
                                   const char* x1, const char* x2, const char* y1, const char* y2, const char* curveWidth,
                                   const char* curveStyle, const char* legendPosition, const char* footer, const char* autoScale,
                                   const char* variables);
private:
  bool mDebug;
  OMCProxy *mpOMCProxy;
  bool mExitApplicationStatus;
  OptionsDialog *mpOptionsDialog;
  MessagesWidget *mpMessagesWidget;
  QDockWidget *mpMessagesDockWidget;
  FileDataNotifier *mpOutputFileDataNotifier;
  FileDataNotifier *mpErrorFileDataNotifier;
  LibraryWidget *mpLibraryWidget;
  QDockWidget *mpLibraryDockWidget;
  GDBAdapter *mpGDBAdapter;
  StackFramesWidget *mpStackFramesWidget;
  QDockWidget *mpStackFramesDockWidget;
  BreakpointsWidget *mpBreakpointsWidget;
  QDockWidget *mpBreakpointsDockWidget;
  LocalsWidget *mpLocalsWidget;
  QDockWidget *mpLocalsDockWidget;
  TargetOutputWidget *mpTargetOutputWidget;
  QDockWidget *mpTargetOutputDockWidget;
  GDBLoggerWidget *mpGDBLoggerWidget;
  QDockWidget *mpGDBLoggerDockWidget;
  DocumentationWidget *mpDocumentationWidget;
  QDockWidget *mpDocumentationDockWidget;
  VariablesWidget *mpVariablesWidget;
  QDockWidget *mpVariablesDockWidget;
  SimulationDialog *mpSimulationDialog;
  TLMCoSimulationDialog *mpTLMCoSimulationDialog;
  PlotWindowContainer *mpPlotWindowContainer;
  ModelWidgetContainer *mpModelWidgetContainer;
  WelcomePageWidget *mpWelcomePageWidget;
  AboutOMEditWidget *mpAboutOMEditDialog;
  InfoBar *mpInfoBar;
  QStackedWidget *mpCentralStackedWidget;
  QProgressBar *mpProgressBar;
  Label *mpPointerXPositionLabel;
  Label *mpPointerYPositionLabel;
  QTabBar *mpPerspectiveTabbar;
  QStatusBar *mpStatusBar;
  QTimer *mpAutoSaveTimer;
  // File Menu
  // Modelica File Actions
  QAction *mpNewModelicaClassAction;
  QAction *mpOpenModelicaFileAction;
  QAction *mpOpenModelicaFileWithEncodingAction;
  QAction *mpLoadModelicaLibraryAction;
  QAction *mpOpenResultFileAction;
  QAction *mpOpenTransformationFileAction;
  // MetaModel File Actions
  QAction *mpNewMetaModelFileAction;
  QAction *mpOpenMetaModelFileAction;
  QAction *mpLoadExternModelAction;
  QAction *mpOpenDirectoryAction;
  QAction *mpSaveAction;
  QAction *mpSaveAsAction;
  QAction *mpSaveAllAction;
  QAction *mpSaveTotalAction;
  QAction *mpRecentFileActions[MaxRecentFiles];
  QAction *mpClearRecentFilesAction;
  QAction *mpPrintModelAction;
  QAction *mpQuitAction;
  // Edit Menu
  QAction *mpUndoAction;
  QAction *mpRedoAction;
  QAction *mpSearchClassesAction;
  QAction *mpCutAction;
  QAction *mpCopyAction;
  QAction *mpPasteAction;
  // View Menu
  QAction *mpShowGridLinesAction;
  QAction *mpResetZoomAction;
  QAction *mpZoomInAction;
  QAction *mpZoomOutAction;
  QAction *mpCloseWindowAction;
  QAction *mpCloseAllWindowsAction;
  QAction *mpCloseAllWindowsButThisAction;
  QAction *mpCascadeWindowsAction;
  QAction *mpTileWindowsHorizontallyAction;
  QAction *mpTileWindowsVerticallyAction;
  // Simulation Menu
  QAction *mpInstantiateModelAction;
  QAction *mpCheckModelAction;
  QAction *mpCheckAllModelsAction;
  QAction *mpSimulateModelAction;
  QAction *mpSimulateWithTransformationalDebuggerAction;
  QAction *mpSimulateWithAlgorithmicDebuggerAction;
#if !defined(WITHOUT_OSG)
  QAction *mpSimulateWithAnimationAction;
#endif
  QAction *mpSimulationSetupAction;
  // FMI Menu
  QAction *mpExportFMUAction;
  QAction *mpImportFMUAction;
  // Export Menu
  QAction *mpExportXMLAction;
  QAction *mpExportFigaroAction;
  // Debug Menu
  QAction *mpDebugConfigurationsAction;
  QAction *mpAttachDebuggerToRunningProcessAction;
  // Tools Menu
  QAction *mpShowOMCLoggerWidgetAction;
  QAction *mpShowOpenModelicaCommandPromptAction;
  QAction *mpShowOMCDiffWidgetAction;
  QAction *mpExportToOMNotebookAction;
  QAction *mpImportFromOMNotebookAction;
  QAction *mpImportNgspiceNetlistAction;
  QAction *mpOpenWorkingDirectoryAction;
  QAction *mpOpenTerminalAction;
  QAction *mpOptionsAction;
  // Help Menu
  QAction *mpUsersGuideAction;
  QAction *mpUsersGuidePdfAction;
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
  QAction *mpReSimulateSetupAction;
  QAction *mpNewPlotWindowAction;
  QAction *mpNewParametricPlotWindowAction;
#if !defined(WITHOUT_OSG)
  QAction *mpNewAnimationWindowAction;
#endif
  QAction *mpClearPlotWindowAction;
  QAction *mpExportVariablesAction;
  // Other Actions
  QAction *mpExportAsImageAction;
  QAction *mpExportToClipboardAction;
  // TLM Simulation Action
  QAction *mpSimulationParamsAction;
  QAction *mpFetchInterfaceDataAction;
  QAction *mpAlignInterfacesAction;
  QAction *mpTLMCoSimulationAction;
  // Toolbars
  QMenu *mpRecentFilesMenu;
  QMenu *mpLibrariesMenu;
  QToolBar *mpFileToolBar;
  QToolBar *mpEditToolBar;
  QToolBar *mpViewToolBar;
  QToolBar *mpShapesToolBar;
  QToolBar *mpModelSwitcherToolBar;
  QToolButton *mpModelSwitcherToolButton;
  QMenu *mpModelSwitcherMenu;
  QToolBar *mpCheckToolBar;
  QToolBar *mpSimulationToolBar;
  QToolBar *mpReSimulationToolBar;
  QToolBar *mpPlotToolBar;
  QToolBar *mpTLMSimulationToolbar;
  QHash<QString, TransformationsWidget*> mTransformationsWidgetHash;
public slots:
  void createNewModelicaClass();
  void openModelicaFile();
  void showOpenModelicaFileDialog();
  void loadModelicaLibrary();
  void showOpenResultFileDialog();
  void showOpenTransformationFileDialog();
  void createNewMetaModelFile();
  void openMetaModelFile();
  void loadExternalModels();
  void openDirectory();
  void loadSystemLibrary();
  void readOutputFile(qint64 bytes);
  void readErrorFile(qint64 bytes);
  void openRecentFile();
  void clearRecentFilesList();
  void undo();
  void redo();
  void focusSearchClasses();
  void setShowGridLines(bool On);
  void resetZoom();
  void zoomIn();
  void zoomOut();
  void closeWindow();
  void closeAllWindows();
  void closeAllWindowsButThis();
  void cascadeSubWindows();
  void tileSubWindowsHorizontally();
  void tileSubWindowsVertically();
  void instantiateModel();
  void checkModel();
  void checkAllModels();
  void simulateModel();
  void simulateModelWithTransformationalDebugger();
  void simulateModelWithAlgorithmicDebugger();
  void simulateModelWithAnimation();
  void openSimulationDialog();
  void exportModelFMU();
  void importModelFMU();
  void exportModelXML();
  void exportModelFigaro();
  void showOpenModelicaCommandPrompt();
  void exportModelToOMNotebook();
  void importModelfromOMNotebook();
  void importNgspiceNetlist();
  void exportModelAsImage(bool copyToClipboard = false);
  void exportToClipboard();
  void fetchInterfaceData();
  void TLMSimulate();
  void openWorkingDirectory();
  void openTerminal();
  void openConfigurationOptions();
  void openUsersGuide();
  void openUsersGuidePdf();
  void openUsersGuideOldPdf();
  void openSystemDocumentation();
  void openOpenModelicaScriptingDocumentation();
  void openModelicaDocumentation();
  void openModelicaByExample();
  void openModelicaWebReference();
  void openAboutOMEdit();
  void toggleShapesButton();
  void openRecentModelWidget();
  void updateModelSwitcherMenu(QMdiSubWindow *pSubWindow);
  void toggleAutoSave();
  void readInterfaceData(LibraryTreeItem *pLibraryTreeItem);
private slots:
  void perspectiveTabChanged(int tabIndex);
  void documentationDockWidgetVisibilityChanged(bool visible);
  void autoSave();
  void switchToWelcomePerspectiveSlot();
  void switchToModelingPerspectiveSlot();
  void switchToPlottingPerspectiveSlot();
  void switchToAlgorithmicDebuggingPerspectiveSlot();
  void showConfigureDialog();
  void showAttachToProcessDialog();
private:
  void createActions();
  void createToolbars();
  void createMenus();
  void autoSaveHelper(LibraryTreeItem *pLibraryTreeItem);
  void switchToWelcomePerspective();
  void switchToModelingPerspective();
  void switchToPlottingPerspective();
  void switchToAlgorithmicDebuggingPerspective();
  void closeAllWindowsButThis(QMdiArea *pMdiArea);
  void tileSubWindows(QMdiArea *pMdiArea, bool horizontally);
  void fetchInterfaceDataHelper(LibraryTreeItem *pLibraryTreeItem);
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
