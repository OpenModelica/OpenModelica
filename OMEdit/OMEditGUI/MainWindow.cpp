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

#include "MainWindow.h"
/* Keep PlotWindowContainer on top to include OSG first */
#include "Plotting/PlotWindowContainer.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Options/OptionsDialog.h"
#include "Modeling/MessagesWidget.h"
#include "OMS/OMSProxy.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelicaClassDialog.h"
#include "OMS/ModelDialog.h"
#include "Debugger/GDB/GDBAdapter.h"
#include "Debugger/StackFrames/StackFramesWidget.h"
#include "Debugger/Locals/LocalsWidget.h"
#include "Modeling/DocumentationWidget.h"
#include "Plotting/VariablesWidget.h"
#include "Search/SearchWidget.h"
#if !defined(WITHOUT_OSG)
#include "Animation/ThreeDViewer.h"
#include "Animation/ViewerWidget.h"
#endif
#include "Util/Helper.h"
#include "Simulation/SimulationOutputWidget.h"
#include "TLM/FetchInterfaceDataDialog.h"
#include "TLM/TLMCoSimulationOutputWidget.h"
#include "OMS/OMSSimulationDialog.h"
#include "Debugger/DebuggerConfigurationsDialog.h"
#include "Debugger/Attach/AttachToProcessDialog.h"
#include "TransformationalDebugger/TransformationsWidget.h"
#include "Options/NotificationsDialog.h"
#include "Simulation/SimulationDialog.h"
#include "TLM/TLMCoSimulationDialog.h"
#include "FMI/ImportFMUDialog.h"
#include "OMS/InstantiateDialog.h"
#include "FMI/ImportFMUModelDescriptionDialog.h"
#include "Git/CommitChangesDialog.h"
#include "Git/RevertCommitsDialog.h"
#include "Git/CleanDialog.h"
#include "Git/GitCommands.h"
#include "Traceability/TraceabilityInformationURI.h"
#include "Traceability/TraceabilityGraphViewWidget.h"
#include "Plotting/DiagramWindow.h"
#include "omc_config.h"

#include <QtSvg/QSvgGenerator>

MainWindow::MainWindow(bool debug, QWidget *parent)
  : QMainWindow(parent), mDebug(debug), mExitApplicationStatus(false)
{
  // This is a very convoluted way of asking for the default system font in Qt
  QFont systmFont("Monospace");
  systmFont.setStyleHint(QFont::System);
  Helper::systemFontInfo = QFontInfo(systmFont);
  // This is a very convoluted way of asking for the default monospace font in Qt
  QFont monospaceFont("Monospace");
  monospaceFont.setStyleHint(QFont::TypeWriter);
  Helper::monospacedFontInfo = QFontInfo(monospaceFont);
  /*! @note Register the RecentFile, FindTextOM and DebuggerConfiguration struct in the Qt's meta system
   * Don't remove/move the following lines.
   * Because RecentFile, FindTextOM and DebuggerConfiguration structs should be registered before reading the recentFilesList, FindTextOM and
   * DebuggerConfiguration section respectively from the settings file.
   */
  qRegisterMetaTypeStreamOperators<RecentFile>("RecentFile");
  qRegisterMetaTypeStreamOperators<FindTextOM>("FindTextOM");
  qRegisterMetaTypeStreamOperators<DebuggerConfiguration>("DebuggerConfiguration");
  /*! @note The above three lines registers the structs as QMetaObjects. Do not remove/move them. */
  setObjectName("MainWindow");
  setWindowTitle(Helper::applicationName + " - "  + Helper::applicationIntroText);
  setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
  setMinimumSize(400, 300);
  resize(800, 600);
  setContentsMargins(1, 1, 1, 1);
}

MainWindow *MainWindow::mpInstance = 0;

/*!
 * \brief MainWindow::instance
 * Creates an instance of MainWindow. If we already have an instance then just return it.
 * \param debug
 * \return
 */
MainWindow *MainWindow::instance(bool debug)
{
  if (!mpInstance) {
    mpInstance = new MainWindow(debug);
  }
  return mpInstance;
}

/*!
 * \brief MainWindow::setUpMainWindow
 * Creates all the GUI widgets.
 * \param threadData
 */
void MainWindow::setUpMainWindow(threadData_t *threadData)
{
  // Reopen the standard output stream.
  QString outputFileName = Utilities::tempDirectory() + "/omeditoutput.txt";
  freopen(outputFileName.toStdString().c_str(), "w", stdout);
  setbuf(stdout, NULL); // used non-buffered stdout
  // Reopen the standard error stream.
  QString errorFileName = Utilities::tempDirectory() + "/omediterror.txt";
  freopen(errorFileName.toStdString().c_str(), "w", stderr);
  setbuf(stderr, NULL); // used non-buffered stderr
  SplashScreen::instance()->showMessage(tr("Initializing"), Qt::AlignRight, Qt::white);
  // Create an object of MessagesWidget.
  MessagesWidget::create();
  // Create MessagesDockWidget dock
  mpMessagesDockWidget = new QDockWidget(tr("Messages Browser"), this);
  mpMessagesDockWidget->setObjectName("Messages");
  mpMessagesDockWidget->setAllowedAreas(Qt::TopDockWidgetArea | Qt::BottomDockWidgetArea);
  mpMessagesDockWidget->setWidget(MessagesWidget::instance());
  addDockWidget(Qt::BottomDockWidgetArea, mpMessagesDockWidget);
  mpMessagesDockWidget->hide();
  connect(MessagesWidget::instance(), SIGNAL(MessageAdded()), SLOT(showMessagesBrowser()));
  // Create the OMCProxy object.
  mpOMCProxy = new OMCProxy(threadData, this);
  if (getExitApplicationStatus()) {
    return;
  }
  SplashScreen::instance()->showMessage(tr("Reading Settings"), Qt::AlignRight, Qt::white);
  // Get the number of processors.
  mNumberOfProcessors = mpOMCProxy->numProcessors();
  // create an object of OMSProxy
  OMSProxy::create();
  // Create an object of OptionsDialog
  OptionsDialog::create();
  SplashScreen::instance()->showMessage(tr("Loading Widgets"), Qt::AlignRight, Qt::white);
  // apply MessagesWidget settings
  MessagesWidget::instance()->applyMessagesSettings();
  // Create an object of QProgressBar
  mpProgressBar = new QProgressBar;
  mpProgressBar->setMaximumWidth(300);
  mpProgressBar->setTextVisible(false);
  mpProgressBar->setVisible(false);
  // Position Label
  mpPositionLabel = new Label;
  mpPositionLabel->setMinimumWidth(75);
  // create the perspective tabs
  mpPerspectiveTabbar = new QTabBar;
  mpPerspectiveTabbar->setDocumentMode(true);
  mpPerspectiveTabbar->setShape(QTabBar::RoundedSouth);
  // welcome perspective
  mpPerspectiveTabbar->addTab(QIcon(":/Resources/icons/omedit.png"), tr("Welcome"));
  QShortcut *pWelcomeShortcut = new QShortcut(QKeySequence("Ctrl+f1"), this);
  connect(pWelcomeShortcut, SIGNAL(activated()), SLOT(switchToWelcomePerspectiveSlot()));
  mpPerspectiveTabbar->setTabToolTip(0, tr("Changes to welcome perspective (%1)").arg(pWelcomeShortcut->key().toString()));
  // modeling perspective
  mpPerspectiveTabbar->addTab(QIcon(":/Resources/icons/modeling.png"), tr("Modeling"));
  QShortcut *pModelingShortcut = new QShortcut(QKeySequence("Ctrl+f2"), this);
  connect(pModelingShortcut, SIGNAL(activated()), SLOT(switchToModelingPerspectiveSlot()));
  mpPerspectiveTabbar->setTabToolTip(1, tr("Changes to modeling perspective (%1)").arg(pModelingShortcut->key().toString()));
  // plotting perspective
  mpPerspectiveTabbar->addTab(QIcon(":/Resources/icons/omplot.png"), tr("Plotting"));
  QShortcut *pPlottingShortcut = new QShortcut(QKeySequence("Ctrl+f3"), this);
  connect(pPlottingShortcut, SIGNAL(activated()), SLOT(switchToPlottingPerspectiveSlot()));
  mpPerspectiveTabbar->setTabToolTip(2, tr("Changes to plotting perspective (%1)").arg(pPlottingShortcut->key().toString()));
  // algorithmic debugging perspective
  mpPerspectiveTabbar->addTab(QIcon(":/Resources/icons/debugger.svg"), tr("Debugging"));
  QShortcut *pAlgorithmicDebuggingShortcut = new QShortcut(QKeySequence("Ctrl+f5"), this);
  connect(pAlgorithmicDebuggingShortcut, SIGNAL(activated()), SLOT(switchToAlgorithmicDebuggingPerspectiveSlot()));
  mpPerspectiveTabbar->setTabToolTip(3, tr("Changes to debugging perspective (%1)").arg(pAlgorithmicDebuggingShortcut->key().toString()));
  // change the perspective when perspective tab bar selection is changed
  connect(mpPerspectiveTabbar, SIGNAL(currentChanged(int)), SLOT(perspectiveTabChanged(int)));
  // Create an object of QStatusBar
  mpStatusBar = new QStatusBar();
  mpStatusBar->setObjectName("statusBar");
  mpStatusBar->setContentsMargins(0, 0, 0, 0);
  // add items to statusbar
  mpStatusBar->addPermanentWidget(mpProgressBar);
  mpStatusBar->addPermanentWidget(mpPositionLabel);
  mpStatusBar->addPermanentWidget(mpPerspectiveTabbar);
  // set status bar for MainWindow
  setStatusBar(mpStatusBar);
  // Create an object of LibraryWidget
  mpLibraryWidget = new LibraryWidget(this);
  // Create LibraryDockWidget
  mpLibraryDockWidget = new QDockWidget(tr("Libraries Browser"), this);
  //mpLibraryDockWidget->setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::MinimumExpanding);
  mpLibraryDockWidget->setObjectName("Libraries");
  mpLibraryDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpLibraryDockWidget->setWidget(mpLibraryWidget);
  addDockWidget(Qt::LeftDockWidgetArea, mpLibraryDockWidget);
  mpLibraryWidget->getLibraryTreeView()->setFocus(Qt::ActiveWindowFocusReason);
  // Create an object of SearchWidget
  mpSearchWidget = new SearchWidget(this);
  mpSearchDockWidget = new QDockWidget(tr("Search Browser"),this);
  mpSearchDockWidget->setObjectName("Search");
  mpSearchDockWidget->setAllowedAreas(Qt::BottomDockWidgetArea | Qt::TopDockWidgetArea);
  mpSearchDockWidget->setWidget(mpSearchWidget);
  addDockWidget(Qt::BottomDockWidgetArea, mpSearchDockWidget);
  mpSearchDockWidget->hide();
  // create the GDB adapter instance
  GDBAdapter::create();
  // create stack frames widget
  mpStackFramesWidget = new StackFramesWidget(this);
  // Create stack frames dock widget
  mpStackFramesDockWidget = new QDockWidget(tr("Stack Frames Browser"), this);
  mpStackFramesDockWidget->setObjectName("StackFrames");
  mpStackFramesDockWidget->setWidget(mpStackFramesWidget);
  addDockWidget(Qt::TopDockWidgetArea, mpStackFramesDockWidget);
  // create breakpoints widget
  mpBreakpointsWidget = new BreakpointsWidget(this);
  // Create breakpoints dock widget
  mpBreakpointsDockWidget = new QDockWidget(tr("BreakPoints Browser"), this);
  mpBreakpointsDockWidget->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Maximum);
  mpBreakpointsDockWidget->setObjectName("BreakPoints");
  mpBreakpointsDockWidget->setWidget(mpBreakpointsWidget);
  addDockWidget(Qt::TopDockWidgetArea, mpBreakpointsDockWidget);
  // create locals widget
  mpLocalsWidget = new LocalsWidget(this);
  // Create locals dock widget
  mpLocalsDockWidget = new QDockWidget(tr("Locals Browser"), this);
  mpLocalsDockWidget->setObjectName("Locals");
  mpLocalsDockWidget->setWidget(mpLocalsWidget);
  addDockWidget(Qt::RightDockWidgetArea, mpLocalsDockWidget);
  // Create target output widget
  mpTargetOutputWidget = new TargetOutputWidget(this);
  // Create GDB console dock widget
  mpTargetOutputDockWidget = new QDockWidget(tr("Output Browser"), this);
  mpTargetOutputDockWidget->setObjectName("OutputBrowser");
  mpTargetOutputDockWidget->setWidget(mpTargetOutputWidget);
  addDockWidget(Qt::BottomDockWidgetArea, mpTargetOutputDockWidget);
  // Create GDB console widget
  mpGDBLoggerWidget = new GDBLoggerWidget(this);
  // Create GDB console dock widget
  mpGDBLoggerDockWidget = new QDockWidget(tr("Debugger CLI"), this);
  mpGDBLoggerDockWidget->setObjectName("DebuggerLog");
  mpGDBLoggerDockWidget->setWidget(mpGDBLoggerWidget);
  addDockWidget(Qt::BottomDockWidgetArea, mpGDBLoggerDockWidget);
  // put the GDB logger dock widget and output dock widget as tabbed items.
  tabifyDockWidget(mpGDBLoggerDockWidget, mpTargetOutputDockWidget);
  // create an object of DocumentationWidget
  mpDocumentationWidget = new DocumentationWidget(this);
  // Create DocumentationWidget dock
  mpDocumentationDockWidget = new QDockWidget(tr("Documentation Browser"), this);
  mpDocumentationDockWidget->setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::MinimumExpanding);
  mpDocumentationDockWidget->setObjectName("Documentation");
  mpDocumentationDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpDocumentationDockWidget->setWidget(mpDocumentationWidget);
  addDockWidget(Qt::RightDockWidgetArea, mpDocumentationDockWidget);
  mpDocumentationDockWidget->hide();
  connect(mpDocumentationDockWidget, SIGNAL(visibilityChanged(bool)), SLOT(documentationDockWidgetVisibilityChanged(bool)));
  // Create an object of PlotWindowContainer
  mpPlotWindowContainer = new PlotWindowContainer(this);
  // create an object of VariablesWidget
  mpVariablesWidget = new VariablesWidget(this);
  // Create VariablesWidget dock
  mpVariablesDockWidget = new QDockWidget(Helper::variablesBrowser, this);
  mpVariablesDockWidget->setObjectName("Variables");
  mpVariablesDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  addDockWidget(Qt::RightDockWidgetArea, mpVariablesDockWidget);
  mpVariablesDockWidget->setWidget(mpVariablesWidget);
  // create traceability graph view widget
  //  mpTraceabilityGraphViewWidget = new TraceabilityGraphViewWidget(this);
  mpTraceabilityInformationURI = new TraceabilityInformationURI(this);
#if !defined(WITHOUT_OSG)
  /* Ticket #4252
   * Do not create an object of ThreeDViewer by default.
   * Only create it when user really use it.
   */
  mpThreeDViewer = 0;
  // Create ThreeDViewer dock
  mpThreeDViewerDockWidget = new QDockWidget(tr("3D Viewer Browser"), this);
  mpThreeDViewerDockWidget->setObjectName("3DViewer");
  mpThreeDViewerDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  addDockWidget(Qt::RightDockWidgetArea, mpThreeDViewerDockWidget);
  mpThreeDViewerDockWidget->hide();
  connect(mpThreeDViewerDockWidget, SIGNAL(visibilityChanged(bool)), SLOT(threeDViewerDockWidgetVisibilityChanged(bool)));
#endif
  // set the corners for the dock widgets
  setCorner(Qt::TopLeftCorner, Qt::LeftDockWidgetArea);
  setCorner(Qt::BottomLeftCorner, Qt::LeftDockWidgetArea);
  setCorner(Qt::TopRightCorner, Qt::RightDockWidgetArea);
  setCorner(Qt::BottomRightCorner, Qt::RightDockWidgetArea);
  //Create Actions, Toolbar and Menus
  SplashScreen::instance()->showMessage(tr("Creating Widgets"), Qt::AlignRight, Qt::white);
  setAcceptDrops(true);
  createActions();
  createToolbars();
  createMenus();
  // enable/disable re-simulation toolbar based on variables browser visibiltiy.
  connect(mpVariablesDockWidget, SIGNAL(visibilityChanged(bool)), this, SLOT(enableReSimulationToolbar(bool)));
  // Create simulation dialog when needed
  mpSimulationDialog = 0;
  // Create TLM co-simulation dialog when needed
  mpTLMCoSimulationDialog = 0;
  // Create the OMSimulator simulation dialog when needed
  mpOMSSimulationDialog = 0;
  // Create an object of ModelWidgetContainer
  mpModelWidgetContainer = new ModelWidgetContainer(this);
  // Create an object of WelcomePageWidget
  mpWelcomePageWidget = new WelcomePageWidget(this);
  updateRecentFileActions();
  // create the Git commands instance
  //mpGitCommands = new GitCommands(this);
  GitCommands::create();
  //Create a centralwidget for the main window
  QWidget *pCentralwidget = new QWidget;
  mpCentralStackedWidget = new QStackedWidget;
  mpCentralStackedWidget->addWidget(mpWelcomePageWidget);
  mpCentralStackedWidget->addWidget(mpModelWidgetContainer);
  mpCentralStackedWidget->addWidget(mpPlotWindowContainer);
  // set the layout
  QGridLayout *pCentralgrid = new QGridLayout;
  pCentralgrid->setVerticalSpacing(4);
  pCentralgrid->setContentsMargins(0, 1, 0, 0);
  pCentralgrid->addWidget(mpCentralStackedWidget, 0, 0);
  pCentralwidget->setLayout(pCentralgrid);
  //Set the centralwidget
  setCentralWidget(pCentralwidget);
  // Load and add user defined Modelica libraries into the Library Widget.
  mpLibraryWidget->getLibraryTreeModel()->addModelicaLibraries();
  // set command line options
  if (OptionsDialog::instance()->getDebuggerPage()->getGenerateOperationsCheckBox()->isChecked()) {
    mpOMCProxy->setCommandLineOptions("-d=infoXmlOperations");
  }
  OptionsDialog::instance()->saveSimulationSettings();
    // restore OMEdit widgets state
  QSettings *pSettings = Utilities::getApplicationSettings();
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()) {
    restoreGeometry(pSettings->value("application/geometry").toByteArray());
    bool restoreMessagesWidget = !MessagesWidget::instance()->getAllMessageWidget()->getMessagesTextBrowser()->toPlainText().isEmpty();
    restoreState(pSettings->value("application/windowState").toByteArray());
    pSettings->beginGroup("algorithmicDebugger");
    /* restore stackframes list and locals columns width */
    mpStackFramesWidget->getStackFramesTreeWidget()->header()->restoreState(pSettings->value("stackFramesTreeState").toByteArray());
    mpBreakpointsWidget->getBreakpointsTreeView()->header()->restoreState(pSettings->value("breakPointsTreeState").toByteArray());
    mpLocalsWidget->getLocalsTreeView()->header()->restoreState(pSettings->value("localsTreeState").toByteArray());
    pSettings->endGroup();
    if (restoreMessagesWidget) {
      showMessagesBrowser();
    }
  }
  switchToWelcomePerspective();
  // read last Open Directory location
  if (pSettings->contains("lastOpenDirectory")) {
    StringHandler::setLastOpenDirectory(pSettings->value("lastOpenDirectory").toString());
  }
  // read the grid lines
  if (pSettings->contains("modeling/gridLines")) {
    mpShowGridLinesAction->setChecked(pSettings->value("modeling/gridLines").toBool());
  }
  // create the auto save timer
  mpAutoSaveTimer = new QTimer(this);
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
  mpAutoSaveTimer->setTimerType(Qt::PreciseTimer);
#endif
  mpAutoSaveTimer->setInterval(OptionsDialog::instance()->getGeneralSettingsPage()->getAutoSaveIntervalSpinBox()->value() * 1000);
  connect(mpAutoSaveTimer, SIGNAL(timeout()), SLOT(autoSave()));
  // read auto save settings
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getEnableAutoSaveGroupBox()->isChecked()) {
    mpAutoSaveTimer->start();
  }
}

#if !defined(WITHOUT_OSG)
/*!
 * \brief MainWindow::isThreeDViewerInitialized
 * Returns true if ThreeDViewer is initialized.
 * \return
 */
bool MainWindow::isThreeDViewerInitialized()
{
  return mpThreeDViewer ? true : false;
}

/*!
 * \brief MainWindow::getThreeDViewer
 * Returns the ThreeDViewer object. Initializes it if its not initialized.
 * \return
 */
ThreeDViewer* MainWindow::getThreeDViewer()
{
  // create an object of ThreeDViewer
  if (!mpThreeDViewer) {
    mpThreeDViewer = new ThreeDViewer(this);
    mpThreeDViewerDockWidget->setWidget(mpThreeDViewer);
  }
  return mpThreeDViewer;
}
#endif

/*!
 * \brief MainWindow::addRecentFile
 * Adds the currently opened file to the recentFilesList settings.
 * \param fileName
 * \param encoding
 */
void MainWindow::addRecentFile(const QString &fileName, const QString &encoding)
{
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> files = pSettings->value("recentFilesList/files").toList();
  // remove the already present RecentFile instance from the list.
  foreach (QVariant file, files)
  {
    RecentFile recentFile = qvariant_cast<RecentFile>(file);
    QFileInfo file1(recentFile.fileName);
    QFileInfo file2(fileName);
    if (file1.absoluteFilePath().compare(file2.absoluteFilePath()) == 0)
      files.removeOne(file);
  }
  RecentFile recentFile;
  recentFile.fileName = fileName;
  recentFile.encoding = encoding;
  files.prepend(QVariant::fromValue(recentFile));
  while (files.size() > MaxRecentFiles)
    files.removeLast();
  pSettings->setValue("recentFilesList/files", files);
  updateRecentFileActions();
}

/*!
 * \brief MainWindow::updateRecentFileActions
 * Updates the actions of the recent files menu items.
 */
void MainWindow::updateRecentFileActions()
{
  /* first set all recent files actions visibility to false. */
  for (int i = 0; i < MaxRecentFiles; ++i)
    mpRecentFileActions[i]->setVisible(false);
  /* read the new recent files list */
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> files = pSettings->value("recentFilesList/files").toList();
  int numRecentFiles = qMin(files.size(), (int)MaxRecentFiles);
  for (int i = 0; i < numRecentFiles; ++i)
  {
    RecentFile recentFile = qvariant_cast<RecentFile>(files[i]);
    mpRecentFileActions[i]->setText(recentFile.fileName);
    QStringList dataList;
    dataList << recentFile.fileName << recentFile.encoding;
    mpRecentFileActions[i]->setData(dataList);
    mpRecentFileActions[i]->setVisible(true);
  }
  mpWelcomePageWidget->addRecentFilesListItems();
}

/*!
 * \brief MainWindow::closeEvent
 * Event triggered re-implemented method that closes the main window.
 * Proposes the user to save the unsaved classes.
 * Asks for quit depending on the settings value.
 * \param event
 */
void MainWindow::closeEvent(QCloseEvent *event)
{
  SaveChangesDialog *pSaveChangesDialog = new SaveChangesDialog(this);
  if (pSaveChangesDialog->exec()) {
    if (askForExit()) {
      beforeClosingMainWindow();
      event->accept();
    } else {
      event->ignore();
    }
  } else {
    event->ignore();
  }
}

/*!
 * \brief MainWindow::askForExit
 * Asks the user before exiting.
 * \return
 */
int MainWindow::askForExit()
{
  if (!OptionsDialog::instance()->getNotificationsPage()->getQuitApplicationCheckBox()->isChecked()) {
    NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::QuitApplication,
                                                                        NotificationsDialog::QuestionIcon, this);
    return pNotificationsDialog->exec();
  }
  return true;
}

/*!
 * \brief MainWindow::beforeClosingMainWindow
 * Called before closing the MainWindow
 * Deletes the object.
 * Saves the window state and geometry in the settings file.
 */
