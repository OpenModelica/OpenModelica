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
#include "Modeling/ElementTreeWidget.h"
#include "Modeling/ModelicaClassDialog.h"
#include "OMS/ModelDialog.h"
#include "CRML/CRMLTranslateAsDialog.h"
#include "Debugger/GDB/GDBAdapter.h"
#include "Debugger/StackFrames/StackFramesWidget.h"
#include "Debugger/Locals/LocalsWidget.h"
#include "Modeling/DocumentationWidget.h"
#include "Plotting/VariablesWidget.h"
#include "Search/SearchWidget.h"
#if !defined(WITHOUT_OSG)
#include "Animation/ViewerWidget.h"
#endif
#include "Util/Helper.h"
#include "Simulation/ArchivedSimulationsWidget.h"
#include "Simulation/SimulationOutputWidget.h"
#include "CRML/CRMLTranslatorOutputWidget.h"
#include "OMS/OMSSimulationOutputWidget.h"
#include "OMS/OMSSimulationDialog.h"
#include "Debugger/DebuggerConfigurationsDialog.h"
#include "Debugger/Attach/AttachToProcessDialog.h"
#include "TransformationalDebugger/TransformationsWidget.h"
#include "Options/NotificationsDialog.h"
#include "Simulation/SimulationDialog.h"
#include "FMI/ImportFMUDialog.h"
#include "FMI/ImportFMUModelDescriptionDialog.h"
#include "Git/CommitChangesDialog.h"
#include "Git/RevertCommitsDialog.h"
#include "Git/CleanDialog.h"
#include "Git/GitCommands.h"
#include "Traceability/TraceabilityInformationURI.h"
#include "Traceability/TraceabilityGraphViewWidget.h"
#include "Plotting/DiagramWindow.h"
#include "Interfaces/InformationInterface.h"
#include "Interfaces/ModelInterface.h"
#include "omedit_config.h"
#include "Util/NetworkAccessManager.h"
#include "Modeling/InstallLibraryDialog.h"
#include "CrashReport/CrashReportDialog.h"
#include "FMI/FMUExportOutputWidget.h"
#include "PlotCurve.h"
#include <QtSvg/QSvgGenerator>
#include <QNetworkProxyFactory>

namespace ToolBars {
  QString welcomePerspective = "welcomePerspective";
  QString modelingModelicaPerspective = "modelingModelicaPerspective";
  QString modelingTextPerspective = "modelingTextPerspective";
  QString modelingOMSPerspective = "modelingOMSPerspective";
  QString plottingPerspective = "plottingPerspective";
  QString debuggingModelicaPerspective = "debuggingPerspective";
  QString debuggingTextPerspective = "debuggingTextPerspective";
  QString debuggingOMSPerspective = "debuggingOMSPerspective";
  QString editToolBar = "editToolBar";
  QString viewToolBar = "viewToolBar";
  QString shapesToolBar = "shapesToolBar";
  QString modelSwitcherToolBar = "modelSwitcherToolBar";
  QString checkToolBar = "checkToolBar";
  QString simulationToolBar = "simulationToolBar";
  QString reSimulationToolBar = "reSimulationToolBar";
  QString plotToolBar = "plotToolBar";
  QString debuggerToolBar = "debuggerToolBar";
  QString OMSimulatorToolBar = "OMSimulatorToolBar";
}

MainWindow::MainWindow(QWidget *parent)
  : QMainWindow(parent), mExitApplicationStatus(false)
{
  // Make sure we honor the system's proxy settings
  QNetworkProxyFactory::setUseSystemConfiguration(true);
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
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  qRegisterMetaType<RecentFile>("RecentFile");
  qRegisterMetaType<FindTextOM>("FindTextOM");
  qRegisterMetaType<DebuggerConfiguration>("DebuggerConfiguration");
#else // #if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  qRegisterMetaTypeStreamOperators<RecentFile>("RecentFile");
  qRegisterMetaTypeStreamOperators<FindTextOM>("FindTextOM");
  qRegisterMetaTypeStreamOperators<DebuggerConfiguration>("DebuggerConfiguration");
#endif // #if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  /*! @note The above three lines registers the structs as QMetaObjects. Do not remove/move them. */
  qRegisterMetaType<QProcess::ProcessError>("QProcess::ProcessError");
  qRegisterMetaType<QProcess::ExitStatus>("QProcess::ExitStatus");
  qRegisterMetaType<StringHandler::SimulationMessageType>("StringHandler::SimulationMessageType");
  /*! @note The above three lines registers the types for simulaiton threads. Do not remove them. */
  setObjectName("MainWindow");
  setWindowTitle(Helper::applicationName + " - "  + Helper::applicationIntroText);
  setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
  setMinimumSize(400, 300);
  setContentsMargins(1, 1, 1, 1);
}

MainWindow *MainWindow::mpInstance = 0;

/*!
 * \brief MainWindow::instance
 * Creates an instance of MainWindow. If we already have an instance then just return it.
 * \return
 */
MainWindow *MainWindow::instance()
{
  if (!mpInstance) {
    mpInstance = new MainWindow;
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
  if (!isTestsuiteRunning()) {
    // Reopen the standard output stream.
    QString outputFileName = Utilities::tempDirectory() + "/omeditoutput.txt";
#ifdef Q_OS_WIN
    _wfreopen((wchar_t*)outputFileName.utf16(), L"w", stdout);
#else
    freopen(outputFileName.toUtf8().constData(), "w", stdout);
#endif
    setbuf(stdout, NULL); // used non-buffered stdout
    // Reopen the standard error stream.
    QString errorFileName = Utilities::tempDirectory() + "/omediterror.txt";
#ifdef Q_OS_WIN
    _wfreopen((wchar_t*)errorFileName.utf16(), L"w", stderr);
#else
    freopen(outputFileName.toUtf8().constData(), "w", stderr);
#endif
    setbuf(stderr, NULL); // used non-buffered stderr
  }
  SplashScreen::instance()->showMessage(tr("Initializing"), Qt::AlignRight, Qt::white);
  // Create an object of MessagesWidget.
  MessagesWidget::create();
  // Create MessagesDockWidget dock
  mpMessagesDockWidget = new QDockWidget(tr("Messages"), this);
  mpMessagesDockWidget->setObjectName("Messages");
  mpMessagesDockWidget->setAllowedAreas(Qt::BottomDockWidgetArea);
  mpMessagesDockWidget->setWidget(MessagesWidget::instance());
  addDockWidget(Qt::BottomDockWidgetArea, mpMessagesDockWidget);
  mpMessagesDockWidget->hide();
  connect(MessagesWidget::instance(), SIGNAL(messageAdded()), SLOT(showMessageBrowser()));
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
  mpLibrariesMenu = 0;
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
  // Create an object of StatusBar
  mpStatusBar = new StatusBar();
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
  mpLibraryDockWidget = new QDockWidget(Helper::libraries, this);
  mpLibraryDockWidget->setObjectName("Libraries");
  mpLibraryDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpLibraryDockWidget->setWidget(mpLibraryWidget);
  addDockWidget(Qt::LeftDockWidgetArea, mpLibraryDockWidget);
  mpLibraryWidget->getLibraryTreeView()->setFocus(Qt::ActiveWindowFocusReason);
  // Create an object of ElementWidget
  mpElementWidget = new ElementWidget(this);
  // Create ElementDockWidget
  mpElementDockWidget = new QDockWidget(Helper::elements, this);
  mpElementDockWidget->setObjectName("ElementBrowser");
  mpElementDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpElementDockWidget->setWidget(mpElementWidget);
  addDockWidget(Qt::LeftDockWidgetArea, mpElementDockWidget);
  // Create an object of SearchWidget
  mpSearchWidget = new SearchWidget(this);
  mpSearchDockWidget = new QDockWidget(tr("Search"),this);
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
  mpStackFramesDockWidget = new QDockWidget(tr("Stack Frames"), this);
  mpStackFramesDockWidget->setObjectName("StackFrames");
  mpStackFramesDockWidget->setWidget(mpStackFramesWidget);
  addDockWidget(Qt::TopDockWidgetArea, mpStackFramesDockWidget);
  // create breakpoints widget
  mpBreakpointsWidget = new BreakpointsWidget(this);
  // Create breakpoints dock widget
  mpBreakpointsDockWidget = new QDockWidget(tr("Breakpoints"), this);
  mpBreakpointsDockWidget->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Maximum);
  mpBreakpointsDockWidget->setObjectName("BreakPoints");
  mpBreakpointsDockWidget->setWidget(mpBreakpointsWidget);
  addDockWidget(Qt::TopDockWidgetArea, mpBreakpointsDockWidget);
  // create locals widget
  mpLocalsWidget = new LocalsWidget(this);
  // Create locals dock widget
  mpLocalsDockWidget = new QDockWidget(tr("Locals"), this);
  mpLocalsDockWidget->setObjectName("Locals");
  mpLocalsDockWidget->setWidget(mpLocalsWidget);
  addDockWidget(Qt::RightDockWidgetArea, mpLocalsDockWidget);
  // Create target output widget
  mpTargetOutputWidget = new TargetOutputWidget(this);
  // Create GDB console dock widget
  mpTargetOutputDockWidget = new QDockWidget(tr("Console Output"), this);
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
  mpDocumentationDockWidget = new QDockWidget(tr("Documentation"), this);
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
  mpVariablesDockWidget = new QDockWidget(Helper::variableBrowser, this);
  mpVariablesDockWidget->setObjectName("Variables");
  mpVariablesDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  addDockWidget(Qt::RightDockWidgetArea, mpVariablesDockWidget);
  mpVariablesDockWidget->setWidget(mpVariablesWidget);
  // create traceability graph view widget
  //  mpTraceabilityGraphViewWidget = new TraceabilityGraphViewWidget(this);
  mpTraceabilityInformationURI = new TraceabilityInformationURI(this);
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
  // enable/disable re-simulation toolbar based on variable browser visibiltiy.
  connect(mpVariablesDockWidget, SIGNAL(visibilityChanged(bool)), this, SLOT(enableReSimulationToolbar(bool)));
  // Create the archived simulation widget
  ArchivedSimulationsWidget::create();
  // Create simulation dialog when needed
  mpSimulationDialog = 0;
  // Create the OMSimulator simulation dialog when needed
  mpOMSSimulationDialog = 0;
  // Create an object of ModelWidgetContainer
  mpModelWidgetContainer = new ModelWidgetContainer(this);
  // Create an object of WelcomePageWidget
  mpWelcomePageWidget = new WelcomePageWidget(this);
  updateRecentFileActionsAndList();
  // OMSens plugin
  mpOMSensPlugin = 0;
  // create the Git commands instance
  //mpGitCommands = new GitCommands(this);
  GitCommands::create();
  // Create a centralwidget for the main window
  mpCentralStackedWidget = new QStackedWidget;
  mpCentralStackedWidget->addWidget(mpWelcomePageWidget);
  mpCentralStackedWidget->addWidget(mpModelWidgetContainer);
  mpCentralStackedWidget->addWidget(mpPlotWindowContainer);
  // central widget layout
  QVBoxLayout *pCentralWidgetLayout = new QVBoxLayout;
  pCentralWidgetLayout->setSpacing(0);
  pCentralWidgetLayout->setContentsMargins(0, 0, 0, 0);
  QWidget *pCentralWidget = new QWidget;
  pCentralWidgetLayout->addWidget(mpCentralStackedWidget, 1);
  // Create a QTabWidget that mimicks the Message Browser
  mpMessagesTabWidget = new QTabWidget(this);
  mpMessagesTabWidget->setTabsClosable(true);
  mpMessagesTabWidget->setDocumentMode(true);
  connect(mpMessagesTabWidget, SIGNAL(tabBarClicked(int)), SLOT(messagesTabBarClicked(int)));
  connect(mpMessagesDockWidget, SIGNAL(visibilityChanged(bool)), SLOT(messagesDockWidgetVisibilityChanged(bool)));
  connect(MessagesWidget::instance(), SIGNAL(messageTabAdded(QWidget*,QString)), SLOT(messageTabAdded(QWidget*,QString)));
  connect(MessagesWidget::instance(), SIGNAL(messageTabClosed(int)), SLOT(messageTabClosed(int)));
  connect(mpMessagesTabWidget, SIGNAL(tabCloseRequested(int)), MessagesWidget::instance(), SLOT(closeTab(int)));
  pCentralWidgetLayout->addWidget(mpMessagesTabWidget, 0);
  pCentralWidget->setLayout(pCentralWidgetLayout);
  //Set the centralwidget
  setCentralWidget(pCentralWidget);
  // Load and add user defined Modelica libraries into the Library Widget.
  if (!isTestsuiteRunning()) {
    mpLibraryWidget->getLibraryTreeModel()->addModelicaLibraries();
  }
  // set command line options
  OptionsDialog::instance()->saveSimulationSettings();
  // create tabs from MessagesWidget
  QTabBar::ButtonPosition closeSide = (QTabBar::ButtonPosition)style()->styleHint(QStyle::SH_TabBar_CloseButtonPosition, 0, mpMessagesTabWidget);
  MessagesTabWidget *pMessagesTabWidget = MessagesWidget::instance()->getMessagesTabWidget();
  for (int i = 0; i < pMessagesTabWidget->count(); ++i) {
    createMessageTab(pMessagesTabWidget->tabText(i), true);
    QWidget *pTabButtonWidget = mpMessagesTabWidget->tabBar()->tabButton(i, closeSide);
    if (pTabButtonWidget) {
      pTabButtonWidget->deleteLater();
    }
    mpMessagesTabWidget->tabBar()->setTabButton(i, closeSide, 0);
  }
  // since createMessageTab() changes the index so switch it back to 0.
  mpMessagesTabWidget->setCurrentIndex(0);
  mpMessagesTabWidget->setVisible(!mpMessagesDockWidget->isVisible());
  // restore OMEdit widgets state
  QSettings *pSettings = Utilities::getApplicationSettings();
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()) {
    bool restoreMessagesWidget = !MessagesWidget::instance()->getAllMessageWidget()->getMessagesTextBrowser()->toPlainText().isEmpty();
    mRestoringState = true;
    /* With qt6 we need to call restoreState before restoreGeometry otherwise OMEdit crash on startup.
     * Don't know why this is happening.
     * The example in Qt docs calls restoreGeometry first.
     */
    restoreState(pSettings->value("application/windowState").toByteArray());
    restoreGeometry(pSettings->value("application/geometry").toByteArray());
    mRestoringState = false;
    pSettings->beginGroup("algorithmicDebugger");
    /* restore stackframes list and locals columns width */
    mpStackFramesWidget->getStackFramesTreeWidget()->header()->restoreState(pSettings->value("stackFramesTreeState").toByteArray());
    mpBreakpointsWidget->getBreakpointsTreeView()->header()->restoreState(pSettings->value("breakPointsTreeState").toByteArray());
    mpLocalsWidget->getLocalsTreeView()->header()->restoreState(pSettings->value("localsTreeState").toByteArray());
    pSettings->endGroup();
    if (restoreMessagesWidget) {
      if (!OptionsDialog::instance()->getMessagesPage()->getEnlargeMessageBrowserCheckBox()->isChecked()) {
        showMessageBrowser();
      } else {
        markMessagesTabWidgetChangedForNewMessage(StringHandler::NoOMError);
      }
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
  mpAutoSaveTimer->setTimerType(Qt::PreciseTimer);
  mpAutoSaveTimer->setInterval(OptionsDialog::instance()->getGeneralSettingsPage()->getAutoSaveIntervalSpinBox()->value() * 1000);
  connect(mpAutoSaveTimer, SIGNAL(timeout()), SLOT(autoSave()));
  // read auto save settings
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getEnableAutoSaveGroupBox()->isChecked()) {
    mpAutoSaveTimer->start();
  }
}

/*!
 * \brief MainWindow::setNewApiProfiling
 * Sets the new api profiling flag.
 * If flag is enabled then creates a file for it.
 * \param newApiProfiling
 */
