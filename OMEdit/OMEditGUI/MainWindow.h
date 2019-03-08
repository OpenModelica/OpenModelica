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

extern "C" {
#include "meta/meta_modelica.h"
#include "omc_config.h"
#include "gc.h"
}

#include <QtGlobal>
#if (QT_VERSION < QT_VERSION_CHECK(4, 6, 0))
#error "OMEdit requires Qt 4.6.0 or newer"
#endif

#include <QMainWindow>
#include <QDialog>
#include <QProgressBar>
#include <QDomDocument>
#include <QStackedWidget>
#include <QActionGroup>
#include <QToolButton>
#include <QMdiSubWindow>
#include <QMdiArea>
#include <QShortcut>

class OMCProxy;
class TransformationsWidget;
class LibraryWidget;
class GDBAdapter;
class StackFramesWidget;
class LocalsWidget;
class TargetOutputWidget;
class GDBLoggerWidget;
class DocumentationWidget;
class PlotWindowContainer;
class VariablesWidget;
#if !defined(WITHOUT_OSG)
class ThreeDViewer;
#endif
class BreakpointsWidget;
class SimulationDialog;
class TLMCoSimulationDialog;
class OMSSimulationDialog;
class ModelWidgetContainer;
class WelcomePageWidget;
class InfoBar;
class AboutOMEditDialog;
class Label;
class FileDataNotifier;
class LibraryTreeItem;
class GitCommands;
class CommitChangesDialog;
class TraceabilityInformationURI;
class TraceabilityGraphViewWidget;
class SearchWidget;