void MainWindow::beforeClosingMainWindow()
{
  mpOMCProxy->quitOMC();
  delete mpOMCProxy;
  // Unload the OMSimulator models
  LibraryTreeItem* pLibraryTreeItem = mpLibraryWidget->getLibraryTreeModel()->getRootLibraryTreeItem();
  for (int i = 0; i < pLibraryTreeItem->childrenSize(); i++) {
    LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
    if (pChildLibraryTreeItem && pChildLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS) {
      mpLibraryWidget->getLibraryTreeModel()->unloadOMSModel(pChildLibraryTreeItem, false);
    }
  }
  // delete the OMSProxy object
  OMSProxy::destroy();
  delete mpModelWidgetContainer;
  if (mpSimulationDialog) {
    delete mpSimulationDialog;
  }
  if (mpTLMCoSimulationDialog) {
    delete mpTLMCoSimulationDialog;
  }
  if (mpOMSSimulationDialog) {
    delete mpOMSSimulationDialog;
  }
  /* save the TransformationsWidget last window geometry and splitters state. */
  QSettings *pSettings = Utilities::getApplicationSettings();
  QHashIterator<QString, TransformationsWidget*> transformationsWidgets(mTransformationsWidgetHash);
  if (mTransformationsWidgetHash.size() > 0) {
    transformationsWidgets.toBack();
    transformationsWidgets.previous();
    TransformationsWidget *pTransformationsWidget = transformationsWidgets.value();
    if (pTransformationsWidget) {
      pSettings->beginGroup("transformationalDebugger");
      pSettings->setValue("geometry", pTransformationsWidget->saveGeometry());
      pSettings->setValue("variablesNestedHorizontalSplitter", pTransformationsWidget->getVariablesNestedHorizontalSplitter()->saveState());
      pSettings->setValue("variablesNestedVerticalSplitter", pTransformationsWidget->getVariablesNestedVerticalSplitter()->saveState());
      pSettings->setValue("variablesHorizontalSplitter", pTransformationsWidget->getVariablesHorizontalSplitter()->saveState());
      pSettings->setValue("equationsNestedHorizontalSplitter", pTransformationsWidget->getEquationsNestedHorizontalSplitter()->saveState());
      pSettings->setValue("equationsNestedVerticalSplitter", pTransformationsWidget->getEquationsNestedVerticalSplitter()->saveState());
      pSettings->setValue("equationsHorizontalSplitter", pTransformationsWidget->getEquationsHorizontalSplitter()->saveState());
      pSettings->setValue("transformationsVerticalSplitter", pTransformationsWidget->getTransformationsVerticalSplitter()->saveState());
      pSettings->endGroup();
    }
  }
  /* delete the TransformationsWidgets */
  transformationsWidgets.toFront();
  while (transformationsWidgets.hasNext()) {
    transformationsWidgets.next();
    TransformationsWidget *pTransformationsWidget = transformationsWidgets.value();
    delete pTransformationsWidget;
  }
  mTransformationsWidgetHash.clear();
  /* save stackframes list and locals columns width */
  pSettings->beginGroup("algorithmicDebugger");
  pSettings->setValue("stackFramesTreeState", mpStackFramesWidget->getStackFramesTreeWidget()->header()->saveState());
  pSettings->setValue("breakPointsTreeState", mpBreakpointsWidget->getBreakpointsTreeView()->header()->saveState());
  pSettings->setValue("localsTreeState", mpLocalsWidget->getLocalsTreeView()->header()->saveState());
  pSettings->endGroup();
  /* save OMEdit MainWindow geometry state */
  pSettings->setValue("application/geometry", saveGeometry());
  pSettings->setValue("application/windowState", saveState());
  // save last Open Directory location
  pSettings->setValue("lastOpenDirectory", StringHandler::getLastOpenDirectory());
  // save the grid lines
  pSettings->setValue("modeling/gridLines", mpShowGridLinesAction->isChecked());
  // save the splitter state of welcome page
  pSettings->setValue("welcomePage/splitterState", mpWelcomePageWidget->getSplitter()->saveState());
  // Delete the FMU directories we created while importing
  if (OptionsDialog::instance()->getFMIPage()->getDeleteFMUDirectoryAndModelCheckBox()->isChecked()) {
    foreach (QString fmuDirectory, mFMUDirectoriesList) {
      if (QDir().exists(fmuDirectory)) {
        Utilities::removeDirectoryRecursivly(fmuDirectory);
      }
    }
    mFMUDirectoriesList.clear();
  }
  delete pSettings;
  // delete the OptionsDialog object
  OptionsDialog::destroy();
  // delete the MessagesWidget object
  MessagesWidget::destroy();
  // delete the GDBAdapter object
  GDBAdapter::destroy();
  // delete the GitCommands object
  GitCommands::destroy();
  // delete the searchwidget object to call the destructor, to cancel the search operation running on seperate thread
  delete mpSearchWidget;
}

/*!
 * \brief MainWindow::openDroppedFile
 * Opens the dropped file.
 * \param event
 */
void MainWindow::openDroppedFile(QDropEvent *event)
{
  int progressValue = 0;
  mpProgressBar->setRange(0, event->mimeData()->urls().size());
  showProgressBar();
  //retrieves the filenames of all the dragged files in list and opens the valid files.
  foreach (QUrl fileUrl, event->mimeData()->urls()) {
    QFileInfo fileInfo(fileUrl.toLocalFile());
    // show file loading message
    mpStatusBar->showMessage(QString(Helper::loading).append(": ").append(fileInfo.absoluteFilePath()));
    mpProgressBar->setValue(++progressValue);
    // check the file extension
    QRegExp resultFilesRegExp("\\b(mat|plt|csv)\\b");
    if (resultFilesRegExp.indexIn(fileInfo.suffix()) != -1) {
      openResultFiles(QStringList(fileInfo.absoluteFilePath()));
    } else {
      mpLibraryWidget->openFile(fileInfo.absoluteFilePath(), Helper::utf8, false);
    }
  }
  mpStatusBar->clearMessage();
  hideProgressBar();
}

/*!
 * \brief MainWindow::openResultFiles
 * Opens the result file(s).
 * \param fileNames
 */
void MainWindow::openResultFiles(QStringList fileNames)
{
  foreach (QString fileName, fileNames) {
    QFileInfo fileInfo(fileName);
    QStringList list = mpOMCProxy->readSimulationResultVars(fileInfo.absoluteFilePath());
    if (list.size() > 0) {
      mpPerspectiveTabbar->setCurrentIndex(2);
      mpVariablesWidget->insertVariablesItemsToTree(fileInfo.fileName(), fileInfo.absoluteDir().absolutePath(), list, SimulationOptions());
    }
  }
}

void MainWindow::simulate(LibraryTreeItem *pLibraryTreeItem)
{
  if (!mpSimulationDialog) {
    mpSimulationDialog = new SimulationDialog(this);
  }
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  mpSimulationDialog->directSimulate(pLibraryTreeItem, false, false, false);
}

void MainWindow::simulateWithTransformationalDebugger(LibraryTreeItem *pLibraryTreeItem)
{
  if (!mpSimulationDialog) {
    mpSimulationDialog = new SimulationDialog(this);
  }
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  mpSimulationDialog->directSimulate(pLibraryTreeItem, true, false, false);
}

void MainWindow::simulateWithAlgorithmicDebugger(LibraryTreeItem *pLibraryTreeItem)
{
  if (!mpSimulationDialog) {
    mpSimulationDialog = new SimulationDialog(this);
  }
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  mpSimulationDialog->directSimulate(pLibraryTreeItem, false, true, false);
}

#if !defined(WITHOUT_OSG)
void MainWindow::simulateWithAnimation(LibraryTreeItem *pLibraryTreeItem)
{
  if (!mpSimulationDialog) {
    mpSimulationDialog = new SimulationDialog(this);
  }
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  mpSimulationDialog->directSimulate(pLibraryTreeItem, false, false, true);
}
#endif

void MainWindow::simulationSetup(LibraryTreeItem *pLibraryTreeItem)
{
  if (!mpSimulationDialog) {
    mpSimulationDialog = new SimulationDialog(this);
  }
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  mpSimulationDialog->show(pLibraryTreeItem, false, SimulationOptions());
}

/*!
 * \brief MainWindow::instantiateOMSModel
 * Instantiates the OMSimulator model.
 * \param pLibraryTreeItem
 * \param checked
 */
void MainWindow::instantiateOMSModel(LibraryTreeItem *pLibraryTreeItem, bool checked)
{
  // get the top level LibraryTreeItem
  LibraryTreeItem *pTopLevelLibraryTreeItem = mpLibraryWidget->getLibraryTreeModel()->findLibraryTreeItem(StringHandler::getFirstWordBeforeDot(pLibraryTreeItem->getNameStructure()));
  if (pTopLevelLibraryTreeItem) {
    if (checked) {
      InstantiateDialog *pInstantiateDialog = new InstantiateDialog(pTopLevelLibraryTreeItem);
      // if user cancels the instantiation
      if (!pInstantiateDialog->exec()) {
        mpOMSInstantiateModelAction->setChecked(false);
      }
    } else {
      if (!OMSProxy::instance()->terminate(pTopLevelLibraryTreeItem->getNameStructure())) {
        mpOMSInstantiateModelAction->setChecked(true);
      } else {
        mpOMSInstantiateModelAction->setText(Helper::instantiateModel);
        mpOMSInstantiateModelAction->setText(Helper::instantiateOMSModelTip);
        mpOMSSimulateAction->setEnabled(false);
        pTopLevelLibraryTreeItem->setModelState(oms_modelState_virgin);
      }
    }
  }
}

/*!
 * \brief MainWindow::simulateOMSModel
 * Simulates the OMSimulator model.
 * \param pLibraryTreeItem
 */
void MainWindow::simulateOMSModel(LibraryTreeItem *pLibraryTreeItem)
{
  // get the top level LibraryTreeItem
  LibraryTreeItem *pTopLevelLibraryTreeItem = mpLibraryWidget->getLibraryTreeModel()->findLibraryTreeItem(StringHandler::getFirstWordBeforeDot(pLibraryTreeItem->getNameStructure()));
  if (pTopLevelLibraryTreeItem) {
    if (!mpOMSSimulationDialog) {
      mpOMSSimulationDialog = new OMSSimulationDialog(this);
    }
    mpOMSSimulationDialog->simulate(pTopLevelLibraryTreeItem);
  }
}

void MainWindow::instantiateModel(LibraryTreeItem *pLibraryTreeItem)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  // set the status message.
  mpStatusBar->showMessage(QString(Helper::instantiateModel).append(" ").append(pLibraryTreeItem->getNameStructure()));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  // check reset messages number before instantiating
  if (OptionsDialog::instance()->getMessagesPage()->getResetMessagesNumberBeforeSimulationCheckBox()->isChecked()) {
    MessagesWidget::instance()->resetMessagesNumber();
  }
  // check clear messages browser before instantiating
  if (OptionsDialog::instance()->getMessagesPage()->getClearMessagesBrowserBeforeSimulationCheckBox()->isChecked()) {
    MessagesWidget::instance()->clearMessages();
  }
  QString instantiateModelResult = mpOMCProxy->instantiateModel(pLibraryTreeItem->getNameStructure());
  if (!instantiateModelResult.isEmpty()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                tr("Instantiation of %1 completed successfully.").arg(pLibraryTreeItem->getNameStructure()),
                                                Helper::scriptingKind, Helper::notificationLevel));
    QString windowTitle = QString(Helper::instantiateModel).append(" - ").append(pLibraryTreeItem->getNameStructure());
    InformationDialog *pInformationDialog = new InformationDialog(windowTitle, instantiateModelResult, true, this);
    pInformationDialog->show();
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

void MainWindow::checkModel(LibraryTreeItem *pLibraryTreeItem)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  // set the status message.
  mpStatusBar->showMessage(QString(Helper::checkModel).append(" ").append(pLibraryTreeItem->getNameStructure()));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  // check reset messages number before checking
  if (OptionsDialog::instance()->getMessagesPage()->getResetMessagesNumberBeforeSimulationCheckBox()->isChecked()) {
    MessagesWidget::instance()->resetMessagesNumber();
  }
  // check clear messages browser before checking
  if (OptionsDialog::instance()->getMessagesPage()->getClearMessagesBrowserBeforeSimulationCheckBox()->isChecked()) {
    MessagesWidget::instance()->clearMessages();
  }
  QString checkModelResult = mpOMCProxy->checkModel(pLibraryTreeItem->getNameStructure());
  if (!checkModelResult.isEmpty()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                tr("Check of %1 completed successfully.").arg(pLibraryTreeItem->getNameStructure()),
                                                Helper::scriptingKind, Helper::notificationLevel));
    QString windowTitle = QString(Helper::checkModel).append(" - ").append(pLibraryTreeItem->getNameStructure());
    InformationDialog *pInformationDialog = new InformationDialog(windowTitle, checkModelResult, false, this);
    pInformationDialog->show();
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

void MainWindow::checkAllModels(LibraryTreeItem *pLibraryTreeItem)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  // set the status message.
  mpStatusBar->showMessage(QString(Helper::checkModel).append(" ").append(pLibraryTreeItem->getNameStructure()));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  QString checkAllModelsResult = mpOMCProxy->checkAllModelsRecursive(pLibraryTreeItem->getNameStructure());
  if (!checkAllModelsResult.isEmpty()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, checkAllModelsResult, Helper::scriptingKind,
                                                Helper::notificationLevel));
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

void MainWindow::exportModelFMU(LibraryTreeItem *pLibraryTreeItem)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  // set the status message.
  mpStatusBar->showMessage(tr("Exporting model as FMU"));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  // create a folder with model name to dump the files in it.
  QString modelDirectoryPath = QString("%1/%2").arg(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory(),
                                                    pLibraryTreeItem->getNameStructure());
  if (!QDir().exists(modelDirectoryPath)) {
    QDir().mkpath(modelDirectoryPath);
  }
  // set the folder as working directory
  MainWindow::instance()->getOMCProxy()->changeDirectory(modelDirectoryPath);
  // buildModelFMU parameters
  QString version = OptionsDialog::instance()->getFMIPage()->getFMIExportVersion();
  QString type = OptionsDialog::instance()->getFMIPage()->getFMIExportType();
  QString FMUName = OptionsDialog::instance()->getFMIPage()->getFMUNameTextBox()->text();
  QString newFmuName = pLibraryTreeItem->getWhereToMoveFMU();
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QString> platforms;
  if (!pSettings->contains("FMIExport/Platforms")) {
    QComboBox *pLinkingComboBox = OptionsDialog::instance()->getFMIPage()->getLinkingComboBox();
    platforms.append(pLinkingComboBox->itemData(pLinkingComboBox->currentIndex()).toString());
  } else {
    platforms = pSettings->value("FMIExport/Platforms").toStringList();
  }
  int index = platforms.indexOf("none");
  if (index > -1) {
    platforms.removeAt(index);
  }
  if (platforms.empty()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::FMU_EMPTY_PLATFORMS).arg(Helper::toolsOptionsPath),
                                                          Helper::scriptingKind, Helper::warningLevel));
  }
  QString fmuFileName = mpOMCProxy->buildModelFMU(pLibraryTreeItem->getNameStructure(), version, type, FMUName, platforms);
  if (!fmuFileName.isEmpty()) { // FMU was generated
    if (!newFmuName.isEmpty()) { // FMU should be moved
      QDir newNameAsDir(newFmuName);
      QString whereToMove;
      if (newNameAsDir.exists()) {
        whereToMove = newNameAsDir.filePath(pLibraryTreeItem->getNameStructure() + ".fmu");
      } else {
        whereToMove = newFmuName;
      }
      QFile(whereToMove).remove();
      if (QFile(fmuFileName).rename(whereToMove)) {
        fmuFileName = whereToMove;
      } else {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                              GUIMessages::getMessage(GUIMessages::FMU_MOVE_FAILED).arg(whereToMove),
                                                              Helper::scriptingKind, Helper::errorLevel));
      }
    }
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::FMU_GENERATED).arg(fmuFileName),
                                                          Helper::scriptingKind, Helper::notificationLevel));
  }
  //trace export FMU
  if (OptionsDialog::instance()->getTraceabilityPage()->getTraceabilityGroupBox()->isChecked() && !fmuFileName.isEmpty()) {
    //Push traceability information automaticaly to Daemon
    MainWindow::instance()->getCommitChangesDialog()->generateTraceabilityURI("fmuExport", pLibraryTreeItem->getFileName(),
                                                                              pLibraryTreeItem->getNameStructure(), fmuFileName);
  }
  MainWindow::instance()->getOMCProxy()->changeDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

/*!
 * \brief MainWindow::exportEncryptedPackage
 * Exports the package as encrypted package
 * \param pLibraryTreeItem
 */
void MainWindow::exportEncryptedPackage(LibraryTreeItem *pLibraryTreeItem)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  // set the status message.
  mpStatusBar->showMessage(tr("Exporting the package as encrypted package"));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  // build encrypted package
  if (mpOMCProxy->buildEncryptedPackage(pLibraryTreeItem->getNameStructure())) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::ENCRYPTED_PACKAGE_GENERATED)
                                                          .arg(QString("%1/%2.mol")
                                                               .arg(MainWindow::instance()->getOMCProxy()->changeDirectory())
                                                               .arg(pLibraryTreeItem->getNameStructure())),
                                                          Helper::scriptingKind, Helper::notificationLevel));
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

/*!
 * \brief MainWindow::exportReadonlyPackage
 * Exports the package as read-only package
 * \param pLibraryTreeItem
 */
void MainWindow::exportReadonlyPackage(LibraryTreeItem *pLibraryTreeItem)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  // set the status message.
  mpStatusBar->showMessage(tr("Exporting the package as read-only package"));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  // build read-only package
  if (mpOMCProxy->buildEncryptedPackage(pLibraryTreeItem->getNameStructure(), false)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::READONLY_PACKAGE_GENERATED)
                                                          .arg(QString("%1/%2.mol")
                                                               .arg(MainWindow::instance()->getOMCProxy()->changeDirectory())
                                                               .arg(pLibraryTreeItem->getNameStructure())),
                                                          Helper::scriptingKind, Helper::notificationLevel));
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

void MainWindow::exportModelXML(LibraryTreeItem *pLibraryTreeItem)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  // set the status message.
  mpStatusBar->showMessage(tr("Exporting model as XML"));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  QString xmlFileName = mpOMCProxy->translateModelXML(pLibraryTreeItem->getNameStructure());
  if (!xmlFileName.isEmpty()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::XML_GENERATED).arg(xmlFileName),
                                                          Helper::scriptingKind, Helper::notificationLevel));
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

void MainWindow::exportModelFigaro(LibraryTreeItem *pLibraryTreeItem)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  ExportFigaroDialog *pExportFigaroDialog = new ExportFigaroDialog(pLibraryTreeItem, this);
  pExportFigaroDialog->exec();
}

/*!
 * \brief MainWindow::fetchInterfaceData
 * \param pLibraryTreeItem
 * Fetches the interface data for TLM co-simulation.
 */
void MainWindow::fetchInterfaceData(LibraryTreeItem *pLibraryTreeItem, QString singleModel)
{
  /* if CompositeModel text is changed manually by user then validate it before fetching the interface data. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  if (pLibraryTreeItem->isSaved()) {
    fetchInterfaceDataHelper(pLibraryTreeItem, singleModel);
  } else {
    QMessageBox *pMessageBox = new QMessageBox(this);
    pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::question));
    pMessageBox->setIcon(QMessageBox::Question);
    pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
    pMessageBox->setText(GUIMessages::getMessage(GUIMessages::COMPOSITEMODEL_UNSAVED).arg(pLibraryTreeItem->getNameStructure()));
    pMessageBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
    pMessageBox->setDefaultButton(QMessageBox::Yes);
    int answer = pMessageBox->exec();
    switch (answer) {
      case QMessageBox::Yes:
        if (mpLibraryWidget->saveLibraryTreeItem(pLibraryTreeItem)) {
          fetchInterfaceDataHelper(pLibraryTreeItem, singleModel);
        }
        break;
      case QMessageBox::No:
      default:
        break;
    }
  }
}

/*!
 * \brief MainWindow::TLMSimulate
 * \param pLibraryTreeItem
 * Starts the TLM co-simulation.
 */
void MainWindow::TLMSimulate(LibraryTreeItem *pLibraryTreeItem)
{
  if (!mpTLMCoSimulationDialog) {
    mpTLMCoSimulationDialog = new TLMCoSimulationDialog(this);
  }
  /* if CompositeModel text is changed manually by user then validate it before starting the TLM co-simulation. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  if (pLibraryTreeItem->isSaved()) {
    mpTLMCoSimulationDialog->show(pLibraryTreeItem);
  } else {
    QMessageBox *pMessageBox = new QMessageBox(this);
    pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::question));
    pMessageBox->setIcon(QMessageBox::Question);
    pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
    pMessageBox->setText(GUIMessages::getMessage(GUIMessages::COMPOSITEMODEL_UNSAVED).arg(pLibraryTreeItem->getNameStructure()));
    pMessageBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
    pMessageBox->setDefaultButton(QMessageBox::Yes);
    int answer = pMessageBox->exec();
    switch (answer) {
      case QMessageBox::Yes:
        if (mpLibraryWidget->saveLibraryTreeItem(pLibraryTreeItem)) {
          mpTLMCoSimulationDialog->show(pLibraryTreeItem);
        }
        break;
      case QMessageBox::No:
      default:
        break;
    }
  }
}

void MainWindow::exportModelToOMNotebook(LibraryTreeItem *pLibraryTreeItem)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  QString omnotebookFileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::exportToOMNotebook),
                                                              NULL, Helper::omnotebookFileTypes, NULL, "onb", &pLibraryTreeItem->getName());
  // if user cancels the operation. or closes the export dialog box.
  if (omnotebookFileName.isEmpty()) {
    return;
  }
  // create a progress bar
  int endtime = 6;    // since in total we do six things while exporting to OMNotebook
  int value = 1;
  // set the status message.
  mpStatusBar->showMessage(tr("Exporting model to OMNotebook"));
  // show the progress bar
  mpProgressBar->setRange(0, endtime);
  showProgressBar();
  // create the xml for the omnotebook file.
  QDomDocument xmlDocument;
  // create Notebook element
  QDomElement notebookElement = xmlDocument.createElement("Notebook");
  xmlDocument.appendChild(notebookElement);
  mpProgressBar->setValue(value++);
  // create title cell
  createOMNotebookTitleCell(pLibraryTreeItem, xmlDocument, notebookElement);
  mpProgressBar->setValue(value++);
  // create image cell
  QStringList pathList = omnotebookFileName.split('/');
  pathList.removeLast();
  QString modelImagePath(pathList.join("/"));
  createOMNotebookImageCell(pLibraryTreeItem, xmlDocument, notebookElement, modelImagePath);
  mpProgressBar->setValue(value++);
  // create a code cell
  createOMNotebookCodeCell(pLibraryTreeItem, xmlDocument, notebookElement);
  mpProgressBar->setValue(value++);
  // create a file object and write the xml in it.
  QFile omnotebookFile(omnotebookFileName);
  omnotebookFile.open(QIODevice::WriteOnly);
  QTextStream textStream(&omnotebookFile);
  textStream.setCodec(Helper::utf8.toStdString().data());
  textStream.setGenerateByteOrderMark(false);
  textStream << xmlDocument.toString();
  omnotebookFile.close();
  mpProgressBar->setValue(value++);
  // hide the progressbar and clear the message in status bar
  mpStatusBar->clearMessage();
  hideProgressBar();
}

//! creates a title cell in omnotebook xml file
void MainWindow::createOMNotebookTitleCell(LibraryTreeItem *pLibraryTreeItem, QDomDocument xmlDocument, QDomElement domElement)
{
  QDomElement textCellElement = xmlDocument.createElement("TextCell");
  textCellElement.setAttribute("style", "Text");
  domElement.appendChild(textCellElement);
  // create text Element
  QDomElement textElement = xmlDocument.createElement("Text");
  textElement.appendChild(xmlDocument.createTextNode("<html><head><meta name=\"qrichtext\" content=\"1\" /><head><body style=\"white-space: pre-wrap; font-family:MS Shell Dlg; font-size:8.25pt; font-weight:400; font-style:normal; text-decoration:none;\"><p style=\"margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px; font-family:Arial; font-size:38pt; font-weight:600; color:#000000;\">" + pLibraryTreeItem->getName() + "</p></body></html>"));
  textCellElement.appendChild(textElement);
}

//! creates a image cell in omnotebook xml file
void MainWindow::createOMNotebookImageCell(LibraryTreeItem *pLibraryTreeItem, QDomDocument xmlDocument, QDomElement domElement,
                                           QString filePath)
{
  GraphicsView *pGraphicsView = pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView();
  QPixmap modelImage(pGraphicsView->viewport()->size());
  modelImage.fill(QColor(Qt::transparent));
  QPainter painter(&modelImage);
  painter.setWindow(pGraphicsView->viewport()->rect());
  // paint the background color first
  painter.fillRect(modelImage.rect(), pGraphicsView->palette().background());
  // paint all the items
  pGraphicsView->render(&painter, QRectF(painter.viewport()), pGraphicsView->viewport()->rect());
  painter.end();
  // create textcell element
  QDomElement textCellElement = xmlDocument.createElement("TextCell");
  domElement.appendChild(textCellElement);
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
  imageBuffer.open(QBuffer::WriteOnly);
  QDataStream out(&imageBuffer);
  out << modelImage;
  imageBuffer.close();
  imageElement.appendChild(xmlDocument.createTextNode(imageBuffer.buffer().toBase64()));
  textCellElement.appendChild(imageElement);
}

//! creates a code cell in omnotebook xml file
void MainWindow::createOMNotebookCodeCell(LibraryTreeItem *pLibraryTreeItem, QDomDocument xmlDocument, QDomElement domElement)
{
  QDomElement textCellElement = xmlDocument.createElement("InputCell");
  domElement.appendChild(textCellElement);
  // create input Element
  QDomElement inputElement = xmlDocument.createElement("Input");
  inputElement.appendChild(xmlDocument.createTextNode(mpOMCProxy->list(pLibraryTreeItem->getNameStructure())));
  textCellElement.appendChild(inputElement);
  // create output Element
  QDomElement outputElement = xmlDocument.createElement("Output");
  outputElement.appendChild(xmlDocument.createTextNode(""));
  textCellElement.appendChild(outputElement);
}

/*!
 * \brief MainWindow::showTransformationsWidget
 * Creates a TransformationsWidget and show it to the user.
 * \param fileName
 * \return
 */
TransformationsWidget *MainWindow::showTransformationsWidget(QString fileName)
{
  TransformationsWidget *pTransformationsWidget = mTransformationsWidgetHash.value(fileName, 0);
  if (!pTransformationsWidget) {
    pTransformationsWidget = new TransformationsWidget(fileName);
    mTransformationsWidgetHash.insert(fileName, pTransformationsWidget);
  } else {
    pTransformationsWidget->reloadTransformations();
  }
  pTransformationsWidget->show();
  pTransformationsWidget->raise();
  pTransformationsWidget->activateWindow();
  pTransformationsWidget->setWindowState(pTransformationsWidget->windowState() & (~Qt::WindowMinimized | Qt::WindowActive));
  return pTransformationsWidget;
}

/*!
 * \brief MainWindow::findFileAndGoToLine
 * Finds the file and opens it at specified line number.
 * \param fileName
 * \param lineNumber
 */
void MainWindow::findFileAndGoToLine(QString fileName, QString lineNumber)
{
  LibraryTreeItem *pLibraryTreeItem = mpLibraryWidget->getLibraryTreeModel()->getLibraryTreeItemFromFile(fileName, lineNumber.toInt());
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
    if (pLibraryTreeItem->getModelWidget() && pLibraryTreeItem->getModelWidget()->getEditor()) {
      pLibraryTreeItem->getModelWidget()->getTextViewToolButton()->setChecked(true);
      pLibraryTreeItem->getModelWidget()->getEditor()->getPlainTextEdit()->goToLineNumber(lineNumber.toInt());
    }
  } else {
    QString msg = tr("Unable to find the file <b>%1</b> with line number <b>%2</b>").arg(fileName).arg(lineNumber);
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief MainWindow::printStandardOutAndErrorFilesMessages
 * Reads the omeditoutput.txt and omediterror.txt files and add the data to Messages Browser if there is any.
 */
void MainWindow::printStandardOutAndErrorFilesMessages()
{
  // read stdout file
  QFile outputFile(Utilities::tempDirectory() + "/omeditoutput.txt");
  if (outputFile.open(QIODevice::ReadOnly)) {
    static qint64 outputFilePosition = 0;
    if (outputFile.seek(outputFilePosition)) {
      QString outputFileData = outputFile.readAll();
      if (!outputFileData.isEmpty()) {
        outputFilePosition = outputFile.pos();
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, outputFileData,
                                                              Helper::scriptingKind, Helper::notificationLevel));
      }
    }
    outputFile.close();
  }
  // read stderr file
  QFile errorFile(Utilities::tempDirectory() + "/omediterror.txt");
  if (errorFile.open(QIODevice::ReadOnly)) {
    static qint64 errorFilePosition = 0;
    if (errorFile.seek(errorFilePosition)) {
      QString errorFileData = errorFile.readAll();
      if (!errorFileData.isEmpty()) {
        errorFilePosition = errorFile.pos();
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, errorFileData,
                                                              Helper::scriptingKind, Helper::errorLevel));
      }
    }
    errorFile.close();
  }
}