void MainWindow::setNewApiProfiling(bool newApiProfiling)
{
  mNewApiProfiling = newApiProfiling;
  if (mNewApiProfiling) {
    QString& tmpPath = Utilities::tempDirectory();
    /* create a file to write OMEdit communication log */
    QString profilingFilePath = QString("%1instanceApiProfiling.txt").arg(tmpPath);
#ifdef Q_OS_WIN
    mpNewApiProfilingFile = _wfopen((wchar_t*)profilingFilePath.utf16(), L"w");
#else
    mpNewApiProfilingFile = fopen(profilingFilePath.toUtf8().constData(), "w");
#endif
  }
}

/*!
 * \brief MainWindow::isModelingPerspectiveActive
 * Returns true if the Modeling perspective is active.
 * \return
 */
bool MainWindow::isModelingPerspectiveActive()
{
  return mpPerspectiveTabbar->currentIndex() == 1;
}

/*!
 * \brief MainWindow::isPlottingPerspectiveActive
 * Returns true if the Plotting perspective is active.
 * \return
 */
bool MainWindow::isPlottingPerspectiveActive()
{
  return mpPerspectiveTabbar->currentIndex() == 2;
}

/*!
 * \brief MainWindow::isDebuggingPerspectiveActive
 * Returns true if the Debugging perspective is active.
 * \return
 */
bool MainWindow::isDebuggingPerspectiveActive()
{
  return mpPerspectiveTabbar->currentIndex() == 3;
}

#define SHOW_HIDE_TOOLBAR(pToolBar, toolBarSettingName, defaultValue) \
  if (pSettings->contains(toolBarSettingName)) { \
    bool signalsState = pToolBar->blockSignals(true); \
    pToolBar->setVisible(pSettings->value(toolBarSettingName).toBool()); \
    pToolBar->blockSignals(signalsState); \
  } else { \
    bool signalsState = pToolBar->blockSignals(true); \
    pToolBar->setVisible(defaultValue); \
    pToolBar->blockSignals(signalsState); \
    pSettings->setValue(toolBarSettingName, defaultValue); \
  }

/*!
 * \brief MainWindow::showModelingPerspectiveToolBars
 * Updates the toolbars visibility for Modeling perspective based on the active library type.
 * \param pModelWidget
 */
void MainWindow::showModelingPerspectiveToolBars(ModelWidget *pModelWidget)
{
  if (mRestoringState) {
    return;
  }
  // show/hide toolbars
  QSettings *pSettings = Utilities::getApplicationSettings();
  if (pModelWidget && pModelWidget->getLibraryTreeItem()->isText()) {
    pSettings->beginGroup(ToolBars::modelingTextPerspective);
    SHOW_HIDE_TOOLBAR(mpEditToolBar, ToolBars::editToolBar, true);
    SHOW_HIDE_TOOLBAR(mpViewToolBar, ToolBars::viewToolBar, true);
    SHOW_HIDE_TOOLBAR(mpShapesToolBar, ToolBars::shapesToolBar, false);
    SHOW_HIDE_TOOLBAR(mpModelSwitcherToolBar, ToolBars::modelSwitcherToolBar, true);
    SHOW_HIDE_TOOLBAR(mpCheckToolBar, ToolBars::checkToolBar, false);
    SHOW_HIDE_TOOLBAR(mpSimulationToolBar, ToolBars::simulationToolBar, false);
    SHOW_HIDE_TOOLBAR(mpReSimulationToolBar, ToolBars::reSimulationToolBar, false);
    mpReSimulationToolBar->setEnabled(mpVariablesDockWidget->isVisible() && !mpVariablesWidget->getVariablesTreeView()->selectionModel()->selectedIndexes().isEmpty());
    SHOW_HIDE_TOOLBAR(mpPlotToolBar, ToolBars::plotToolBar, false);
    SHOW_HIDE_TOOLBAR(mpDebuggerToolBar, ToolBars::debuggerToolBar, false);
  } else if (pModelWidget && pModelWidget->getLibraryTreeItem()->isCRML()) {
    pSettings->beginGroup(ToolBars::modelingTextPerspective);
    SHOW_HIDE_TOOLBAR(mpEditToolBar, ToolBars::editToolBar, true);
    SHOW_HIDE_TOOLBAR(mpViewToolBar, ToolBars::viewToolBar, true);
    SHOW_HIDE_TOOLBAR(mpShapesToolBar, ToolBars::shapesToolBar, false);
    SHOW_HIDE_TOOLBAR(mpModelSwitcherToolBar, ToolBars::modelSwitcherToolBar, true);
    SHOW_HIDE_TOOLBAR(mpCheckToolBar, ToolBars::checkToolBar, false);
    SHOW_HIDE_TOOLBAR(mpSimulationToolBar, ToolBars::simulationToolBar, false);
    SHOW_HIDE_TOOLBAR(mpReSimulationToolBar, ToolBars::reSimulationToolBar, false);
    mpReSimulationToolBar->setEnabled(mpVariablesDockWidget->isVisible() && !mpVariablesWidget->getVariablesTreeView()->selectionModel()->selectedIndexes().isEmpty());
    SHOW_HIDE_TOOLBAR(mpPlotToolBar, ToolBars::plotToolBar, false);
    SHOW_HIDE_TOOLBAR(mpDebuggerToolBar, ToolBars::debuggerToolBar, false);
    SHOW_HIDE_TOOLBAR(mpOMSimulatorToolbar, ToolBars::OMSimulatorToolBar, false);
  } else if (pModelWidget && pModelWidget->getLibraryTreeItem()->isSSP()) {
    pSettings->beginGroup(ToolBars::modelingOMSPerspective);
    SHOW_HIDE_TOOLBAR(mpEditToolBar, ToolBars::editToolBar, true);
    SHOW_HIDE_TOOLBAR(mpViewToolBar, ToolBars::viewToolBar, true);
    SHOW_HIDE_TOOLBAR(mpShapesToolBar, ToolBars::shapesToolBar, false);
    SHOW_HIDE_TOOLBAR(mpModelSwitcherToolBar, ToolBars::modelSwitcherToolBar, true);
    SHOW_HIDE_TOOLBAR(mpCheckToolBar, ToolBars::checkToolBar, false);
    SHOW_HIDE_TOOLBAR(mpSimulationToolBar, ToolBars::simulationToolBar, true);
    SHOW_HIDE_TOOLBAR(mpReSimulationToolBar, ToolBars::reSimulationToolBar, false);
    mpReSimulationToolBar->setEnabled(mpVariablesDockWidget->isVisible() && !mpVariablesWidget->getVariablesTreeView()->selectionModel()->selectedIndexes().isEmpty());
    SHOW_HIDE_TOOLBAR(mpPlotToolBar, ToolBars::plotToolBar, false);
    SHOW_HIDE_TOOLBAR(mpDebuggerToolBar, ToolBars::debuggerToolBar, false);
    SHOW_HIDE_TOOLBAR(mpOMSimulatorToolbar, ToolBars::OMSimulatorToolBar, true);
  } else { // Covers the case of LibraryTreeItem::Modelica and default.
    pSettings->beginGroup(ToolBars::modelingModelicaPerspective);
    SHOW_HIDE_TOOLBAR(mpEditToolBar, ToolBars::editToolBar, true);
    SHOW_HIDE_TOOLBAR(mpViewToolBar, ToolBars::viewToolBar, true);
    SHOW_HIDE_TOOLBAR(mpShapesToolBar, ToolBars::shapesToolBar, true);
    SHOW_HIDE_TOOLBAR(mpModelSwitcherToolBar, ToolBars::modelSwitcherToolBar, true);
    SHOW_HIDE_TOOLBAR(mpCheckToolBar, ToolBars::checkToolBar, true);
    SHOW_HIDE_TOOLBAR(mpSimulationToolBar, ToolBars::simulationToolBar, true);
    SHOW_HIDE_TOOLBAR(mpReSimulationToolBar, ToolBars::reSimulationToolBar, false);
    mpReSimulationToolBar->setEnabled(mpVariablesDockWidget->isVisible() && !mpVariablesWidget->getVariablesTreeView()->selectionModel()->selectedIndexes().isEmpty());
    SHOW_HIDE_TOOLBAR(mpPlotToolBar, ToolBars::plotToolBar, false);
    SHOW_HIDE_TOOLBAR(mpDebuggerToolBar, ToolBars::debuggerToolBar, false);
    SHOW_HIDE_TOOLBAR(mpOMSimulatorToolbar, ToolBars::OMSimulatorToolBar, false);
  }
  pSettings->endGroup();
}

/*!
 * \brief MainWindow::showDebuggingPerspectiveToolBars
 * Updates the toolbars visibility for Debugging perspective based on the active library type.
 * \param pModelWidget
 */
void MainWindow::showDebuggingPerspectiveToolBars(ModelWidget *pModelWidget)
{
  if (mRestoringState) {
    return;
  }
  // show/hide toolbars
  QSettings *pSettings = Utilities::getApplicationSettings();
  if (pModelWidget && pModelWidget->getLibraryTreeItem()->isText()) {
    pSettings->beginGroup(ToolBars::debuggingTextPerspective);
    SHOW_HIDE_TOOLBAR(mpEditToolBar, ToolBars::editToolBar, true);
    SHOW_HIDE_TOOLBAR(mpViewToolBar, ToolBars::viewToolBar, true);
    SHOW_HIDE_TOOLBAR(mpShapesToolBar, ToolBars::shapesToolBar, false);
    SHOW_HIDE_TOOLBAR(mpModelSwitcherToolBar, ToolBars::modelSwitcherToolBar, true);
    SHOW_HIDE_TOOLBAR(mpCheckToolBar, ToolBars::checkToolBar, false);
    SHOW_HIDE_TOOLBAR(mpSimulationToolBar, ToolBars::simulationToolBar, false);
    SHOW_HIDE_TOOLBAR(mpReSimulationToolBar, ToolBars::reSimulationToolBar, false);
    mpReSimulationToolBar->setEnabled(mpVariablesDockWidget->isVisible() && !mpVariablesWidget->getVariablesTreeView()->selectionModel()->selectedIndexes().isEmpty());
    SHOW_HIDE_TOOLBAR(mpPlotToolBar, ToolBars::plotToolBar, false);
    SHOW_HIDE_TOOLBAR(mpDebuggerToolBar, ToolBars::debuggerToolBar, true);
    SHOW_HIDE_TOOLBAR(mpOMSimulatorToolbar, ToolBars::OMSimulatorToolBar, false);
  } else if (pModelWidget && pModelWidget->getLibraryTreeItem()->isSSP()) {
    pSettings->beginGroup(ToolBars::debuggingOMSPerspective);
    SHOW_HIDE_TOOLBAR(mpEditToolBar, ToolBars::editToolBar, true);
    SHOW_HIDE_TOOLBAR(mpViewToolBar, ToolBars::viewToolBar, true);
    SHOW_HIDE_TOOLBAR(mpShapesToolBar, ToolBars::shapesToolBar, false);
    SHOW_HIDE_TOOLBAR(mpModelSwitcherToolBar, ToolBars::modelSwitcherToolBar, true);
    SHOW_HIDE_TOOLBAR(mpCheckToolBar, ToolBars::checkToolBar, false);
    SHOW_HIDE_TOOLBAR(mpSimulationToolBar, ToolBars::simulationToolBar, false);
    SHOW_HIDE_TOOLBAR(mpReSimulationToolBar, ToolBars::reSimulationToolBar, false);
    mpReSimulationToolBar->setEnabled(mpVariablesDockWidget->isVisible() && !mpVariablesWidget->getVariablesTreeView()->selectionModel()->selectedIndexes().isEmpty());
    SHOW_HIDE_TOOLBAR(mpPlotToolBar, ToolBars::plotToolBar, false);
    SHOW_HIDE_TOOLBAR(mpDebuggerToolBar, ToolBars::debuggerToolBar, true);
    SHOW_HIDE_TOOLBAR(mpOMSimulatorToolbar, ToolBars::OMSimulatorToolBar, true);
  } else { // Covers the case of LibraryTreeItem::Modelica and default.
    pSettings->beginGroup(ToolBars::debuggingModelicaPerspective);
    SHOW_HIDE_TOOLBAR(mpEditToolBar, ToolBars::editToolBar, true);
    SHOW_HIDE_TOOLBAR(mpViewToolBar, ToolBars::viewToolBar, true);
    SHOW_HIDE_TOOLBAR(mpShapesToolBar, ToolBars::shapesToolBar, true);
    SHOW_HIDE_TOOLBAR(mpModelSwitcherToolBar, ToolBars::modelSwitcherToolBar, true);
    SHOW_HIDE_TOOLBAR(mpCheckToolBar, ToolBars::checkToolBar, true);
    SHOW_HIDE_TOOLBAR(mpSimulationToolBar, ToolBars::simulationToolBar, true);
    SHOW_HIDE_TOOLBAR(mpReSimulationToolBar, ToolBars::reSimulationToolBar, false);
    mpReSimulationToolBar->setEnabled(mpVariablesDockWidget->isVisible() && !mpVariablesWidget->getVariablesTreeView()->selectionModel()->selectedIndexes().isEmpty());
    SHOW_HIDE_TOOLBAR(mpPlotToolBar, ToolBars::plotToolBar, false);
    SHOW_HIDE_TOOLBAR(mpDebuggerToolBar, ToolBars::debuggerToolBar, true);
    SHOW_HIDE_TOOLBAR(mpOMSimulatorToolbar, ToolBars::OMSimulatorToolBar, false);
  }
  pSettings->endGroup();
}

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
  foreach (QVariant file, files) {
    RecentFile recentFile = qvariant_cast<RecentFile>(file);
    QFileInfo file1(recentFile.fileName);
    QFileInfo file2(fileName);
    if (file1.absoluteFilePath().compare(file2.absoluteFilePath()) == 0) {
      files.removeOne(file);
    }
  }
  RecentFile recentFile;
  recentFile.fileName = fileName;
  recentFile.encoding = encoding;
  files.prepend(QVariant::fromValue(recentFile));
  pSettings->setValue("recentFilesList/files", files);
  updateRecentFileActionsAndList();
}

/*!
 * \brief MainWindow::updateRecentFileActionsAndList
 * Updates the actions of the recent files menu and recent files list on the welcome page.
 */
void MainWindow::updateRecentFileActionsAndList()
{
  /* read the new recent files list */
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> files = pSettings->value("recentFilesList/files").toList();
  int recentFilesSize = OptionsDialog::instance()->getGeneralSettingsPage()->getRecentFilesAndLatestNewsSizeSpinBox()->value();
  while (files.size() > recentFilesSize) {
    files.removeLast();
  }
  pSettings->setValue("recentFilesList/files", files);
  /* Clear the recent files menu. This will also delete the actions.
   * void QMenu::clear()
   * Removes all the menu's actions. Actions owned by the menu and not shown in any other widget are deleted.
   */
  mpRecentFilesMenu->clear();
  createRecentFileActions();
  mpWelcomePageWidget->addRecentFilesListItems();
}

/*!
 * \brief MainWindow::createRecentFileActions
 * Creates the recent file actions.
 */