class MainWindow : public QMainWindow
{
  Q_OBJECT
public:
  enum { MaxRecentFiles = 8 };
private:
  MainWindow(bool debug, QWidget *parent = 0);
  static MainWindow *mpInstance;
public:
  static MainWindow *instance(bool debug = false);
  void setUpMainWindow(threadData_t *threadData);
  bool isDebug() {return mDebug;}
  OMCProxy* getOMCProxy() {return mpOMCProxy;}
  void setExitApplicationStatus(bool status) {mExitApplicationStatus = status;}
  bool getExitApplicationStatus() {return mExitApplicationStatus;}
  int getNumberOfProcessors() {return mNumberOfProcessors;}
  LibraryWidget* getLibraryWidget() {return mpLibraryWidget;}
  StackFramesWidget* getStackFramesWidget() {return mpStackFramesWidget;}
  BreakpointsWidget* getBreakpointsWidget() {return mpBreakpointsWidget;}
  LocalsWidget* getLocalsWidget() {return mpLocalsWidget;}
  TargetOutputWidget* getTargetOutputWidget() {return mpTargetOutputWidget;}
  QDockWidget* getTargetOutputDockWidget() {return mpTargetOutputDockWidget;}
  GDBLoggerWidget* getGDBLoggerWidget() {return mpGDBLoggerWidget;}
  DocumentationWidget* getDocumentationWidget() {return mpDocumentationWidget;}
  QDockWidget* getDocumentationDockWidget() {return mpDocumentationDockWidget;}
  PlotWindowContainer* getPlotWindowContainer() {return mpPlotWindowContainer;}
  VariablesWidget* getVariablesWidget() {return mpVariablesWidget;}
  QDockWidget* getVariablesDockWidget() {return mpVariablesDockWidget;}
  SearchWidget* getSearchWidget() {return mpSearchWidget;}

#if !defined(WITHOUT_OSG)
  bool isThreeDViewerInitialized();
  ThreeDViewer* getThreeDViewer();
  QDockWidget* getThreeDViewerDockWidget() {return mpThreeDViewerDockWidget;}
#endif
  SimulationDialog* getSimulationDialog() {return mpSimulationDialog;}
  TLMCoSimulationDialog* getTLMCoSimulationDialog() {return mpTLMCoSimulationDialog;}
  OMSSimulationDialog* getOMSSimulationDialog() {return mpOMSSimulationDialog;}
  ModelWidgetContainer* getModelWidgetContainer() {return mpModelWidgetContainer;}
  WelcomePageWidget* getWelcomePageWidget() {return mpWelcomePageWidget;}
  GitCommands* getGitCommands() {return mpGitCommands;}
  CommitChangesDialog* getCommitChangesDialog() {return mpCommitChangesDialog;}
  TraceabilityInformationURI* getTraceabilityInformationURI() {return mpTraceabilityInformationURI;}
  QStatusBar* getStatusBar() {return mpStatusBar;}
  QProgressBar* getProgressBar() {return mpProgressBar;}
  void showProgressBar() {mpProgressBar->setVisible(true);}
  void hideProgressBar() {mpProgressBar->setVisible(false);}
  Label* getPositionLabel() {return mpPositionLabel;}
  QTabBar* getPerspectiveTabBar() {return mpPerspectiveTabbar;}
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
  QAction* getCloseAllWindowsAction() {return mpCloseAllWindowsAction;}
  QAction* getCloseAllWindowsButThisAction() {return mpCloseAllWindowsButThisAction;}
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
  QAction* getExportEncryptedPackageAction() {return mpExportEncryptedPackageAction;}
  QAction* getExportRealonlyPackageAction() {return mpExportReadonlyPackageAction;}
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
  QAction* getTransitionModeAction() {return mpTransitionModeAction;}
  QAction* getReSimulateModelAction() {return mpReSimulateModelAction;}
  QAction* getReSimulateSetupAction() {return mpReSimulateSetupAction;}
  QAction* getSimulationParamsAction() {return mpSimulationParamsAction;}
  QAction* getFetchInterfaceDataAction() {return mpFetchInterfaceDataAction;}
  QAction* getAlignInterfacesAction() {return mpAlignInterfacesAction;}
  QAction* getTLMSimulationAction() {return mpTLMCoSimulationAction;}
  QAction* getAddSystemAction() {return mpAddSystemAction;}
  QAction* getAddOrEditIconAction() {return mpAddOrEditIconAction;}
  QAction* getDeleteIconAction() {return mpDeleteIconAction;}
  QAction* getAddConnectorAction() {return mpAddConnectorAction;}
  QAction* getAddBusAction() {return mpAddBusAction;}
  QAction* getAddTLMBusAction() {return mpAddTLMBusAction;}
  QAction* getAddSubModelAction() {return mpAddSubModelAction;}
  QAction* getOMSInstantiateModelAction() {return mpOMSInstantiateModelAction;}
  QAction* getOMSSimulationSetupAction() {return mpOMSSimulateAction;}
  QAction* getLogCurrentFileAction() {return mpLogCurrentFileAction;}
  QAction* getStageCurrentFileForCommitAction() {return mpStageCurrentFileForCommitAction;}
  QAction* getUnstageCurrentFileFromCommitAction() {return mpUnstageCurrentFileFromCommitAction;}
  QAction* getCommitFilesAction() {return mpCommitFilesAction;}
  QAction* getRevertCommitAction() {return mpRevertCommitAction;}
  QAction* getCleanWorkingDirectoryAction() {return mpCleanWorkingDirectoryAction;}
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
  void instantiateOMSModel(LibraryTreeItem *pLibraryTreeItem, bool checked);
  void simulateOMSModel(LibraryTreeItem *pLibraryTreeItem);
  void instantiateModel(LibraryTreeItem *pLibraryTreeItem);
  void checkModel(LibraryTreeItem *pLibraryTreeItem);
  void checkAllModels(LibraryTreeItem *pLibraryTreeItem);
  void exportModelFMU(LibraryTreeItem *pLibraryTreeItem);
  void exportEncryptedPackage(LibraryTreeItem *pLibraryTreeItem);
  void exportReadonlyPackage(LibraryTreeItem *pLibraryTreeItem);
  void exportModelXML(LibraryTreeItem *pLibraryTreeItem);
  void exportModelFigaro(LibraryTreeItem *pLibraryTreeItem);
  void fetchInterfaceData(LibraryTreeItem *pLibraryTreeItem, QString singleModel=QString());
  void TLMSimulate(LibraryTreeItem *pLibraryTreeItem);
  void exportModelToOMNotebook(LibraryTreeItem *pLibraryTreeItem);
  void createOMNotebookTitleCell(LibraryTreeItem *pLibraryTreeItem, QDomDocument xmlDocument, QDomElement domElement);
  void createOMNotebookImageCell(LibraryTreeItem *pLibraryTreeItem, QDomDocument xmlDocument, QDomElement domElement, QString filePath);
  void createOMNotebookCodeCell(LibraryTreeItem *pLibraryTreeItem, QDomDocument xmlDocument, QDomElement domElement);
  TransformationsWidget* showTransformationsWidget(QString fileName);
  void findFileAndGoToLine(QString fileName, QString lineNumber);
  void printStandardOutAndErrorFilesMessages();
  static void PlotCallbackFunction(void *p, int externalWindow, const char* filename, const char* title, const char* grid,
                                   const char* plotType, const char* logX, const char* logY, const char* xLabel, const char* yLabel,
                                   const char* x1, const char* x2, const char* y1, const char* y2, const char* curveWidth,
                                   const char* curveStyle, const char* legendPosition, const char* footer, const char* autoScale,
                                   const char* variables);