void MainWindow::PlotCallbackFunction(void *p, int externalWindow, const char* filename, const char *title, const char *grid,
                                      const char *plotType, const char *logX, const char *logY, const char *xLabel, const char *yLabel,
                                      const char *x1, const char *x2, const char *y1, const char *y2, const char *curveWidth,
                                      const char *curveStyle, const char *legendPosition, const char *footer, const char *autoScale,
                                      const char *variables)
{
  MainWindow *pMainWindow = (MainWindow*)p;
  if (pMainWindow) {
    QFileInfo fileInfo(filename);
    pMainWindow->openResultFiles(QStringList() << filename);
    if (!fileInfo.exists()) return;
    OMPlot::PlotWindow *pPlotWindow = pMainWindow->getPlotWindowContainer()->getCurrentWindow();
    if (pPlotWindow && !externalWindow) {
      if (pPlotWindow->getPlotType() == OMPlot::PlotWindow::PLOT && strcmp(plotType, "plotparametric") == 0) {
        pMainWindow->getPlotWindowContainer()->addParametricPlotWindow();
      } else if (pPlotWindow->getPlotType() == OMPlot::PlotWindow::PLOTPARAMETRIC &&
                 ((strcmp(plotType, "plot") == 0) || (strcmp(plotType, "plotall") == 0))) {
        pMainWindow->getPlotWindowContainer()->addPlotWindow();
      }
    } else if (externalWindow || pMainWindow->getPlotWindowContainer()->subWindowList().size() == 0) {
      if ((strcmp(plotType, "plot") == 0) || (strcmp(plotType, "plotall") == 0)) {
        pMainWindow->getPlotWindowContainer()->addPlotWindow();
      } else if (strcmp(plotType, "plotparametric") == 0) {
        pMainWindow->getPlotWindowContainer()->addParametricPlotWindow();
      }
    }
    // get the current window again and set plot arguments on it
    pPlotWindow = pMainWindow->getPlotWindowContainer()->getCurrentWindow();
    pPlotWindow->setTitle(QString(title));
    pPlotWindow->setGrid(QString(grid));
    if (QString(logX) == "true") {
      pPlotWindow->setLogX(true);
    } else if (QString(logX) == "false") {
      pPlotWindow->setLogX(false);
    } else {
      throw OMPlot::PlotException("Invalid input" + QString(logX));
    }
    if (QString(logY) == "true") {
      pPlotWindow->setLogY(true);
    } else if (QString(logY) == "false") {
      pPlotWindow->setLogY(false);
    } else {
      throw OMPlot::PlotException("Invalid input" + QString(logY));
    }
    pPlotWindow->setXLabel(QString(xLabel));
    pPlotWindow->setYLabel(QString(yLabel));
    pPlotWindow->setXRange(QString(x1).toDouble(), QString(x2).toDouble());
    pPlotWindow->setYRange(QString(y1).toDouble(), QString(y2).toDouble());
    pPlotWindow->setCurveWidth(QString(curveWidth).toDouble());
    pPlotWindow->setCurveStyle(QString(curveStyle).toInt());
    pPlotWindow->setLegendPosition(QString(legendPosition));
    pPlotWindow->setFooter(QString(footer));
    if (QString(autoScale) == "true") {
      pPlotWindow->setAutoScale(true);
    } else if (QString(autoScale) == "false") {
      pPlotWindow->setAutoScale(false);
    } else {
      throw OMPlot::PlotException("Invalid input" + QString(autoScale));
    }
    // plot variables
    QStringList variablesList = QString(variables).split(" ", QString::SkipEmptyParts);
    VariablesTreeItem *pVariableTreeItem;
    VariablesTreeModel *pVariablesTreeModel = pMainWindow->getVariablesWidget()->getVariablesTreeModel();
    bool state = pVariablesTreeModel->blockSignals(true);
    foreach (QString variable, variablesList) {
      variable = fileInfo.fileName() + "." + variable;
      pVariableTreeItem = pVariablesTreeModel->findVariablesTreeItem(variable, pVariablesTreeModel->getRootVariablesTreeItem());
      if (pVariableTreeItem) {
        QModelIndex index = pVariablesTreeModel->variablesTreeItemIndex(pVariableTreeItem);
        OMPlot::PlotCurve *pPlotCurve = 0;
        foreach (OMPlot::PlotCurve *curve, pPlotWindow->getPlot()->getPlotCurvesList()) {
          if (curve->getNameStructure().compare(pVariableTreeItem->getVariableName()) == 0) {
            pPlotCurve = curve;
            break;
          }
        }
        pVariablesTreeModel->setData(index, Qt::Checked, Qt::CheckStateRole);
        pMainWindow->getVariablesWidget()->plotVariables(index, pPlotWindow->getCurveWidth(), pPlotWindow->getCurveStyle(), pPlotCurve);
      }
    }
    // variables list is empty for plotAll
    if (strcmp(plotType, "plotall") == 0) {
      pVariableTreeItem = pVariablesTreeModel->findVariablesTreeItem(fileInfo.fileName(), pVariablesTreeModel->getRootVariablesTreeItem());
      if (pVariableTreeItem) {
        pMainWindow->getVariablesWidget()->getVariablesTreeModel()->plotAllVariables(pVariableTreeItem, pPlotWindow);
      }
    }
    pVariablesTreeModel->blockSignals(state);
  }
}

/*!
 * \brief MainWindow::showMessagesBrowser
 * Slot activated when MessagesWidget::MessageAdded signal is raised.\n
 * Shows the Messages Browser.
 */
void MainWindow::showMessagesBrowser()
{
  mpMessagesDockWidget->show();
  // In case user has tabbed the dock widgets then make Messages Browser active.
  QList<QDockWidget*> tabifiedDockWidgetsList = tabifiedDockWidgets(mpMessagesDockWidget);
  if (tabifiedDockWidgetsList.size() > 0) {
    tabifyDockWidget(tabifiedDockWidgetsList.at(0), mpMessagesDockWidget);
  }
}

/*!
 * \brief MainWindow::showSearchBrowser
 * Shows the Search Browser, selects the search text if any and sets the focus on it.
 */
void MainWindow::showSearchBrowser()
{
  mpSearchDockWidget->show();
  // In case user has tabbed the dock widgets then make searchwidget active when ctrl+h is pressed.
  QList<QDockWidget*> tabifiedDockWidgetsList = tabifiedDockWidgets(mpSearchDockWidget);
  if (tabifiedDockWidgetsList.size() > 0) {
    tabifyDockWidget(tabifiedDockWidgetsList.at(0), mpSearchDockWidget);
  }
  mpSearchWidget->getSearchStringComboBox()->lineEdit()->selectAll();
  mpSearchWidget->getSearchStringComboBox()->lineEdit()->setFocus(Qt::ActiveWindowFocusReason);
  mpSearchWidget->getSearchStackedWidget()->setCurrentIndex(0);
  mpSearchWidget->getSearchHistoryCombobox()->setCurrentIndex(0);
}

//! Opens the new model widget.
void MainWindow::createNewModelicaClass()
{
  ModelicaClassDialog *pModelicaClassDialog = new ModelicaClassDialog(this);
  pModelicaClassDialog->exec();
}

void MainWindow::openModelicaFile()
{
  QStringList fileNames;
  fileNames = StringHandler::getOpenFileNames(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFiles),
                                              NULL, Helper::omFileTypes, NULL);
  if (fileNames.isEmpty()) {
    return;
  }
  int progressValue = 0;
  mpProgressBar->setRange(0, fileNames.size());
  showProgressBar();
  foreach (QString file, fileNames) {
    file = file.replace("\\", "/");
    mpStatusBar->showMessage(QString(Helper::loading).append(": ").append(file));
    mpProgressBar->setValue(++progressValue);
    // if file doesn't exists
    if (!QFile::exists(file)) {
      QMessageBox *pMessageBox = new QMessageBox(this);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(file)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(file)));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    } else {
      mpLibraryWidget->openFile(file, Helper::utf8, false);
    }
  }
  mpStatusBar->clearMessage();
  hideProgressBar();
}

void MainWindow::showOpenModelicaFileDialog()
{
  OpenModelicaFile *pOpenModelicaFile = new OpenModelicaFile(this);
  pOpenModelicaFile->show();
}

void MainWindow::loadModelicaLibrary()
{
  QString libraryPath = StringHandler::getExistingDirectory(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseDirectory), NULL);
  if (libraryPath.isEmpty())
    return;
  libraryPath = libraryPath + QDir::separator() + "package.mo";
  libraryPath = libraryPath.replace("\\", "/");
  mpLibraryWidget->openFile(libraryPath, Helper::utf8, true, true);
}

void MainWindow::loadEncryptedLibrary()
{
  QStringList fileNames;
  fileNames = StringHandler::getOpenFileNames(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFiles),
                                              NULL, Helper::omEncryptedFileTypes, NULL);
  if (fileNames.isEmpty()) {
    return;
  }
  int progressValue = 0;
  mpProgressBar->setRange(0, fileNames.size());
  showProgressBar();
  foreach (QString file, fileNames) {
    file = file.replace("\\", "/");
    mpStatusBar->showMessage(QString(Helper::loading).append(": ").append(file));
    mpProgressBar->setValue(++progressValue);
    // if file doesn't exists
    if (!QFile::exists(file)) {
      QMessageBox *pMessageBox = new QMessageBox(this);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(file)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(file)));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    } else {
      QFileInfo fileInfo(file);
      QString library = fileInfo.completeBaseName();
      LibraryTreeModel *pLibraryTreeModel = mpLibraryWidget->getLibraryTreeModel();
      if (pLibraryTreeModel->findLibraryTreeItemOneLevel(library)) {
        QMessageBox *pMessageBox = new QMessageBox(this);
        pMessageBox->setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::information));
        pMessageBox->setIcon(QMessageBox::Information);
        pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
        pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(library)));
        pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES))
                                        .arg(library).append("\n")
                                        .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(library)));
        pMessageBox->setStandardButtons(QMessageBox::Ok);
        pMessageBox->exec();
      } else {  /* if library is not loaded then load it. */
        mpLibraryWidget->openFile(file, Helper::utf8, false);
      }
    }
  }
  mpStatusBar->clearMessage();
  hideProgressBar();
}

void MainWindow::showOpenResultFileDialog()
{
  QStringList fileNames = StringHandler::getOpenFileNames(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFiles),
                                                          NULL, Helper::omResultFileTypes, NULL);
  if (fileNames.isEmpty())
    return;
  openResultFiles(fileNames);
}

/*!
 * \brief MainWindow::showOpenTransformationFileDialog
 * Slot activated when mpOpenTransformationFileAction triggered signal is raised.\n
 * Shows a TransformationsWidget.
 */
void MainWindow::showOpenTransformationFileDialog()
{
  QString fileName = StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                    NULL, Helper::infoXmlFileTypes, NULL);
  if (fileName.isEmpty()) {
    return;
  }
  showTransformationsWidget(fileName);
}

/*!
 * \brief MainWindow::createNewCompositeModelFile
 * Creates a new TLM LibraryTreeItem & ModelWidget.\n
 * Slot activated when mpNewCompositeModelFileAction triggered signal is raised.
 */
void MainWindow::createNewCompositeModelFile()
{
  QString compositeModelName = mpLibraryWidget->getLibraryTreeModel()->getUniqueTopLevelItemName("CompositeModel");
  LibraryTreeModel *pLibraryTreeModel = mpLibraryWidget->getLibraryTreeModel();
  LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(LibraryTreeItem::CompositeModel, compositeModelName, compositeModelName, "",
                                                                               false, pLibraryTreeModel->getRootLibraryTreeItem());
  if (pLibraryTreeItem) {
    mpLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  }
}

/*!
 * \brief MainWindow::openCompositeModelFile
 * Opens the CompositeModel file(s).\n
 * Slot activated when mpOpenCompositeModelFileAction triggered signal is raised.
 */
void MainWindow::openCompositeModelFile()
{
  QStringList fileNames;
  fileNames = StringHandler::getOpenFileNames(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFiles), NULL,
                                              Helper::xmlFileTypes, NULL);
  if (fileNames.isEmpty()) {
    return;
  }
  int progressValue = 0;
  mpProgressBar->setRange(0, fileNames.size());
  showProgressBar();
  foreach (QString file, fileNames) {
    file = file.replace("\\", "/");
    mpStatusBar->showMessage(QString(Helper::loading).append(": ").append(file));
    mpProgressBar->setValue(++progressValue);
    // if file doesn't exists
    if (!QFile::exists(file)) {
      QMessageBox *pMessageBox = new QMessageBox(this);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(file)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(file)));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    } else {
      mpLibraryWidget->openFile(file, Helper::utf8, false);
    }
  }
  mpStatusBar->clearMessage();
  hideProgressBar();
}

/*!
 * \brief MainWindow::createNewOMSModel
 * Create a new OMSimulator model.
 */
void MainWindow::createNewOMSModel()
{
  CreateModelDialog *pCreateModelDialog = new CreateModelDialog;
  pCreateModelDialog->exec();
}

/*!
 * \brief MainWindow::openOMSModelFile
 * Opens the OMSimulator model file(s).\n
 * Slot activated when mpOpenOMSModelFileAction triggered signal is raised.
 */
void MainWindow::openOMSModelFile()
{
  QStringList fileNames;
  fileNames = StringHandler::getOpenFileNames(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFiles), NULL,
                                              Helper::omsFileTypes, NULL);
  if (fileNames.isEmpty()) {
    return;
  }
  int progressValue = 0;
  mpProgressBar->setRange(0, fileNames.size());
  showProgressBar();
  foreach (QString file, fileNames) {
    file = file.replace("\\", "/");
    mpStatusBar->showMessage(QString(Helper::loading).append(": ").append(file));
    mpProgressBar->setValue(++progressValue);
    // if file doesn't exists
    if (!QFile::exists(file)) {
      QMessageBox *pMessageBox = new QMessageBox(this);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(file)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(file)));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    } else {
      mpLibraryWidget->openFile(file, Helper::utf8);
    }
  }
  mpStatusBar->clearMessage();
  hideProgressBar();

}

/*!
 * \brief MainWindow::loadExternalModels
 * Loads the external model(s) for TLM meta-modeling.\n
 * Slot activated when mpLoadExternModelAction triggered signal is raised.
 */
void MainWindow::loadExternalModels()
{
  QStringList fileNames;
  fileNames = StringHandler::getOpenFileNames(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFiles), NULL,
                                              NULL, NULL);
  if (fileNames.isEmpty()) {
    return;
  }
  int progressValue = 0;
  mpProgressBar->setRange(0, fileNames.size());
  showProgressBar();
  foreach (QString file, fileNames) {
    file = file.replace("\\", "/");
    mpStatusBar->showMessage(QString(Helper::loading).append(": ").append(file));
    mpProgressBar->setValue(++progressValue);
    // if file doesn't exists
    if (!QFile::exists(file)) {
      QMessageBox *pMessageBox = new QMessageBox(this);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(file)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(file)));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    } else {
      mpLibraryWidget->openFile(file, Helper::utf8, false, false, true);
    }
  }
  mpStatusBar->clearMessage();
  hideProgressBar();
}

/*!
 * \brief MainWindow::openDirectory
 * Opens the directory.
 */
void MainWindow::openDirectory()
{
  QString dir = StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseDirectory), NULL);
  if (dir.isEmpty()) {
    return;
  }
  mpLibraryWidget->openFile(dir, Helper::utf8, true);
}

/*!
 * \brief MainWindow::loadSystemLibrary
 * Loads a system library.
 */
void MainWindow::loadSystemLibrary()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction) {
    /* check if library is already loaded. */
    QString library = pAction->data().toString();
    LibraryTreeModel *pLibraryTreeModel = mpLibraryWidget->getLibraryTreeModel();
    if (pLibraryTreeModel->findLibraryTreeItemOneLevel(library)) {
      QMessageBox *pMessageBox = new QMessageBox(this);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
      pMessageBox->setIcon(QMessageBox::Information);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(library)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES))
                                      .arg(library).append("\n")
                                      .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(library)));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    } else {  /* if library is not loaded then load it. */
      mpProgressBar->setRange(0, 0);
      showProgressBar();
      mpStatusBar->showMessage(QString(Helper::loading).append(": ").append(library));

      if (library.compare("OpenModelica") == 0) {
        pLibraryTreeModel->createLibraryTreeItem(library, pLibraryTreeModel->getRootLibraryTreeItem(), true, true, true);
        pLibraryTreeModel->checkIfAnyNonExistingClassLoaded();
      } else if (mpOMCProxy->loadModel(library)) {
        mpLibraryWidget->getLibraryTreeModel()->loadDependentLibraries(mpOMCProxy->getClassNames());
      }
      mpStatusBar->clearMessage();
      hideProgressBar();
    }
  }
}

/*!
 * \brief MainWindow::writeOutputFileData
 * Writes the output data from stdout file and adds it to MessagesWidget.
 * \param data
 */
void MainWindow::writeOutputFileData(QString data)
{
  MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, data,
                                                        Helper::scriptingKind, Helper::notificationLevel));
}

/*!
 * \brief MainWindow::writeErrorFileData
 * Writes the error data from stderr file and adds it to MessagesWidget.
 * \param data
 */
void MainWindow::writeErrorFileData(QString data)
{
  MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, data,
                                                        Helper::scriptingKind, Helper::errorLevel));
}

//! Opens the recent file.
void MainWindow::openRecentFile()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction) {
    QStringList dataList = pAction->data().toStringList();
    mpLibraryWidget->openFile(dataList.at(0), dataList.at(1), true, true);
  }
}

void MainWindow::clearRecentFilesList()
{
  QSettings *pSettings = Utilities::getApplicationSettings();
  pSettings->remove("recentFilesList/files");
  updateRecentFileActions();
  mpWelcomePageWidget->addRecentFilesListItems();
}

/*!
 * \brief MainWindow::undo
 * Calls the undo command for the selected view.
 */
void MainWindow::undo()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget &&
      ((pModelWidget->getIconGraphicsView() && pModelWidget->getIconGraphicsView()->isVisible()) ||
       (pModelWidget->getDiagramGraphicsView() && pModelWidget->getDiagramGraphicsView()->isVisible()))) {
    pModelWidget->clearSelection();
    pModelWidget->getUndoStack()->undo();
    pModelWidget->updateClassAnnotationIfNeeded();
    pModelWidget->updateModelText();
  } else if (pModelWidget && pModelWidget->getEditor() && pModelWidget->getEditor()->isVisible()
             && pModelWidget->getEditor()->getPlainTextEdit()->document()->isUndoAvailable()) {
    pModelWidget->getEditor()->getPlainTextEdit()->document()->undo();
  }
}

/*!
 * \brief MainWindow::redo
 * Calls the redo command for the selected view.
 */
void MainWindow::redo()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget &&
      ((pModelWidget->getIconGraphicsView() && pModelWidget->getIconGraphicsView()->isVisible()) ||
       (pModelWidget->getDiagramGraphicsView() && pModelWidget->getDiagramGraphicsView()->isVisible()))) {
    pModelWidget->clearSelection();
    pModelWidget->getUndoStack()->redo();
    pModelWidget->updateClassAnnotationIfNeeded();
    pModelWidget->updateModelText();
  } else if (pModelWidget && pModelWidget->getEditor() && pModelWidget->getEditor()->isVisible()
             && pModelWidget->getEditor()->getPlainTextEdit()->document()->isRedoAvailable()) {
    pModelWidget->getEditor()->getPlainTextEdit()->document()->redo();
  }
}