void MainWindow::createRecentFileActions()
{
  /* read the new recent files list */
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> files = pSettings->value("recentFilesList/files").toList();
  int recentFilesSize = OptionsDialog::instance()->getGeneralSettingsPage()->getRecentFilesAndLatestNewsSizeSpinBox()->value();
  int numRecentFiles = qMin(files.size(), recentFilesSize);
  for (int i = 0; i < numRecentFiles; ++i) {
    RecentFile recentFile = qvariant_cast<RecentFile>(files[i]);
    QAction *pRecentFileAction = new QAction(this);
    pRecentFileAction->setText(recentFile.fileName);
    QStringList dataList;
    dataList << recentFile.fileName << recentFile.encoding;
    pRecentFileAction->setData(dataList);
    connect(pRecentFileAction, SIGNAL(triggered()), this, SLOT(openRecentFile()));
    mpRecentFilesMenu->addAction(pRecentFileAction);
  }
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
  if (!OptionsDialog::instance()->getNotificationsPage()->getQuitApplicationCheckBox()->isChecked() && !isTestsuiteRunning()) {
    NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::QuitApplication, NotificationsDialog::QuestionIcon, this);
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
  // Issue #9101. Close all top level windows
  foreach (QWidget *pWidget, QApplication::topLevelWidgets())  {
    if (pWidget == this) {
      continue;
    }
    pWidget->close();
  }
  mpOMCProxy->quitOMC();
  delete mpOMCProxy;
  // delete the OMSProxy object
  OMSProxy::destroy();
  delete mpLibraryWidget;
  delete mpElementWidget;
  delete mpModelWidgetContainer;
  // delete the ArchivedSimulationsWidget object
  ArchivedSimulationsWidget::destroy();
  if (mpSimulationDialog) {
    delete mpSimulationDialog;
  }
  if (mpOMSSimulationDialog) {
    delete mpOMSSimulationDialog;
  }

  QSettings *pSettings = Utilities::getApplicationSettings();
  /* delete the TransformationsWidgets */
  const int size = mTransformationsWidgetHash.size();
  int index = 0;
  QHashIterator<QString, TransformationsWidget*> transformationsWidgets(mTransformationsWidgetHash);
  transformationsWidgets.toFront();
  while (transformationsWidgets.hasNext()) {
    transformationsWidgets.next();
    TransformationsWidget *pTransformationsWidget = transformationsWidgets.value();
    index++;
    if (pTransformationsWidget) {
      /* save the TransformationsWidget last window geometry and splitters state. */
      if (index == size) { // last item
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
      delete pTransformationsWidget;
    }
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
        Utilities::removeDirectoryRecursively(fmuDirectory);
      }
    }
    mFMUDirectoriesList.clear();
  }
  // Delete the MOL directories
  foreach (QString molDirectory, mMOLDirectoriesList) {
    if (QDir().exists(molDirectory)) {
      Utilities::removeDirectoryRecursively(molDirectory);
    }
  }
  mMOLDirectoriesList.clear();
  // close any result file
  // delete the MessagesWidget object
  MessagesWidget::destroy();
  // set restoring state to true so we don't try to save the toolbars settings after deleting the setting object.
  mRestoringState = true;
  delete pSettings;
  // delete the OptionsDialog object
  OptionsDialog::destroy();
  // delete the GDBAdapter object
  GDBAdapter::destroy();
  // delete the GitCommands object
  GitCommands::destroy();
  // delete the searchwidget object to call the destructor, to cancel the search operation running on seperate thread
  delete mpSearchWidget;
  // if new api profiling file is open then close it.
  if (mpNewApiProfilingFile) {
    fclose(mpNewApiProfilingFile);
  }
}

/*!
 * \brief MainWindow::openDroppedFile
 * Opens the dropped file.
 * \param pMimeData
 */
void MainWindow::openDroppedFile(const QMimeData *pMimeData)
{
  int progressValue = 0;
  mpProgressBar->setRange(0, pMimeData->urls().size());
  showProgressBar();
  //retrieves the filenames of all the dragged files in list and opens the valid files.
  foreach (QUrl fileUrl, pMimeData->urls()) {
    QFileInfo fileInfo(fileUrl.toLocalFile());
    mpProgressBar->setValue(++progressValue);
    // check the file extension
    QRegExp resultFilesRegExp(Helper::omResultFileTypesRegExp);
    if (resultFilesRegExp.indexIn(fileInfo.suffix()) != -1) {
      openResultFile(fileInfo.absoluteFilePath());
    } else {
      mpLibraryWidget->openFile(fileInfo.absoluteFilePath(), Helper::utf8, false);
    }
  }
  hideProgressBar();
}

/*!
 * \brief MainWindow::openResultFile
 * Opens the result file.
 * \param fileName
 */
void MainWindow::openResultFile(const QString &fileName)
{
  mpStatusBar->showMessage(QString("%1: %2").arg(Helper::loading, fileName));
  QFileInfo fileInfo(fileName);
  QStringList list = mpOMCProxy->readSimulationResultVars(fileInfo.absoluteFilePath());
  if (list.size() > 0) {
    switchToPlottingPerspectiveSlot();
    mpVariablesWidget->insertVariablesItemsToTree(fileInfo.fileName(), fileInfo.absoluteDir().absolutePath(), list, SimulationOptions());
  }
  mpStatusBar->clearMessage();
}

void MainWindow::simulate(LibraryTreeItem *pLibraryTreeItem)
{
  if (pLibraryTreeItem->isModelica()) {
    if (!mpSimulationDialog) {
      mpSimulationDialog = new SimulationDialog(this);
    }
    /* if Modelica text is changed manually by user then validate it before saving. */
    if (pLibraryTreeItem->getModelWidget()) {
      if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
        return;
      }
    }
    mpSimulationDialog->directSimulate(pLibraryTreeItem, false, false, false, false);
  } else if (pLibraryTreeItem->isSSP()) {
    // get the top level LibraryTreeItem
    LibraryTreeItem *pTopLevelLibraryTreeItem = mpLibraryWidget->getLibraryTreeModel()->getTopLevelLibraryTreeItem(pLibraryTreeItem);
    if (pTopLevelLibraryTreeItem) {
      if (!mpOMSSimulationDialog) {
        mpOMSSimulationDialog = new OMSSimulationDialog(this);
      }
      if (pTopLevelLibraryTreeItem) {
        mpOMSSimulationDialog->simulate(pTopLevelLibraryTreeItem);
      }
    }
  }
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
  mpSimulationDialog->directSimulate(pLibraryTreeItem, true, false, false, false);
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
  mpSimulationDialog->directSimulate(pLibraryTreeItem, false, true, false, false);
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
  mpSimulationDialog->directSimulate(pLibraryTreeItem, false, false, true, false);
}
#endif

void MainWindow::simulationSetup(LibraryTreeItem *pLibraryTreeItem)
{
  if (pLibraryTreeItem->isModelica()) {
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
  } else if (pLibraryTreeItem->isSSP()) {
    // get the top level LibraryTreeItem
    LibraryTreeItem *pTopLevelLibraryTreeItem = mpLibraryWidget->getLibraryTreeModel()->getTopLevelLibraryTreeItem(pLibraryTreeItem);
    if (pTopLevelLibraryTreeItem) {
      if (!mpOMSSimulationDialog) {
        mpOMSSimulationDialog = new OMSSimulationDialog(this);
      }
      mpOMSSimulationDialog->exec(pTopLevelLibraryTreeItem->getNameStructure(), pLibraryTreeItem);
    }
  }
}

/*!
 * \brief MainWindow::translateCRML
 * Translates the CRML model.
 * \param pLibraryTreeItem
 */
void MainWindow::translateCRML(LibraryTreeItem *pLibraryTreeItem)
{
  /* if CRML text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }

  CRMLTranslatorOptions crmlTranslatorOptions;
  crmlTranslatorOptions.setMode("translate");
  crmlTranslatorOptions.setCRMLFile(pLibraryTreeItem->getFileName());
  crmlTranslatorOptions.setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
  CRMLPage *pCRMLPage = OptionsDialog::instance()->getCRMLPage();
  crmlTranslatorOptions.setCompilerJar(pCRMLPage->getCompilerJarTextBox()->text());
  crmlTranslatorOptions.setCompilerCommandLineOptions(pCRMLPage->getCompilerCommandLineOptionsTextBox()->text());
  crmlTranslatorOptions.setCompilerProcess(pCRMLPage->getCompilerProcessTextBox()->text());
  crmlTranslatorOptions.setModelicaLibraries(pCRMLPage->getModelicaLibraries()->items());

  CRMLTranslatorOutputWidget *pCRMLTranslatorOutputWidget = new CRMLTranslatorOutputWidget(crmlTranslatorOptions);
  MessagesWidget::instance()->addSimulationOutputTab(pCRMLTranslatorOutputWidget, pLibraryTreeItem->getName());
  pCRMLTranslatorOutputWidget->start();
}

void MainWindow::translateAsCRML(LibraryTreeItem *pLibraryTreeItem)
{
  /* if the CRML text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }

  CRMLTranslatorOptions crmlTranslatorOptions;
  crmlTranslatorOptions.setMode("translateAs");
  crmlTranslatorOptions.setCRMLFile(pLibraryTreeItem->getFileName());
  crmlTranslatorOptions.setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
  CRMLPage *pCRMLPage = OptionsDialog::instance()->getCRMLPage();
  crmlTranslatorOptions.setCompilerJar(pCRMLPage->getCompilerJarTextBox()->text());
  crmlTranslatorOptions.setCompilerCommandLineOptions(pCRMLPage->getCompilerCommandLineOptionsTextBox()->text());
  crmlTranslatorOptions.setCompilerProcess(pCRMLPage->getCompilerProcessTextBox()->text());
  crmlTranslatorOptions.setModelicaLibraries(pCRMLPage->getModelicaLibraries()->items());
  // output directory and within will be set from the CRMLTranslateAsDialog
  CRMLTranslateAsDialog *pCRMLTranslateAsDialog = new CRMLTranslateAsDialog(&crmlTranslatorOptions, this);
  if (pCRMLTranslateAsDialog->exec()) {
    CRMLTranslatorOutputWidget *pCRMLTranslatorOutputWidget = new CRMLTranslatorOutputWidget(crmlTranslatorOptions);
    MessagesWidget::instance()->addSimulationOutputTab(pCRMLTranslatorOutputWidget, pLibraryTreeItem->getName());
    pCRMLTranslatorOutputWidget->start();
  }
}

void MainWindow::runScript(LibraryTreeItem *pLibraryTreeItem)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  // set the status message.
  mpStatusBar->showMessage(QString("%1 %2").arg(Helper::runScript, pLibraryTreeItem->getNameStructure()));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  QString result = mpOMCProxy->runScript(pLibraryTreeItem->getFileName());
  if (!result.isEmpty()) {
    QString windowTitle = QString("%1 - %2").arg(Helper::runScript, pLibraryTreeItem->getNameStructure());
    InformationDialog *pInformationDialog = new InformationDialog(windowTitle, result, true, this);
    pInformationDialog->show();
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
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
  mpStatusBar->showMessage(QString("%1 %2").arg(Helper::instantiateModel, pLibraryTreeItem->getNameStructure()));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  // check reset messages number before instantiating
  if (OptionsDialog::instance()->getMessagesPage()->getResetMessagesNumberBeforeSimulationCheckBox()->isChecked()) {
    MessagesWidget::instance()->resetMessagesNumber();
  }
  // check clear message browser before instantiating
  if (OptionsDialog::instance()->getMessagesPage()->getClearMessagesBrowserBeforeSimulationCheckBox()->isChecked()) {
    MessagesWidget::instance()->clearMessages();
  }
  QString instantiateModelResult = mpOMCProxy->instantiateModel(pLibraryTreeItem->getNameStructure());
  if (!instantiateModelResult.isEmpty()) {
    QString windowTitle = QString("%1 - %2").arg(Helper::instantiateModel, pLibraryTreeItem->getNameStructure());
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
  mpStatusBar->showMessage(QString("%1 %2").arg(Helper::checkModel, pLibraryTreeItem->getNameStructure()));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  // check reset messages number before checking
  if (OptionsDialog::instance()->getMessagesPage()->getResetMessagesNumberBeforeSimulationCheckBox()->isChecked()) {
    MessagesWidget::instance()->resetMessagesNumber();
  }
  // check clear message browser before checking
  if (OptionsDialog::instance()->getMessagesPage()->getClearMessagesBrowserBeforeSimulationCheckBox()->isChecked()) {
    MessagesWidget::instance()->clearMessages();
  }
  QString checkModelResult = mpOMCProxy->checkModel(pLibraryTreeItem->getNameStructure());
  if (!checkModelResult.isEmpty()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, checkModelResult, Helper::scriptingKind, Helper::notificationLevel));
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
  mpStatusBar->showMessage(QString("%1 %2").arg(Helper::checkModel, pLibraryTreeItem->getNameStructure()));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  QString checkAllModelsResult = mpOMCProxy->checkAllModelsRecursive(pLibraryTreeItem->getNameStructure());
  if (!checkAllModelsResult.isEmpty()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, checkAllModelsResult, Helper::scriptingKind, Helper::notificationLevel));
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

void MainWindow::exportModelFMU(LibraryTreeItem *pLibraryTreeItem)
{
  // check for supported targetLanguage C or Cpp
  QString targetLanguage = OptionsDialog::instance()->getSimulationPage()->getTargetLanguageComboBox()->currentText();
  if (targetLanguage.compare("C") != 0 && targetLanguage.compare("Cpp") != 0) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Target Language <b>%1</b> is not supported for FMU Export. Only <b>C</b> and <b>Cpp</b> are supported").arg(targetLanguage),
                                                                  tr("FMU_EXPORT Failed"), Helper::errorLevel));
    return;
  }

  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeItem->getModelWidget()) {
    if (!pLibraryTreeItem->getModelWidget()->validateText(&pLibraryTreeItem)) {
      return;
    }
  }
  // set the status message.
  mpStatusBar->showMessage(tr("Translating model %1 as FMU").arg(pLibraryTreeItem->getName()));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  /*
   * create a folder with hashed string from model name
   * see https://github.com/OpenModelica/OpenModelica/issues/12171, to have short temp directory path and dump the files in it.
  */
  QString modelDirectoryPath = QString("%1/%2%3").arg(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory(), pLibraryTreeItem->getName(), Utilities::generateHash(pLibraryTreeItem->getNameStructure()));

  QDir dir(modelDirectoryPath);
  if (dir.exists()) {
    dir.removeRecursively();
  }
  dir.mkpath(modelDirectoryPath);

  // set the folder as working directory
  MainWindow::instance()->getOMCProxy()->changeDirectory(modelDirectoryPath);
  // buildModelFMU parameters
  QString version = OptionsDialog::instance()->getFMIPage()->getFMIExportVersion();
  QString type = OptionsDialog::instance()->getFMIPage()->getFMIExportType();
  QString FMUName = OptionsDialog::instance()->getFMIPage()->getFMUNameTextBox()->text();
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QString> platforms;
  if (pSettings->contains("FMIExport/Platforms")) {
    platforms = pSettings->value("FMIExport/Platforms").toStringList();
  } else {
    platforms.append("static"); // default is static
  }
  if (platforms.empty()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::FMU_EMPTY_PLATFORMS).arg(Helper::toolsOptionsPath),
                                                          Helper::scriptingKind, Helper::warningLevel));
  }
  QString fmiFlags = OptionsDialog::instance()->getFMIPage()->getFMIFlags();
  if (!fmiFlags.isEmpty()) {
    mpOMCProxy->setCommandLineOptions(QString("--fmiFlags=%1").arg(fmiFlags));
  }
  mpOMCProxy->setCommandLineOptions(QString("--fmiFilter=%1").arg(OptionsDialog::instance()->getFMIPage()->getModelDescriptionFiltersComboBox()->currentText()));
  mpOMCProxy->setCommandLineOptions(QString("--fmiSources=%1").arg(OptionsDialog::instance()->getFMIPage()->getIncludeSourceCodeCheckBox()->isChecked() ? "true" : "false"));
  // set the generate debug symbols flag
  if (OptionsDialog::instance()->getFMIPage()->getGenerateDebugSymbolsCheckBox()->isChecked()) {
    mpOMCProxy->setCommandLineOptions(QString("-d=gendebugsymbols"));
  }
  bool includeResources = OptionsDialog::instance()->getFMIPage()->getIncludeResourcesCheckBox()->isChecked();
  bool isTranslationSuccessful = mpOMCProxy->translateModelFMU(pLibraryTreeItem->getNameStructure(), version, type, FMUName, platforms, includeResources);
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();

  if (isTranslationSuccessful) {
    // create a FMU compilation window  similar to simulation process
    FmuExportOutputWidget * pFmuExportOutputWidget = new FmuExportOutputWidget(pLibraryTreeItem, this);
    MessagesWidget::instance()->addSimulationOutputTab(pFmuExportOutputWidget, pLibraryTreeItem->getName() + "_fmuExport");
    if (targetLanguage.compare("C") == 0) {
      pFmuExportOutputWidget->compileModelCRuntime();
    } else {
      pFmuExportOutputWidget->compileModelCppRuntime();
    }
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, QString("Translation of FMU: <b>%1</b> Failed").arg(pLibraryTreeItem->getName()),
                                                                  "Translation Error", Helper::errorLevel));
  }
}