  QList<QString> mFMUDirectoriesList;
private:
  bool mDebug;
  OMCProxy *mpOMCProxy;
  bool mExitApplicationStatus;
  int mNumberOfProcessors;
  SearchWidget *mpSearchWidget;
  QDockWidget *mpSearchDockWidget;
  QDockWidget *mpMessagesDockWidget;
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
  PlotWindowContainer *mpPlotWindowContainer;
  VariablesWidget *mpVariablesWidget;
  QDockWidget *mpVariablesDockWidget;
  TraceabilityGraphViewWidget *mpTraceabilityGraphViewWidget;
#if !defined(WITHOUT_OSG)
  ThreeDViewer *mpThreeDViewer;
  QDockWidget *mpThreeDViewerDockWidget;
#endif
  SimulationDialog *mpSimulationDialog;
  TLMCoSimulationDialog *mpTLMCoSimulationDialog;
  OMSSimulationDialog *mpOMSSimulationDialog;
  ModelWidgetContainer *mpModelWidgetContainer;
  WelcomePageWidget *mpWelcomePageWidget;
  GitCommands *mpGitCommands;
  CommitChangesDialog *mpCommitChangesDialog;
  TraceabilityInformationURI *mpTraceabilityInformationURI;
  QStackedWidget *mpCentralStackedWidget;
  QProgressBar *mpProgressBar;
  Label *mpPositionLabel;
  QTabBar *mpPerspectiveTabbar;
  QStatusBar *mpStatusBar;
  QTimer *mpAutoSaveTimer;
  QShortcut *mpSearchBrowserShortcut;
  // File Menu
  // Modelica File Actions
  QAction *mpNewModelicaClassAction;
  QAction *mpOpenModelicaFileAction;
  QAction *mpOpenModelicaFileWithEncodingAction;
  QAction *mpLoadModelicaLibraryAction;
  QAction *mpLoadEncryptedLibraryAction;
  QAction *mpOpenResultFileAction;
  QAction *mpOpenTransformationFileAction;
  // CompositeModel File Actions
  QAction *mpNewCompositeModelFileAction;
  QAction *mpOpenCompositeModelFileAction;
  QAction *mpLoadExternModelAction;
  // OMSimulator File Actions
  QAction *mpNewOMSimulatorModelAction;
  QAction *mpOpenOMSModelFileAction;
  QAction *mpOpenDirectoryAction;
  QAction *mpSaveAction;
  QAction *mpSaveAsAction;
  QAction *mpSaveAllAction;
  QAction *mpSaveTotalAction;
  QAction *mpImportFMUAction;
  QAction *mpImportFMUModelDescriptionAction;
  QAction *mpImportFromOMNotebookAction;
  QAction *mpImportNgspiceNetlistAction;
  QAction *mpExportToClipboardAction;
  QAction *mpExportAsImageAction;
  QAction *mpExportFMUAction;
  QAction *mpExportReadonlyPackageAction;
  QAction *mpExportEncryptedPackageAction;
  QAction *mpExportXMLAction;
  QAction *mpExportFigaroAction;
  QAction *mpExportToOMNotebookAction;
  QAction *mpRecentFileActions[MaxRecentFiles];
  QAction *mpClearRecentFilesAction;
  QAction *mpPrintModelAction;
  QAction *mpQuitAction;
  // Edit Menu
  QAction *mpUndoAction;
  QAction *mpRedoAction;
  QAction *mpFilterClassesAction;
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
  QAction *mpToggleTabOrSubWindowView;
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
  // Debug Menu
  QAction *mpDebugConfigurationsAction;
  QAction *mpAttachDebuggerToRunningProcessAction;
  // Git Menu
  QAction *mpCreateGitRepositoryAction;
  QAction *mpLogCurrentFileAction;
  QAction *mpStageCurrentFileForCommitAction;
  QAction *mpUnstageCurrentFileFromCommitAction;
  QAction *mpCommitFilesAction;
  QAction *mpRevertCommitAction;
  QAction *mpCleanWorkingDirectoryAction;
  // Tools Menu
  QAction *mpShowOMCLoggerWidgetAction;
  QAction *mpShowOpenModelicaCommandPromptAction;
  QAction *mpShowOMCDiffWidgetAction;
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
  QAction *mpOMSimulatorUsersGuideAction;
  QAction *mpOpenModelicaTLMSimulatorDocumentationAction;
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
  QAction *mpTransitionModeAction;
  // Model Switcher Toolbar Actions
  QAction *mpModelSwitcherActions[MaxRecentFiles];
  // Plot Toolbar Actions
  QAction *mpReSimulateModelAction;
  QAction *mpReSimulateSetupAction;
  QAction *mpNewPlotWindowAction;
  QAction *mpNewParametricPlotWindowAction;
  QAction *mpNewArrayPlotWindowAction;
  QAction *mpNewArrayParametricPlotWindowAction;
#if !defined(WITHOUT_OSG)
  QAction *mpNewAnimationWindowAction;
#endif
  QAction *mpDiagramWindowAction;
  QAction *mpClearPlotWindowAction;
  QAction *mpExportVariablesAction;
  // TLM Simulation Action
  QAction *mpSimulationParamsAction;
  QAction *mpFetchInterfaceDataAction;
  QAction *mpAlignInterfacesAction;
  QAction *mpTLMCoSimulationAction;
  // OMSimulator Actions
  QAction *mpAddSystemAction;
  QAction *mpAddOrEditIconAction;
  QAction *mpDeleteIconAction;
  QAction *mpAddConnectorAction;
  QAction *mpAddBusAction;
  QAction *mpAddTLMBusAction;
  QAction *mpAddSubModelAction;
  QAction *mpOMSInstantiateModelAction;
  QAction *mpOMSSimulateAction;
  QAction *mpOMSArchivedSimulationsAction;
  // Toolbars
  QMenu *mpRecentFilesMenu;
  QMenu *mpLibrariesMenu;
  QToolBar *mpFileToolBar;
  QToolBar *mpEditToolBar;
  QToolBar *mpViewToolBar;
  QToolBar *mpShapesToolBar;
  QToolBar *mpModelSwitcherToolBar;
  QMenu *mpModelSwitcherMenu;
  QToolButton *mpModelSwitcherToolButton;
  QToolBar *mpCheckToolBar;
  QToolBar *mpSimulationToolBar;
  QToolBar *mpReSimulationToolBar;
  QToolBar *mpPlotToolBar;
  QToolBar *mpDebuggerToolBar;
  QMenu *mpDebugConfigurationMenu;
  QToolButton *mpDebugConfigurationToolButton;
  QToolBar *mpTLMSimulationToolbar;
  QToolBar *mpOMSimulatorToobar;
  QHash<QString, TransformationsWidget*> mTransformationsWidgetHash;
public slots:
  void showMessagesBrowser();
  void showSearchBrowser();
  void createNewModelicaClass();
  void openModelicaFile();
  void showOpenModelicaFileDialog();
  void loadModelicaLibrary();
  void loadEncryptedLibrary();
  void showOpenResultFileDialog();
  void showOpenTransformationFileDialog();
  void createNewCompositeModelFile();
  void openCompositeModelFile();
  void loadExternalModels();
  void createNewOMSModel();
  void openOMSModelFile();
  void openDirectory();
  void loadSystemLibrary();
  void writeOutputFileData(QString data);
  void writeErrorFileData(QString data);
  void openRecentFile();
  void clearRecentFilesList();
  void undo();
  void redo();
  void focusFilterClasses();
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
  void toggleTabOrSubWindowView();
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
  void importFMUModelDescription();
  void exportEncryptedPackage();
  void exportReadonlyPackage();
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
  void instantiateOMSModel(bool checked);
  void simulateOMSModel();
  void showOMSArchivedSimulations();
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
  void openOMSimulatorUsersGuide();
  void openOpenModelicaTLMSimulatorDocumentation();
  void openAboutOMEdit();
  void toggleShapesButton();
  void openRecentModelWidget();
  void updateModelSwitcherMenu(QMdiSubWindow *pSubWindow);
  void runDebugConfiguration();
  void updateDebuggerToolBarMenu();
  void toggleAutoSave();
  void readInterfaceData(LibraryTreeItem *pLibraryTreeItem);
  void enableReSimulationToolbar(bool visible);
private slots:
  void perspectiveTabChanged(int tabIndex);
  void documentationDockWidgetVisibilityChanged(bool visible);
  void threeDViewerDockWidgetVisibilityChanged(bool visible);
  void autoSave();
  void switchToWelcomePerspectiveSlot();
  void switchToModelingPerspectiveSlot();
  void switchToPlottingPerspectiveSlot();
  void switchToAlgorithmicDebuggingPerspectiveSlot();
  void showDebugConfigurationsDialog();
  void showAttachToProcessDialog();
  void createGitRepository();
  void logCurrentFile();
  void stageCurrentFileForCommit();
  void unstageCurrentFileFromCommit();
  void commitFiles();
  void revertCommit();
  void cleanWorkingDirectory();
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
  void fetchInterfaceDataHelper(LibraryTreeItem *pLibraryTreeItem, QString singleModel=QString());
protected:
  virtual void dragEnterEvent(QDragEnterEvent *event);
  virtual void dragMoveEvent(QDragMoveEvent *event);
  virtual void dropEvent(QDropEvent *event);
};

class AboutOMEditDialog : public QDialog
{
  Q_OBJECT
public:
  AboutOMEditDialog(MainWindow *pMainWindow);
};

#endif // MAINWINDOW_H