/*!
 * \brief MainWindow::focusFilterClasses
 * Sets the focus on filter classes text box in Libraries Browser.
 */
void MainWindow::focusFilterClasses()
{
  mpLibraryWidget->getTreeSearchFilters()->getFilterTextBox()->setFocus(Qt::ActiveWindowFocusReason);
}

void MainWindow::setShowGridLines(bool showLines)
{
  mpModelWidgetContainer->setShowGridLines(showLines);
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getIconGraphicsView() && pModelWidget->getIconGraphicsView()->isVisible()) {
    pModelWidget->getIconGraphicsView()->scene()->update();
  } else if (pModelWidget && pModelWidget->getDiagramGraphicsView() && pModelWidget->getDiagramGraphicsView()->isVisible()) {
    pModelWidget->getDiagramGraphicsView()->scene()->update();
  }
}

/*!
 * \brief MainWindow::resetZoom
 * Tells the current model to reset zoom to 100%.
 * \sa MainWindow::zoomIn()
 * \sa MainWindow::zoomOut()
 */
void MainWindow::resetZoom()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    if (pModelWidget->getDiagramGraphicsView() && pModelWidget->getDiagramGraphicsView()->isVisible()) {
      pModelWidget->getDiagramGraphicsView()->resetZoom();
    } else if (pModelWidget->getIconGraphicsView() && pModelWidget->getIconGraphicsView()->isVisible()) {
      pModelWidget->getIconGraphicsView()->resetZoom();
    } else if (pModelWidget->getEditor() && pModelWidget->getEditor()->isVisible()) {
      pModelWidget->getEditor()->getPlainTextEdit()->resetZoom();
    }
  }
}

/*!
 * \brief MainWindow::zoomIn
 * Tells the current model to increase its zoom factor.
 * \sa MainWindow::resetZoom()
 * \sa MainWindow::zoomOut()
 */
void MainWindow::zoomIn()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    if (pModelWidget->getDiagramGraphicsView() && pModelWidget->getDiagramGraphicsView()->isVisible()) {
      pModelWidget->getDiagramGraphicsView()->zoomIn();
    } else if (pModelWidget->getIconGraphicsView() && pModelWidget->getIconGraphicsView()->isVisible()) {
      pModelWidget->getIconGraphicsView()->zoomIn();
    } else if (pModelWidget->getEditor() && pModelWidget->getEditor()->isVisible()) {
      pModelWidget->getEditor()->getPlainTextEdit()->zoomIn();
    }
  }
}

/*!
 * \brief MainWindow::zoomOut
 * Tells the current model to decrease its zoom factor.
 * \sa MainWindow::resetZoom()
 * \sa MainWindow::zoomIn()
 */
void MainWindow::zoomOut()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    if (pModelWidget->getDiagramGraphicsView() && pModelWidget->getDiagramGraphicsView()->isVisible()) {
      pModelWidget->getDiagramGraphicsView()->zoomOut();
    } else if (pModelWidget->getIconGraphicsView() && pModelWidget->getIconGraphicsView()->isVisible()) {
      pModelWidget->getIconGraphicsView()->zoomOut();
    } else if (pModelWidget->getEditor() && pModelWidget->getEditor()->isVisible()) {
      pModelWidget->getEditor()->getPlainTextEdit()->zoomOut();
    }
  }
}

/*!
 * \brief MainWindow::closeWindow
 * Closes the active window.
 */
void MainWindow::closeWindow()
{
  switch (mpCentralStackedWidget->currentIndex()) {
    case 1:
      mpModelWidgetContainer->closeActiveSubWindow();
      break;
    case 2:
      mpPlotWindowContainer->closeActiveSubWindow();
    default:
      break;
  }
}

/*!
 * \brief MainWindow::closeAllWindows
 * Closes all windows of the selected perspective.
 */
void MainWindow::closeAllWindows()
{
  switch (mpCentralStackedWidget->currentIndex()) {
    case 1:
      mpModelWidgetContainer->closeAllSubWindows();
      break;
    case 2:
      mpPlotWindowContainer->closeAllSubWindows();
    default:
      break;
  }
}

/*!
 * \brief MainWindow::closeAllWindowsButThis
 * Closes all windows of the selected perspective except the active window.
 */
void MainWindow::closeAllWindowsButThis()
{
  switch (mpCentralStackedWidget->currentIndex()) {
    case 1:
      closeAllWindowsButThis(mpModelWidgetContainer);
      break;
    case 2:
      closeAllWindowsButThis(mpPlotWindowContainer);
    default:
      break;
  }
}

/*!
  Slot activated when mpCascadeWindowsAction triggered signal is raised.\n
  Arranges all child windows in a cascade pattern.
  */
void MainWindow::cascadeSubWindows()
{
  switch (mpCentralStackedWidget->currentIndex()) {
    case 1:
      mpModelWidgetContainer->cascadeSubWindows();
      break;
    case 2:
      mpPlotWindowContainer->cascadeSubWindows();
    default:
      break;
  }
}

/*!
  Slot activated when mpTileWindowsHorizontallyAction triggered signal is raised.\n
  Arranges all child windows in a horizontally tiled pattern.
  */
void MainWindow::tileSubWindowsHorizontally()
{
  switch (mpCentralStackedWidget->currentIndex()) {
    case 1:
      tileSubWindows(mpModelWidgetContainer, true);
      break;
    case 2:
      tileSubWindows(mpPlotWindowContainer, true);
    default:
      break;
  }
}

/*!
  Slot activated when mpTileWindowsVerticallyAction triggered signal is raised.\n
  Arranges all child windows in a vertically tiled pattern.
  */
void MainWindow::tileSubWindowsVertically()
{
  switch (mpCentralStackedWidget->currentIndex()) {
    case 1:
      tileSubWindows(mpModelWidgetContainer, false);
      break;
    case 2:
      tileSubWindows(mpPlotWindowContainer, false);
    default:
      break;
  }
}

/*!
 * \brief MainWindow::toggleTabOrSubWindowView
 * Slot activated when mpToggleTabOrSubWindowView triggered signal is raised.\n
 * Toggles between tab or sub-window view mode.
 */
void MainWindow::toggleTabOrSubWindowView()
{
  QMdiArea *pMdiArea = 0;
  // get the current QMdiArea
  switch (mpCentralStackedWidget->currentIndex()) {
    case 1:
      pMdiArea = mpModelWidgetContainer;
      break;
    case 2:
      pMdiArea = mpPlotWindowContainer;
      break;
    default:
      return;
  }
  // set the QMdiArea view mode
  if (pMdiArea) {
    QMdiSubWindow *pSubWindow = 0;
    switch (pMdiArea->viewMode()) {
      case QMdiArea::SubWindowView:
        pMdiArea->setViewMode(QMdiArea::TabbedView);
        break;
      case QMdiArea::TabbedView:
        pMdiArea->setViewMode(QMdiArea::SubWindowView);
        pSubWindow = pMdiArea->currentSubWindow();
        if (pSubWindow) {
          pSubWindow->show();
          pSubWindow->setWindowState(Qt::WindowMaximized);
        }
        break;
      default:
        break;
    }
  }
}

void MainWindow::instantiateModel()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    instantiateModel(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                .arg(tr("instantiating")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

void MainWindow::checkModel()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    checkModel(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                .arg(tr("checking")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

void MainWindow::checkAllModels()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    checkAllModels(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                .arg(tr("checking")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

/*!
  Simualtes the model directly.
  */
//!
void MainWindow::simulateModel()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    simulate(pModelWidget->getLibraryTreeItem());
  }
}

/*!
  Simualtes the model directly with animation flag.
  */
//!
void MainWindow::simulateModelWithAnimation()
{
#if !defined(WITHOUT_OSG)
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    simulateWithAnimation(pModelWidget->getLibraryTreeItem());
  }
#else
  assert(0);
#endif
}

/*!
  Simualtes the model with transformational debugger
  */
void MainWindow::simulateModelWithTransformationalDebugger()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    simulateWithTransformationalDebugger(pModelWidget->getLibraryTreeItem());
  }
}

/*!
  Simualtes the model with algorithmic debugger
  */
void MainWindow::simulateModelWithAlgorithmicDebugger()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    simulateWithAlgorithmicDebugger(pModelWidget->getLibraryTreeItem());
  }
}

/*!
  Opens the Simualtion Dialog
  */
void MainWindow::openSimulationDialog()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    simulationSetup(pModelWidget->getLibraryTreeItem());
  }
}

//! Exports the current model to FMU
void MainWindow::exportModelFMU()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    exportModelFMU(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                          .arg(tr("making FMU")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

/*!
 * \brief MainWindow::exportEncryptedPackage
 * Slot activated when mpExportEncryptedPackageAction triggered SIGNAL is raised.
 */
void MainWindow::exportEncryptedPackage()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    exportEncryptedPackage(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                          .arg(tr("making encrypted package")), Helper::scriptingKind,
                                                          Helper::notificationLevel));
  }
}

/*!
 * \brief MainWindow::exportReadonlyPackage
 * Slot activated when mpExportReadonlyPackageAction triggered SIGNAL is raised.
 */
void MainWindow::exportReadonlyPackage()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    exportReadonlyPackage(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                          .arg(tr("making read-only package")), Helper::scriptingKind,
                                                          Helper::notificationLevel));
  }
}

//! Exports the current model to XML
void MainWindow::exportModelXML()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    exportModelXML(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                          .arg(tr("making XML")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

//! Exports the current model to XML
void MainWindow::exportModelFigaro()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    exportModelFigaro(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                          .arg(tr("exporting to Figaro")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

/*!
 * \brief MainWindow::showOpenModelicaCommandPrompt
 * Opens the command prompt to compile OpenModelica generated code with MinGW and run it.
 */
void MainWindow::showOpenModelicaCommandPrompt()
{
  QString commandPrompt = "cmd.exe";
  QString promptBatch = QString("%1/share/omc/scripts/Prompt.bat").arg(Helper::OpenModelicaHome);
  QStringList args;
  args << "/K" << promptBatch;
  if (!QProcess::startDetached(commandPrompt, args, OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory())) {
    QString errorString = tr("Unable to run command <b>%1</b> with arguments <b>%2</b>.").arg(commandPrompt).arg(args.join(" "));
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, errorString, Helper::scriptingKind,
                                                          Helper::errorLevel));
  }
}

//! Imports the model from FMU
void MainWindow::importModelFMU()
{
  ImportFMUDialog *pImportFMUDialog = new ImportFMUDialog(this);
  pImportFMUDialog->exec();
}

//! Imports the model from FMU model description
void MainWindow::importFMUModelDescription()
{
  ImportFMUModelDescriptionDialog *pImportFMUModelDescriptionDialog = new ImportFMUModelDescriptionDialog(this);
  pImportFMUModelDescriptionDialog->exec();
}

//! Exports the current model to OMNotebook.
//! Creates a new onb file and add the model text and model image in it.
//! @see importModelfromOMNotebook();
void MainWindow::exportModelToOMNotebook()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    exportModelToOMNotebook(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                          .arg(tr("exporting to OMNotebook")), Helper::scriptingKind,
                                                          Helper::notificationLevel));
  }
}

//! Imports the models from OMNotebook.
//! @see exportModelToOMNotebook();
void MainWindow::importModelfromOMNotebook()
{
  QString fileName = StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::importFromOMNotebook),
                                                    NULL, Helper::omnotebookFileTypes);
  if (fileName.isEmpty())
    return;
  // create a progress bar
  int endtime = 3;    // since in total we do three things while importing from OMNotebook
  int value = 1;
  // show the progressbar and set the message in status bar
  mpStatusBar->showMessage(tr("Importing model(s) from OMNotebook"));
  mpProgressBar->setRange(0, endtime);
  showProgressBar();
  // open the xml file
  QFile file(fileName);
  if (!file.open(QIODevice::ReadOnly))
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(fileName).arg(file.errorString()), Helper::ok);
    hideProgressBar();
    return;
  }
  mpProgressBar->setValue(value++);
  // create the xml from the omnotebook file.
  QDomDocument xmlDocument;
  if (!xmlDocument.setContent(&file))
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          tr("Error reading the xml file"), Helper::ok);
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
      mpLibraryWidget->parseAndLoadModelicaText(nodes.at(i).toElement().text());
    }
    mpProgressBar->setValue(value++);
  }
  file.close();
  // hide the progressbar and clear the message in status bar
  mpStatusBar->clearMessage();
  hideProgressBar();
}

// Tool to convert ngspice netlist to modelica code - added by Rakhi
void MainWindow::importNgspiceNetlist()
{
  QString fileName = StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::importNgspiceNetlist),
                                                    NULL, Helper::ngspiceNetlistFileTypes);
  if (fileName.isEmpty())
    return;
  // create a progress bar
  int endtime = 0;
  // show the progress bar and set the message in status bar
  mpStatusBar->showMessage(tr("Importing ngspice netlist and converting to Modelica code"));
  mpProgressBar->setRange(0, endtime);
  showProgressBar();
  if (mpOMCProxy->ngspicetoModelica(fileName))
  {
    QFileInfo fileInfo(fileName);
    QString modelicaFile = QString(fileInfo.absoluteDir().absolutePath()).append("/").append(fileInfo.baseName()).append(".mo");
    mpLibraryWidget->openFile(modelicaFile, Helper::utf8, true, true);
  }
  // hide the progress bar and clear the message in status bar
  mpStatusBar->clearMessage();
  hideProgressBar();
}

//! Exports the current model as image
void MainWindow::exportModelAsImage(bool copyToClipboard)
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
    QString fileName;
    if (!copyToClipboard) {
      fileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::exportAsImage),
                                                NULL, Helper::imageFileTypes, NULL, "svg", &pLibraryTreeItem->getName());
      // if user cancels the operation. or closes the export dialog box.
      if (fileName.isEmpty()) {
        return;
      }
    }
    // show the progressbar and set the message in status bar
    mpProgressBar->setRange(0, 0);
    showProgressBar();
    mpStatusBar->showMessage(tr("Exporting model as an Image"));
    QPainter painter;
    QSvgGenerator svgGenerator;
    GraphicsView *pGraphicsView;
    if (pLibraryTreeItem->getModelWidget()->getIconGraphicsView()->isVisible()) {
      pGraphicsView = pLibraryTreeItem->getModelWidget()->getIconGraphicsView();
    } else {
      pGraphicsView = pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView();
    }
    QRect destinationRect = pGraphicsView->itemsBoundingRect().toAlignedRect();
    QImage modelImage(destinationRect.size(), QImage::Format_ARGB32_Premultiplied);
    // export svg
    if (fileName.endsWith(".svg")) {
      svgGenerator.setTitle(QString(Helper::applicationName).append(" - ").append(Helper::applicationIntroText));
      svgGenerator.setDescription("Generated by OMEdit - OpenModelica Connection Editor");
      svgGenerator.setSize(destinationRect.size());
      svgGenerator.setViewBox(QRect(0, 0, destinationRect.width(), destinationRect.height()));
      svgGenerator.setFileName(fileName);
      painter.begin(&svgGenerator);
    } else {
      if (fileName.endsWith(".png") || fileName.endsWith(".tiff")) {
        modelImage.fill(QColor(Qt::transparent));
      } else if (fileName.endsWith(".bmp") || copyToClipboard) {
        modelImage.fill(QColor(Qt::white));
      }
      painter.begin(&modelImage);
    }
    painter.setWindow(destinationRect);
    // paint all the items
    bool oldSkipDrawBackground = pGraphicsView->mSkipBackground;
    pGraphicsView->mSkipBackground = true;
    pGraphicsView->render(&painter, destinationRect, destinationRect);
    painter.end();
    pGraphicsView->mSkipBackground = oldSkipDrawBackground;
    if (!fileName.endsWith(".svg") && !copyToClipboard) {
      if (!modelImage.save(fileName)) {
        QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                              tr("Error saving the image file"), Helper::ok);
      }
    } else if (copyToClipboard) {
      QClipboard *pClipboard = QApplication::clipboard();
      pClipboard->setImage(modelImage);
    }
    // hide the progressbar and clear the message in status bar
    mpStatusBar->clearMessage();
    hideProgressBar();
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                .arg(tr("exporting to Image")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

/*!
  Slot activated when mpExportToClipboardAction triggered signal is raised.\n
  Copies the current model to clipboard.
  */
void MainWindow::exportToClipboard()
{
  exportModelAsImage(true);
}

/*!
 * \brief MainWindow::fetchInterfaceData
 * Slot activated when mpFetchInterfaceDataAction triggered signal is raised.
 * Calls the function that fetches the interface data.
 */
void MainWindow::fetchInterfaceData()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    fetchInterfaceData(pModelWidget->getLibraryTreeItem());
  }
}

/*!
 * \brief MainWindow::TLMSimulate
 * Slot activated when mpTLMSimulateAction triggered signal is raised.
 * Calls the function that starts the TLM simulation.
 */
void MainWindow::TLMSimulate()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    TLMSimulate(pModelWidget->getLibraryTreeItem());
  }
}

/*!
 * \brief MainWindow::instantiateOMSModel
 * Slot activated when mpOMSInstantiateModelAction triggered signal is raised.
 * Calls MainWindow::instantiateOMSModel(LibraryTreeItem*)
 * \param checked
 */
void MainWindow::instantiateOMSModel(bool checked)
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    instantiateOMSModel(pModelWidget->getLibraryTreeItem(), checked);
  }
}

/*!
 * \brief MainWindow::simulateOMSModel
 * Slot activated when mpOMSSimulationSetupAction triggered signal is raised.
 * Calls MainWindow::simulateOMSModel(LibraryTreeItem*)
 */
void MainWindow::simulateOMSModel()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    simulateOMSModel(pModelWidget->getLibraryTreeItem());
  }
}

/*!
 * \brief MainWindow::showOMSArchivedSimulations
 * Shows the archived simulations.
 */
void MainWindow::showOMSArchivedSimulations()
{
  if (!mpOMSSimulationDialog) {
    mpOMSSimulationDialog = new OMSSimulationDialog(this);
  }
  mpOMSSimulationDialog->show();
}

/*!
 * \brief MainWindow::openWorkingDirectory
 * Opens the current working directory.
 */
void MainWindow::openWorkingDirectory()
{
  QUrl workingDirectory (QString("file:///%1").arg(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory()));
  if (!QDesktopServices::openUrl(workingDirectory)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(workingDirectory.toString()),
                                                Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief MainWindow::openTerminal
 * Opens the terminal.
 */
void MainWindow::openTerminal()
{
  QString terminalCommand = OptionsDialog::instance()->getGeneralSettingsPage()->getTerminalCommand();
  if (terminalCommand.isEmpty()) {
    QString message = GUIMessages::getMessage(GUIMessages::TERMINAL_COMMAND_NOT_SET).arg(Helper::toolsOptionsPath);
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, message, Helper::scriptingKind,
                                                Helper::errorLevel));
    return;
  }
  QString arguments = OptionsDialog::instance()->getGeneralSettingsPage()->getTerminalCommandArguments();
  QStringList args = arguments.split(" ");
  if (!QProcess::startDetached(terminalCommand, args, OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory())) {
    QString errorString = tr("Unable to run terminal command <b>%1</b> with arguments <b>%2</b>.").arg(terminalCommand).arg(arguments);
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, errorString, Helper::scriptingKind,
                                                Helper::errorLevel));
  }
}

/*!
 * \brief MainWindow::openConfigurationOptions
 * Slot activated when mpOptionsAction triggered signal is raised.
 * Shows the OptionsDialog
 */
void MainWindow::openConfigurationOptions()
{
  OptionsDialog::instance()->show();
}

/*!
 * \brief MainWindow::openUsersGuide
 * Slot activated when mpUsersGuideAction triggered signal is raised.\n
 * Opens the html based version of OpenModelica users guide.
 */