#ifndef OM_ENABLE_ENCRYPTION
void showEncryptionSupportMessage()
{
  QMessageBox::information(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName).arg(Helper::information),
                           QString("The open-source versions of OpenModelica cannot handle encrypted libraries,"
                                   " because the private key for decryption cannot be made public.<br /><br />"
                                   "OpenModelica supports loading encrypted libraries through SEMLA technology, provided by Modelon AB."
                                   " For that, you need a special version of OpenModelica that is only released in binary form;"
                                   " please contact your library supplier for information on how to get it.<br /><br />"
                                   "Read more about <u><a href=\"https://openmodelica.org/doc/OpenModelicaUsersGuide/%1/encryption.html\">OpenModelica Encryption</a></u>.")
                           .arg(Helper::OpenModelicaUsersGuideVersion), QMessageBox::Ok);
}
#endif // OM_ENABLE_ENCRYPTION

/*!
 * \brief MainWindow::exportEncryptedPackage
 * Exports the package as encrypted package
 * \param pLibraryTreeItem
 */
void MainWindow::exportEncryptedPackage(LibraryTreeItem *pLibraryTreeItem)
{
#ifdef OM_ENABLE_ENCRYPTION
  if (!pLibraryTreeItem) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                          .arg(tr("making encrypted package")), Helper::scriptingKind, Helper::notificationLevel));
    return;
  }
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
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
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
#else // OM_ENABLE_ENCRYPTION
  Q_UNUSED(pLibraryTreeItem);
  showEncryptionSupportMessage();
#endif // OM_ENABLE_ENCRYPTION
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
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
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
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
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
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  textStream.setEncoding(QStringConverter::Utf8);
#else
  textStream.setCodec(Helper::utf8.toUtf8().constData());
#endif
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
  painter.fillRect(modelImage.rect(), pGraphicsView->palette().window());
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
 * \param fileName - path to model_info.json file.
 * \param profiling - enable/disable profiling
 * \param checkProfilingExists - check profiling files exists
 * \return
 */
TransformationsWidget *MainWindow::showTransformationsWidget(QString fileName, bool profiling, bool checkProfilingExists)
{
  TransformationsWidget *pTransformationsWidget = mTransformationsWidgetHash.value(fileName, 0);
  if (!pTransformationsWidget) {
    pTransformationsWidget = new TransformationsWidget(fileName, profiling, checkProfilingExists);
    mTransformationsWidgetHash.insert(fileName, pTransformationsWidget);
  } else {
    pTransformationsWidget->loadTransformations(profiling, checkProfilingExists);
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
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg, Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief MainWindow::printStandardOutAndErrorFilesMessages
 * Reads the omeditoutput.txt and omediterror.txt files and add the data to Message Browser if there is any.
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
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, outputFileData, Helper::scriptingKind, Helper::notificationLevel));
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
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, errorFileData, Helper::scriptingKind, Helper::errorLevel));
      }
    }
    errorFile.close();
  }
}

/*!
 * \brief MainWindow::PlotCallbackFunction
 * Callback function to handle the plot API calls.
 * \param p
 * \param externalWindow
 * \param filename
 * \param title
 * \param grid
 * \param plotType
 * \param logX
 * \param logY
 * \param xLabel
 * \param yLabel
 * \param x1
 * \param x2
 * \param y1
 * \param y2
 * \param curveWidth
 * \param curveStyle
 * \param legendPosition
 * \param footer
 * \param autoScale
 * \param variables
 */
void MainWindow::PlotCallbackFunction(void *p, int externalWindow, const char* filename, const char *title, const char *grid,
                                      const char *plotType, const char *logX, const char *logY, const char *xLabel, const char *yLabel,
                                      const char *x1, const char *x2, const char *y1, const char *y2, const char *curveWidth,
                                      const char *curveStyle, const char *legendPosition, const char *footer, const char *autoScale, const char *variables)
{
  MainWindow *pMainWindow = (MainWindow*)p;
  if (pMainWindow) {
    QFileInfo fileInfo(filename);
    pMainWindow->openResultFile(filename);
    if (!fileInfo.exists()) return;
    OMPlot::PlotWindow *pPlotWindow = pMainWindow->getPlotWindowContainer()->getCurrentWindow();
    if (pPlotWindow && !externalWindow) {
      if (pPlotWindow->isPlot() && strcmp(plotType, "plotparametric") == 0) {
        pMainWindow->getPlotWindowContainer()->addParametricPlotWindow();
      } else if (pPlotWindow->isPlotParametric() && ((strcmp(plotType, "plot") == 0) || (strcmp(plotType, "plotall") == 0))) {
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
#if QT_VERSION >= QT_VERSION_CHECK(5, 14, 0)
    QStringList variablesList = QString(variables).split(" ", Qt::SkipEmptyParts);
#else // QT_VERSION_CHECK
    QStringList variablesList = QString(variables).split(" ", QString::SkipEmptyParts);
#endif // QT_VERSION_CHECK
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
        pMainWindow->getVariablesWidget()->plotVariables(index, pPlotWindow->getCurveWidth(), pPlotWindow->getCurveStyle(), Qt::NoModifier, pPlotCurve);
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
 * \brief MainWindow::LoadModelCallbackFunction
 * Callback function to handle automatically loaded libraries.
 * \param p
 * \param modelName
 */
void MainWindow::LoadModelCallbackFunction(void *p, const char *modelName)
{
  MainWindow *pMainWindow = (MainWindow*)p;
  if (pMainWindow) {
    pMainWindow->getLibraryWidget()->loadAutoLoadedLibrary(QString(modelName));
  }
}

/*!
 * \brief MainWindow::addSystemLibraries
 * Add the system libraries to the menu.
 */
void MainWindow::addSystemLibraries()
{
  if (mpLibrariesMenu) {
    mpLibrariesMenu->clear();
    // get the available libraries and versions.
    QStringList libraries = MainWindow::instance()->getOMCProxy()->getAvailableLibraries();
    foreach (QString library, libraries) {
      QStringList versions = MainWindow::instance()->getOMCProxy()->getAvailableLibraryVersions(library);
      if (versions.isEmpty()) {
        QAction *pAction = new QAction(library, this);
        pAction->setData(QStringList() << library << "");
        connect(pAction, SIGNAL(triggered()), mpLibraryWidget, SLOT(loadSystemLibrary()));
        mpLibrariesMenu->addAction(pAction);
      } else {
        QMenu *pLibraryMenu = new QMenu(library);
        foreach (QString version, versions) {
          QAction *pAction = new QAction(StringHandler::convertSemVertoReadableString(version), this);
          pAction->setData(QStringList() << library << version);
          connect(pAction, SIGNAL(triggered()), mpLibraryWidget, SLOT(loadSystemLibrary()));
          pLibraryMenu->addAction(pAction);
        }
        mpLibrariesMenu->addMenu(pLibraryMenu);
      }
    }
  }
}

/*!
 * \brief MainWindow::getLibraryIndexFilePath
 * Returns the library index file path.
 * \return
 */
QString MainWindow::getLibraryIndexFilePath() const
{
  return QString("%1/.openmodelica/libraries/index.json").arg(Helper::userHomeDirectory);
}

/*!
 * \brief MainWindow::writeNewApiProfiling
 * Writes to new api profiling file.
 * \param str
 */
void MainWindow::writeNewApiProfiling(const QString &str)
{
  if (mpNewApiProfilingFile) {
    fputs(QString("%1\n").arg(str).toUtf8().constData(), mpNewApiProfilingFile);
    fflush(mpNewApiProfilingFile);
  }
}

/*!
 * \brief MainWindow::markMessagesTabWidgetChangedForNewMessage
 * Start the animation of MessageTab.
 * \param errorType
 */
void MainWindow::markMessagesTabWidgetChangedForNewMessage(StringHandler::OpenModelicaErrors errorType)
{
  MessageTab *pMessageTab = 0;
  switch (errorType) {
    case StringHandler::Notification:
      pMessageTab = qobject_cast<MessageTab*>(mpMessagesTabWidget->widget(1));
      break;
    case StringHandler::Warning:
      pMessageTab = qobject_cast<MessageTab*>(mpMessagesTabWidget->widget(2));
      break;
    case StringHandler::Internal:
    case StringHandler::OMError:
      pMessageTab = qobject_cast<MessageTab*>(mpMessagesTabWidget->widget(3));
      break;
    default:
      break;
  }

  if (pMessageTab) {
    pMessageTab->markTabChanged();
  }

  MessageTab *pAllMessageTab = qobject_cast<MessageTab*>(mpMessagesTabWidget->widget(0));
  if (pAllMessageTab) {
    pAllMessageTab->markTabChanged();
  }
}

/*!
 * \brief MainWindow::showMessageBrowser
 * Slot activated when MessagesWidget::messageAdded signal is raised.\n
 * Shows the Message Browser.
 */
void MainWindow::showMessageBrowser()
{
  mpMessagesDockWidget->show();
  // In case user has tabbed the dock widgets then make Message Browser active.
  QList<QDockWidget*> tabifiedDockWidgetsList = tabifiedDockWidgets(mpMessagesDockWidget);
  if (tabifiedDockWidgetsList.size() > 0) {
    tabifyDockWidget(tabifiedDockWidgetsList.at(0), mpMessagesDockWidget);
  }
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

/*!
 * \brief MainWindow::createNewModelicaClass
 * Opens the new model dialog.
 */
void MainWindow::createNewModelicaClass()
{
  ModelicaClassDialog *pModelicaClassDialog = new ModelicaClassDialog(this);
  pModelicaClassDialog->exec();
}

/*!
 * \brief MainWindow::createNewMOSFile
 * Opens the new Modelica Scripting dialog.
 */
void MainWindow::createNewMOSFile()
{
  CreateNewItemDialog *pCreateNewItemDialog = new CreateNewItemDialog("", true, ".mos", this);
  pCreateNewItemDialog->exec();
}

/*!
 * \brief MainWindow::createNewSSPModel
 * Opens the new SSP model dialog.
 */
void MainWindow::createNewSSPModel()
{
  CreateModelDialog *pCreateModelDialog = new CreateModelDialog(this);
  pCreateModelDialog->exec();
}

/*!
 * \brief MainWindow::createNewCRMLFile
 * Opens the new CRML Model dialog.
 */
void MainWindow::createNewCRMLFile()
{
  CreateNewItemDialog *pCreateNewItemDialog = new CreateNewItemDialog("", true, ".crml", this);
  pCreateNewItemDialog->exec();
}

void MainWindow::openModelicaFile()
{
  QStringList fileNames;
  fileNames = StringHandler::getOpenFileNames(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFiles), NULL, Helper::omFileTypes, NULL);
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
      pMessageBox->setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::error));
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
#ifdef OM_ENABLE_ENCRYPTION
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
#else // OM_ENABLE_ENCRYPTION
  showEncryptionSupportMessage();
#endif // OM_ENABLE_ENCRYPTION
}

/*!
 * \brief MainWindow::showOpenResultFileDialog
 * Shows the dialog to open the result files.
 */
void MainWindow::showOpenResultFileDialog()
{
  QStringList fileNames = StringHandler::getOpenFileNames(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFiles), NULL, Helper::omResultFileTypes, NULL);
  if (fileNames.isEmpty()) {
    return;
  }
  int progressValue = 0;
  mpProgressBar->setRange(0, fileNames.size());
  showProgressBar();
  foreach (QString fileName, fileNames) {
    mpProgressBar->setValue(++progressValue);
    openResultFile(fileName);
  }
  hideProgressBar();

}

/*!
 * \brief MainWindow::showOpenTransformationFileDialog
 * Slot activated when mpOpenTransformationFileAction triggered signal is raised.\n
 * Shows a TransformationsWidget.
 */
void MainWindow::showOpenTransformationFileDialog()
{
  QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, Helper::infoXmlFileTypes, NULL);
  if (fileName.isEmpty()) {
    return;
  }
  mpProgressBar->setRange(0, 0);
  mpStatusBar->showMessage(QString("%1: %2").arg(Helper::loading, fileName));
  showTransformationsWidget(fileName, false, true);
  mpStatusBar->clearMessage();
  hideProgressBar();
}

/*!
 * \brief MainWindow::unloadAll
 * Slot activated when mpUnloadAll triggered signal is raised.\n
 * Unloads all the loaded classes.
 * \param onlyModelicaClasses
 */
void MainWindow::unloadAll(bool onlyModelicaClasses)
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->getRootLibraryTreeItem();
  for (int i = pLibraryTreeItem->childrenSize(); --i >= 0; ) {
    LibraryTreeItem *pChildLibraryTreeItem = pLibraryTreeItem->child(i);
    if (pChildLibraryTreeItem) {
      if ((pChildLibraryTreeItem->getNameStructure().compare(Helper::OMEditInternal) == 0)) {
        continue;
      } else if (pChildLibraryTreeItem->isModelica()) {
        MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->unloadClass(pChildLibraryTreeItem, false, false);
      } else if (!onlyModelicaClasses && pChildLibraryTreeItem->isSSP()) {
        MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->unloadOMSModel(pChildLibraryTreeItem, true, false);
      } else if (!onlyModelicaClasses) { // LibraryTreeItem::Text
        MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->unloadTextFile(pChildLibraryTreeItem, false);
      }
    }
  }
  // clear everything from OMC
  MainWindow::instance()->getOMCProxy()->clear();
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
 * \brief MainWindow::writeOutputFileData
 * Writes the output data from stdout file and adds it to MessagesWidget.
 * \param data
 */
void MainWindow::writeOutputFileData(QString data)
{
  MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, data, Helper::scriptingKind, Helper::notificationLevel));
}

/*!
 * \brief MainWindow::writeErrorFileData
 * Writes the error data from stderr file and adds it to MessagesWidget.
 * \param data
 */
void MainWindow::writeErrorFileData(QString data)
{
  MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, data, Helper::scriptingKind, Helper::errorLevel));
}

/*!
 * \brief MainWindow::openRecentFile
 * Opens the recent file.
 */
void MainWindow::openRecentFile()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction) {
    QStringList dataList = pAction->data().toStringList();
    mpLibraryWidget->openFile(dataList.at(0), dataList.at(1), true, true);
  }
}

/*!
 * \brief MainWindow::clearRecentFilesList
 * Clears the recent files list. Asks the user for confirmation.
 */
void MainWindow::clearRecentFilesList()
{
  QMessageBox *pMessageBox = new QMessageBox(this);
  pMessageBox->setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::question));
  pMessageBox->setIcon(QMessageBox::Question);
  pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
  pMessageBox->setText(tr("Are you sure you want to clear recent files?"));
  pMessageBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
  pMessageBox->setDefaultButton(QMessageBox::Yes);
  int answer = pMessageBox->exec();
  switch (answer) {
    case QMessageBox::Yes:
      {
        QSettings *pSettings = Utilities::getApplicationSettings();
        pSettings->remove("recentFilesList/files");
        updateRecentFileActionsAndList();
      }
      break;
    case QMessageBox::No:
      // No was clicked.
      break;
    default:
      // should never be reached
      break;
  }
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
 * Sets the focus on filter classes text box in Library Browser.
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
  if (isModelingPerspectiveActive()) {
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
  } else if (isPlottingPerspectiveActive()) {
    if (mpPlotWindowContainer->currentSubWindow() && mpPlotWindowContainer->isDiagramWindow(mpPlotWindowContainer->currentSubWindow()->widget())
        && mpPlotWindowContainer->getDiagramWindow() && mpPlotWindowContainer->getDiagramWindow()->getModelWidget()) {
      mpPlotWindowContainer->getDiagramWindow()->getModelWidget()->getDiagramGraphicsView()->resetZoom();
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
  if (isModelingPerspectiveActive()) {
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
  } else if (isPlottingPerspectiveActive()) {
    if (mpPlotWindowContainer->currentSubWindow() && mpPlotWindowContainer->isDiagramWindow(mpPlotWindowContainer->currentSubWindow()->widget())
        && mpPlotWindowContainer->getDiagramWindow() && mpPlotWindowContainer->getDiagramWindow()->getModelWidget()) {
      mpPlotWindowContainer->getDiagramWindow()->getModelWidget()->getDiagramGraphicsView()->zoomIn();
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
  if (isModelingPerspectiveActive()) {
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
  } else if (isPlottingPerspectiveActive()) {
    if (mpPlotWindowContainer->currentSubWindow() && mpPlotWindowContainer->isDiagramWindow(mpPlotWindowContainer->currentSubWindow()->widget())
        && mpPlotWindowContainer->getDiagramWindow() && mpPlotWindowContainer->getDiagramWindow()->getModelWidget()) {
      mpPlotWindowContainer->getDiagramWindow()->getModelWidget()->getDiagramGraphicsView()->zoomOut();
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

void MainWindow::checkModel()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    checkModel(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                .arg(tr("checking")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

void MainWindow::checkAllModels()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    checkAllModels(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                .arg(tr("checking")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

void MainWindow::instantiateModel()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    instantiateModel(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                .arg(tr("instantiating")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

/*!
 * \brief MainWindow::openSimulationDialog
 * Opens the Simualtion Dialog.
 */
void MainWindow::openSimulationDialog()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    simulationSetup(pModelWidget->getLibraryTreeItem());
  }
}

/*!
 * \brief MainWindow::simulateModel
 * Simulates the model directly.
 */
void MainWindow::simulateModel()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    simulate(pModelWidget->getLibraryTreeItem());
  }
}

/*!
 * \brief MainWindow::simulateModelWithAnimation
 * Simulates the model directly with animation flag.
 */
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
 * \brief MainWindow::simulateModelWithTransformationalDebugger
 * Simulates the model with transformational debugger
 */
void MainWindow::simulateModelWithTransformationalDebugger()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    simulateWithTransformationalDebugger(pModelWidget->getLibraryTreeItem());
  }
}

/*!
 * \brief MainWindow::simulateModelWithAlgorithmicDebugger
 * Simulates the model with algorithmic debugger
 */
void MainWindow::simulateModelWithAlgorithmicDebugger()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    simulateWithAlgorithmicDebugger(pModelWidget->getLibraryTreeItem());
  }
}

void MainWindow::simulateModelInteractive()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getLibraryTreeItem() && pModelWidget->getLibraryTreeItem()->isSSP()) {
    // get the top level LibraryTreeItem
    LibraryTreeItem *pTopLevelLibraryTreeItem = mpLibraryWidget->getLibraryTreeModel()->getTopLevelLibraryTreeItem(pModelWidget->getLibraryTreeItem());
    if (pTopLevelLibraryTreeItem) {
      if (!mpOMSSimulationDialog) {
        mpOMSSimulationDialog = new OMSSimulationDialog(this);
      }
      if (pTopLevelLibraryTreeItem) {
        mpOMSSimulationDialog->simulate(pTopLevelLibraryTreeItem, true);
      }
    }
  }
}

/*!
 * \brief MainWindow::showArchivedSimulations
 * Shows the list of archived simulations.
 */
void MainWindow::showArchivedSimulations()
{
  ArchivedSimulationsWidget::instance()->show();
}

/*!
 * \brief MainWindow::exportModelFMU
 * Exports the current model to FMU
 */
void MainWindow::exportModelFMU()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    exportModelFMU(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
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
    exportEncryptedPackage(0);
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
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                          .arg(tr("making read-only package")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

//! Exports the current model to XML
void MainWindow::exportModelXML()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget) {
    exportModelXML(pModelWidget->getLibraryTreeItem());
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
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
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                          .arg(tr("exporting to Figaro")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

#ifdef Q_OS_WIN
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
  QDetachableProcess process;
  process.setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
  process.start(commandPrompt, args);
  if (process.error() == QProcess::FailedToStart) {
    QString errorString = tr("Unable to run command <b>%1</b> with arguments <b>%2</b>. Process failed with error <b>%3</b>").arg(commandPrompt, args.join(" "), process.errorString());
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, errorString, Helper::scriptingKind, Helper::errorLevel));
  }
}
#endif

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
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                          .arg(tr("exporting to OMNotebook")), Helper::scriptingKind, Helper::notificationLevel));
  }
}

/*!
 * \brief MainWindow::openInstallLibraryDialog
 * Opens the install library dialog.
 */
bool MainWindow::openInstallLibraryDialog()
{
  updateLibraryIndex(false);
  bool returnValue = false;
  QString indexFilePath = getLibraryIndexFilePath();
  if (QFile::exists(indexFilePath)) {
    InstallLibraryDialog *pInstallLibraryDialog = new InstallLibraryDialog;
    returnValue = pInstallLibraryDialog->exec();
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::LIBRARY_INDEX_FILE_NOT_FOUND).arg(indexFilePath),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
  return returnValue;
}

/*!
 * \brief MainWindow::updateInstalledLibraries
 * Opens the upgrade installed libraries dialog.
 */
void MainWindow::upgradeInstalledLibraries()
{
  updateLibraryIndex(false);
  QString indexFilePath = getLibraryIndexFilePath();
  if (QFile::exists(indexFilePath)) {
    UpgradeInstalledLibrariesDialog *pUpdateInstalledLibrariesDialog = new UpgradeInstalledLibrariesDialog;
    pUpdateInstalledLibrariesDialog->exec();
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::LIBRARY_INDEX_FILE_NOT_FOUND).arg(indexFilePath),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief MainWindow::updateLibraryIndex
 * Slot activated when Update Library Index menu item is triggered.
 */
void MainWindow::updateLibraryIndex()
{
  updateLibraryIndex(true);
}

/*!
 * \brief MainWindow::updateLibraryIndex
 * Calls OMCProxy::updatePackageIndex() once per OMEdit session.
 * \param forceUpdate
 */
void MainWindow::updateLibraryIndex(bool forceUpdate)
{
  static int init = 0;
  if (forceUpdate || !init) {
    init = 1;
    // show the progressbar and set the message in status bar
    mpStatusBar->showMessage(tr("Updating library index"));
    mpProgressBar->setRange(0, 0);
    showProgressBar();
    if (!MainWindow::instance()->getOMCProxy()->updatePackageIndex()) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Failed to update the library index. This could be because of bad internet connection."),
                                                            Helper::scriptingKind, Helper::errorLevel));
    }
    // hide the progressbar and clear the message in status bar
    mpStatusBar->clearMessage();
    hideProgressBar();
  }
}

//! Imports the models from OMNotebook.
//! @see exportModelToOMNotebook();
void MainWindow::importModelfromOMNotebook()
{
  QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::importFromOMNotebook), NULL, Helper::omnotebookFileTypes);
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
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(fileName).arg(file.errorString()), QMessageBox::Ok);
    hideProgressBar();
    return;
  }
  mpProgressBar->setValue(value++);
  // create the xml from the omnotebook file.
  QDomDocument xmlDocument;
  if (!xmlDocument.setContent(&file))
  {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Error reading the xml file"), QMessageBox::Ok);
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
  QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::importNgspiceNetlist), NULL, Helper::ngspiceNetlistFileTypes);
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
      fileName = StringHandler::getSaveFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::exportAsImage),
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
      svgGenerator.setTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::applicationIntroText));
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
        QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Error saving the image file"), QMessageBox::Ok);
      }
    } else if (copyToClipboard) {
      QClipboard *pClipboard = QApplication::clipboard();
      pClipboard->setImage(modelImage);
    }
    // hide the progressbar and clear the message in status bar
    mpStatusBar->clearMessage();
    hideProgressBar();
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
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
 * \brief MainWindow::openTemporaryDirectory
 * Opens the temporary directory
 */
void MainWindow::openTemporaryDirectory()
{
  QUrl temporaryDirectory (QString("file:///%1").arg(Utilities::tempDirectory()));
  if (!QDesktopServices::openUrl(temporaryDirectory)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(temporaryDirectory.toString()),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief MainWindow::openWorkingDirectory
 * Opens the current working directory.
 */
void MainWindow::openWorkingDirectory()
{
  QUrl workingDirectory (QString("file:///%1").arg(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory()));
  if (!QDesktopServices::openUrl(workingDirectory)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(workingDirectory.toString()),
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
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, message, Helper::scriptingKind, Helper::errorLevel));
    return;
  }
  QString arguments = OptionsDialog::instance()->getGeneralSettingsPage()->getTerminalCommandArguments();
  QDetachableProcess process;
  process.setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
#if QT_VERSION >= QT_VERSION_CHECK(5, 15, 0)
  const QStringList args(QProcess::splitCommand(arguments));
  process.start(terminalCommand, args);
#else
  process.start(terminalCommand + " " + arguments);
#endif
  if (process.error() == QProcess::FailedToStart) {
    QString errorString = tr("Unable to run terminal command <b>%1</b> with arguments <b>%2</b>. Process failed with error <b>%3</b>")
                          .arg(terminalCommand, arguments, process.errorString());
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, errorString, Helper::scriptingKind, Helper::errorLevel));
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
 * \brief MainWindow::runOMSensPlugin
 * Slots activated when run OMSens action is triggered.\n
 * Runs OMSens plugin.
 */
void MainWindow::runOMSensPlugin()
{
  if (!mpOMSensPlugin) {
    // load OMSens plugin
#ifdef Q_OS_MAC
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("OMSens is not supported on MacOS"), Helper::scriptingKind, Helper::errorLevel));
    return;
  }
#else
#ifdef Q_OS_WIN
    QPluginLoader loader(QString("%1/lib/omc/omsensplugin.dll").arg(Helper::OpenModelicaHome));
#else
    QPluginLoader loader(QString("%1/lib/%2/omc/libomsensplugin.so").arg(Helper::OpenModelicaHome, HOST_SHORT));
#endif
    mpOMSensPlugin = loader.instance();
    if (!mpOMSensPlugin) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Failed to load OMSens plugin. %1").arg(loader.errorString()), Helper::scriptingKind, Helper::errorLevel));
      return;
    }
  }
  // if OMSens plugin is already loaded.
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
    if (!pModelWidget->getLibraryTreeItem()->isSaved()) {
      // save the model
      if (!MainWindow::instance()->getLibraryWidget()->saveLibraryTreeItem(pModelWidget->getLibraryTreeItem())) {
        return;
      }
    }
    InformationInterface *pInformationInterface = qobject_cast<InformationInterface*>(mpOMSensPlugin);
    pInformationInterface->setOpenModelicaHome(Helper::OpenModelicaHome);
    pInformationInterface->setTempPath(Utilities::tempDirectory());
    pInformationInterface->setOMSensPath(OptionsDialog::instance()->getSensitivityOptimizationPage()->getOMSensBackendPathTextBox()->text());
    pInformationInterface->setPython(OptionsDialog::instance()->getSensitivityOptimizationPage()->getPythonTextBox()->text());
    ModelInterface *pModelInterface = qobject_cast<ModelInterface*>(mpOMSensPlugin);
    pModelInterface->analyzeModel(pModelWidget->toOMSensData());
  } else {
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::information), tr("Please open a model before starting the OMSens plugin."), QMessageBox::Ok);
  }
#endif
}

/*!
 * \brief MainWindow::openUsersGuide
 * Slot activated when mpUsersGuideAction triggered signal is raised.\n
 * Opens the html based version of OpenModelica users guide.
 */
void MainWindow::openUsersGuide()
{
  QUrl usersGuidePath(QString("https://openmodelica.org/doc/OpenModelicaUsersGuide/%1/").arg(Helper::OpenModelicaUsersGuideVersion));
  QDesktopServices::openUrl(usersGuidePath);
}

/*!
 * \brief MainWindow::openUsersGuideNewPdf
 * Slot activated when mpUsersGuideNewPdfAction triggered signal is raised.\n
 * Opens the new pdf versions of OpenModelica users guide.
 */