void MainWindow::openUsersGuide()
{
  QUrl usersGuidePath (QString("file:///").append(QString(Helper::OpenModelicaHome).replace("\\", "/"))
                       .append("/share/doc/omc/OpenModelicaUsersGuide/index.html"));
  if (!QDesktopServices::openUrl(usersGuidePath)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(usersGuidePath.toString()),
                                                Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief MainWindow::openUsersGuideNewPdf
 * Slot activated when mpUsersGuideNewPdfAction triggered signal is raised.\n
 * Opens the new pdf versions of OpenModelica users guide.
 */
void MainWindow::openUsersGuidePdf()
{
  QUrl usersGuidePath (QString("file:///").append(QString(Helper::OpenModelicaHome).replace("\\", "/"))
                       .append("/share/doc/omc/OpenModelicaUsersGuide-latest.pdf"));
  if (!QDesktopServices::openUrl(usersGuidePath)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(usersGuidePath.toString()),
                                                Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief MainWindow::openUsersGuideOldPdf
 * Slot activated when mpUsersGuideOldPdfAction triggered signal is raised.\n
 * Opens the old pdf versions of OpenModelica users guide.
 */
void MainWindow::openUsersGuideOldPdf()
{
  QUrl usersGuidePath (QString("file:///").append(QString(Helper::OpenModelicaHome).replace("\\", "/"))
                       .append("/share/doc/omc/OpenModelicaUsersGuide.pdf"));
  if (!QDesktopServices::openUrl(usersGuidePath)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(usersGuidePath.toString()),
                                                Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief MainWindow::openSystemDocumentation
 * Slot activated when mpSystemDocumentationAction triggered signal is raised.\n
 * Opens the OpenModelica system documentation.
 */
void MainWindow::openSystemDocumentation()
{
  QUrl systemDocumentationPath (QString("file:///").append(QString(Helper::OpenModelicaHome).replace("\\", "/"))
                                .append("/share/doc/omc/SystemDocumentation/OpenModelicaSystem.pdf"));
  if (!QDesktopServices::openUrl(systemDocumentationPath)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(systemDocumentationPath.toString()),
                                                Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief MainWindow::openOpenModelicaScriptingDocumentation
 * Opens the OpenModelica scripting documentation.
 */
void MainWindow::openOpenModelicaScriptingDocumentation()
{
  QUrl openModelicaScriptingUrl (QUrl("https://build.openmodelica.org/Documentation/OpenModelica.Scripting.html"));
  QDesktopServices::openUrl(openModelicaScriptingUrl);
}

/*!
 * \brief MainWindow::openModelicaDocumentation
 * Opens the Modelica documentation.
 */
void MainWindow::openModelicaDocumentation()
{
  QUrl modelicaDocumentationUrl (QUrl("https://build.openmodelica.org/Documentation/index.html"));
  QDesktopServices::openUrl(modelicaDocumentationUrl);
}

void MainWindow::openModelicaByExample()
{
  QUrl modelicaByExampleUrl (QUrl("http://book.xogeny.com"));
  QDesktopServices::openUrl(modelicaByExampleUrl);
}

void MainWindow::openModelicaWebReference()
{
  QUrl modelicaWebReference (QUrl("http://modref.xogeny.com"));
  QDesktopServices::openUrl(modelicaWebReference);
}

/*!
 * \brief MainWindow::openOMSimulatorUsersGuide
 * Opens the OMSimulator Users Guide.
 */
void MainWindow::openOMSimulatorUsersGuide()
{
  QUrl OMSimulatorUsersGuideUrl (QString("https://openmodelica.org/doc/OMSimulator/master/html/"));
  QDesktopServices::openUrl(OMSimulatorUsersGuideUrl);
}

/*!
 * \brief MainWindow::openOpenModelicaTLMSimulatorDocumentation
 * Opens the OpenModelica TLM Simulator documentation.
 */
void MainWindow::openOpenModelicaTLMSimulatorDocumentation()
{
  QUrl openModelicaTLMSimulatorDocumentation (QString("file:///").append(QString(Helper::OpenModelicaHome).replace("\\", "/"))
                                              .append("/OMTLMSimulator/Documentation/OMTLMSimulator.pdf"));
  if (!QDesktopServices::openUrl(openModelicaTLMSimulatorDocumentation)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE)
                                                          .arg(openModelicaTLMSimulatorDocumentation.toString()),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
}

void MainWindow::openAboutOMEdit()
{
  AboutOMEditDialog *pAboutOMEditDialog = new AboutOMEditDialog(this);
  pAboutOMEditDialog->exec();
}

void MainWindow::toggleShapesButton()
{
  QAction *clickedAction = qobject_cast<QAction*>(const_cast<QObject*>(sender()));
  QList<QAction*> shapeActions = mpShapesActionGroup->actions();
  foreach (QAction *shapeAction, shapeActions) {
    if (shapeAction != clickedAction) {
      shapeAction->setChecked(false);
    }
  }
  // cancel connection if another tool is chosen
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    GraphicsView *pGraphicsView = pModelWidget->getDiagramGraphicsView();
    if (pGraphicsView->isCreatingConnection()) {
      pGraphicsView->removeCurrentConnection();
    }
    if (pGraphicsView->isCreatingTransition()) {
      pGraphicsView->removeCurrentTransition();
    }
  }
}

/*!
 * \brief MainWindow::openRecentModelWidget
 * Slot activated when mpModelSwitcherActions triggered SIGNAL is raised.\n
 * Before switching to new ModelWidget try to update the class contents if user has changed anything.
 */
void MainWindow::openRecentModelWidget()
{
  /* if Model text is changed manually by user then validate it before opening recent ModelWidget. */
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
    LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
    if (!pModelWidget->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  QAction *pAction = qobject_cast<QAction*>(sender());
  QToolButton *pToolButton = qobject_cast<QToolButton*>(sender());
  LibraryTreeItem *pLibraryTreeItem;
  if (pAction) {
    pLibraryTreeItem = mpLibraryWidget->getLibraryTreeModel()->findLibraryTreeItem(pAction->data().toString());
    mpModelWidgetContainer->addModelWidget(pLibraryTreeItem->getModelWidget(), false);
  } else if (pToolButton && mpModelSwitcherActions[0]->isVisible()) {
    pLibraryTreeItem = mpLibraryWidget->getLibraryTreeModel()->findLibraryTreeItem(mpModelSwitcherActions[0]->data().toString());
    mpModelWidgetContainer->addModelWidget(pLibraryTreeItem->getModelWidget(), false);
  }
}

void MainWindow::updateModelSwitcherMenu(QMdiSubWindow *pActivatedWindow)
{
  Q_UNUSED(pActivatedWindow);
  // get list of opened Model Widgets
  QList<QMdiSubWindow*> subWindowsList = mpModelWidgetContainer->subWindowList(QMdiArea::ActivationHistoryOrder);
  // remove the current active ModelWidget from the list.
  if (!subWindowsList.isEmpty()) {
    subWindowsList.removeLast();
    mpModelSwitcherToolButton->setEnabled(true);
  }
  // if there is no other ModelWidgets then disable the ModelSwitcher button.
  if (subWindowsList.isEmpty()) {
    mpModelSwitcherToolButton->setEnabled(false);
    return;
  }
  int j = 0;
  for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
    if (j >= MaxRecentFiles) {
      break;
    }
    ModelWidget *pModelWidget = qobject_cast<ModelWidget*>(subWindowsList.at(i)->widget());
    if (pModelWidget) {
      mpModelSwitcherActions[j]->setText(pModelWidget->getLibraryTreeItem()->getNameStructure());
      mpModelSwitcherActions[j]->setData(pModelWidget->getLibraryTreeItem()->getNameStructure());
      mpModelSwitcherActions[j]->setVisible(true);
    }
    j++;
  }
  // if subwindowlist size is less than MaxRecentFiles then hide the remaining actions
  int numRecentModels = qMin(subWindowsList.size(), (int)MaxRecentFiles);
  for (j = numRecentModels ; j < MaxRecentFiles ; j++) {
    mpModelSwitcherActions[j]->setVisible(false);
  }
}

/*!
 * \brief MainWindow::runDebugConfiguration
 * Runs the
 */
void MainWindow::runDebugConfiguration()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  QToolButton *pToolButton = qobject_cast<QToolButton*>(sender());
  if (pAction) {
    pAction = pAction;
  } else if (pToolButton) {
    QList<QAction *> actions = mpDebugConfigurationMenu->actions();
    // read the settings and add debug configurations
    QSettings *pSettings = Utilities::getApplicationSettings();
    QList<QVariant> debugConfigurations = pSettings->value("debuggerConfigurationList/configurations").toList();
    if (debugConfigurations.size() > 0) {
      pAction = actions[0];
    } else {
      showDebugConfigurationsDialog();
      return;
    }
  }
  if (pAction) {
    DebuggerConfigurationsDialog *pDebuggerConfigurationsDialog = new DebuggerConfigurationsDialog(this);
    connect(pDebuggerConfigurationsDialog, SIGNAL(debuggerLaunched()), SLOT(switchToAlgorithmicDebuggingPerspectiveSlot()));
    DebuggerConfigurationPage* pDebuggerConfigurationPage = pDebuggerConfigurationsDialog->getDebuggerConfigurationPage(pAction->text());
    if (pDebuggerConfigurationPage) {
      pDebuggerConfigurationsDialog->runConfiguration(pDebuggerConfigurationPage);
    }
    pDebuggerConfigurationsDialog->deleteLater();
  }
}

/*!
 * \brief MainWindow::updateDebuggerToolBarMenu
 * Updates the debugger toolbar menu.
 */
void MainWindow::updateDebuggerToolBarMenu()
{
  mpDebugConfigurationMenu->clear();
  // read the settings and add debug configurations
  QSettings *pSettings = Utilities::getApplicationSettings();
  /* If user doesn't have the key debuggerConfigurationList/configurations
   * it means the debug configurations are save in old format.
   * Makesure we update it to new list format here.
   */
  if (!pSettings->contains("debuggerConfigurationList/configurations")) {
    pSettings->beginGroup("debuggerConfigurationList");
    QStringList configurationKeys = pSettings->childKeys();
    QList<QVariant> debugConfigurations;
    foreach (QString configurationKey, configurationKeys) {
      debugConfigurations.append(pSettings->value(configurationKey));
    }
    // Once all the debug configurations moved to new list format then clear the old ones.
    pSettings->remove(""); // calling remove with empty string will remove all keys in the current group.
    pSettings->setValue("configurations", debugConfigurations);
    pSettings->endGroup();
  }
  QList<QVariant> debugConfigurations = pSettings->value("debuggerConfigurationList/configurations").toList();
  foreach (QVariant configuration, debugConfigurations) {
    DebuggerConfiguration debugConfiguration = qvariant_cast<DebuggerConfiguration>(configuration);
    QAction *pAction = new QAction(mpDebugConfigurationMenu);
    pAction->setText(debugConfiguration.name);
    connect(pAction, SIGNAL(triggered()), SLOT(runDebugConfiguration()));
    mpDebugConfigurationMenu->addAction(pAction);
  }
  if (debugConfigurations.size() > 0) {
    mpDebugConfigurationMenu->addSeparator();
  }
  mpDebugConfigurationMenu->addAction(mpDebugConfigurationsAction);
  mpDebugConfigurationMenu->addAction(mpAttachDebuggerToRunningProcessAction);
}

/*!
 * \brief MainWindow::toggleAutoSave
 * Start/Stop the auto save timer based on the settings.
 */
void MainWindow::toggleAutoSave()
{
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getEnableAutoSaveGroupBox()->isChecked()) {
    mpAutoSaveTimer->start();
  } else {
    mpAutoSaveTimer->stop();
  }
}

/*!
 * \brief MainWindow::readInterfaceData
 * \param pLibraryTreeItem
 * Reads the interface data by reading the interfaceData.xml file and updates the meta-model text.
 */
void MainWindow::readInterfaceData(LibraryTreeItem *pLibraryTreeItem)
{
  if (!pLibraryTreeItem) {
    return;
  }

  FetchInterfaceDataDialog *pDialog = qobject_cast<FetchInterfaceDataDialog*>(sender());
  QString singleModel = pDialog->getSingleModel();

  QFileInfo fileInfo(pLibraryTreeItem->getFileName());
  QFile file(fileInfo.absoluteDir().absolutePath()+ "/interfaceData.xml");
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg("interfaceData.xml")
                          .arg(file.errorString()), Helper::ok);
  } else {
    QDomDocument modelDataDocument;
    modelDataDocument.setContent(&file);
    file.close();
    // Get the interfaces element
    QDomElement modelData, interfaces,parameters;
    modelData = modelDataDocument.documentElement();
    interfaces = modelData.firstChildElement("Interfaces");
    parameters = modelData.firstChildElement("Parameters");
    if(interfaces.isNull() && parameters.isNull()) {
        interfaces = modelDataDocument.documentElement();   //Backwards compatibility, remove later /Robert
    }

    // if we don't have ModelWidget then show it.
    if (!pLibraryTreeItem->getModelWidget()) {
      mpLibraryWidget->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
    }
    CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(pLibraryTreeItem->getModelWidget()->getEditor());
    pCompositeModelEditor->addInterfacesData(interfaces, parameters, singleModel);
    pLibraryTreeItem->getModelWidget()->updateModelText();
  }
}

/*!
 * \brief MainWindow::enableReSimulationToolbar
 * * Handles the VisibilityChanged signal of Variables Dock Widget.
 * \param visible
 */
void MainWindow::enableReSimulationToolbar(bool visible)
{
  mpReSimulationToolBar->setVisible(visible);
  if (visible) {
    mpReSimulationToolBar->setEnabled(!mpVariablesWidget->getVariablesTreeView()->selectionModel()->selectedIndexes().isEmpty());
  } else {
    mpReSimulationToolBar->setEnabled(false);
  }
}

/*!
 * \brief MainWindow::perspectiveTabChanged
 * Handles the perspective tab changed case.
 * \param tabIndex
 */
void MainWindow::perspectiveTabChanged(int tabIndex)
{
  switch (tabIndex) {
    case 0:
      switchToWelcomePerspective();
      break;
    case 1:
      switchToModelingPerspective();
      break;
    case 2:
      switchToPlottingPerspective();
      break;
    case 3:
      switchToAlgorithmicDebuggingPerspective();
      break;
    default:
      switchToWelcomePerspective();
      break;
  }
}

/*!
 * \brief MainWindow::documentationDockWidgetVisibilityChanged
 * Handles the VisibilityChanged signal of Documentation Dock Widget.
 * \param visible
 */
void MainWindow::documentationDockWidgetVisibilityChanged(bool visible)
{
  if (visible) {
    ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
    if (pModelWidget && pModelWidget->getLibraryTreeItem() &&
        pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
      LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
      if (pModelWidget->validateText(&pLibraryTreeItem)) {
        mpDocumentationWidget->showDocumentation(pLibraryTreeItem);
      }
    }
  }
}

/*!
 * \brief MainWindow::threeDViewerDockWidgetVisibilityChanged
 * Handles the VisibilityChanged signal of ThreeDViewer Dock Widget.
 * \param visible
 */
void MainWindow::threeDViewerDockWidgetVisibilityChanged(bool visible)
{
#if !defined(WITHOUT_OSG)
  if (visible) {
    getThreeDViewer()->getViewerWidget()->update();
  }
#else
  Q_UNUSED(visible);
#endif
}

/*!
 * \brief MainWindow::autoSave
 * Slot activated when mpAutoSaveTimer timeout SIGNAL is raised.\n
 * Auto saves the classes which user has alreadys saved to a file. Classes not saved to a file are not saved.
 */
void MainWindow::autoSave()
{
  autoSaveHelper(mpLibraryWidget->getLibraryTreeModel()->getRootLibraryTreeItem());
}

/*!
 * \brief MainWindow::switchToWelcomePerspectiveSlot
 * Slot activated when Ctrl+f1 is clicked.
 * Switches to welcome perspective.
 */
void MainWindow::switchToWelcomePerspectiveSlot()
{
  mpPerspectiveTabbar->setCurrentIndex(0);
}

/*!
 * \brief MainWindow::switchToModelingPerspectiveSlot
 * Slot activated when Ctrl+f2 is clicked.
 * Switches to modeling perspective.
 */
void MainWindow::switchToModelingPerspectiveSlot()
{
  mpPerspectiveTabbar->setCurrentIndex(1);
}

/*!
 * \brief MainWindow::switchToPlottingPerspectiveSlot
 * Slot activated when Ctrl+f3 is clicked.
 * Switches to plotting perspective.
 */
void MainWindow::switchToPlottingPerspectiveSlot()
{
  mpPerspectiveTabbar->setCurrentIndex(2);
}

/*!
 * \brief MainWindow::switchToAlgorithmicDebuggingPerspectiveSlot
 * Slot activated when Ctrl+f5 is clicked.
 * Switches to algorithmic debugging perspective.
 */
void MainWindow::switchToAlgorithmicDebuggingPerspectiveSlot()
{
  mpPerspectiveTabbar->setCurrentIndex(3);
}

/*!
 * \brief MainWindow::showDebugConfigurationsDialog
 * Slot activated when mpDebugConfigurationsAction triggered signal is raised.\n
 * Shows the debugger configurations.
 */
void MainWindow::showDebugConfigurationsDialog()
{
  DebuggerConfigurationsDialog *pDebuggerConfigurationsDialog = new DebuggerConfigurationsDialog(this);
  connect(pDebuggerConfigurationsDialog, SIGNAL(debuggerLaunched()), SLOT(switchToAlgorithmicDebuggingPerspectiveSlot()));
  pDebuggerConfigurationsDialog->exec();
}

/*!
 * \brief MainWindow::showAttachToProcessDialog
 * Slot activated when mpAttachDebuggerToRunningProcessAction triggered signal is raised.\n
 * Shows the attach to process dialog.
 */
void MainWindow::showAttachToProcessDialog()
{
  AttachToProcessDialog *pAttachToProcessDialog = new AttachToProcessDialog(this);
  pAttachToProcessDialog->exec();
}

/*!
 * \brief MainWindow::createGitRepository
 * Slot activated when mpcreateGitRepositoryAction triggered signal is raised.\n
 * creates a git repository.
 */
void MainWindow::createGitRepository()
{
  QString gitRepositoryPath = StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseDirectory), NULL);
  if (gitRepositoryPath.isEmpty())
    return;
  GitCommands::instance()->createGitRepository(gitRepositoryPath);
}

/*!
 * \brief MainWindow::logCurrentFile
 * Slot activated when mplogCurrentFileAction triggered signal is raised.\n
 * Shows the commited history of the current file.
 */
void MainWindow::logCurrentFile()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
     GitCommands::instance()->logCurrentFile(pModelWidget->getLibraryTreeItem()->getFileName());
  }
}

/*!
 * \brief MainWindow::stageCurrentFileForCommit
 * Slot activated when mpstageCurrentFileForCommitAction triggered signal is raised.\n
 * Sstages the current file for the next commit.
 */
void MainWindow::stageCurrentFileForCommit()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
     GitCommands::instance()->stageCurrentFileForCommit(pModelWidget->getLibraryTreeItem()->getFileName());
  }
}

/*!
 * \brief MainWindow::unstageCurrentFileFromCommit
 * Slot activated when mpunstageCurrentFileFromCommitAction triggered signal is raised.\n
 * unSstages the current file from the next commit.
 */
void MainWindow::unstageCurrentFileFromCommit()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
     GitCommands::instance()->unstageCurrentFileFromCommit(pModelWidget->getLibraryTreeItem()->getFileName());
  }
}

/*!
 * \brief MainWindow::commitFiles
 * Slot activated when mpcommitFilesaction triggered signal is raised.\n
 * commites modified files to git repository.
 */
void MainWindow::commitFiles()
{
  CommitChangesDialog *pCommitChangesDialog = new CommitChangesDialog(this);
  pCommitChangesDialog->exec();
}

/*!
 * \brief MainWindow::revertCommit
 * Slot activated when mpRevertCommitAction triggered signal is raised.\n
 * reverts previous commit.
 */
void MainWindow::revertCommit()
{
  RevertCommitsDialog *pRevertCommitsDialog = new RevertCommitsDialog(this);
  pRevertCommitsDialog->exec();
}

/*!
 * \brief MainWindow::cleanWorkingDirectory
 * Slot activated when mpCleanWorkingDirectoryAction triggered signal is raised.\n
 */
void MainWindow::cleanWorkingDirectory()
{
  CleanDialog *pCleanDialog = new CleanDialog(this);
  pCleanDialog->exec();
//  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
//  if (pModelWidget) {
//     mpGitCommands->cleanWorkingDirectory();
//  }
}


//! Defines the actions used by the toolbars
void MainWindow::createActions()
{
  mpSearchBrowserShortcut = new QShortcut(QKeySequence("Ctrl+h"), this);
  connect(mpSearchBrowserShortcut, SIGNAL(activated()), SLOT(showSearchBrowser()));
  /* Menu Actions */
  // File Menu
  // create new Modelica class action
  mpNewModelicaClassAction = new QAction(QIcon(":/Resources/icons/new.svg"), Helper::newModelicaClass, this);
  mpNewModelicaClassAction->setStatusTip(Helper::createNewModelicaClass);
  mpNewModelicaClassAction->setShortcut(QKeySequence("Ctrl+n"));
  connect(mpNewModelicaClassAction, SIGNAL(triggered()), SLOT(createNewModelicaClass()));
  // open Modelica file action
  mpOpenModelicaFileAction = new QAction(QIcon(":/Resources/icons/open.svg"), Helper::openModelicaFiles, this);
  mpOpenModelicaFileAction->setShortcut(QKeySequence("Ctrl+o"));
  mpOpenModelicaFileAction->setStatusTip(tr("Opens the Modelica file(s)"));
  connect(mpOpenModelicaFileAction, SIGNAL(triggered()), SLOT(openModelicaFile()));
  // open Modelica file with encoding action
  mpOpenModelicaFileWithEncodingAction = new QAction(Helper::openConvertModelicaFiles, this);
  mpOpenModelicaFileWithEncodingAction->setStatusTip(tr("Opens and converts the Modelica file(s) with encoding"));
  connect(mpOpenModelicaFileWithEncodingAction, SIGNAL(triggered()), SLOT(showOpenModelicaFileDialog()));
  // load Modelica library action
  mpLoadModelicaLibraryAction = new QAction(tr("Load Library"), this);
  mpLoadModelicaLibraryAction->setStatusTip(tr("Loads the Modelica library"));
  connect(mpLoadModelicaLibraryAction, SIGNAL(triggered()), SLOT(loadModelicaLibrary()));
  // load encrypted library action
  mpLoadEncryptedLibraryAction = new QAction(tr("Load Encrypted Library"), this);
  mpLoadEncryptedLibraryAction->setStatusTip(tr("Loads the encrypted Modelica library"));
  connect(mpLoadEncryptedLibraryAction, SIGNAL(triggered()), SLOT(loadEncryptedLibrary()));
  // open result file action
  mpOpenResultFileAction = new QAction(tr("Open Result File(s)"), this);
  mpOpenResultFileAction->setShortcut(QKeySequence("Ctrl+shift+o"));
  mpOpenResultFileAction->setStatusTip(tr("Opens the OpenModelica Result file"));
  connect(mpOpenResultFileAction, SIGNAL(triggered()), SLOT(showOpenResultFileDialog()));
  // open transformations file action
  mpOpenTransformationFileAction = new QAction(tr("Open Transformations File"), this);
  mpOpenTransformationFileAction->setStatusTip(tr("Opens the class transformations file"));
  connect(mpOpenTransformationFileAction, SIGNAL(triggered()), SLOT(showOpenTransformationFileDialog()));
  // create new CompositeModel action
  mpNewCompositeModelFileAction = new QAction(QIcon(":/Resources/icons/new.svg"), tr("New Composite Model"), this);
  mpNewCompositeModelFileAction->setStatusTip(tr("Create New Composite Model file"));
  connect(mpNewCompositeModelFileAction, SIGNAL(triggered()), SLOT(createNewCompositeModelFile()));
  // open CompositeModel file action
  mpOpenCompositeModelFileAction = new QAction(QIcon(":/Resources/icons/open.svg"), tr("Open Composite Model(s)"), this);
  mpOpenCompositeModelFileAction->setStatusTip(tr("Opens the Composite Model file(s)"));
  connect(mpOpenCompositeModelFileAction, SIGNAL(triggered()), SLOT(openCompositeModelFile()));
  // load External Model action
  mpLoadExternModelAction = new QAction(tr("Load External Model(s)"), this);
  mpLoadExternModelAction->setStatusTip(tr("Loads the External Model(s) for the TLM co-simulation"));
  connect(mpLoadExternModelAction, SIGNAL(triggered()), SLOT(loadExternalModels()));
  // create new OMSimulator Model action
  mpNewOMSimulatorModelAction = new QAction(QIcon(":/Resources/icons/new.svg"), Helper::newModel, this);
  mpNewOMSimulatorModelAction->setStatusTip(tr("Creates a new OMSimulator Model"));
  mpNewOMSimulatorModelAction->setShortcut(QKeySequence("Ctrl+t"));
  connect(mpNewOMSimulatorModelAction, SIGNAL(triggered()), SLOT(createNewOMSModel()));
  // open OMSimulator Model file action
  mpOpenOMSModelFileAction = new QAction(QIcon(":/Resources/icons/open.svg"), tr("Open OMSimulator Model(s)"), this);
  mpOpenOMSModelFileAction->setStatusTip(tr("Opens the OMSimulator model file(s)"));
  connect(mpOpenOMSModelFileAction, SIGNAL(triggered()), SLOT(openOMSModelFile()));
  // open the directory action
  mpOpenDirectoryAction = new QAction(tr("Open Directory"), this);
  mpOpenDirectoryAction->setStatusTip(tr("Opens the directory"));
  connect(mpOpenDirectoryAction, SIGNAL(triggered()), SLOT(openDirectory()));
  // save file action
  mpSaveAction = new QAction(QIcon(":/Resources/icons/save.svg"), Helper::save, this);
  mpSaveAction->setShortcut(QKeySequence("Ctrl+s"));
  mpSaveAction->setStatusTip(Helper::saveTip);
  mpSaveAction->setEnabled(false);
  // save as file action
  mpSaveAsAction = new QAction(QIcon(":/Resources/icons/saveas.svg"), Helper::saveAs, this);
  mpSaveAsAction->setStatusTip(Helper::saveAsTip);
  mpSaveAsAction->setEnabled(false);
  // save all file action
  mpSaveAllAction = new QAction(QIcon(":/Resources/icons/saveall.svg"), tr("Save All"), this);
  mpSaveAllAction->setStatusTip(tr("Save All Files"));
  mpSaveAllAction->setEnabled(false);
  // Save Total action
  mpSaveTotalAction = new QAction(Helper::saveTotal, this);
  mpSaveTotalAction->setStatusTip(Helper::saveTotalTip);
  mpSaveTotalAction->setEnabled(false);
  // import FMU action
  mpImportFMUAction = new QAction(QIcon(":/Resources/icons/import-fmu.svg"), Helper::FMU, this);
  mpImportFMUAction->setStatusTip(Helper::importFMUTip);
  connect(mpImportFMUAction, SIGNAL(triggered()), SLOT(importModelFMU()));
  // import FMU model description action
  mpImportFMUModelDescriptionAction = new QAction(tr("FMU Model Description"), this);
  mpImportFMUModelDescriptionAction->setStatusTip(tr("Imports the model from Functional Mockup Interface (FMU) model description"));
  connect(mpImportFMUModelDescriptionAction, SIGNAL(triggered()), SLOT(importFMUModelDescription()));
  // import from OMNotebook action
  mpImportFromOMNotebookAction = new QAction(QIcon(":/Resources/icons/import-omnotebook.svg"), tr("From OMNotebook"), this);
  mpImportFromOMNotebookAction->setStatusTip(Helper::importFromOMNotebookTip);
  connect(mpImportFromOMNotebookAction, SIGNAL(triggered()), SLOT(importModelfromOMNotebook()));
  // import ngspice netlist action
  mpImportNgspiceNetlistAction = new QAction(tr("Ngspice netlist"), this);
  mpImportNgspiceNetlistAction->setStatusTip(Helper::importNgspiceNetlistTip);
  connect(mpImportNgspiceNetlistAction, SIGNAL(triggered()), SLOT(importNgspiceNetlist()));
  // export to clipboard action
  mpExportToClipboardAction = new QAction(tr("To Clipboard"), this);
  mpExportToClipboardAction->setStatusTip(Helper::exportAsImageTip);
  connect(mpExportToClipboardAction, SIGNAL(triggered()), SLOT(exportToClipboard()));
  // export as image action
  mpExportAsImageAction = new QAction(QIcon(":/Resources/icons/bitmap-shape.svg"), tr("Image"), this);
  mpExportAsImageAction->setStatusTip(Helper::exportAsImageTip);
  connect(mpExportAsImageAction, SIGNAL(triggered()), SLOT(exportModelAsImage()));
  // export FMU action
  mpExportFMUAction = new QAction(QIcon(":/Resources/icons/export-fmu.svg"), Helper::FMU, this);
  mpExportFMUAction->setStatusTip(Helper::exportFMUTip);
  mpExportFMUAction->setEnabled(false);
  connect(mpExportFMUAction, SIGNAL(triggered()), SLOT(exportModelFMU()));
  // export read-only package action
  mpExportReadonlyPackageAction = new QAction(Helper::exportReadonlyPackage, this);
  mpExportReadonlyPackageAction->setStatusTip(Helper::exportRealonlyPackageTip);
  connect(mpExportReadonlyPackageAction, SIGNAL(triggered()), SLOT(exportReadonlyPackage()));
  // export encrypted package action
  mpExportEncryptedPackageAction = new QAction(Helper::exportEncryptedPackage, this);
  mpExportEncryptedPackageAction->setStatusTip(Helper::exportEncryptedPackageTip);
  connect(mpExportEncryptedPackageAction, SIGNAL(triggered()), SLOT(exportEncryptedPackage()));
  // export XML action
  mpExportXMLAction = new QAction(QIcon(":/Resources/icons/export-xml.svg"), Helper::exportXML, this);
  mpExportXMLAction->setStatusTip(Helper::exportXMLTip);
  mpExportXMLAction->setEnabled(false);
  connect(mpExportXMLAction, SIGNAL(triggered()), SLOT(exportModelXML()));
  // export XML action
  mpExportFigaroAction = new QAction(QIcon(":/Resources/icons/console.svg"), tr("Figaro"), this);
  mpExportFigaroAction->setStatusTip(Helper::exportFigaroTip);
  mpExportFigaroAction->setEnabled(false);
  connect(mpExportFigaroAction, SIGNAL(triggered()), SLOT(exportModelFigaro()));
  // export to OMNotebook action
  mpExportToOMNotebookAction = new QAction(QIcon(":/Resources/icons/export-omnotebook.svg"), tr("To OMNotebook"), this);
  mpExportToOMNotebookAction->setStatusTip(Helper::exportToOMNotebookTip);
  mpExportToOMNotebookAction->setEnabled(false);
  connect(mpExportToOMNotebookAction, SIGNAL(triggered()), SLOT(exportModelToOMNotebook()));
  // recent files action
  for (int i = 0; i < MaxRecentFiles; ++i) {
    mpRecentFileActions[i] = new QAction(this);
    mpRecentFileActions[i]->setVisible(false);
    connect(mpRecentFileActions[i], SIGNAL(triggered()), this, SLOT(openRecentFile()));
  }
  // clear recent files action
  mpClearRecentFilesAction = new QAction(Helper::clearRecentFiles, this);
  mpClearRecentFilesAction->setStatusTip(tr("Clears the recent files list"));
  connect(mpClearRecentFilesAction, SIGNAL(triggered()), SLOT(clearRecentFilesList()));
  // print  action
  mpPrintModelAction = new QAction(QIcon(":/Resources/icons/print.svg"), tr("Print..."), this);
  mpPrintModelAction->setShortcut(QKeySequence("Ctrl+p"));
  // close OMEdit action
  mpQuitAction = new QAction(QIcon(":/Resources/icons/quit.svg"), tr("Quit"), this);
  mpQuitAction->setStatusTip(tr("Quit the ").append(Helper::applicationIntroText));
  mpQuitAction->setShortcut(QKeySequence("Ctrl+q"));
  mpQuitAction->setMenuRole(QAction::QuitRole);
  connect(mpQuitAction, SIGNAL(triggered()), SLOT(close()));
  // Edit Menu
  // undo action
  mpUndoAction = new QAction(QIcon(":/Resources/icons/undo.svg"), tr("Undo"), this);
  mpUndoAction->setShortcut(QKeySequence::Undo);
  mpUndoAction->setEnabled(false);
  connect(mpUndoAction, SIGNAL(triggered()), SLOT(undo()));
  // redo action
  mpRedoAction = new QAction(QIcon(":/Resources/icons/redo.svg"), tr("Redo"), this);
  mpRedoAction->setShortcut(QKeySequence::Redo);
  mpRedoAction->setEnabled(false);
  connect(mpRedoAction, SIGNAL(triggered()), SLOT(redo()));
  // filter classes action
  mpFilterClassesAction = new QAction(Helper::filterClasses, this);
  mpFilterClassesAction->setShortcut(QKeySequence("Ctrl+Shift+f"));
  connect(mpFilterClassesAction, SIGNAL(triggered()), SLOT(focusFilterClasses()));
  // cut action
  mpCutAction = new QAction(QIcon(":/Resources/icons/cut.svg"), tr("Cut"), this);
  mpCutAction->setShortcut(QKeySequence("Ctrl+x"));
  // copy action
  mpCopyAction = new QAction(QIcon(":/Resources/icons/copy.svg"), Helper::copy, this);
  //! @todo opening this will stop copying data from messages window.
  //mpCopyAction->setShortcut(QKeySequence("Ctrl+c"));
  // paste action
  mpPasteAction = new QAction(QIcon(":/Resources/icons/paste.svg"), tr("Paste"), this);
  mpPasteAction->setShortcut(QKeySequence("Ctrl+v"));
  // View Menu
  // show/hide gridlines action
  mpShowGridLinesAction = new QAction(QIcon(":/Resources/icons/grid.svg"), tr("Grid Lines"), this);
  mpShowGridLinesAction->setStatusTip(tr("Show/Hide the grid lines"));
  mpShowGridLinesAction->setCheckable(true);
  mpShowGridLinesAction->setChecked(true);
  mpShowGridLinesAction->setEnabled(false);
  connect(mpShowGridLinesAction, SIGNAL(toggled(bool)), SLOT(setShowGridLines(bool)));
  // reset zoom action
  mpResetZoomAction = new QAction(QIcon(":/Resources/icons/zoomReset.svg"), Helper::resetZoom, this);
  mpResetZoomAction->setStatusTip(Helper::resetZoom);
  mpResetZoomAction->setShortcut(QKeySequence("Ctrl+0"));
  mpResetZoomAction->setEnabled(false);
  connect(mpResetZoomAction, SIGNAL(triggered()), SLOT(resetZoom()));
  // zoom in action
  mpZoomInAction = new QAction(QIcon(":/Resources/icons/zoomIn.svg"), Helper::zoomIn, this);
  mpZoomInAction->setStatusTip(Helper::zoomIn);
  mpZoomInAction->setShortcut(QKeySequence("Ctrl++"));
  mpZoomInAction->setEnabled(false);
  connect(mpZoomInAction, SIGNAL(triggered()), SLOT(zoomIn()));
  // zoom out action
  mpZoomOutAction = new QAction(QIcon(":/Resources/icons/zoomOut.svg"), Helper::zoomOut, this);
  mpZoomOutAction->setStatusTip(Helper::zoomOut);
  mpZoomOutAction->setShortcut(QKeySequence("Ctrl+-"));
  mpZoomOutAction->setEnabled(false);
  connect(mpZoomOutAction, SIGNAL(triggered()), SLOT(zoomOut()));
  // close window action
  mpCloseWindowAction = new QAction(tr("Close Window"), this);
  mpCloseWindowAction->setStatusTip(tr("Closes the active window"));
  connect(mpCloseWindowAction, SIGNAL(triggered()), SLOT(closeWindow()));
  // close all windows action
  mpCloseAllWindowsAction = new QAction(tr("Close All Windows"), this);
  mpCloseAllWindowsAction->setStatusTip(tr("Closes all windows"));
  connect(mpCloseAllWindowsAction, SIGNAL(triggered()), SLOT(closeAllWindows()));
  // close all windows but this action
  mpCloseAllWindowsButThisAction = new QAction(tr("Close All Windows But This"), this);
  mpCloseAllWindowsButThisAction->setStatusTip(tr("Closes all windows except active window"));
  connect(mpCloseAllWindowsButThisAction, SIGNAL(triggered()), SLOT(closeAllWindowsButThis()));
  // Cascade windows action
  mpCascadeWindowsAction = new QAction(tr("Cascade Windows"), this);
  mpCascadeWindowsAction->setStatusTip(tr("Arranges all the child windows in a cascade pattern"));
  connect(mpCascadeWindowsAction, SIGNAL(triggered()), SLOT(cascadeSubWindows()));
  // Tile windows Horizontally action
  mpTileWindowsHorizontallyAction = new QAction(tr("Tile Windows Horizontally"), this);
  mpTileWindowsHorizontallyAction->setStatusTip(tr("Arranges all child windows in a horizontally tiled pattern"));
  connect(mpTileWindowsHorizontallyAction, SIGNAL(triggered()), SLOT(tileSubWindowsHorizontally()));
  // Tile windows Vertically action
  mpTileWindowsVerticallyAction = new QAction(tr("Tile Windows Vertically"), this);
  mpTileWindowsVerticallyAction->setStatusTip(tr("Arranges all child windows in a vertically tiled pattern"));
  connect(mpTileWindowsVerticallyAction, SIGNAL(triggered()), SLOT(tileSubWindowsVertically()));
  // Toggle between tab or sub-window view
  mpToggleTabOrSubWindowView = new QAction(tr("Toggle Tab/Sub-window View"), this);
  mpToggleTabOrSubWindowView->setStatusTip(tr("Toggle between tab or sub-window view mode"));
  connect(mpToggleTabOrSubWindowView, SIGNAL(triggered()), SLOT(toggleTabOrSubWindowView()));
  // Simulation Menu
  // instantiate model action
  mpInstantiateModelAction = new QAction(QIcon(":/Resources/icons/flatmodel.svg"), tr("Instantiate Model"), this);
  mpInstantiateModelAction->setStatusTip(tr("Instantiates the modelica model"));
  mpInstantiateModelAction->setEnabled(false);
  connect(mpInstantiateModelAction, SIGNAL(triggered()), SLOT(instantiateModel()));
  // check model action
  mpCheckModelAction = new QAction(QIcon(":/Resources/icons/check.svg"), Helper::checkModel, this);
  mpCheckModelAction->setStatusTip(Helper::checkModelTip);
  mpCheckModelAction->setEnabled(false);
  connect(mpCheckModelAction, SIGNAL(triggered()), SLOT(checkModel()));
  // check all models action
  mpCheckAllModelsAction = new QAction(QIcon(":/Resources/icons/check-all.svg"), Helper::checkAllModels, this);
  mpCheckAllModelsAction->setStatusTip(Helper::checkAllModelsTip);
  mpCheckAllModelsAction->setEnabled(false);
  connect(mpCheckAllModelsAction, SIGNAL(triggered()), SLOT(checkAllModels()));
  // simulate action
  mpSimulateModelAction = new QAction(QIcon(":/Resources/icons/simulate.svg"), Helper::simulate, this);
  mpSimulateModelAction->setStatusTip(Helper::simulateTip);
  mpSimulateModelAction->setEnabled(false);
  connect(mpSimulateModelAction, SIGNAL(triggered()), SLOT(simulateModel()));
  // simulate with transformational debugger action
  mpSimulateWithTransformationalDebuggerAction = new QAction(QIcon(":/Resources/icons/simulate-equation.svg"), Helper::simulateWithTransformationalDebugger, this);
  mpSimulateWithTransformationalDebuggerAction->setStatusTip(Helper::simulateWithTransformationalDebuggerTip);
  mpSimulateWithTransformationalDebuggerAction->setEnabled(false);
  connect(mpSimulateWithTransformationalDebuggerAction, SIGNAL(triggered()), SLOT(simulateModelWithTransformationalDebugger()));
  // simulate with algorithmic debugger action
  mpSimulateWithAlgorithmicDebuggerAction = new QAction(QIcon(":/Resources/icons/simulate-debug.svg"), Helper::simulateWithAlgorithmicDebugger, this);
  mpSimulateWithAlgorithmicDebuggerAction->setStatusTip(Helper::simulateWithAlgorithmicDebuggerTip);
  mpSimulateWithAlgorithmicDebuggerAction->setEnabled(false);
  connect(mpSimulateWithAlgorithmicDebuggerAction, SIGNAL(triggered()), SLOT(simulateModelWithAlgorithmicDebugger()));
#if !defined(WITHOUT_OSG)
  // simulate with animation action
  mpSimulateWithAnimationAction = new QAction(QIcon(":/Resources/icons/simulate-animation.svg"), Helper::simulateWithAnimation, this);
  mpSimulateWithAnimationAction->setStatusTip(Helper::simulateWithAnimationTip);
  mpSimulateWithAnimationAction->setEnabled(false);
  connect(mpSimulateWithAnimationAction, SIGNAL(triggered()), SLOT(simulateModelWithAnimation()));
#endif
  // simulation setup action
  mpSimulationSetupAction = new QAction(QIcon(":/Resources/icons/simulation-center.svg"), Helper::simulationSetup, this);
  mpSimulationSetupAction->setStatusTip(Helper::simulationSetupTip);
  mpSimulationSetupAction->setEnabled(false);
  connect(mpSimulationSetupAction, SIGNAL(triggered()), SLOT(openSimulationDialog()));
  // Debug Menu
  // Debug configurations
  mpDebugConfigurationsAction = new QAction(Helper::debugConfigurations, this);
  mpDebugConfigurationsAction->setStatusTip(Helper::debugConfigurationsTip);
  connect(mpDebugConfigurationsAction, SIGNAL(triggered()), SLOT(showDebugConfigurationsDialog()));
  // attach debugger to process
  mpAttachDebuggerToRunningProcessAction = new QAction(Helper::attachToRunningProcess, this);
  mpAttachDebuggerToRunningProcessAction->setStatusTip(Helper::attachToRunningProcessTip);
  connect(mpAttachDebuggerToRunningProcessAction, SIGNAL(triggered()), SLOT(showAttachToProcessDialog()));
  // Git and traceability Menu
  // Create git repository action
  mpCreateGitRepositoryAction = new QAction(Helper::createGitReposiory, this);
  mpCreateGitRepositoryAction->setStatusTip(Helper::createGitReposioryTip);
  connect(mpCreateGitRepositoryAction, SIGNAL(triggered()), SLOT(createGitRepository()));
  // Log current file action
  mpLogCurrentFileAction = new QAction(Helper::logCurrentFile, this);
  mpLogCurrentFileAction->setStatusTip(Helper::logCurrentFileTip);
  mpLogCurrentFileAction->setEnabled(false);
  connect(mpLogCurrentFileAction, SIGNAL(triggered()), SLOT(logCurrentFile()));
  // Stage current file for commit action
  mpStageCurrentFileForCommitAction = new QAction(Helper::stageCurrentFileForCommit, this);
  mpStageCurrentFileForCommitAction->setStatusTip(Helper::stageCurrentFileForCommitTip);
  mpStageCurrentFileForCommitAction->setEnabled(false);
  connect(mpStageCurrentFileForCommitAction, SIGNAL(triggered()), SLOT(stageCurrentFileForCommit()));
  // Unstage current file from commit action
  mpUnstageCurrentFileFromCommitAction = new QAction(Helper::unstageCurrentFileFromCommit, this);
  mpUnstageCurrentFileFromCommitAction->setStatusTip(Helper::unstageCurrentFileFromCommitTip);
  mpUnstageCurrentFileFromCommitAction->setEnabled(false);
  connect(mpUnstageCurrentFileFromCommitAction, SIGNAL(triggered()), SLOT(unstageCurrentFileFromCommit()));
  // Commit action
  mpCommitFilesAction = new QAction(Helper::commitFiles, this);
  mpCommitFilesAction->setStatusTip(Helper::commitFilesTip);
  mpCommitFilesAction->setEnabled(false);
  connect(mpCommitFilesAction, SIGNAL(triggered()), SLOT(commitFiles()));
  // revert action
  mpRevertCommitAction = new QAction("Revert", this);
  // mpRevertCommitAction->setStatusTip(Helper::commitFilesTip);
  mpRevertCommitAction->setEnabled(false);
  connect(mpRevertCommitAction, SIGNAL(triggered()), SLOT(revertCommit()));
  // clean working directory action
  mpCleanWorkingDirectoryAction = new QAction("Clean", this);
  mpCleanWorkingDirectoryAction->setEnabled(false);
  connect(mpCleanWorkingDirectoryAction, SIGNAL(triggered()), SLOT(cleanWorkingDirectory()));
  // Tools Menu
  // show OMC Logger widget action
  mpShowOMCLoggerWidgetAction = new QAction(QIcon(":/Resources/icons/console.svg"), Helper::OpenModelicaCompilerCLI, this);
  mpShowOMCLoggerWidgetAction->setStatusTip(tr("Shows OpenModelica Compiler CLI"));
  connect(mpShowOMCLoggerWidgetAction, SIGNAL(triggered()), mpOMCProxy, SLOT(openOMCLoggerWidget()));
  // show OpenModelica command prompt action
  mpShowOpenModelicaCommandPromptAction = new QAction(QIcon(":/Resources/icons/console.svg"), tr("OpenModelica Command Prompt"), this);
  mpShowOpenModelicaCommandPromptAction->setStatusTip(tr("Shows OpenModelica Compiler CLI"));
  connect(mpShowOpenModelicaCommandPromptAction, SIGNAL(triggered()), SLOT(showOpenModelicaCommandPrompt()));
  // show OMC Diff widget action
  if (isDebug()) {
    mpShowOMCDiffWidgetAction = new QAction(QIcon(":/Resources/icons/console.svg"), tr("OpenModelica Compiler Diff"), this);
    mpShowOMCDiffWidgetAction->setStatusTip(tr("Shows OpenModelica Compiler Diff"));
    connect(mpShowOMCDiffWidgetAction, SIGNAL(triggered()), mpOMCProxy, SLOT(openOMCDiffWidget()));
  }
  // open working directory action
  mpOpenWorkingDirectoryAction = new QAction(tr("Open Working Directory"), this);
  mpOpenWorkingDirectoryAction->setStatusTip(tr("Opens the current working directory"));
  connect(mpOpenWorkingDirectoryAction, SIGNAL(triggered()), SLOT(openWorkingDirectory()));
  // open terminal action
  mpOpenTerminalAction = new QAction(tr("Open Terminal"), this);
  mpOpenTerminalAction->setStatusTip(tr("Opens the terminal"));
  connect(mpOpenTerminalAction, SIGNAL(triggered()), SLOT(openTerminal()));
  // open options action
  mpOptionsAction = new QAction(QIcon(":/Resources/icons/options.svg"), tr("Options"), this);
  mpOptionsAction->setStatusTip(tr("Shows the options window"));
  mpOptionsAction->setMenuRole(QAction::PreferencesRole);
  connect(mpOptionsAction, SIGNAL(triggered()), SLOT(openConfigurationOptions()));
  // Help Menu
  // users guide action
  mpUsersGuideAction = new QAction(tr("OpenModelica Users Guide"), this);
  mpUsersGuideAction->setStatusTip(tr("Opens the OpenModelica Users Guide"));
  mpUsersGuideAction->setShortcut(QKeySequence(Qt::Key_F1));
  connect(mpUsersGuideAction, SIGNAL(triggered()), SLOT(openUsersGuide()));
  // users guide new pdf action
  mpUsersGuidePdfAction = new QAction(tr("OpenModelica Users Guide (PDF)"), this);
  mpUsersGuidePdfAction->setStatusTip(tr("Opens the OpenModelica Users Guide (PDF)"));
  connect(mpUsersGuidePdfAction, SIGNAL(triggered()), SLOT(openUsersGuidePdf()));
  // system documentation action
  mpSystemDocumentationAction = new QAction(tr("OpenModelica System Documentation"), this);
  mpSystemDocumentationAction->setStatusTip(tr("Opens the OpenModelica System Documentation"));
  connect(mpSystemDocumentationAction, SIGNAL(triggered()), SLOT(openSystemDocumentation()));
  // OpenModelica Scripting documentation action
  mpOpenModelicaScriptingAction = new QAction(tr("OpenModelica Scripting Documentation"), this);
  mpOpenModelicaScriptingAction->setStatusTip(tr("Opens the OpenModelica Scripting Documentation"));
  connect(mpOpenModelicaScriptingAction, SIGNAL(triggered()), SLOT(openOpenModelicaScriptingDocumentation()));
  // Modelica documentation action
  mpModelicaDocumentationAction = new QAction(tr("Modelica Documentation"), this);
  mpModelicaDocumentationAction->setStatusTip(tr("Opens the Modelica Documentation"));
  connect(mpModelicaDocumentationAction, SIGNAL(triggered()), SLOT(openModelicaDocumentation()));
  // Modelica By Example action
  mpModelicaByExampleAction = new QAction(tr("Modelica By Example"), this);
  mpModelicaByExampleAction->setStatusTip(tr("Opens the Modelica By Example online book"));
  connect(mpModelicaByExampleAction, SIGNAL(triggered()), SLOT(openModelicaByExample()));
  // Modelica Web Reference action
  mpModelicaWebReferenceAction = new QAction(tr("Modelica Web Reference"), this);
  mpModelicaWebReferenceAction->setStatusTip(tr("Opens the Modelica Web Reference"));
  connect(mpModelicaWebReferenceAction, SIGNAL(triggered()), SLOT(openModelicaWebReference()));
  // OMSimulator users guide action
  mpOMSimulatorUsersGuideAction = new QAction(tr("OMSimulator Users Guide"), this);
  mpOMSimulatorUsersGuideAction->setStatusTip(tr("Opens the OMSimulator Users Guide"));
  connect(mpOMSimulatorUsersGuideAction, SIGNAL(triggered()), SLOT(openOMSimulatorUsersGuide()));
  // OMTLMSimulator documenatation action
  mpOpenModelicaTLMSimulatorDocumentationAction = new QAction(tr("OpenModelica TLM Simulator Documentation"), this);
  mpOpenModelicaTLMSimulatorDocumentationAction->setStatusTip(tr("Opens the OpenModelica TLM Simulator Documentation"));
  connect(mpOpenModelicaTLMSimulatorDocumentationAction, SIGNAL(triggered()), SLOT(openOpenModelicaTLMSimulatorDocumentation()));
  // about OMEdit action
  mpAboutOMEditAction = new QAction(tr("About OMEdit"), this);
  mpAboutOMEditAction->setStatusTip(tr("Information about OMEdit"));
  mpAboutOMEditAction->setMenuRole(QAction::AboutRole);
  connect(mpAboutOMEditAction, SIGNAL(triggered()), SLOT(openAboutOMEdit()));
  /* Toolbar Actions */
  // custom shapes group
  mpShapesActionGroup = new QActionGroup(this);
  mpShapesActionGroup->setExclusive(false);
  // line creation action
  mpLineShapeAction = new QAction(QIcon(":/Resources/icons/line-shape.svg"), Helper::line, mpShapesActionGroup);
  mpLineShapeAction->setStatusTip(tr("Draws a line shape"));
  mpLineShapeAction->setCheckable(true);
  connect(mpLineShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // polygon creation action
  mpPolygonShapeAction = new QAction(QIcon(":/Resources/icons/polygon-shape.svg"), tr("Polygon"), mpShapesActionGroup);
  mpPolygonShapeAction->setStatusTip(tr("Draws a polygon shape"));
  mpPolygonShapeAction->setCheckable(true);
  connect(mpPolygonShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // rectangle creation action
  mpRectangleShapeAction = new QAction(QIcon(":/Resources/icons/rectangle-shape.svg"), tr("Rectangle"), mpShapesActionGroup);
  mpRectangleShapeAction->setStatusTip(tr("Draws a rectangle shape"));
  mpRectangleShapeAction->setCheckable(true);
  connect(mpRectangleShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // ellipse creation action
  mpEllipseShapeAction = new QAction(QIcon(":/Resources/icons/ellipse-shape.svg"), tr("Ellipse"), mpShapesActionGroup);
  mpEllipseShapeAction->setStatusTip(tr("Draws an ellipse shape"));
  mpEllipseShapeAction->setCheckable(true);
  connect(mpEllipseShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // text creation action
  mpTextShapeAction = new QAction(QIcon(":/Resources/icons/text-shape.svg"), tr("Text"), mpShapesActionGroup);
  mpTextShapeAction->setStatusTip(tr("Draws a text shape"));
  mpTextShapeAction->setCheckable(true);
  connect(mpTextShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // bitmap creation action
  mpBitmapShapeAction = new QAction(QIcon(":/Resources/icons/bitmap-shape.svg"), tr("Bitmap"), mpShapesActionGroup);
  mpBitmapShapeAction->setStatusTip(tr("Inserts a bitmap"));
  mpBitmapShapeAction->setCheckable(true);
  connect(mpBitmapShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // connect/unconnect action
  mpConnectModeAction = new QAction(QIcon(":/Resources/icons/connect-mode.svg"), tr("Connect/Unconnect Mode"), mpShapesActionGroup);
  mpConnectModeAction->setStatusTip(tr("Changes to/from connect mode"));
  mpConnectModeAction->setCheckable(true);
  mpConnectModeAction->setChecked(true);
  connect(mpConnectModeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // transition mode action
  mpTransitionModeAction = new QAction(QIcon(":/Resources/icons/transition-mode.svg"), tr("Transition Mode"), this);
  mpTransitionModeAction->setStatusTip(tr("Changes to/from transition mode"));
  mpTransitionModeAction->setCheckable(true);
  mpTransitionModeAction->setChecked(true);
  // model switcher actions
  for (int i = 0; i < MaxRecentFiles; ++i) {
    mpModelSwitcherActions[i] = new QAction(this);
    mpModelSwitcherActions[i]->setVisible(false);
    connect(mpModelSwitcherActions[i], SIGNAL(triggered()), this, SLOT(openRecentModelWidget()));
  }
  // resimulate action
  mpReSimulateModelAction = new QAction(QIcon(":/Resources/icons/re-simulate.svg"), Helper::reSimulate, this);
  mpReSimulateModelAction->setStatusTip(Helper::reSimulateTip);
  connect(mpReSimulateModelAction, SIGNAL(triggered()), mpVariablesWidget, SLOT(directReSimulate()));
  // resimulate setup action
  mpReSimulateSetupAction = new QAction(QIcon(":/Resources/icons/re-simulation-center.svg"), Helper::reSimulateSetup, this);
  mpReSimulateSetupAction->setStatusTip(Helper::reSimulateSetupTip);
  connect(mpReSimulateSetupAction, SIGNAL(triggered()), mpVariablesWidget, SLOT(showReSimulateSetup()));
  // new plot window action
  mpNewPlotWindowAction = new QAction(QIcon(":/Resources/icons/plot-window.svg"), tr("New Plot Window"), this);
  mpNewPlotWindowAction->setStatusTip(tr("Inserts new plot window"));
  connect(mpNewPlotWindowAction, SIGNAL(triggered()), mpPlotWindowContainer, SLOT(addPlotWindow()));
  // new parametric plot action
  mpNewParametricPlotWindowAction = new QAction(QIcon(":/Resources/icons/parametric-plot-window.svg"), tr("New Parametric Plot Window"), this);
  mpNewParametricPlotWindowAction->setStatusTip(tr("Inserts new parametric plot window"));
  connect(mpNewParametricPlotWindowAction, SIGNAL(triggered()), mpPlotWindowContainer, SLOT(addParametricPlotWindow()));
  // new array plot window action
  mpNewArrayPlotWindowAction = new QAction(QIcon(":/Resources/icons/array-plot-window.svg"), tr("New Array Plot Window"), this);
  mpNewArrayPlotWindowAction->setStatusTip(tr("Inserts new array plot window"));
  connect(mpNewArrayPlotWindowAction, SIGNAL(triggered()), mpPlotWindowContainer, SLOT(addArrayPlotWindow()));
  // new array parametric plot window action
  mpNewArrayParametricPlotWindowAction = new QAction(QIcon(":/Resources/icons/array-parametric-plot-window.svg"), tr("New Array Parametric Plot Window"), this);
  mpNewArrayParametricPlotWindowAction->setStatusTip(tr("Inserts new array parametric plot window"));
  connect(mpNewArrayParametricPlotWindowAction, SIGNAL(triggered()), mpPlotWindowContainer, SLOT(addArrayParametricPlotWindow()));
#if !defined(WITHOUT_OSG)
  // new mpAnimationWindowAction plot action
  mpNewAnimationWindowAction = new QAction(QIcon(":/Resources/icons/animation.svg"), tr("New Animation Window"), this);
  mpNewAnimationWindowAction->setStatusTip(tr("Inserts new animation window"));
  connect(mpNewAnimationWindowAction, SIGNAL(triggered()), mpPlotWindowContainer, SLOT(addAnimationWindow()));
#endif
  // Diagram window action
  mpDiagramWindowAction = new QAction(QIcon(":/Resources/icons/modeling.png"), tr("Diagram Window"), this);
  mpDiagramWindowAction->setStatusTip(tr("Inserts a diagram window"));
  connect(mpDiagramWindowAction, SIGNAL(triggered()), mpPlotWindowContainer, SLOT(addDiagramWindow()));
  // export variables action
  mpExportVariablesAction = new QAction(QIcon(":/Resources/icons/export-variables.svg"), Helper::exportVariables, this);
  mpExportVariablesAction->setStatusTip(tr("Exports the plotted variables to a CSV file"));
  connect(mpExportVariablesAction, SIGNAL(triggered()), mpPlotWindowContainer, SLOT(exportVariables()));
  // clear plot window action
  mpClearPlotWindowAction = new QAction(QIcon(":/Resources/icons/clear.svg"), tr("Clear Plot Window"), this);
  mpClearPlotWindowAction->setStatusTip(tr("Clears all the curves from the plot window"));
  connect(mpClearPlotWindowAction, SIGNAL(triggered()), mpPlotWindowContainer, SLOT(clearPlotWindow()));
  // simulation parameters
  mpSimulationParamsAction = new QAction(QIcon(":/Resources/icons/simulation-parameters.svg"), Helper::simulationParams, this);
  mpSimulationParamsAction->setStatusTip(Helper::simulationParamsTip);
  // fetch interface data
  mpFetchInterfaceDataAction = new QAction(QIcon(":/Resources/icons/interface-data.svg"), Helper::fetchInterfaceData, this);
  mpFetchInterfaceDataAction->setStatusTip(Helper::fetchInterfaceDataTip);
  connect(mpFetchInterfaceDataAction, SIGNAL(triggered()), SLOT(fetchInterfaceData()));
  // align interfaces
  mpAlignInterfacesAction = new QAction(QIcon(":/Resources/icons/align-interfaces.svg"), Helper::alignInterfaces, this);
  mpAlignInterfacesAction->setStatusTip(Helper::alignInterfacesTip);
  // TLM simulate action
  mpTLMCoSimulationAction = new QAction(QIcon(":/Resources/icons/tlm-simulate.svg"), Helper::tlmCoSimulationSetup, this);
  mpTLMCoSimulationAction->setStatusTip(Helper::tlmCoSimulationSetupTip);
  mpTLMCoSimulationAction->setEnabled(false);
  connect(mpTLMCoSimulationAction, SIGNAL(triggered()), SLOT(TLMSimulate()));
  // Add System Action
  mpAddSystemAction = new QAction(QIcon(":/Resources/icons/add-system.svg"), Helper::addSystem, this);
  mpAddSystemAction->setStatusTip(Helper::addSystemTip);
  // Add or Edit icon Action
  mpAddOrEditIconAction = new QAction(QIcon(":/Resources/icons/bitmap-shape.svg"), tr("Add/Edit Icon"), this);
  mpAddOrEditIconAction->setStatusTip(tr("Adds/Edits an icon"));
  // delete icon action
  mpDeleteIconAction = new QAction(QIcon(":/Resources/icons/bitmap-delete.svg"), tr("Delete Icon"), this);
  mpDeleteIconAction->setStatusTip(tr("Deletes an icon"));
  // Add connector action
  mpAddConnectorAction = new QAction(QIcon(":/Resources/icons/add-connector.svg"), Helper::addConnector, this);
  mpAddConnectorAction->setStatusTip(Helper::addConnectorTip);
  // Add bus action
  mpAddBusAction = new QAction(QIcon(":/Resources/icons/bus.svg"), Helper::addBus, this);
  mpAddBusAction->setStatusTip(Helper::addBusTip);
  // Add tlm bus action
  mpAddTLMBusAction = new QAction(QIcon(":/Resources/icons/tlm-bus.svg"), Helper::addTLMBus, this);
  mpAddTLMBusAction->setStatusTip(Helper::addTLMBusTip);
  // Add SubModel Action
  mpAddSubModelAction = new QAction(QIcon(":/Resources/icons/import-fmu.svg"), Helper::addSubModel, this);
  mpAddSubModelAction->setStatusTip(Helper::addSubModelTip);
  // OMSimulator simulation setup action
  mpOMSInstantiateModelAction = new QAction(QIcon(":/Resources/icons/instantiate.svg"), Helper::instantiateModel, this);
  mpOMSInstantiateModelAction->setStatusTip(Helper::instantiateOMSModelTip);
  mpOMSInstantiateModelAction->setCheckable(true);
  connect(mpOMSInstantiateModelAction, SIGNAL(triggered(bool)), SLOT(instantiateOMSModel(bool)));
  // OMSimulator simulation setup action
  mpOMSSimulateAction = new QAction(QIcon(":/Resources/icons/tlm-simulate.svg"), Helper::simulate, this);
  mpOMSSimulateAction->setStatusTip(Helper::OMSSimulateTip);
  connect(mpOMSSimulateAction, SIGNAL(triggered()), SLOT(simulateOMSModel()));
  // Archived simulations
  mpOMSArchivedSimulationsAction = new QAction(Helper::archivedSimulations, this);
  mpOMSArchivedSimulationsAction->setStatusTip(Helper::archivedSimulations);
  connect(mpOMSArchivedSimulationsAction, SIGNAL(triggered()), SLOT(showOMSArchivedSimulations()));
}

//! Creates the menus
void MainWindow::createMenus()
{
  //Create the menubar
  //Create the menus
  // File menu
  QMenu *pFileMenu = new QMenu(menuBar());
  pFileMenu->setObjectName("menuFile");
  pFileMenu->setTitle(tr("&File"));
  // add actions to File menu
  pFileMenu->addAction(mpNewModelicaClassAction);
  pFileMenu->addAction(mpOpenModelicaFileAction);
  pFileMenu->addAction(mpOpenModelicaFileWithEncodingAction);
  pFileMenu->addAction(mpLoadModelicaLibraryAction);
  pFileMenu->addAction(mpLoadEncryptedLibraryAction);
  pFileMenu->addAction(mpOpenResultFileAction);
  pFileMenu->addAction(mpOpenTransformationFileAction);
  pFileMenu->addSeparator();
  pFileMenu->addAction(mpNewCompositeModelFileAction);
  pFileMenu->addAction(mpOpenCompositeModelFileAction);
  pFileMenu->addAction(mpLoadExternModelAction);
  pFileMenu->addSeparator();
  pFileMenu->addAction(mpOpenDirectoryAction);
  pFileMenu->addSeparator();
  pFileMenu->addAction(mpSaveAction);
  pFileMenu->addAction(mpSaveAsAction);
  //menuFile->addAction(saveAllAction);
  pFileMenu->addAction(mpSaveTotalAction);
  pFileMenu->addSeparator();
  // Import menu
  QMenu *pImportMenu = new QMenu(menuBar());
  pImportMenu->setTitle(tr("Import"));
  // add actions to Import menu
  pImportMenu->addAction(mpImportFMUAction);
  pImportMenu->addAction(mpImportFMUModelDescriptionAction);
  pImportMenu->addAction(mpImportFromOMNotebookAction);
  pImportMenu->addAction(mpImportNgspiceNetlistAction);
  pFileMenu->addMenu(pImportMenu);
  // Export menu
  QMenu *pExportMenu = new QMenu(menuBar());
  pExportMenu->setTitle(tr("Export"));
  // add actions to Export menu
  pExportMenu->addAction(mpExportToClipboardAction);
  pExportMenu->addAction(mpExportAsImageAction);
  pExportMenu->addAction(mpExportFMUAction);
  pExportMenu->addAction(mpExportReadonlyPackageAction);
  pExportMenu->addAction(mpExportEncryptedPackageAction);
  pExportMenu->addAction(mpExportXMLAction);
  pExportMenu->addAction(mpExportFigaroAction);
  pExportMenu->addAction(mpExportToOMNotebookAction);
  pFileMenu->addMenu(pExportMenu);
  pFileMenu->addSeparator();
  // System libraries menu
  mpLibrariesMenu = new QMenu(menuBar());
  mpLibrariesMenu->setObjectName("LibrariesMenu");
  mpLibrariesMenu->setTitle(tr("&System Libraries"));
  // get the available libraries.
  QStringList libraries = mpOMCProxy->getAvailableLibraries();
  libraries.append("OpenModelica");
  libraries.sort();
  for (int i = 0; i < libraries.size(); ++i) {
    QAction *pAction = new QAction(libraries[i], this);
    pAction->setData(libraries[i]);
    if (libraries[i].compare("Modelica") == 0) {
      pAction->setShortcut(QKeySequence("Ctrl+m"));
    }
    connect(pAction, SIGNAL(triggered()), SLOT(loadSystemLibrary()));
    mpLibrariesMenu->addAction(pAction);
  }
  pFileMenu->addMenu(mpLibrariesMenu);
  pFileMenu->addSeparator();
  mpRecentFilesMenu = new QMenu(menuBar());
  mpRecentFilesMenu->setObjectName("RecentFilesMenu");
  mpRecentFilesMenu->setTitle(tr("Recent &Files"));
  for (int i = 0; i < MaxRecentFiles; ++i)
    mpRecentFilesMenu->addAction(mpRecentFileActions[i]);
  pFileMenu->addMenu(mpRecentFilesMenu);
  pFileMenu->addAction(mpClearRecentFilesAction);
  pFileMenu->addSeparator();
  pFileMenu->addAction(mpPrintModelAction);
  pFileMenu->addSeparator();
  pFileMenu->addAction(mpQuitAction);
  // add File menu to menu bar
  menuBar()->addAction(pFileMenu->menuAction());
  // Edit menu
  QMenu *pEditMenu = new QMenu(menuBar());
  pEditMenu->setTitle(tr("&Edit"));
  // add actions to Edit menu
  pEditMenu->addAction(mpUndoAction);
  pEditMenu->addAction(mpRedoAction);
  pEditMenu->addSeparator();
  pEditMenu->addAction(mpFilterClassesAction);
  //  pEditMenu->addAction(mpCutAction);
  //  pEditMenu->addAction(mpCopyAction);
  //  pEditMenu->addAction(mpPasteAction);
  // add Edit menu to menu bar
  menuBar()->addAction(pEditMenu->menuAction());
  // View menu
  QMenu *pViewMenu = new QMenu(menuBar());
  pViewMenu->setTitle(tr("&View"));
  // Toolbars View Menu
  QMenu *pViewToolbarsMenu = new QMenu(menuBar());
  pViewToolbarsMenu->setObjectName("ToolbarsViewMenu");
  pViewToolbarsMenu->setTitle(tr("Toolbars"));
  // Windows View Menu
  QMenu *pViewWindowsMenu = new QMenu(menuBar());
  pViewWindowsMenu->setObjectName("WindowsViewMenu");
  pViewWindowsMenu->setTitle(tr("Windows"));
  // add actions to View menu
  // Add Actions to Toolbars View Sub Menu
  pViewToolbarsMenu->addAction(mpFileToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpEditToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpViewToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpShapesToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpModelSwitcherToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpCheckToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpSimulationToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpReSimulationToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpPlotToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpDebuggerToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpTLMSimulationToolbar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpOMSimulatorToobar->toggleViewAction());
  // Add Actions to Windows View Sub Menu
  pViewWindowsMenu->addAction(mpLibraryDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpDocumentationDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpVariablesDockWidget->toggleViewAction());
#if !defined(WITHOUT_OSG)
  pViewWindowsMenu->addAction(mpThreeDViewerDockWidget->toggleViewAction());
#endif
  pViewWindowsMenu->addAction(mpMessagesDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpSearchDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpStackFramesDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpBreakpointsDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpLocalsDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpTargetOutputDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpGDBLoggerDockWidget->toggleViewAction());
  pViewWindowsMenu->addSeparator();
  pViewWindowsMenu->addAction(mpCloseWindowAction);
  pViewWindowsMenu->addAction(mpCloseAllWindowsAction);
  pViewWindowsMenu->addAction(mpCloseAllWindowsButThisAction);
  pViewWindowsMenu->addSeparator();
  pViewWindowsMenu->addAction(mpCascadeWindowsAction);
  pViewWindowsMenu->addAction(mpTileWindowsHorizontallyAction);
  pViewWindowsMenu->addAction(mpTileWindowsVerticallyAction);
  pViewMenu->addAction(pViewToolbarsMenu->menuAction());
  pViewMenu->addAction(pViewWindowsMenu->menuAction());
  pViewMenu->addSeparator();
  pViewMenu->addAction(mpToggleTabOrSubWindowView);
  pViewMenu->addSeparator();
  pViewMenu->addAction(mpShowGridLinesAction);
  pViewMenu->addAction(mpResetZoomAction);
  pViewMenu->addAction(mpZoomInAction);
  pViewMenu->addAction(mpZoomOutAction);
  // add View menu to menu bar
  menuBar()->addAction(pViewMenu->menuAction());
  // Simulation Menu
  QMenu *pSimulationMenu = new QMenu(menuBar());
  pSimulationMenu->setTitle(tr("&Simulation"));
  // add actions to Simulation menu
  pSimulationMenu->addAction(mpInstantiateModelAction);
  pSimulationMenu->addAction(mpCheckModelAction);
  pSimulationMenu->addAction(mpCheckAllModelsAction);
  pSimulationMenu->addAction(mpSimulateModelAction);
  pSimulationMenu->addAction(mpSimulateWithTransformationalDebuggerAction);
  pSimulationMenu->addAction(mpSimulateWithAlgorithmicDebuggerAction);
#if !defined(WITHOUT_OSG)
  pSimulationMenu->addAction(mpSimulateWithAnimationAction);
#endif
  pSimulationMenu->addAction(mpSimulationSetupAction);
  // add Simulation menu to menu bar
  menuBar()->addAction(pSimulationMenu->menuAction());
  // Debug menu
  QMenu *pDebugMenu = new QMenu(menuBar());
  pDebugMenu->setTitle(tr("&Debug"));
  // add actions to Debug menu
  pDebugMenu->addAction(mpDebugConfigurationsAction);
  pDebugMenu->addAction(mpAttachDebuggerToRunningProcessAction);
  // add Debug menu to menu bar
  menuBar()->addAction(pDebugMenu->menuAction());
  // OMSimulator menu
  QMenu *pOMSimulatorMenu = new QMenu(menuBar());
  pOMSimulatorMenu->setTitle(tr("&OMSimulator"));
  // add actions to OMSimulator menu
  pOMSimulatorMenu->addAction(mpNewOMSimulatorModelAction);
  pOMSimulatorMenu->addAction(mpOpenOMSModelFileAction);
  pOMSimulatorMenu->addSeparator();
  pOMSimulatorMenu->addAction(mpAddSystemAction);
  pOMSimulatorMenu->addSeparator();
  pOMSimulatorMenu->addAction(mpAddOrEditIconAction);
  pOMSimulatorMenu->addAction(mpDeleteIconAction);
  pOMSimulatorMenu->addSeparator();
  pOMSimulatorMenu->addAction(mpAddConnectorAction);
  pOMSimulatorMenu->addAction(mpAddBusAction);
  pOMSimulatorMenu->addAction(mpAddTLMBusAction);
  pOMSimulatorMenu->addSeparator();
  pOMSimulatorMenu->addAction(mpAddSubModelAction);
  pOMSimulatorMenu->addSeparator();
  pOMSimulatorMenu->addAction(mpOMSInstantiateModelAction);
  pOMSimulatorMenu->addAction(mpOMSSimulateAction);
  pOMSimulatorMenu->addAction(mpOMSArchivedSimulationsAction);
  // add OMSimulator menu to menu bar
  menuBar()->addAction(pOMSimulatorMenu->menuAction());
  // Git menu
  QMenu *pGitMenu = new QMenu(menuBar());
  pGitMenu->setTitle(tr("&Git"));
  // Traceability actions
  QMenu *pTraceabilityMenu = new QMenu(menuBar());
  pTraceabilityMenu->setObjectName(tr("TraceabilityMenu"));
  pTraceabilityMenu->setTitle(tr("Traceability"));
  // add actions to Git menu
  pGitMenu->addAction(mpCreateGitRepositoryAction);
  pGitMenu->addSeparator();
  pGitMenu->addAction(mpLogCurrentFileAction);
  pGitMenu->addAction(mpStageCurrentFileForCommitAction);
  pGitMenu->addAction(mpUnstageCurrentFileFromCommitAction);
  pGitMenu->addSeparator();
  pGitMenu->addAction(mpCommitFilesAction);
  pGitMenu->addAction(mpRevertCommitAction);
  pGitMenu->addSeparator();
  pGitMenu->addAction(mpCleanWorkingDirectoryAction);
  pGitMenu->addSeparator();
  pGitMenu->addAction(pTraceabilityMenu->menuAction());
  pGitMenu->setEnabled(false);
  // add Git menu to menu bar
  menuBar()->addAction(pGitMenu->menuAction());
  // Tools menu
  QMenu *pToolsMenu = new QMenu(menuBar());
  pToolsMenu->setTitle(tr("&Tools"));
  // add actions to Tools menu
  pToolsMenu->addAction(mpShowOMCLoggerWidgetAction);
#ifdef Q_OS_WIN
  pToolsMenu->addAction(mpShowOpenModelicaCommandPromptAction);
#endif
  if (isDebug()) {
    pToolsMenu->addAction(mpShowOMCDiffWidgetAction);
  }
  pToolsMenu->addSeparator();
  pToolsMenu->addAction(mpOpenWorkingDirectoryAction);
  pToolsMenu->addAction(mpOpenTerminalAction);
  pToolsMenu->addSeparator();
  pToolsMenu->addAction(mpOptionsAction);
  // add Tools menu to menu bar
  menuBar()->addAction(pToolsMenu->menuAction());
  // Help menu
  QMenu *pHelpMenu = new QMenu(menuBar());
  pHelpMenu->setTitle(tr("&Help"));
  // add actions to Help menu
  pHelpMenu->addAction(mpUsersGuideAction);
  pHelpMenu->addAction(mpUsersGuidePdfAction);
  pHelpMenu->addAction(mpSystemDocumentationAction);
  pHelpMenu->addAction(mpOpenModelicaScriptingAction);
  pHelpMenu->addAction(mpModelicaDocumentationAction);
  pHelpMenu->addSeparator();
  //  pHelpMenu->addAction(mpModelicaByExampleAction);
  //  pHelpMenu->addAction(mpModelicaWebReferenceAction);
  //  pHelpMenu->addSeparator();
  pHelpMenu->addAction(mpOMSimulatorUsersGuideAction);
  pHelpMenu->addAction(mpOpenModelicaTLMSimulatorDocumentationAction);
  pHelpMenu->addSeparator();
  pHelpMenu->addAction(mpAboutOMEditAction);
  // add Help menu to menu bar
  menuBar()->addAction(pHelpMenu->menuAction());
}

/*!
 * \brief MainWindow::autoSaveHelper
 * Helper function for MainWindow::autoSave()
 * \param pLibraryTreeItem
 */
void MainWindow::autoSaveHelper(LibraryTreeItem *pLibraryTreeItem)
{
  foreach (LibraryTreeItem *pChildLibraryTreeItem, pLibraryTreeItem->childrenItems()) {
    if (pChildLibraryTreeItem && !pChildLibraryTreeItem->isSystemLibrary()) {
      if (pChildLibraryTreeItem->isFilePathValid() && !pChildLibraryTreeItem->isSaved()) {
        mpLibraryWidget->saveLibraryTreeItem(pChildLibraryTreeItem);
      } else {
        autoSaveHelper(pChildLibraryTreeItem);
      }
    }
  }
}

/*!
 * \brief MainWindow::switchToWelcomePerspective
 * Switches to Welcome perspective.
 */
void MainWindow::switchToWelcomePerspective()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
    LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
    if (!pModelWidget->validateText(&pLibraryTreeItem)) {
      bool signalsState = mpPerspectiveTabbar->blockSignals(true);
      mpPerspectiveTabbar->setCurrentIndex(1);
      mpPerspectiveTabbar->blockSignals(signalsState);
      return;
    }
  }
  mpCentralStackedWidget->setCurrentWidget(mpWelcomePageWidget);
  mpModelWidgetContainer->currentModelWidgetChanged(0);
  mpUndoAction->setEnabled(false);
  mpRedoAction->setEnabled(false);
  mpModelSwitcherToolButton->setEnabled(false);
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getHideVariablesBrowserCheckBox()->isChecked()) {
    mpVariablesDockWidget->hide();
  }
  mpStackFramesDockWidget->hide();
  mpBreakpointsDockWidget->hide();
  mpLocalsDockWidget->hide();
  mpTargetOutputDockWidget->hide();
  mpGDBLoggerDockWidget->hide();
#if !defined(WITHOUT_OSG)
  mpThreeDViewerDockWidget->hide();
#endif
  // hide toolbars
  mpEditToolBar->setVisible(false);
  mpViewToolBar->setVisible(false);
  mpShapesToolBar->setVisible(false);
  mpModelSwitcherToolBar->setVisible(false);
  mpCheckToolBar->setVisible(false);
  mpSimulationToolBar->setVisible(false);
  enableReSimulationToolbar(mpVariablesDockWidget->isVisible());
  mpPlotToolBar->setVisible(false);
  mpPlotToolBar->setEnabled(false);
  mpTLMSimulationToolbar->setVisible(false);
  mpOMSimulatorToobar->setVisible(false);
}

/*!
 * \brief MainWindow::switchToModelingPerspective
 * Switches to Modeling perspective.
 */
void MainWindow::switchToModelingPerspective()
{
  mpCentralStackedWidget->setCurrentWidget(mpModelWidgetContainer);
  mpModelWidgetContainer->currentModelWidgetChanged(mpModelWidgetContainer->getCurrentMdiSubWindow());
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getHideVariablesBrowserCheckBox()->isChecked()) {
    mpVariablesDockWidget->hide();
  }
  // show/hide toolbars
  mpEditToolBar->setVisible(true);
  mpViewToolBar->setVisible(true);
  mpShapesToolBar->setVisible(true);
  mpModelSwitcherToolBar->setVisible(true);
  mpCheckToolBar->setVisible(true);
  mpSimulationToolBar->setVisible(true);
  enableReSimulationToolbar(mpVariablesDockWidget->isVisible());
  mpPlotToolBar->setVisible(false);
  mpPlotToolBar->setEnabled(false);
  mpTLMSimulationToolbar->setVisible(true);
  mpOMSimulatorToobar->setVisible(true);
  // In case user has tabbed the dock widgets then make LibraryWidget active.
  QList<QDockWidget*> tabifiedDockWidgetsList = tabifiedDockWidgets(mpLibraryDockWidget);
  if (tabifiedDockWidgetsList.size() > 0) {
    tabifyDockWidget(tabifiedDockWidgetsList.at(0), mpLibraryDockWidget);
  }
  mpStackFramesDockWidget->hide();
  mpBreakpointsDockWidget->hide();
  mpLocalsDockWidget->hide();
  mpTargetOutputDockWidget->hide();
  mpGDBLoggerDockWidget->hide();
}

/*!
 * \brief MainWindow::switchToPlottingPerspective
 * Switches to plotting perspective.
 */
void MainWindow::switchToPlottingPerspective()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
    LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
    if (!pModelWidget->validateText(&pLibraryTreeItem)) {
      bool signalsState = mpPerspectiveTabbar->blockSignals(true);
      mpPerspectiveTabbar->setCurrentIndex(1);
      mpPerspectiveTabbar->blockSignals(signalsState);
      return;
    }
  }
  mpCentralStackedWidget->setCurrentWidget(mpPlotWindowContainer);
  mpModelWidgetContainer->currentModelWidgetChanged(0);
  mpUndoAction->setEnabled(false);
  mpRedoAction->setEnabled(false);
  mpModelSwitcherToolButton->setEnabled(false);
  // if no plotwindow is opened then open one for user
  if (mpPlotWindowContainer->subWindowList().size() == 0) {
    mpPlotWindowContainer->addPlotWindow(true);
  }
  // if we have DiagramWindow then draw items on it based on the current ModelWidget
  if (pModelWidget && mpPlotWindowContainer->getDiagramSubWindowFromMdi()) {
    mpPlotWindowContainer->getDiagramWindow()->drawDiagram();
  }
  mpVariablesDockWidget->show();
  // show/hide toolbars
  mpEditToolBar->setVisible(false);
  mpViewToolBar->setVisible(false);
  mpShapesToolBar->setVisible(false);
  mpModelSwitcherToolBar->setVisible(false);
  mpCheckToolBar->setVisible(false);
  mpSimulationToolBar->setVisible(false);
  enableReSimulationToolbar(mpVariablesDockWidget->isVisible());
  mpPlotToolBar->setVisible(true);
  mpPlotToolBar->setEnabled(true);
  mpTLMSimulationToolbar->setVisible(false);
  mpOMSimulatorToobar->setVisible(false);
  // In case user has tabbed the dock widgets then make VariablesWidget active.
  QList<QDockWidget*> tabifiedDockWidgetsList = tabifiedDockWidgets(mpVariablesDockWidget);
  if (tabifiedDockWidgetsList.size() > 0) {
    tabifyDockWidget(tabifiedDockWidgetsList.at(0), mpVariablesDockWidget);
  }
  mpStackFramesDockWidget->hide();
  mpBreakpointsDockWidget->hide();
  mpLocalsDockWidget->hide();
  mpTargetOutputDockWidget->hide();
  mpGDBLoggerDockWidget->hide();
#if !defined(WITHOUT_OSG)
  mpThreeDViewerDockWidget->hide();
#endif
}

/*!
 * \brief MainWindow::switchToAlgorithmicDebuggingPerspective
 * Switches to algorithmic debugging perspective.
 */
void MainWindow::switchToAlgorithmicDebuggingPerspective()
{
  mpCentralStackedWidget->setCurrentWidget(mpModelWidgetContainer);
  mpModelWidgetContainer->currentModelWidgetChanged(mpModelWidgetContainer->getCurrentMdiSubWindow());
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getHideVariablesBrowserCheckBox()->isChecked()) {
    mpVariablesDockWidget->hide();
  }
  // show/hide toolbars
  mpEditToolBar->setVisible(true);
  mpViewToolBar->setVisible(true);
  mpShapesToolBar->setVisible(true);
  mpModelSwitcherToolBar->setVisible(true);
  mpCheckToolBar->setVisible(true);
  mpSimulationToolBar->setVisible(true);
  enableReSimulationToolbar(mpVariablesDockWidget->isVisible());
  mpPlotToolBar->setVisible(false);
  mpPlotToolBar->setEnabled(false);
  mpTLMSimulationToolbar->setVisible(false);
  mpOMSimulatorToobar->setVisible(false);
  // In case user has tabbed the dock widgets then make LibraryWidget active.
  QList<QDockWidget*> tabifiedDockWidgetsList = tabifiedDockWidgets(mpLibraryDockWidget);
  if (tabifiedDockWidgetsList.size() > 0) {
    tabifyDockWidget(tabifiedDockWidgetsList.at(0), mpLibraryDockWidget);
  }
  mpStackFramesDockWidget->show();
  mpBreakpointsDockWidget->show();
  mpLocalsDockWidget->show();
  mpTargetOutputDockWidget->show();
  mpGDBLoggerDockWidget->show();
}