void MainWindow::openUsersGuidePdf()
{
  QUrl usersGuidePath(QString("file:///%1/share/doc/omc/OpenModelicaUsersGuide-latest.pdf").arg(Helper::OpenModelicaHome));
  if (!QDesktopServices::openUrl(usersGuidePath)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(usersGuidePath.toString()),
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
  QUrl systemDocumentationPath(QString("file:///%1/share/doc/omc/SystemDocumentation/OpenModelicaSystem.pdf").arg(Helper::OpenModelicaHome));
  if (!QDesktopServices::openUrl(systemDocumentationPath)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(systemDocumentationPath.toString()),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief MainWindow::openOpenModelicaScriptingDocumentation
 * Opens the OpenModelica scripting documentation.
 */
void MainWindow::openOpenModelicaScriptingDocumentation()
{
  QUrl openModelicaScriptingUrl("https://build.openmodelica.org/Documentation/OpenModelica.Scripting.html");
  QDesktopServices::openUrl(openModelicaScriptingUrl);
}

/*!
 * \brief MainWindow::openModelicaDocumentation
 * Opens the Modelica documentation.
 */
void MainWindow::openModelicaDocumentation()
{
  QUrl modelicaDocumentationUrl("https://build.openmodelica.org/Documentation/index.html");
  QDesktopServices::openUrl(modelicaDocumentationUrl);
}

/*!
 * \brief MainWindow::openOMSimulatorUsersGuide
 * Opens the OMSimulator Users Guide.
 */
void MainWindow::openOMSimulatorUsersGuide()
{
  QUrl OMSimulatorUsersGuideUrl("https://openmodelica.org/doc/OMSimulator/master/OMSimulator/UsersGuide/html/");
  QDesktopServices::openUrl(OMSimulatorUsersGuideUrl);
}

void MainWindow::openAboutOMEdit()
{
  AboutOMEditDialog *pAboutOMEditDialog = new AboutOMEditDialog(this);
  pAboutOMEditDialog->resize(400, 600);
  pAboutOMEditDialog->exec();
}

void MainWindow::toggleShapesButton()
{
  setFocus();
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
 * \brief MainWindow::editToolBarVisibilityChanged
 * Slot activated when toolbar visibility is changed.
 * \param visible
 */
void MainWindow::editToolBarVisibilityChanged(bool visible)
{
  toolBarVisibilityChanged(ToolBars::editToolBar, visible);
}

/*!
 * \brief MainWindow::viewToolBarVisibilityChanged
 * Slot activated when toolbar visibility is changed.
 * \param visible
 */
void MainWindow::viewToolBarVisibilityChanged(bool visible)
{
  toolBarVisibilityChanged(ToolBars::viewToolBar, visible);
}

/*!
 * \brief MainWindow::shapesToolBarVisibilityChanged
 * Slot activated when toolbar visibility is changed.
 * \param visible
 */
void MainWindow::shapesToolBarVisibilityChanged(bool visible)
{
  toolBarVisibilityChanged(ToolBars::shapesToolBar, visible);
}

/*!
 * \brief MainWindow::modelSwitcherToolBarVisibilityChanged
 * Slot activated when toolbar visibility is changed.
 * \param visible
 */
void MainWindow::modelSwitcherToolBarVisibilityChanged(bool visible)
{
  toolBarVisibilityChanged(ToolBars::modelSwitcherToolBar, visible);
}

/*!
 * \brief MainWindow::checkToolBarVisibilityChanged
 * Slot activated when toolbar visibility is changed.
 * \param visible
 */
void MainWindow::checkToolBarVisibilityChanged(bool visible)
{
  toolBarVisibilityChanged(ToolBars::checkToolBar, visible);
}

/*!
 * \brief MainWindow::simulationToolBarVisibilityChanged
 * Slot activated when toolbar visibility is changed.
 * \param visible
 */
void MainWindow::simulationToolBarVisibilityChanged(bool visible)
{
  toolBarVisibilityChanged(ToolBars::simulationToolBar, visible);
}

/*!
 * \brief MainWindow::reSimulationToolBarVisibilityChanged
 * Slot activated when toolbar visibility is changed.
 * \param visible
 */
void MainWindow::reSimulationToolBarVisibilityChanged(bool visible)
{
  toolBarVisibilityChanged(ToolBars::reSimulationToolBar, visible);
}

/*!
 * \brief MainWindow::plotToolBarVisibilityChanged
 * Slot activated when toolbar visibility is changed.
 * \param visible
 */
void MainWindow::plotToolBarVisibilityChanged(bool visible)
{
  toolBarVisibilityChanged(ToolBars::plotToolBar, visible);
}

/*!
 * \brief MainWindow::debuggerToolBarVisibilityChanged
 * Slot activated when toolbar visibility is changed.
 * \param visible
 */
void MainWindow::debuggerToolBarVisibilityChanged(bool visible)
{
  toolBarVisibilityChanged(ToolBars::debuggerToolBar, visible);
}

/*!
 * \brief MainWindow::OMSimulatorToolBarVisibilityChanged
 * Slot activated when toolbar visibility is changed.
 * \param visible
 */
void MainWindow::OMSimulatorToolBarVisibilityChanged(bool visible)
{
  toolBarVisibilityChanged(ToolBars::OMSimulatorToolBar, visible);
}

/*!
 * \brief MainWindow::openRecentModelWidget
 * Slot activated when mpModelSwitcherActions triggered SIGNAL is raised.\n
 * Before switching to new ModelWidget try to update the class contents if user has changed anything.
 */
void MainWindow::openRecentModelWidget()
{
  /* if Model text is changed manually by user then validate it before opening recent ModelWidget. */
  if (!mpModelWidgetContainer->validateText()) {
    return;
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
    if (j >= MaxRecentModels) {
      break;
    }
    ModelWidget *pModelWidget = qobject_cast<ModelWidget*>(subWindowsList.at(i)->widget());
    if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
      mpModelSwitcherActions[j]->setText(pModelWidget->getLibraryTreeItem()->getNameStructure());
      mpModelSwitcherActions[j]->setData(pModelWidget->getLibraryTreeItem()->getNameStructure());
      mpModelSwitcherActions[j]->setVisible(true);
    }
    j++;
  }
  // if subwindowlist size is less than MaxRecentFiles then hide the remaining actions
  int numRecentModels = qMin(subWindowsList.size(), (int)MaxRecentModels);
  for (j = numRecentModels ; j < MaxRecentModels ; j++) {
    mpModelSwitcherActions[j]->setVisible(false);
  }
}

/*!
 * \brief MainWindow::runDebugConfiguration
 * Runs the debug configuration.
 */
void MainWindow::runDebugConfiguration()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  QToolButton *pToolButton = qobject_cast<QToolButton*>(sender());

  if (!pAction && pToolButton) {
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
    if (!debugConfigurations.isEmpty()) {
      pSettings->setValue("configurations", debugConfigurations);
    }
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
        pModelWidget->getLibraryTreeItem()->isModelica()) {
      LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
      if (pModelWidget->validateText(&pLibraryTreeItem)) {
        mpDocumentationWidget->showDocumentation(pLibraryTreeItem);
      }
    }
  }
}

/*!
 * \brief MainWindow::messagesTabBarClicked
 * Shows the MessagesWidget when tab is clicked.
 * \param index
 */
void MainWindow::messagesTabBarClicked(int index)
{
  showMessageBrowser();
  emit resetMessagesTabWidgetNames();
  MessagesWidget::instance()->getMessagesTabWidget()->setCurrentIndex(index);
}

/*!
 * \brief MainWindow::messagesDockWidgetVisibilityChanged
 * Handles the VisibilityChanged signal of MessagesBrowser Dock Widget.
 * \param visible
 */
void MainWindow::messagesDockWidgetVisibilityChanged(bool visible)
{
  // Avoid firing a paint event on the animation window when the main window is closing
  if (MessagesWidget::instance()) {
    mpMessagesTabWidget->setVisible(!visible);
    if (!visible) {
      mpMessagesTabWidget->setCurrentIndex(MessagesWidget::instance()->getMessagesTabWidget()->currentIndex());
      emit resetMessagesTabWidgetNames();
    }
  }
}

/*!
 * \brief MainWindow::messageTabAdded
 * Handles the messageTabAdded signal of MessagesWidget.
 * \param pSimulationOutputTab
 * \param name
 */
void MainWindow::messageTabAdded(QWidget *pSimulationOutputTab, const QString &name)
{
  MessageTab *pMessageTab = createMessageTab(name, false);
  SimulationOutputWidget *pSimulationOutputWidget = qobject_cast<SimulationOutputWidget*>(pSimulationOutputTab);
  if (pSimulationOutputWidget) {
    connect(pSimulationOutputWidget, SIGNAL(updateText(QString)), pMessageTab, SLOT(updateText(QString)));
    connect(pSimulationOutputWidget, SIGNAL(updateProgressBar(QProgressBar*)), pMessageTab, SLOT(updateProgress(QProgressBar*)));
  } else {
    OMSSimulationOutputWidget *pOMSSimulationOutputWidget = qobject_cast<OMSSimulationOutputWidget*>(pSimulationOutputTab);
    if (pOMSSimulationOutputWidget) {
      connect(pOMSSimulationOutputWidget, SIGNAL(updateText(QString)), pMessageTab, SLOT(updateText(QString)));
      connect(pOMSSimulationOutputWidget, SIGNAL(updateProgressBar(QProgressBar*)), pMessageTab, SLOT(updateProgress(QProgressBar*)));
    } else {
      CRMLTranslatorOutputWidget *pCRMLTranslatorOutputWidget = qobject_cast<CRMLTranslatorOutputWidget*>(pSimulationOutputTab);
      if (pCRMLTranslatorOutputWidget) {
        connect(pCRMLTranslatorOutputWidget, SIGNAL(updateText(QString)), pMessageTab, SLOT(updateText(QString)));
        connect(pCRMLTranslatorOutputWidget, SIGNAL(updateProgressBar(QProgressBar*)), pMessageTab, SLOT(updateProgress(QProgressBar*)));
      }
    }
  }
}

/*!
 * \brief MainWindow::messageTabClosed
 * Handles the messageTabClosed signal of MessagesWidget.
 * \param name
 */
void MainWindow::messageTabClosed(int index)
{
  mpMessagesTabWidget->removeTab(index);
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
 * \brief MainWindow::showDataReconciliationDialog
 * Slot activated when mpCalculateDataReconciliationAction triggered signal is raised.\n
 * Shows the data reconciliation dialog.
 */
void MainWindow::showDataReconciliationDialog()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
    LibraryTreeItem *pLibraryTreeItem = pModelWidget->getLibraryTreeItem();
    DataReconciliationDialog *pDataReconciliationDialog = new DataReconciliationDialog(pLibraryTreeItem);
    if (pDataReconciliationDialog->exec()) {
      if (!mpSimulationDialog) {
        mpSimulationDialog = new SimulationDialog(this);
      }
      /* if Modelica text is changed manually by user then validate it before saving. */
      if (pModelWidget && !pModelWidget->validateText(&pLibraryTreeItem)) {
        return;
      }
      mpSimulationDialog->directSimulate(pLibraryTreeItem, false, false, false, true);
    }
  }
}

/*!
 * \brief MainWindow::runCRMLTestsuite
 * Slot activated when mpRunCRMLTestsuiteAction triggered signal is raised.\n
 * Runs the CRML testsuite and opens the result as html.
 */