/*!
 * \brief MainWindow::closeAllWindowsButThis
 * Closes all windows except the active window.
 * \param pMdiArea
 */
void MainWindow::closeAllWindowsButThis(QMdiArea *pMdiArea)
{
  foreach (QMdiSubWindow *pSubWindow, pMdiArea->subWindowList(QMdiArea::ActivationHistoryOrder)) {
    if (pSubWindow == pMdiArea->activeSubWindow()) {
      continue;
    } else {
      pSubWindow->close();
    }
  }
}

/*!
  Arranges all child windows in a horizontally tiled pattern.
  \param pMdiArea - the subwindows parent mdi area.
  */
void MainWindow::tileSubWindows(QMdiArea *pMdiArea, bool horizontally)
{
  QList<QMdiSubWindow*> subWindowsList = pMdiArea->subWindowList(QMdiArea::ActivationHistoryOrder);
  if (subWindowsList.count() < 2) {
    pMdiArea->tileSubWindows();
    return;
  }
  QPoint position(0, 0);
  for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
    QMdiSubWindow *pSubWindow = subWindowsList[i];
    if (!pSubWindow->isVisible() || (pSubWindow->isMinimized() && !pSubWindow->isShaded())) {
      continue;
    }
    if (pSubWindow->isMaximized() || pSubWindow->isShaded()) {
      pSubWindow->showNormal();
    }
    QRect rect;
    if (horizontally) {
      rect = QRect(0, 0, pMdiArea->width(), qMax(pSubWindow->minimumSizeHint().height(), pMdiArea->height() / subWindowsList.count()));
    } else {
      rect = QRect(0, 0, qMax(pSubWindow->minimumSizeHint().width(), pMdiArea->width() / subWindowsList.count()), pMdiArea->height());
    }
    pSubWindow->setGeometry(rect);
    pSubWindow->move(position);
    if (horizontally) {
      position.setY(position.y() + pSubWindow->height());
    } else {
      position.setX(position.x() + pSubWindow->width());
    }
  }
}

/*!
 * \brief MainWindow::fetchInterfaceDataHelper
 * \param pLibraryTreeItem
 * Helper function for fetching the interface data.
 */
void MainWindow::fetchInterfaceDataHelper(LibraryTreeItem *pLibraryTreeItem, QString singleModel)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  FetchInterfaceDataDialog *pFetchInterfaceDataDialog = new FetchInterfaceDataDialog(pLibraryTreeItem, singleModel, this);
  connect(pFetchInterfaceDataDialog, SIGNAL(readInterfaceData(LibraryTreeItem*)), SLOT(readInterfaceData(LibraryTreeItem*)));
  pFetchInterfaceDataDialog->exec();
}

//! Creates the toolbars
void MainWindow::createToolbars()
{
  int toolbarIconSize = OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value();
  setIconSize(QSize(toolbarIconSize, toolbarIconSize));
  // File Toolbar
  mpFileToolBar = addToolBar(tr("File Toolbar"));
  mpFileToolBar->setObjectName("File Toolbar");
  mpFileToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to File Toolbar
  mpFileToolBar->addAction(mpNewModelicaClassAction);
  mpFileToolBar->addAction(mpOpenModelicaFileAction);
  mpFileToolBar->addAction(mpSaveAction);
  mpFileToolBar->addAction(mpSaveAsAction);
  //mpFileToolBar->addAction(mpSaveAllAction);
  // Edit Toolbar
  mpEditToolBar = addToolBar(tr("Edit Toolbar"));
  mpEditToolBar->setObjectName("Edit Toolbar");
  mpEditToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to edit toolbar
  mpEditToolBar->addAction(mpUndoAction);
  mpEditToolBar->addAction(mpRedoAction);
  //  mpEditToolBar->addAction(mpCutAction);
  //  mpEditToolBar->addAction(mpCopyAction);
  //  mpEditToolBar->addAction(mpPasteAction);
  // View Toolbar
  mpViewToolBar = addToolBar(tr("View Toolbar"));
  mpViewToolBar->setObjectName("View Toolbar");
  mpViewToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to View Toolbar
  mpViewToolBar->addAction(mpShowGridLinesAction);
  mpViewToolBar->addSeparator();
  mpViewToolBar->addAction(mpResetZoomAction);
  mpViewToolBar->addAction(mpZoomInAction);
  mpViewToolBar->addAction(mpZoomOutAction);
  // Shapes Toolbar
  mpShapesToolBar = addToolBar(tr("Shapes Toolbar"));
  mpShapesToolBar->setObjectName("Shapes Toolbar");
  mpShapesToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to Shapes Toolbar
  mpShapesToolBar->addAction(mpLineShapeAction);
  mpShapesToolBar->addAction(mpPolygonShapeAction);
  mpShapesToolBar->addAction(mpRectangleShapeAction);
  mpShapesToolBar->addAction(mpEllipseShapeAction);
  mpShapesToolBar->addAction(mpTextShapeAction);
  mpShapesToolBar->addAction(mpBitmapShapeAction);
  mpShapesToolBar->addSeparator();
  mpShapesToolBar->addAction(mpConnectModeAction);
  mpShapesToolBar->addSeparator();
  mpShapesToolBar->addAction(mpTransitionModeAction);
  // Model Swithcer Toolbar
  mpModelSwitcherToolBar = addToolBar(tr("ModelSwitcher Toolbar"));
  mpModelSwitcherToolBar->setObjectName("ModelSwitcher Toolbar");
  mpModelSwitcherToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // Model Switcher Menu
  mpModelSwitcherMenu = new QMenu;
  for (int i = 0; i < MaxRecentFiles; ++i) {
    mpModelSwitcherMenu->addAction(mpModelSwitcherActions[i]);
  }
  // Model Switcher ToolButton
  mpModelSwitcherToolButton = new QToolButton;
  mpModelSwitcherToolButton->setEnabled(false);
  mpModelSwitcherToolButton->setMenu(mpModelSwitcherMenu);
  mpModelSwitcherToolButton->setPopupMode(QToolButton::MenuButtonPopup);
  mpModelSwitcherToolButton->setIcon(QIcon(":/Resources/icons/switch.svg"));
  connect(mpModelSwitcherToolButton, SIGNAL(clicked()), this, SLOT(openRecentModelWidget()));
  mpModelSwitcherToolBar->addWidget(mpModelSwitcherToolButton);
  // Check Toolbar
  mpCheckToolBar = addToolBar(tr("Check Toolbar"));
  mpCheckToolBar->setObjectName("Check Toolbar");
  mpCheckToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to Check Toolbar
  mpCheckToolBar->addAction(mpCheckModelAction);
  mpCheckToolBar->addAction(mpCheckAllModelsAction);
  mpCheckToolBar->addAction(mpInstantiateModelAction);
  // Simulation Toolbar
  mpSimulationToolBar = addToolBar(tr("Simulation Toolbar"));
  mpSimulationToolBar->setObjectName("Simulation Toolbar");
  mpSimulationToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to Simulation Toolbar
  mpSimulationToolBar->addAction(mpSimulateModelAction);
  mpSimulationToolBar->addAction(mpSimulateWithTransformationalDebuggerAction);
  mpSimulationToolBar->addAction(mpSimulateWithAlgorithmicDebuggerAction);
#if !defined(WITHOUT_OSG)
  mpSimulationToolBar->addAction(mpSimulateWithAnimationAction);
#endif
  mpSimulationToolBar->addAction(mpSimulationSetupAction);
  // Re-simulation Toolbar
  mpReSimulationToolBar = addToolBar(tr("Re-simulation Toolbar"));
  mpReSimulationToolBar->setObjectName("Re-simulation Toolbar");
  mpReSimulationToolBar->setAllowedAreas(Qt::TopToolBarArea);
  mpReSimulationToolBar->setEnabled(false);
  // add actions to Re-simulation Toolbar
  mpReSimulationToolBar->addAction(mpReSimulateModelAction);
  mpReSimulationToolBar->addAction(mpReSimulateSetupAction);
  // Plot Toolbar
  mpPlotToolBar = addToolBar(tr("Plot Toolbar"));
  mpPlotToolBar->setObjectName("Plot Toolbar");
  mpPlotToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to Plot Toolbar
  mpPlotToolBar->addAction(mpNewPlotWindowAction);
  mpPlotToolBar->addAction(mpNewParametricPlotWindowAction);
  mpPlotToolBar->addAction(mpNewArrayPlotWindowAction);
  mpPlotToolBar->addAction(mpNewArrayParametricPlotWindowAction);
#if !defined(WITHOUT_OSG)
  mpPlotToolBar->addAction(mpNewAnimationWindowAction);
#endif
  mpPlotToolBar->addAction(mpDiagramWindowAction);
  mpPlotToolBar->addSeparator();
  mpPlotToolBar->addAction(mpExportVariablesAction);
  mpPlotToolBar->addSeparator();
  mpPlotToolBar->addAction(mpClearPlotWindowAction);
  // Debugger Toolbar
  mpDebuggerToolBar = addToolBar(tr("Debugger Toolbar"));
  mpDebuggerToolBar->setObjectName("Debugger Toolbar");
  mpDebuggerToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // Debug Configuration Menu
  mpDebugConfigurationMenu = new QMenu;
  updateDebuggerToolBarMenu();
  // Model Switcher ToolButton
  mpDebugConfigurationToolButton = new QToolButton;
  mpDebugConfigurationToolButton->setToolTip(tr("Run the debugger"));
  mpDebugConfigurationToolButton->setMenu(mpDebugConfigurationMenu);
  mpDebugConfigurationToolButton->setPopupMode(QToolButton::MenuButtonPopup);
  mpDebugConfigurationToolButton->setIcon(QIcon(":/Resources/icons/debugger.svg"));
  connect(mpDebugConfigurationToolButton, SIGNAL(clicked()), SLOT(runDebugConfiguration()));
  mpDebuggerToolBar->addWidget(mpDebugConfigurationToolButton);
  // TLM Simulation Toolbar
  mpTLMSimulationToolbar = addToolBar(tr("TLM Simulation Toolbar"));
  mpTLMSimulationToolbar->setObjectName("TLM Simulation Toolbar");
  mpTLMSimulationToolbar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to TLM Simulation Toolbar
  mpTLMSimulationToolbar->addAction(mpSimulationParamsAction);
  mpTLMSimulationToolbar->addSeparator();
  mpTLMSimulationToolbar->addAction(mpFetchInterfaceDataAction);
  mpTLMSimulationToolbar->addAction(mpAlignInterfacesAction);
  mpTLMSimulationToolbar->addSeparator();
  mpTLMSimulationToolbar->addAction(mpTLMCoSimulationAction);
  // OMSimulator Toolbar
  mpOMSimulatorToobar = addToolBar(tr("OMSimulator Toolbar"));
  mpOMSimulatorToobar->setObjectName("OMSimulator Toolbar");
  mpOMSimulatorToobar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to OMSimulator Toolbar
  mpOMSimulatorToobar->addAction(mpAddSystemAction);
  mpOMSimulatorToobar->addSeparator();
  mpOMSimulatorToobar->addAction(mpAddOrEditIconAction);
  mpOMSimulatorToobar->addAction(mpDeleteIconAction);
  mpOMSimulatorToobar->addSeparator();
  mpOMSimulatorToobar->addAction(mpAddConnectorAction);
  mpOMSimulatorToobar->addAction(mpAddBusAction);
  mpOMSimulatorToobar->addAction(mpAddTLMBusAction);
  mpOMSimulatorToobar->addSeparator();
  mpOMSimulatorToobar->addAction(mpAddSubModelAction);
  mpOMSimulatorToobar->addSeparator();
  mpOMSimulatorToobar->addAction(mpOMSInstantiateModelAction);
  mpOMSimulatorToobar->addAction(mpOMSSimulateAction);
}

//! when the dragged object enters the main window
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
  if(event->mimeData()->hasFormat(Helper::modelicaFileFormat))
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
  if (!event->mimeData()->hasFormat(Helper::modelicaFileFormat))
  {
    event->ignore();
    return;
  }
  openDroppedFile(event);
  event->accept();
}

/*!
 * \class AboutOMEditDialog
 * \brief Creates a dialog that shows the about text of OMEdit.
 * Information about OpenModelica Connection Editor. Shows the list of OMEdit contributors.
 */
/*!
 * \brief AboutOMEditWidget::AboutOMEditDialog
 * \param pParent - pointer to MainWindow
 */
AboutOMEditDialog::AboutOMEditDialog(MainWindow *pMainWindow)
  : QDialog(pMainWindow)
{
  setWindowTitle(tr("About %1").arg(Helper::applicationName));
  setAttribute(Qt::WA_DeleteOnClose);

  const QString aboutText = tr(
     "<h2>%1 - %2</h2>"
     "<b>%3</b><br />"
     "<b>Connected to %4</b><br />"
     "<b>Connected to %5</b><br /><br />"
     "Copyright <b>Open Source Modelica Consortium (OSMC)</b>.<br />"
     "Distributed under OSMC-PL and GPL, see <u><a href=\"http://www.openmodelica.org\">www.openmodelica.org</a></u>.<br /><br />"
     "Initially developed by <b>Adeel Asghar</b> and <b>Sonia Tariq</b> as part of their final master thesis."
#if defined(WITHOUT_OSG)
     "<br /><em>Compiled without 3D animation support</em>."
#endif
     "<br /><br /><b>Contributors:</b>"
     "<ul>"
     "<li>Adeel Asghar - <u><a href=\"mailto:adeel.asghar@liu.se\">adeel.asghar@liu.se</a></u></li>"
     "<li>Sonia Tariq</li>"
     "<li>Martin Sjölund - <u><a href=\"mailto:martin.sjolund@liu.se\">martin.sjolund@liu.se</a></u></li>"
     "<li>Alachew Shitahun - <u><a href=\"mailto:alachew.mengist@liu.se\">alachew.mengist@liu.se</a></u></li>"
     "<li>Jan Kokert - <u><a href=\"mailto:jan.kokert@imtek.uni-freiburg.de\">jan.kokert@imtek.uni-freiburg.de</a></u></li>"
     "<li>Dr. Henning Kiel - <u><a href=\"mailto:henning.kiel@w-hs.de\">henning.kiel@w-hs.de</a></u></li>"
     "<li>Haris Kapidzic</li>"
     "<li>Abhinn Kothari</li>"
     "<li>Lennart Ochel - <u><a href=\"mailto:lennart.ochel@liu.se\">lennart.ochel@liu.se</a></u></li>"
     "<li>Volker Waurich - <u><a href=\"mailto:volker.waurich@tu-dresden.de\">volker.waurich@tu-dresden.de</a></u></li>"
     "<li>Rüdiger Franke</li>"
     "<li>Martin Flehmig</li>"
     "<li>Robert Braun - <u><a href=\"mailto:robert.braun@liu.se\">robert.braun@liu.se</a></u></li>"
     "<li>Per Östlund - <u><a href=\"mailto:per.ostlund@liu.se\">per.ostlund@liu.se</a></u></li>"
     "<li>Dietmar Winkler</li>"
     "<li>Anatoly Severin<li>"
     "<li>Adrian Pop - <u><a href=\"mailto:adrian.pop@liu.se\">adrian.pop@liu.se</a></u></li>"
     "</ul>")
     .arg(Helper::applicationName,
          Helper::applicationIntroText,
          GIT_SHA,
          Helper::OpenModelicaVersion,
          oms_getVersion());
  // about text label
  Label *pAboutTextLabel = new Label(aboutText);
  pAboutTextLabel->setWordWrap(true);
  pAboutTextLabel->setOpenExternalLinks(true);
  pAboutTextLabel->setTextInteractionFlags(Qt::TextBrowserInteraction);
  pAboutTextLabel->setToolTip("");
  // close button
  QPushButton *pCloseButton = new QPushButton(Helper::close);
  connect(pCloseButton, SIGNAL(clicked()), SLOT(reject()));
  // logo label
  Label *pLogoLabel = new Label;
  QPixmap pixmap(":/Resources/icons/omedit.png");
  pLogoLabel->setPixmap(pixmap.scaled(128, 128, Qt::KeepAspectRatio, Qt::SmoothTransformation));
  // main layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->addWidget(pLogoLabel, 0, 0, Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(pAboutTextLabel, 0, 1, Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(pCloseButton, 1, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}