void MainWindow::runCRMLTestsuite()
{
  CRMLTranslatorOptions crmlTranslatorOptions;
  crmlTranslatorOptions.setMode("testsuite");
  crmlTranslatorOptions.setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
  CRMLPage *pCRMLPage = OptionsDialog::instance()->getCRMLPage();
  crmlTranslatorOptions.setCompilerJar(pCRMLPage->getCompilerJarTextBox()->text());
  crmlTranslatorOptions.setCompilerCommandLineOptions(pCRMLPage->getCompilerCommandLineOptionsTextBox()->text());
  crmlTranslatorOptions.setCompilerProcess(pCRMLPage->getCompilerProcessTextBox()->text());

  CRMLTranslatorOutputWidget *pCRMLTranslatorOutputWidget = new CRMLTranslatorOutputWidget(crmlTranslatorOptions);
  MessagesWidget::instance()->addSimulationOutputTab(pCRMLTranslatorOutputWidget, tr("CRML Testsuite"));
  pCRMLTranslatorOutputWidget->start();
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
  mpNewModelicaClassAction = new QAction(Helper::newModelicaClass, this);
  mpNewModelicaClassAction->setStatusTip(Helper::createNewModelicaClass);
  mpNewModelicaClassAction->setShortcut(QKeySequence("Ctrl+n"));
  connect(mpNewModelicaClassAction, SIGNAL(triggered()), SLOT(createNewModelicaClass()));
  // create new MOS action
  mpNewMOSFileAction = new QAction(Helper::newMOSScript, this);
  mpNewMOSFileAction->setStatusTip(Helper::newMOSScriptTip);
  connect(mpNewMOSFileAction, SIGNAL(triggered()), SLOT(createNewMOSFile()));
  // create new SSP Model action
  mpNewSSPModelAction = new QAction(Helper::newOMSimulatorModel, this);
  mpNewSSPModelAction->setStatusTip(Helper::newOMSimulatorModelTip);
  connect(mpNewSSPModelAction, SIGNAL(triggered()), SLOT(createNewSSPModel()));
  // create new CRML action
  if (isCRMLEnabled()) {
    mpNewCRMLFileAction = new QAction(Helper::newCRMLModel, this);
    mpNewCRMLFileAction->setStatusTip(Helper::newCRMLModelTip);
    connect(mpNewCRMLFileAction, SIGNAL(triggered()), SLOT(createNewCRMLFile()));
  }
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
  // unload all action
  mpUnloadAllAction = new QAction(tr("Unload All"), this);
  mpUnloadAllAction->setStatusTip(tr("Unloads all loaded classes"));
  connect(mpUnloadAllAction, SIGNAL(triggered()), SLOT(unloadAll()));
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
  // install library action
  mpInstallLibraryAction = new QAction(Helper::installLibrary, this);
  mpInstallLibraryAction->setStatusTip(tr("Opens the install library window"));
  connect(mpInstallLibraryAction, SIGNAL(triggered()), SLOT(openInstallLibraryDialog()));
  // upgrade installed libraries action
  mpUpgradeInstalledLibrariesAction = new QAction(Helper::upgradeInstalledLibraries, this);
  mpUpgradeInstalledLibrariesAction->setStatusTip(tr("Upgrades the installed libraries"));
  connect(mpUpgradeInstalledLibrariesAction, SIGNAL(triggered()), SLOT(upgradeInstalledLibraries()));
  // update library index action
  mpUpdateLibraryIndexAction = new QAction(Helper::updateLibraryIndex, this);
  mpUpdateLibraryIndexAction->setStatusTip(tr("Updates the library index"));
  connect(mpUpdateLibraryIndexAction, SIGNAL(triggered()), SLOT(updateLibraryIndex()));
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
  // fit to diagram
  mpFitToDiagramAction = new QAction(QIcon(":/Resources/icons/fit-to-diagram.svg"), Helper::fitToDiagram, this);
  mpFitToDiagramAction->setStatusTip(Helper::fitToDiagram);
  mpFitToDiagramAction->setEnabled(false);
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
  // instantiate model action
  mpInstantiateModelAction = new QAction(QIcon(":/Resources/icons/flatmodel.svg"), tr("Instantiate Model"), this);
  mpInstantiateModelAction->setStatusTip(tr("Instantiates the modelica model"));
  mpInstantiateModelAction->setEnabled(false);
  connect(mpInstantiateModelAction, SIGNAL(triggered()), SLOT(instantiateModel()));
  // simulation setup action
  mpSimulationSetupAction = new QAction(QIcon(":/Resources/icons/simulation-center.svg"), Helper::simulationSetup, this);
  mpSimulationSetupAction->setStatusTip(Helper::simulationSetupTip);
  mpSimulationSetupAction->setEnabled(false);
  connect(mpSimulationSetupAction, SIGNAL(triggered()), SLOT(openSimulationDialog()));
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
  // simulate interactive action
  mpSimulateModelInteractiveAction = new QAction(QIcon(":/Resources/icons/simulate.svg"), Helper::simulate, this);
  mpSimulateModelInteractiveAction->setStatusTip(Helper::simulateTip);
  mpSimulateModelInteractiveAction->setEnabled(false);
  connect(mpSimulateModelInteractiveAction, SIGNAL(triggered()), SLOT(simulateModelInteractive()));
  // archived simulations action
  mpArchivedSimulationsAction = new QAction(Helper::archivedSimulations, this);
  mpArchivedSimulationsAction->setStatusTip(tr("Shows the list of archived simulations"));
  connect(mpArchivedSimulationsAction, SIGNAL(triggered()), SLOT(showArchivedSimulations()));
  // Data reconciliation menu
  // calculate data reconciliation
  mpCalculateDataReconciliationAction = new QAction(tr("Calculate Data Reconciliation"), this);
  mpCalculateDataReconciliationAction->setStatusTip(tr("Calculates the data reconciliation"));
  connect(mpCalculateDataReconciliationAction, SIGNAL(triggered()), SLOT(showDataReconciliationDialog()));
  // CRML menu
  if (isCRMLEnabled()) {
    // run testsuite
    mpRunCRMLTestsuiteAction = new QAction(tr("Run CRML Testsuite"), this);
    mpRunCRMLTestsuiteAction->setStatusTip(tr("Runs the CRML Testsuite and display report"));
    connect(mpRunCRMLTestsuiteAction, SIGNAL(triggered()), SLOT(runCRMLTestsuite()));
  }
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
#ifdef Q_OS_WIN
  // show OpenModelica command prompt action
  mpShowOpenModelicaCommandPromptAction = new QAction(QIcon(":/Resources/icons/console.svg"), tr("OpenModelica Command Prompt"), this);
  mpShowOpenModelicaCommandPromptAction->setStatusTip(tr("Open OpenModelica command prompt"));
  connect(mpShowOpenModelicaCommandPromptAction, SIGNAL(triggered()), SLOT(showOpenModelicaCommandPrompt()));
#endif
  // show OMC Diff widget action
  if (isDebug()) {
    mpShowOMCDiffWidgetAction = new QAction(QIcon(":/Resources/icons/console.svg"), tr("OpenModelica Compiler Diff"), this);
    mpShowOMCDiffWidgetAction->setStatusTip(tr("Shows OpenModelica Compiler Diff"));
    connect(mpShowOMCDiffWidgetAction, SIGNAL(triggered()), mpOMCProxy, SLOT(openOMCDiffWidget()));
  }
  // open temporary directory action
  mpOpenTemporaryDirectoryAction = new QAction(tr("Open Temporary Directory"), this);
  mpOpenTemporaryDirectoryAction->setStatusTip(tr("Opens the temporary directory"));
  connect(mpOpenTemporaryDirectoryAction, SIGNAL(triggered()), SLOT(openTemporaryDirectory()));
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
  // Run Sensitivity Analysis and Optimization action
  mpRunOMSensAction = new QAction(tr("Run Sensitivity Analysis and Optimization"), this);
  mpRunOMSensAction->setStatusTip(tr("Runs the sensitivity analysis and optimization"));
  connect(mpRunOMSensAction, SIGNAL(triggered()), SLOT(runOMSensPlugin()));
  // Help Menu
  // users guide action
  mpUsersGuideAction = new QAction(tr("OpenModelica User's Guide"), this);
  mpUsersGuideAction->setStatusTip(tr("Opens the OpenModelica User's Guide"));
  mpUsersGuideAction->setShortcut(QKeySequence(Qt::Key_F1));
  connect(mpUsersGuideAction, SIGNAL(triggered()), SLOT(openUsersGuide()));
  // users guide new pdf action
  mpUsersGuidePdfAction = new QAction(tr("OpenModelica User's Guide (PDF)"), this);
  mpUsersGuidePdfAction->setStatusTip(tr("Opens the OpenModelica User's Guide (PDF)"));
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
  // OMSimulator users guide action
  mpOMSimulatorUsersGuideAction = new QAction(tr("OMSimulator User's Guide"), this);
  mpOMSimulatorUsersGuideAction->setStatusTip(tr("Opens the OMSimulator User's Guide"));
  connect(mpOMSimulatorUsersGuideAction, SIGNAL(triggered()), SLOT(openOMSimulatorUsersGuide()));
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
  for (int i = 0; i < MaxRecentModels; ++i) {
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
  // Add SubModel Action
  mpAddSubModelAction = new QAction(QIcon(":/Resources/icons/import-fmu.svg"), Helper::addSubModel, this);
  mpAddSubModelAction->setStatusTip(Helper::addSubModelTip);
}

//! Creates the menus
void MainWindow::createMenus()
{
  //Create the menubar
  //Create the menus
  // File menu
  mpFileMenu = new QMenu(menuBar());
  mpFileMenu->setObjectName("menuFile");
  mpFileMenu->setTitle(tr("&File"));
  // add actions to File menu
  mpFileMenu->addMenu(mpNewModelMenu);
  mpFileMenu->addAction(mpOpenModelicaFileAction);
  mpFileMenu->addAction(mpOpenModelicaFileWithEncodingAction);
  mpFileMenu->addAction(mpLoadModelicaLibraryAction);
  mpFileMenu->addAction(mpLoadEncryptedLibraryAction);
  mpFileMenu->addAction(mpOpenResultFileAction);
  mpFileMenu->addAction(mpOpenTransformationFileAction);
  mpFileMenu->addSeparator();
  mpFileMenu->addAction(mpUnloadAllAction);
  mpFileMenu->addSeparator();
  mpFileMenu->addAction(mpOpenDirectoryAction);
  mpFileMenu->addSeparator();
  mpFileMenu->addAction(mpSaveAction);
  mpFileMenu->addAction(mpSaveAsAction);
  //menuFile->addAction(saveAllAction);
  mpFileMenu->addAction(mpSaveTotalAction);
  mpFileMenu->addSeparator();
  // Import menu
  QMenu *pImportMenu = new QMenu(menuBar());
  pImportMenu->setTitle(tr("Import"));
  // add actions to Import menu
  pImportMenu->addAction(mpImportFMUAction);
  pImportMenu->addAction(mpImportFMUModelDescriptionAction);
  pImportMenu->addAction(mpImportFromOMNotebookAction);
  pImportMenu->addAction(mpImportNgspiceNetlistAction);
  mpFileMenu->addMenu(pImportMenu);
  // Export menu
  QMenu *pExportMenu = new QMenu(menuBar());
  pExportMenu->setTitle(Helper::exportt);
  // add actions to Export menu
  pExportMenu->addAction(mpExportToClipboardAction);
  pExportMenu->addAction(mpExportAsImageAction);
  pExportMenu->addAction(mpExportFMUAction);
  pExportMenu->addAction(mpExportReadonlyPackageAction);
  pExportMenu->addAction(mpExportEncryptedPackageAction);
  pExportMenu->addAction(mpExportXMLAction);
  pExportMenu->addAction(mpExportFigaroAction);
  pExportMenu->addAction(mpExportToOMNotebookAction);
  mpFileMenu->addMenu(pExportMenu);
  mpFileMenu->addSeparator();
  // System libraries menu
  mpLibrariesMenu = new QMenu(menuBar());
  mpLibrariesMenu->setObjectName("SystemLibrariesMenu");
  mpLibrariesMenu->setTitle(tr("&System Libraries"));
  addSystemLibraries();
  mpFileMenu->addMenu(mpLibrariesMenu);
  // manage libraries menu
  QMenu *pManageLibrariesMenu = new QMenu(menuBar());
  pManageLibrariesMenu->setObjectName("ManageLibrariesMenu");
  pManageLibrariesMenu->setTitle(tr("&Manage Libraries"));
  // add actions to manage libraries
  pManageLibrariesMenu->addAction(mpInstallLibraryAction);
  pManageLibrariesMenu->addAction(mpUpgradeInstalledLibrariesAction);
  pManageLibrariesMenu->addAction(mpUpdateLibraryIndexAction);
  mpFileMenu->addMenu(pManageLibrariesMenu);
  mpFileMenu->addSeparator();
  mpRecentFilesMenu = new QMenu(menuBar());
  mpRecentFilesMenu->setObjectName("RecentFilesMenu");
  mpRecentFilesMenu->setTitle(tr("Recent &Files"));
  // we don't create the recent files actions here. It will be done when WelcomePageWidget is created and updateRecentFileActionsAndList() is called.
  mpFileMenu->addMenu(mpRecentFilesMenu);
  mpFileMenu->addAction(mpClearRecentFilesAction);
  mpFileMenu->addSeparator();
  mpFileMenu->addAction(mpPrintModelAction);
  mpFileMenu->addSeparator();
  mpFileMenu->addAction(mpQuitAction);
  // add File menu to menu bar
  menuBar()->addAction(mpFileMenu->menuAction());
  // Edit menu
  QMenu *pEditMenu = new QMenu(menuBar());
  pEditMenu->setTitle(tr("&Edit"));
  // add actions to Edit menu
  pEditMenu->addAction(mpUndoAction);
  pEditMenu->addAction(mpRedoAction);
  pEditMenu->addSeparator();
  pEditMenu->addAction(mpFilterClassesAction);
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
  pViewToolbarsMenu->addAction(mpOMSimulatorToolbar->toggleViewAction());
  // Add Actions to Windows View Sub Menu
  pViewWindowsMenu->addAction(mpLibraryDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpElementDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpDocumentationDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpVariablesDockWidget->toggleViewAction());
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
  pViewMenu->addSeparator();
  pViewMenu->addAction(mpResetZoomAction);
  pViewMenu->addAction(mpZoomInAction);
  pViewMenu->addAction(mpZoomOutAction);
  pViewMenu->addSeparator();
  pViewMenu->addAction(mpFitToDiagramAction);
  // add View menu to menu bar
  menuBar()->addAction(pViewMenu->menuAction());
  // OMSimulator menu
  QMenu *pSSPMenu = new QMenu(menuBar());
  pSSPMenu->setTitle(tr("&SSP"));
  // add actions to SSP menu
  pSSPMenu->addAction(mpAddSystemAction);
  pSSPMenu->addSeparator();
  pSSPMenu->addAction(mpAddOrEditIconAction);
  pSSPMenu->addAction(mpDeleteIconAction);
  pSSPMenu->addSeparator();
  pSSPMenu->addAction(mpAddConnectorAction);
  pSSPMenu->addAction(mpAddBusAction);
  pSSPMenu->addSeparator();
  pSSPMenu->addAction(mpAddSubModelAction);
  // add OMSimulator menu to menu bar
  menuBar()->addAction(pSSPMenu->menuAction());
  // Simulation Menu
  QMenu *pSimulationMenu = new QMenu(menuBar());
  pSimulationMenu->setTitle(tr("&Simulation"));
  // add actions to Simulation menu
  pSimulationMenu->addAction(mpCheckModelAction);
  pSimulationMenu->addAction(mpCheckAllModelsAction);
  pSimulationMenu->addAction(mpInstantiateModelAction);
  pSimulationMenu->addAction(mpSimulationSetupAction);
  pSimulationMenu->addAction(mpSimulateModelAction);
  pSimulationMenu->addAction(mpSimulateWithTransformationalDebuggerAction);
  pSimulationMenu->addAction(mpSimulateWithAlgorithmicDebuggerAction);
#if !defined(WITHOUT_OSG)
  pSimulationMenu->addAction(mpSimulateWithAnimationAction);
#endif
//  pSimulationMenu->addAction(mpSimulateModelInteractiveAction);
  pSimulationMenu->addSeparator();
  pSimulationMenu->addAction(mpArchivedSimulationsAction);
  // add Simulation menu to menu bar
  menuBar()->addAction(pSimulationMenu->menuAction());
  // Data reconciliation Menu
  QMenu *pDataReconciliationMenu = new QMenu(menuBar());
  pDataReconciliationMenu->setTitle(tr("&Data Reconciliation"));
  // add actions to data reconciliation menu
  pDataReconciliationMenu->addAction(mpCalculateDataReconciliationAction);
  // add data reconciliation menu to menu bar
  menuBar()->addAction(pDataReconciliationMenu->menuAction());
  // CRML menu
  if (isCRMLEnabled()) {
    QMenu *pCRMLMenu = new QMenu(menuBar());
    pCRMLMenu->setTitle(tr("&CRML"));
    // add actions to CRML menu
    pCRMLMenu->addAction(mpRunCRMLTestsuiteAction);
    // add data CRML menu to menu bar
    menuBar()->addAction(pCRMLMenu->menuAction());
  }
#ifndef Q_OS_MAC
  // Sensitivity Optimization menu
  QMenu *pSensitivityOptimizationMenu = new QMenu(menuBar());
  pSensitivityOptimizationMenu->setTitle(Helper::sensitivityOptimization);
  // add actions to Sensitivity Optimization menu
  pSensitivityOptimizationMenu->addAction(mpRunOMSensAction);
  // add Sensitivity Optimization menu to menu bar
  menuBar()->addAction(pSensitivityOptimizationMenu->menuAction());
#endif
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
  // add Git menu to menu bar
  /*! @todo Fix the Git feature and then uncomment the line below to add it to the menu.
   * For now just don't add it to the menu.
   */
  //menuBar()->addAction(pGitMenu->menuAction());
  // Debug menu
  QMenu *pDebugMenu = new QMenu(menuBar());
  pDebugMenu->setTitle(tr("&Debug"));
  // add actions to Debug menu
  pDebugMenu->addAction(mpDebugConfigurationsAction);
  pDebugMenu->addAction(mpAttachDebuggerToRunningProcessAction);
  // add Debug menu to menu bar
  menuBar()->addAction(pDebugMenu->menuAction());
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
  pToolsMenu->addAction(mpOpenTemporaryDirectoryAction);
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
  pHelpMenu->addAction(mpOMSimulatorUsersGuideAction);
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
  if (!mpModelWidgetContainer->validateText()) {
    bool signalsState = mpPerspectiveTabbar->blockSignals(true);
    mpPerspectiveTabbar->setCurrentIndex(1);
    mpPerspectiveTabbar->blockSignals(signalsState);
    return;
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
  // show/hide toolbars
  QSettings *pSettings = Utilities::getApplicationSettings();
  pSettings->beginGroup(ToolBars::welcomePerspective);
  SHOW_HIDE_TOOLBAR(mpEditToolBar, ToolBars::editToolBar, false);
  SHOW_HIDE_TOOLBAR(mpViewToolBar, ToolBars::viewToolBar, false);
  SHOW_HIDE_TOOLBAR(mpShapesToolBar, ToolBars::shapesToolBar, false);
  SHOW_HIDE_TOOLBAR(mpModelSwitcherToolBar, ToolBars::modelSwitcherToolBar, false);
  SHOW_HIDE_TOOLBAR(mpCheckToolBar, ToolBars::checkToolBar, false);
  SHOW_HIDE_TOOLBAR(mpSimulationToolBar, ToolBars::simulationToolBar, false);
  SHOW_HIDE_TOOLBAR(mpReSimulationToolBar, ToolBars::reSimulationToolBar, false);
  mpReSimulationToolBar->setEnabled(mpVariablesDockWidget->isVisible() && !mpVariablesWidget->getVariablesTreeView()->selectionModel()->selectedIndexes().isEmpty());
  SHOW_HIDE_TOOLBAR(mpPlotToolBar, ToolBars::plotToolBar, false);
  SHOW_HIDE_TOOLBAR(mpDebuggerToolBar, ToolBars::debuggerToolBar, false);
  SHOW_HIDE_TOOLBAR(mpOMSimulatorToolbar, ToolBars::OMSimulatorToolBar, false);
  pSettings->endGroup();
}

#define ADD_SHOW_DIAGRAMVIEW() \
  if (mpPlotWindowContainer->getDiagramWindow() && mpPlotWindowContainer->getDiagramWindow()->getModelWidget()) { \
    ModelWidget *pModelWidget = mpPlotWindowContainer->getDiagramWindow()->getModelWidget(); \
    mpPlotWindowContainer->getDiagramWindow()->removeVisualizationDiagram(); \
    pModelWidget->getDiagramGraphicsView()->emitResetDynamicSelect(); \
    pModelWidget->getMainLayout()->addWidget(pModelWidget->getDiagramGraphicsView(), 1); \
  }

/*!
 * \brief MainWindow::switchToModelingPerspective
 * Switches to Modeling perspective.
 */
void MainWindow::switchToModelingPerspective()
{
  ADD_SHOW_DIAGRAMVIEW();
  mpCentralStackedWidget->setCurrentWidget(mpModelWidgetContainer);
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getHideVariablesBrowserCheckBox()->isChecked()) {
    mpVariablesDockWidget->hide();
  }
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
  if (!mpModelWidgetContainer->validateText()) {
    bool signalsState = mpPerspectiveTabbar->blockSignals(true);
    mpPerspectiveTabbar->setCurrentIndex(1);
    mpPerspectiveTabbar->blockSignals(signalsState);
    return;
  }
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  mpCentralStackedWidget->setCurrentWidget(mpPlotWindowContainer);
  mpUndoAction->setEnabled(false);
  mpRedoAction->setEnabled(false);
  mpModelSwitcherToolButton->setEnabled(false);
  // if no plotwindow is opened then open one for user
  if (mpPlotWindowContainer->subWindowList().size() == 0) {
    mpPlotWindowContainer->addPlotWindow();
  }
  if (pModelWidget) {
    mpPlotWindowContainer->showDiagramWindow(pModelWidget, true);
  }
  mpVariablesDockWidget->show();
  // show/hide toolbars
  QSettings *pSettings = Utilities::getApplicationSettings();
  pSettings->beginGroup(ToolBars::plottingPerspective);
  SHOW_HIDE_TOOLBAR(mpEditToolBar, ToolBars::editToolBar, false);
  SHOW_HIDE_TOOLBAR(mpViewToolBar, ToolBars::viewToolBar, true);
  SHOW_HIDE_TOOLBAR(mpShapesToolBar, ToolBars::shapesToolBar, false);
  SHOW_HIDE_TOOLBAR(mpModelSwitcherToolBar, ToolBars::modelSwitcherToolBar, false);
  SHOW_HIDE_TOOLBAR(mpCheckToolBar, ToolBars::checkToolBar, false);
  SHOW_HIDE_TOOLBAR(mpSimulationToolBar, ToolBars::simulationToolBar, false);
  SHOW_HIDE_TOOLBAR(mpReSimulationToolBar, ToolBars::reSimulationToolBar, true);
  mpReSimulationToolBar->setEnabled(mpVariablesDockWidget->isVisible() && !mpVariablesWidget->getVariablesTreeView()->selectionModel()->selectedIndexes().isEmpty());
  SHOW_HIDE_TOOLBAR(mpPlotToolBar, ToolBars::plotToolBar, true);
  SHOW_HIDE_TOOLBAR(mpDebuggerToolBar, ToolBars::debuggerToolBar, false);
  SHOW_HIDE_TOOLBAR(mpOMSimulatorToolbar, ToolBars::OMSimulatorToolBar, false);
  pSettings->endGroup();
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
}

/*!
 * \brief MainWindow::switchToAlgorithmicDebuggingPerspective
 * Switches to algorithmic debugging perspective.
 */
void MainWindow::switchToAlgorithmicDebuggingPerspective()
{
  mpCentralStackedWidget->setCurrentWidget(mpModelWidgetContainer);
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getHideVariablesBrowserCheckBox()->isChecked()) {
    mpVariablesDockWidget->hide();
  }
  ADD_SHOW_DIAGRAMVIEW();
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
  // New Menu
  mpNewModelMenu = new QMenu;
  mpNewModelMenu = new QMenu(menuBar());
  mpNewModelMenu->setObjectName("NewModelMenu");
  mpNewModelMenu->setTitle(tr("&New"));
  mpNewModelMenu->setIcon(QIcon(":/Resources/icons/new.svg"));
  mpNewModelMenu->addAction(mpNewModelicaClassAction);
  mpNewModelMenu->addAction(mpNewMOSFileAction);
  mpNewModelMenu->addSeparator();
  mpNewModelMenu->addAction(mpNewSSPModelAction);
  if (isCRMLEnabled()) {
    mpNewModelMenu->addSeparator();
    mpNewModelMenu->addAction(mpNewCRMLFileAction);
  }
  // new ToolButton
  QToolButton *pNewToolButton = new QToolButton;
  pNewToolButton->setMenu(mpNewModelMenu);
  pNewToolButton->setPopupMode(QToolButton::MenuButtonPopup);
  // Don't change the order of following two lines otherwise the icon of toolbar button is overwritten by default action.
  pNewToolButton->setDefaultAction(mpNewModelicaClassAction);
  pNewToolButton->setIcon(QIcon(":/Resources/icons/new.svg"));
  mpFileToolBar->addWidget(pNewToolButton);
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
  connect(mpEditToolBar, SIGNAL(visibilityChanged(bool)), SLOT(editToolBarVisibilityChanged(bool)));
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
  mpViewToolBar->addSeparator();
  mpViewToolBar->addAction(mpFitToDiagramAction);
  connect(mpViewToolBar, SIGNAL(visibilityChanged(bool)), SLOT(viewToolBarVisibilityChanged(bool)));
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
  connect(mpShapesToolBar, SIGNAL(visibilityChanged(bool)), SLOT(shapesToolBarVisibilityChanged(bool)));
  // Model Swithcer Toolbar
  mpModelSwitcherToolBar = addToolBar(tr("ModelSwitcher Toolbar"));
  mpModelSwitcherToolBar->setObjectName("ModelSwitcher Toolbar");
  mpModelSwitcherToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // Model Switcher Menu
  mpModelSwitcherMenu = new QMenu;
  for (int i = 0; i < MaxRecentModels; ++i) {
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
  connect(mpModelSwitcherToolBar, SIGNAL(visibilityChanged(bool)), SLOT(modelSwitcherToolBarVisibilityChanged(bool)));
  // Check Toolbar
  mpCheckToolBar = addToolBar(tr("Check Toolbar"));
  mpCheckToolBar->setObjectName("Check Toolbar");
  mpCheckToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to Check Toolbar
  mpCheckToolBar->addAction(mpCheckModelAction);
  mpCheckToolBar->addAction(mpCheckAllModelsAction);
  mpCheckToolBar->addAction(mpInstantiateModelAction);
  connect(mpCheckToolBar, SIGNAL(visibilityChanged(bool)), SLOT(checkToolBarVisibilityChanged(bool)));
  // Simulation Toolbar
  mpSimulationToolBar = addToolBar(tr("Simulation Toolbar"));
  mpSimulationToolBar->setObjectName("Simulation Toolbar");
  mpSimulationToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to Simulation Toolbar
  mpSimulationToolBar->addAction(mpSimulationSetupAction);
  mpSimulationToolBar->addAction(mpSimulateModelAction);
  mpSimulationToolBar->addAction(mpSimulateWithTransformationalDebuggerAction);
  mpSimulationToolBar->addAction(mpSimulateWithAlgorithmicDebuggerAction);
#if !defined(WITHOUT_OSG)
  mpSimulationToolBar->addAction(mpSimulateWithAnimationAction);
#endif
//  mpSimulationToolBar->addAction(mpSimulateModelInteractiveAction);
  connect(mpSimulationToolBar, SIGNAL(visibilityChanged(bool)), SLOT(simulationToolBarVisibilityChanged(bool)));
  // Re-simulation Toolbar
  mpReSimulationToolBar = addToolBar(tr("Re-simulation Toolbar"));
  mpReSimulationToolBar->setObjectName("Re-simulation Toolbar");
  mpReSimulationToolBar->setAllowedAreas(Qt::TopToolBarArea);
  mpReSimulationToolBar->setEnabled(false);
  // add actions to Re-simulation Toolbar
  mpReSimulationToolBar->addAction(mpReSimulateModelAction);
  mpReSimulationToolBar->addAction(mpReSimulateSetupAction);
  connect(mpReSimulationToolBar, SIGNAL(visibilityChanged(bool)), SLOT(reSimulationToolBarVisibilityChanged(bool)));
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
  connect(mpPlotToolBar, SIGNAL(visibilityChanged(bool)), SLOT(plotToolBarVisibilityChanged(bool)));
  // Debugger Toolbar
  mpDebuggerToolBar = addToolBar(tr("Debugger Toolbar"));
  mpDebuggerToolBar->setObjectName("Debugger Toolbar");
  mpDebuggerToolBar->setAllowedAreas(Qt::TopToolBarArea);
  connect(mpDebuggerToolBar, SIGNAL(visibilityChanged(bool)), SLOT(debuggerToolBarVisibilityChanged(bool)));
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
  // SSP Toolbar
  mpOMSimulatorToolbar = addToolBar(tr("SSP Toolbar"));
  mpOMSimulatorToolbar->setObjectName("SSP Toolbar");
  mpOMSimulatorToolbar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to SSP Toolbar
  mpOMSimulatorToolbar->addAction(mpAddSystemAction);
  mpOMSimulatorToolbar->addSeparator();
  mpOMSimulatorToolbar->addAction(mpAddOrEditIconAction);
  mpOMSimulatorToolbar->addAction(mpDeleteIconAction);
  mpOMSimulatorToolbar->addSeparator();
  mpOMSimulatorToolbar->addAction(mpAddConnectorAction);
  mpOMSimulatorToolbar->addAction(mpAddBusAction);
  mpOMSimulatorToolbar->addSeparator();
  mpOMSimulatorToolbar->addAction(mpAddSubModelAction);
  connect(mpOMSimulatorToolbar, SIGNAL(visibilityChanged(bool)), SLOT(OMSimulatorToolBarVisibilityChanged(bool)));
}

/*!
 * \brief MainWindow::toolBarVisibilityChanged
 * Writes the toolbar visibility to the settings file.
 * \param toolbar
 * \param visible
 */
void MainWindow::toolBarVisibilityChanged(const QString &toolbar, bool visible)
{
  if (mRestoringState) {
    return;
  }
  QSettings *pSettings = Utilities::getApplicationSettings();
  QString perspective;
  ModelWidget *pModelWidget = 0;
  switch (mpPerspectiveTabbar->currentIndex()) {
    case 0:
      perspective = ToolBars::welcomePerspective;
      break;
    case 1:
      pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
      if (pModelWidget && pModelWidget->getLibraryTreeItem()->isText()) {
        perspective = ToolBars::modelingTextPerspective;
      } else if (pModelWidget && pModelWidget->getLibraryTreeItem()->isSSP()) {
        perspective = ToolBars::modelingOMSPerspective;
      } else {
        perspective = ToolBars::modelingModelicaPerspective;
      }
      break;
    case 2:
      perspective = ToolBars::plottingPerspective;
      break;
    case 3:
      pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
      if (pModelWidget && pModelWidget->getLibraryTreeItem()->isText()) {
        perspective = ToolBars::debuggingTextPerspective;
      } else if (pModelWidget && pModelWidget->getLibraryTreeItem()->isSSP()) {
        perspective = ToolBars::debuggingOMSPerspective;
      } else {
        perspective = ToolBars::debuggingModelicaPerspective;
      }
      break;
    default:
      perspective = ToolBars::welcomePerspective;
      break;
  }

  pSettings->beginGroup(perspective);
  pSettings->setValue(toolbar, visible);
  pSettings->endGroup();
}

/*!
 * \brief MainWindow::createMessageTab
 * Creates the MessageTab.
 * \param name
 * \param fixedTab
 * \return
 */
MessageTab *MainWindow::createMessageTab(const QString &name, bool fixedTab)
{
  MessageTab *pMessageTab = new MessageTab(name, fixedTab);
  int index = mpMessagesTabWidget->addTab(pMessageTab, name);
  pMessageTab->setIndex(index);
  mpMessagesTabWidget->setCurrentIndex(index);
  connect(pMessageTab, SIGNAL(clicked(int)), mpMessagesTabWidget, SIGNAL(tabBarClicked(int)));
  connect(this, SIGNAL(resetMessagesTabWidgetNames()), pMessageTab, SLOT(resetTabText()));
  return pMessageTab;
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
  openDroppedFile(event->mimeData());
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
     "<b>Connected to %3 %4 encryption support</b><br />"
     "<b>Connected to %5</b><br /><br />"
     "Installation path <b>%6</b><br /><br />"
     "Copyright <b>Open Source Modelica Consortium (OSMC)</b>.<br />"
     "Distributed under OSMC-PL and GPL, see <u><a href=\"http://www.openmodelica.org\">www.openmodelica.org</a></u>."
#if defined(WITHOUT_OSG)
     "<br /><em>Compiled without 3D animation support</em>."
#endif
     "")
     .arg(Helper::applicationName,
          Helper::applicationIntroText,
          Helper::OpenModelicaVersion,
#ifdef OM_ENABLE_ENCRYPTION
          "with",
#else
          "without",
#endif
          oms_getVersion(),
          Helper::OpenModelicaHome);
  // about text label
  Label *pAboutTextLabel = new Label(aboutText);
  pAboutTextLabel->setWordWrap(true);
  pAboutTextLabel->setOpenExternalLinks(true);
  pAboutTextLabel->setTextInteractionFlags(Qt::TextBrowserInteraction);
  pAboutTextLabel->setToolTip("");

  QString url("https://github.com/OpenModelica/OpenModelica/graphs/contributors");
  Label *pOMContributorsHeadingLabel = new Label;
  pOMContributorsHeadingLabel->setOpenExternalLinks(true);
  pOMContributorsHeadingLabel->setTextInteractionFlags(Qt::TextBrowserInteraction);
  pOMContributorsHeadingLabel->setText(QString("<b>OpenModelica Contributors:</b>"
                                               "<br />Source: <a href=\"%1\">%1</a>"
                                               "<br />Sorted by the number of commits per contributor in descending order.")
                                       .arg(url));
  pOMContributorsHeadingLabel->setToolTip("");

  NetworkAccessManager *pNetworkAccessManager = new NetworkAccessManager;
  connect(pNetworkAccessManager, SIGNAL(finished(QNetworkReply*)), SLOT(readOMContributors(QNetworkReply*)));
  pNetworkAccessManager->get(QNetworkRequest(QUrl("https://api.github.com/repos/OpenModelica/OpenModelica/contributors")));

  mpOMContributorsLabel = new Label;
  mpOMContributorsLabel->setObjectName("OMContributorsLabel");
  mpOMContributorsLabel->setWordWrap(true);
  mpOMContributorsLabel->setOpenExternalLinks(true);
  mpOMContributorsLabel->setTextInteractionFlags(Qt::TextBrowserInteraction);

  QScrollArea *pOMContributorsScrollArea = new QScrollArea;
  pOMContributorsScrollArea->setFrameShape(QFrame::NoFrame);
  pOMContributorsScrollArea->setWidgetResizable(true);
  pOMContributorsScrollArea->setWidget(mpOMContributorsLabel);
  // crash test button
  QPushButton *pCrashTestButton = new QPushButton(Helper::crashTest);
  pCrashTestButton->setAutoDefault(false);
  pCrashTestButton->setToolTip("Tests if the crash report functionality works properly");
  connect(pCrashTestButton, SIGNAL(clicked()), SLOT(crashTest()));
  // report button
  QPushButton *pReportButton = new QPushButton(Helper::reportIssue);
  pReportButton->setAutoDefault(false);
  connect(pReportButton, SIGNAL(clicked()), SLOT(showReportIssue()));
  // close button
  QPushButton *pCloseButton = new QPushButton(Helper::close);
  pCloseButton->setAutoDefault(true);
  connect(pCloseButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  QDialogButtonBox *pButtonBox = new QDialogButtonBox(Qt::Horizontal);
  pButtonBox->addButton(pCrashTestButton, QDialogButtonBox::ActionRole);
  pButtonBox->addButton(pReportButton, QDialogButtonBox::ActionRole);
  pButtonBox->addButton(pCloseButton, QDialogButtonBox::ActionRole);
  // logo label
  Label *pLogoLabel = new Label;
  QPixmap pixmap(":/Resources/icons/omedit.png");
  pLogoLabel->setPixmap(pixmap.scaled(128, 128, Qt::KeepAspectRatio, Qt::SmoothTransformation));
  // vertical layout
  QVBoxLayout *pVerticalLayout = new QVBoxLayout;
  pVerticalLayout->addWidget(pAboutTextLabel);
  pVerticalLayout->addWidget(pOMContributorsHeadingLabel);
  pVerticalLayout->addWidget(pOMContributorsScrollArea);
  // main layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->addWidget(pLogoLabel, 0, 0, Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addLayout(pVerticalLayout, 0, 1, Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(pButtonBox, 1, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief AboutOMEditDialog::readOMContributors
 * Slot activated when NetworkAccessManager finished SIGNAL is raised.\n
 * Reads the OpenModelica contributors and makes a list of it.
 * \param pNetworkReply
 */
void AboutOMEditDialog::readOMContributors(QNetworkReply *pNetworkReply)
{
  QList<QVariant> result;
  const QByteArray jsonData = pNetworkReply->readAll();
  JsonDocument jsonDocument;
  if (!jsonDocument.parse(jsonData)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "Failed to parse json of github contributors.", Helper::scriptingKind, Helper::errorLevel));
    MainWindow::instance()->printStandardOutAndErrorFilesMessages();
  } else {
    result = jsonDocument.result.toList();
  }
  QString contributors;
  foreach (QVariant variant, result) {
    QVariantMap map = variant.toMap();
    if (map["login"].toString().compare(QStringLiteral("OpenModelica-Hudson")) == 0) {
      continue;
    }
    contributors.append(QString("<li>%1 - <u><a href=\"%2\">%2</a></u></li>").arg(map["login"].toString(), map["html_url"].toString()));
  }
  mpOMContributorsLabel->setText(QString("<ul>%1</ul>").arg(contributors));
  mpOMContributorsLabel->setToolTip("");

  pNetworkReply->deleteLater();
}

/*!
 * \brief AboutOMEditDialog::showReportIssue
 * Opens the CrashReportDialog for sending the issue report manually.
 */
void AboutOMEditDialog::showReportIssue()
{
  // show the CrashReportDialog
  CrashReportDialog *pCrashReportDialog = new CrashReportDialog("", true);
  pCrashReportDialog->exec();
}

/*!
 * \brief AboutOMEditDialog::crashTest
 * Attempts to crash OMEdit to test the crash test reporting feature.
 */
void AboutOMEditDialog::crashTest()
{
  struct crash {
    int a;
    void *b;
  };
  struct crash *x = NULL;
  fprintf(stderr, "%d %p\n", x->a, x->b);
}


/*!
 * \class MessageTab
 * \brief Creates a tab that mimicks the tab of Message Browser.
 */
/*!
 * \brief MessageTab::MessageTab
 * \param fixedTab
 */
MessageTab::MessageTab(const QString &name, bool fixedTab)
 : QWidget()
{
  mName = name;
  mpProgressLabel = new Label;
  mpProgressLabel->setElideMode(Qt::ElideMiddle);
  mpProgressLabel->installEventFilter(this);
  if (fixedTab) {
    mpProgressLabel->setText(tr("Click to open message browser."));
  }
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  mpProgressBar->installEventFilter(this);
  // layout
  QHBoxLayout *pMainLayout = new QHBoxLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->addWidget(mpProgressLabel);
  if (!fixedTab) {
    pMainLayout->addWidget(mpProgressBar);
  }
  setLayout(pMainLayout);
}

/*!
 * \brief MessageTab::markTabChanged
 * Mark the tab changed by adding an asterisk to its name.
 */
void MessageTab::markTabChanged()
{
  MainWindow::instance()->getMessagesTabWidget()->tabBar()->setTabText(mIndex, QString(mName).append("*"));
}

/*!
 * \brief MessageTab::updateText
 * Updates the text label.
 * \param text
 */
void MessageTab::updateText(const QString &text)
{
  mpProgressLabel->setText(text);
}

/*!
 * \brief MessageTab::updateProgress
 * Updates the progressBar
 * \param pProgressBar
 */
void MessageTab::updateProgress(QProgressBar *pProgressBar)
{
  mpProgressBar->setRange(pProgressBar->minimum(), pProgressBar->maximum());
  mpProgressBar->setValue(pProgressBar->value());
  mpProgressBar->setTextVisible(pProgressBar->isTextVisible());
}

/*!
 * \brief MessageTab::resetTabText
 * Resets the tab text to its original text.
 */
void MessageTab::resetTabText()
{
  MainWindow::instance()->getMessagesTabWidget()->tabBar()->setTabText(mIndex, mName);
}

/*!
 * \brief MessageTab::eventFilter
 * Emits the clicked signal on left mouse press.
 * \param pObject
 * \param pEvent
 * \return
 */
bool MessageTab::eventFilter(QObject *pObject, QEvent *pEvent)
{
  if (pEvent->type() == QEvent::MouseButtonPress) {
    QMouseEvent *pMouseEvent = static_cast<QMouseEvent*>(pEvent);
    if (pMouseEvent && pMouseEvent->button() == Qt::LeftButton) {
      emit clicked(mIndex);
      return true;
    }
  }
  return QObject::eventFilter(pObject, pEvent);
}
