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

#include "SimulationDialog.h"
#include "MainWindow.h"
#include "Modeling/ItemDelegate.h"
#include "Options/OptionsDialog.h"
#include "Modeling/MessagesWidget.h"
#include "Debugger/GDB/GDBAdapter.h"
#include "Simulation/SimulationOutputWidget.h"
#include "Plotting/VariablesWidget.h"
#include "Plotting/PlotWindowContainer.h"
#include "Modeling/Commands.h"
#if !defined(WITHOUT_OSG)
#include "Animation/AnimationWindow.h"
#endif
#include "TranslationFlagsWidget.h"

#include <QDebug>
#include <limits>

/*!
 * \class SimulationDialog
 * \brief Displays a dialog with simulation options.
 */
/*!
 * \brief SimulationDialog::SimulationDialog
 * \param pParent
 */
SimulationDialog::SimulationDialog(QWidget *pParent)
  : QDialog(pParent)
{
  resize(550, 550);
  setUpForm();
}

SimulationDialog::~SimulationDialog()
{
  // kill the clients
  foreach (OpcUaClient *pOpcUaClient, mOpcUaClientsMap) {
    delete pOpcUaClient;
  }
  mOpcUaClientsMap.clear();
}

/*!
 * \brief SimulationDialog::show
 * \param pLibraryTreeItem - pointer to LibraryTreeItem
 * \param isReSimulate
 * \param simulationOptions
 */
void SimulationDialog::show(LibraryTreeItem *pLibraryTreeItem, bool isReSimulate, SimulationOptions simulationOptions)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  initializeFields(isReSimulate, simulationOptions);
  setVisible(true);
  /* restore the window geometry. */
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations() &&
      Utilities::getApplicationSettings()->contains("SimulationDialog/geometry")) {
    restoreGeometry(Utilities::getApplicationSettings()->value("SimulationDialog/geometry").toByteArray());
  }
}

/*!
 * \brief SimulationDialog::directSimulate
 * * Directly simulates the model without showing the simulation dialog.
 * \param pLibraryTreeItem
 * \param launchTransformationalDebugger
 * \param launchAlgorithmicDebugger
 * \param launchAnimation
 * \param enableDataReconciliation
 */
void SimulationDialog::directSimulate(LibraryTreeItem *pLibraryTreeItem, bool launchTransformationalDebugger, bool launchAlgorithmicDebugger, bool launchAnimation, bool enableDataReconciliation)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  initializeFields(false, SimulationOptions());
  mpBuildOnlyCheckBox->setChecked(false);
  mpLaunchTransformationalDebuggerCheckBox->setChecked(launchTransformationalDebugger);
  mpLaunchAlgorithmicDebuggerCheckBox->setChecked(launchAlgorithmicDebugger);
#if !defined(WITHOUT_OSG)
  mpLaunchAnimationCheckBox->setChecked(launchAnimation);
#else
  assert(false==launchAnimation);
#endif
  /* ticket:4440 OMEdit does not simulate
   * Make sure we always simulate when directSimulate() is called.
   */
  bool simulateCheckBoxState = mpSimulateCheckBox->isChecked();
  bool simuationFlagsCheckState = mpSaveSimulationFlagsAnnotationCheckBox->isChecked();
  mpSimulateCheckBox->setChecked(true);
  mpLibraryTreeItem->mSimulationOptions.setEnableDataReconciliation(enableDataReconciliation);
  if (enableDataReconciliation && mpLibraryTreeItem->mSimulationOptions.getDataReconciliationSaveSetting()) {
    mpSaveSimulationFlagsAnnotationCheckBox->setChecked(true);
  }
  simulate();
  mpSimulateCheckBox->setChecked(simulateCheckBoxState);
  mpSaveSimulationFlagsAnnotationCheckBox->setChecked(simuationFlagsCheckState);
}

/*!
 * \brief SimulationDialog::removeSimulationOutputWidget
 * Remove the simulation output widget.
 * \param pSimulationOutputWidget
 */
void SimulationDialog::removeSimulationOutputWidget(SimulationOutputWidget* pSimulationOutputWidget)
{
  // close the window
  // remove the old opc ua instance
  int port = pSimulationOutputWidget->getSimulationOptions().getInteractiveSimulationPortNumber();
  if (mOpcUaClientsMap.contains(port)) {
    OMPlot::PlotWindow *pPlotWindow = mOpcUaClientsMap.value(pSimulationOutputWidget->getSimulationOptions().getInteractiveSimulationPortNumber())->getTargetPlotWindow();
    if (pPlotWindow) {
      pPlotWindow->parentWidget()->close();
    }
    delete mOpcUaClientsMap.value(port);
    mOpcUaClientsMap.remove(port);
  }
  // Kill the compilation and simulation processes if they are running.
  if (pSimulationOutputWidget->isCompilationProcessRunning() && pSimulationOutputWidget->getCompilationProcess()) {
    pSimulationOutputWidget->getCompilationProcess()->kill();
  }
  if (pSimulationOutputWidget->isSimulationProcessRunning() && pSimulationOutputWidget->getSimulationProcess()) {
    pSimulationOutputWidget->getSimulationProcess()->kill();
  }
}

/*!
  Creates all the controls and set their layout.
  */
void SimulationDialog::setUpForm()
{
  // simulation widget heading
  mpSimulationHeading = Utilities::getHeadingLabel("");
  mpSimulationHeading->setElideMode(Qt::ElideMiddle);
  // Horizontal separator
  mpHorizontalLine = Utilities::getHeadingLine();
  // simulation tab widget
  mpSimulationTabWidget = new QTabWidget;
  // General Tab
  mpGeneralTab = new QWidget;
  // General Tab scroll area
  mpGeneralTabScrollArea = new VerticalScrollArea;
  mpGeneralTabScrollArea->setFrameShape(QFrame::NoFrame);
  mpGeneralTabScrollArea->setBackgroundRole(QPalette::Base);
  mpGeneralTabScrollArea->setWidget(mpGeneralTab);
  // Simulation Interval
  mpSimulationIntervalGroupBox = new QGroupBox(tr("Simulation Interval"));
  mpStartTimeLabel = new Label(QString("%1:").arg(Helper::startTime));
  mpStartTimeTextBox = new QLineEdit;
  mpStopTimeLabel = new Label(QString("%1:").arg(Helper::stopTime));
  mpStopTimeTextBox = new QLineEdit;
  // Output Interval
  mpNumberofIntervalsRadioButton = new QRadioButton(tr("Number of Intervals:"));
  mpNumberofIntervalsRadioButton->setChecked(true);
  connect(mpNumberofIntervalsRadioButton, SIGNAL(toggled(bool)), SLOT(numberOfIntervalsRadioToggled(bool)));
  mpNumberofIntervalsSpinBox = new QSpinBox;
  mpNumberofIntervalsSpinBox->setRange(0, std::numeric_limits<int>::max());
  mpNumberofIntervalsSpinBox->setSingleStep(100);
  // Interval
  mpIntervalRadioButton = new QRadioButton(tr("Interval:"));
  connect(mpIntervalRadioButton, SIGNAL(toggled(bool)), SLOT(intervalRadioToggled(bool)));
  mpIntervalTextBox = new QLineEdit;
  mpIntervalTextBox->setEnabled(false);
  // set the layout for simulation interval groupbox
  QGridLayout *pSimulationIntervalGridLayout = new QGridLayout;
  pSimulationIntervalGridLayout->setColumnStretch(1, 1);
  pSimulationIntervalGridLayout->addWidget(mpStartTimeLabel, 0, 0);
  pSimulationIntervalGridLayout->addWidget(mpStartTimeTextBox, 0, 1);
  pSimulationIntervalGridLayout->addWidget(new Label(Helper::secs), 0, 2);
  pSimulationIntervalGridLayout->addWidget(mpStopTimeLabel, 1, 0);
  pSimulationIntervalGridLayout->addWidget(mpStopTimeTextBox, 1, 1);
  pSimulationIntervalGridLayout->addWidget(new Label(Helper::secs), 1, 2);
  pSimulationIntervalGridLayout->addWidget(mpNumberofIntervalsRadioButton, 2, 0);
  pSimulationIntervalGridLayout->addWidget(mpNumberofIntervalsSpinBox, 2, 1, 1, 2);
  pSimulationIntervalGridLayout->addWidget(mpIntervalRadioButton, 3, 0);
  pSimulationIntervalGridLayout->addWidget(mpIntervalTextBox, 3, 1);
  pSimulationIntervalGridLayout->addWidget(new Label(Helper::secs), 3, 2);
  mpSimulationIntervalGroupBox->setLayout(pSimulationIntervalGridLayout);
  // Integration
  mpIntegrationGroupBox = new QGroupBox(tr("Integration"));
  mpMethodLabel = new Label(tr("Method:"));
  // get the solver methods
  QStringList solverMethods, solverMethodsDesc;
  MainWindow::instance()->getOMCProxy()->getSolverMethods(&solverMethods, &solverMethodsDesc);
  mpMethodComboBox = new QComboBox;
  mpMethodComboBox->addItems(solverMethods);
  Utilities::setToolTip(mpMethodComboBox, "Integration Methods", solverMethodsDesc);
  connect(mpMethodComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(enableDasslIdaOptions(QString)));
  mpMehtodHelpButton = new QToolButton;
  mpMehtodHelpButton->setIcon(QIcon(":/Resources/icons/link-external.svg"));
  mpMehtodHelpButton->setToolTip(tr("Integration help"));
  connect(mpMehtodHelpButton, SIGNAL(clicked()), SLOT(showIntegrationHelp()));
  // Tolerance
  mpToleranceLabel = new Label(tr("Tolerance:"));
  mpToleranceTextBox = new QLineEdit;
  // jacobian
  mpJacobianLabel = new Label(tr("Jacobian:"));
  mpJacobianLabel->setToolTip(MainWindow::instance()->getOMCProxy()->getJacobianFlagDetailedDescription());
  QStringList jacobianMethods, jacobianMethodsDesc;
  MainWindow::instance()->getOMCProxy()->getJacobianMethods(&jacobianMethods, &jacobianMethodsDesc);
  mpJacobianComboBox = new QComboBox;
  jacobianMethods.prepend("");
  jacobianMethodsDesc.prepend("");
  mpJacobianComboBox->addItems(jacobianMethods);
  Utilities::setToolTip(mpJacobianComboBox, "Jacobians", jacobianMethodsDesc);
  // dassl/ida options
  mpDasslIdaOptionsGroupBox = new QGroupBox(tr("DASSL/IDA Options"));
  // no root finding
  mpRootFindingCheckBox = new QCheckBox(tr("Root Finding"));
  mpRootFindingCheckBox->setToolTip(tr("Activates the internal root finding procedure of methods: dassl and ida."));
  // no restart
  mpRestartAfterEventCheckBox = new QCheckBox(tr("Restart After Event"));
  mpRestartAfterEventCheckBox->setToolTip(tr("Activates the restart of the integration method after an event is performed, used by the methods: dassl, ida"));
  // initial step size
  mpInitialStepSizeLabel = new Label(tr("Initial Step Size:"));
  mpInitialStepSizeTextBox = new QLineEdit;
  // max step size
  mpMaxStepSizeLabel = new Label(tr("Maximum Step Size:"));
  mpMaxStepSizeTextBox = new QLineEdit;
  // max integration order
  mpMaxIntegrationOrderLabel = new Label(tr("Maximum Integration Order:"));
  mpMaxIntegrationOrderSpinBox = new QSpinBox;
  // set the layout for DASSL/Ida options groupbox
  QGridLayout *pDasslIdaOptionsGridLayout = new QGridLayout;
  pDasslIdaOptionsGridLayout->setColumnStretch(1, 1);
  pDasslIdaOptionsGridLayout->addWidget(mpRootFindingCheckBox, 0, 0, 1, 2);
  pDasslIdaOptionsGridLayout->addWidget(mpRestartAfterEventCheckBox, 1, 0, 1, 2);
  pDasslIdaOptionsGridLayout->addWidget(mpInitialStepSizeLabel, 2, 0);
  pDasslIdaOptionsGridLayout->addWidget(mpInitialStepSizeTextBox, 2, 1);
  pDasslIdaOptionsGridLayout->addWidget(mpMaxStepSizeLabel, 3, 0);
  pDasslIdaOptionsGridLayout->addWidget(mpMaxStepSizeTextBox, 3, 1);
  pDasslIdaOptionsGridLayout->addWidget(mpMaxIntegrationOrderLabel, 4, 0);
  pDasslIdaOptionsGridLayout->addWidget(mpMaxIntegrationOrderSpinBox, 4, 1);
  mpDasslIdaOptionsGroupBox->setLayout(pDasslIdaOptionsGridLayout);
  // set the layout for integration groupbox
  QGridLayout *pIntegrationGridLayout = new QGridLayout;
  pIntegrationGridLayout->setColumnStretch(1, 1);
  pIntegrationGridLayout->addWidget(mpMethodLabel, 0, 0);
  pIntegrationGridLayout->addWidget(mpMethodComboBox, 0, 1);
  pIntegrationGridLayout->addWidget(mpMehtodHelpButton, 0, 2);
  pIntegrationGridLayout->addWidget(mpToleranceLabel, 1, 0);
  pIntegrationGridLayout->addWidget(mpToleranceTextBox, 1, 1, 1, 2);
  pIntegrationGridLayout->addWidget(mpJacobianLabel, 2, 0);
  pIntegrationGridLayout->addWidget(mpJacobianComboBox, 2, 1, 1, 2);
  pIntegrationGridLayout->addWidget(mpDasslIdaOptionsGroupBox, 3, 0, 1, 3);
  mpIntegrationGroupBox->setLayout(pIntegrationGridLayout);
  // Compiler Flags
  mpCflagsLabel = new Label(tr("C/C++ Compiler Flags (Optional):"));
  mpCflagsLabel->setToolTip(tr("Space separated list of C/C++ compiler flags"));
  mpCflagsTextBox = new QLineEdit;
  // Number of Processors
  mpNumberOfProcessorsLabel = new Label(tr("Number of Processors:"));
  mpNumberOfProcessorsSpinBox = new QSpinBox;
  mpNumberOfProcessorsSpinBox->setMinimum(1);
  mpNumberOfProcessorsNoteLabel = new Label(tr("Use 1 processor if you encounter problems during compilation."));
  // build only
  mpBuildOnlyCheckBox = new QCheckBox(tr("Build Only"));
  connect(mpBuildOnlyCheckBox, SIGNAL(toggled(bool)), SLOT(buildOnly(bool)));
  // Launch Transformational Debugger checkbox
  mpLaunchTransformationalDebuggerCheckBox = new QCheckBox(tr("Launch Transformational Debugger"));
  // Launch Algorithmic Debugger checkbox
  mpLaunchAlgorithmicDebuggerCheckBox = new QCheckBox(tr("Launch Algorithmic Debugger"));
#if !defined(WITHOUT_OSG)
  // Launch Animation
  mpLaunchAnimationCheckBox = new QCheckBox(tr("Launch Animation"));
#endif
  QGridLayout *pLaunchOptionsLayout = new QGridLayout;
  pLaunchOptionsLayout->setAlignment(Qt::AlignTop);
  pLaunchOptionsLayout->addWidget(mpBuildOnlyCheckBox, 0, 0);
  pLaunchOptionsLayout->addWidget(mpLaunchTransformationalDebuggerCheckBox, 0, 1);
#if !defined(WITHOUT_OSG)
  pLaunchOptionsLayout->addWidget(mpLaunchAlgorithmicDebuggerCheckBox, 1, 0);
  pLaunchOptionsLayout->addWidget(mpLaunchAnimationCheckBox, 1, 1);
#else
  pLaunchOptionsLayout->addWidget(mpLaunchAlgorithmicDebuggerCheckBox, 1, 0, 1, 2);
#endif
  // set General Tab Layout
  QGridLayout *pGeneralTabLayout = new QGridLayout;
  pGeneralTabLayout->setAlignment(Qt::AlignTop);
  pGeneralTabLayout->addWidget(mpSimulationIntervalGroupBox, 0, 0, 1, 3);
  pGeneralTabLayout->addWidget(mpIntegrationGroupBox, 1, 0, 1, 3);
  pGeneralTabLayout->addWidget(mpCflagsLabel, 2, 0);
  pGeneralTabLayout->addWidget(mpCflagsTextBox, 2, 1, 1, 2);
  pGeneralTabLayout->addWidget(mpNumberOfProcessorsLabel, 3, 0);
  pGeneralTabLayout->addWidget(mpNumberOfProcessorsSpinBox, 3, 1);
  pGeneralTabLayout->addWidget(mpNumberOfProcessorsNoteLabel, 3, 2);
  pGeneralTabLayout->addLayout(pLaunchOptionsLayout, 4, 0, 1, 3);
  mpGeneralTab->setLayout(pGeneralTabLayout);
  // add General Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpGeneralTabScrollArea, Helper::general);
  // interactive simulation tab
  mpInteractiveSimulationTab = new QWidget;
  // interactive simulation
  QString interactiveSimulationText = tr("Interactive Simulation");
  mpInteractiveSimulationGroupBox = new QGroupBox(interactiveSimulationText);
  mpInteractiveSimulationGroupBox->setCheckable(true);
  mpInteractiveSimulationStepCheckBox = new QCheckBox(tr("Simulate with steps"));
  mpInteractiveSimulationStepCheckBox->setToolTip(tr("Activates communication with the simulation remote every time step.\n"
                                                     "Can cause high overhead but values will not be missed."));
  mpInteractiveSimulationPortLabel = new Label(tr("Simulation server port: "));
  mpInteractiveSimulationPortLabel->setToolTip(tr("Specifies the embedded server port."));
  mpInteractiveSimulationPortNumberTextBox = new QLineEdit;
  connect(mpInteractiveSimulationGroupBox, SIGNAL(toggled(bool)), SLOT(interactiveSimulation(bool)));
  // interactive simulation layout
  QGridLayout *pInteractiveSimulationLayout = new QGridLayout;
  pInteractiveSimulationLayout->setColumnStretch(1, 1);
  pInteractiveSimulationLayout->addWidget(mpInteractiveSimulationStepCheckBox, 0, 0);
  pInteractiveSimulationLayout->addWidget(mpInteractiveSimulationPortLabel, 1, 0);
  pInteractiveSimulationLayout->addWidget(mpInteractiveSimulationPortNumberTextBox, 1, 1);
  mpInteractiveSimulationGroupBox->setLayout(pInteractiveSimulationLayout);
  // set interactive simulation Tab Layout
  QGridLayout *pInteractiveSimulationTabLayout = new QGridLayout;
  pInteractiveSimulationTabLayout->setAlignment(Qt::AlignTop);
  pInteractiveSimulationTabLayout->addWidget(mpInteractiveSimulationGroupBox, 0, 0);
  mpInteractiveSimulationTab->setLayout(pInteractiveSimulationTabLayout);
  // add interactive simulation Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpInteractiveSimulationTab, interactiveSimulationText);
  // Translation Tab
  mpTranslationTab = new QWidget;
  mpTranslationFlagsWidget = new TranslationFlagsWidget(this);
  // set Translation Tab Layout
  QGridLayout *pTranslationTabLayout = new QGridLayout;
  pTranslationTabLayout->setAlignment(Qt::AlignTop);
  pTranslationTabLayout->addWidget(mpTranslationFlagsWidget, 0, 0);
  mpTranslationTab->setLayout(pTranslationTabLayout);
  // add Translation Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpTranslationTab, Helper::translationFlags);
  // Simulation Flags Tab
  mpSimulationFlagsTab = new QWidget;
  // Simulation Flags Tab scroll area
  mpSimulationFlagsTabScrollArea = new QScrollArea;
  mpSimulationFlagsTabScrollArea->setFrameShape(QFrame::NoFrame);
  mpSimulationFlagsTabScrollArea->setBackgroundRole(QPalette::Base);
  mpSimulationFlagsTabScrollArea->setWidgetResizable(true);
  mpSimulationFlagsTabScrollArea->setWidget(mpSimulationFlagsTab);
  // Model Setup File
  mpModelSetupFileLabel = new Label(tr("Model Setup File (Optional):"));
  mpModelSetupFileLabel->setToolTip(tr("Specifies a new setup XML file to the generated simulation code."));
  mpModelSetupFileTextBox = new QLineEdit;
  mpModelSetupFileBrowseButton = new QPushButton(Helper::browse);
  connect(mpModelSetupFileBrowseButton, SIGNAL(clicked()), SLOT(browseModelSetupFile()));
  mpModelSetupFileBrowseButton->setAutoDefault(false);
  // Initialization Methods
  mpInitializationMethodLabel = new Label(tr("Initialization Method (Optional):"));
  mpInitializationMethodLabel->setToolTip(tr("Specifies the initialization method."));
  // get the initialization methods
  QStringList initializationMethods, initializationMethodsDesc;
  MainWindow::instance()->getOMCProxy()->getInitializationMethods(&initializationMethods, &initializationMethodsDesc);
  initializationMethods.prepend("");
  initializationMethodsDesc.prepend("");
  mpInitializationMethodComboBox = new QComboBox;
  mpInitializationMethodComboBox->addItems(initializationMethods);
  Utilities::setToolTip(mpInitializationMethodComboBox, "Initialization Methods", initializationMethodsDesc);
  // Equation System Initialization File
  mpEquationSystemInitializationFileLabel = new Label(tr("Equation System Initialization File (Optional):"));
  mpEquationSystemInitializationFileLabel->setToolTip(tr("Specifies an external file for the initialization of the model."));
  mpEquationSystemInitializationFileTextBox = new QLineEdit;
  mpEquationSystemInitializationFileBrowseButton = new QPushButton(Helper::browse);
  connect(mpEquationSystemInitializationFileBrowseButton, SIGNAL(clicked()), SLOT(browseEquationSystemInitializationFile()));
  mpEquationSystemInitializationFileBrowseButton->setAutoDefault(false);
  // Equation System time
  mpEquationSystemInitializationTimeLabel = new Label(tr("Equation System Initialization Time (Optional):"));
  mpEquationSystemInitializationTimeLabel->setToolTip(tr("Specifies a time for the initialization of the model."));
  mpEquationSystemInitializationTimeTextBox = new QLineEdit;
  // clock
  mpClockLabel = new Label(tr("Clock (Optional):"));
  mpClockComboBox = new QComboBox;
  mpClockComboBox->addItems(Helper::clockOptions.split(","));
  // Linear Solvers
  mpLinearSolverLabel = new Label(tr("Linear Solver (Optional):"));
  // get the linear solvers
  QStringList linearSolverMethods, linearSolverMethodsDesc;
  MainWindow::instance()->getOMCProxy()->getLinearSolvers(&linearSolverMethods, &linearSolverMethodsDesc);
  linearSolverMethods.prepend("");
  linearSolverMethodsDesc.prepend("");
  mpLinearSolverComboBox = new QComboBox;
  mpLinearSolverComboBox->addItems(linearSolverMethods);
  Utilities::setToolTip(mpLinearSolverComboBox, "Linear Solvers", linearSolverMethodsDesc);
  // Non Linear Solvers
  mpNonLinearSolverLabel = new Label(tr("Non Linear Solver (Optional):"));
  // get the non-linear solvers
  QStringList nonLinearSolverMethods, nonLinearSolverMethodsDesc;
  MainWindow::instance()->getOMCProxy()->getNonLinearSolvers(&nonLinearSolverMethods, &nonLinearSolverMethodsDesc);
  nonLinearSolverMethods.prepend("");
  nonLinearSolverMethodsDesc.prepend("");
  mpNonLinearSolverComboBox = new QComboBox;
  mpNonLinearSolverComboBox->addItems(nonLinearSolverMethods);
  Utilities::setToolTip(mpNonLinearSolverComboBox, "Non Linear Solvers", nonLinearSolverMethodsDesc);
  // time where the linearization of the model should be performed
  mpLinearizationTimeLabel = new Label(tr("Linearization Time (Optional):"));
  mpLinearizationTimeTextBox = new QLineEdit;
  // output variables
  mpOutputVariablesLabel = new Label(tr("Output Variables (Optional):"));
  mpOutputVariablesLabel->setToolTip(tr("Comma separated list of variables. Output the variables at the end of the simulation to the standard output."));
  mpOutputVariablesTextBox = new QLineEdit;
  // measure simulation time checkbox
  mpProfilingLabel = new Label(tr("Profiling (enable performance measurements)"));
  mpProfilingComboBox = new QComboBox;
  OMCInterface::getConfigFlagValidOptions_res profiling = MainWindow::instance()->getOMCProxy()->getConfigFlagValidOptions("profiling");
  mpProfilingComboBox->addItems(profiling.validOptions);
  mpProfilingComboBox->setCurrentIndex(0);
  Utilities::setToolTip(mpProfilingComboBox, profiling.mainDescription, profiling.descriptions);
  // cpu-time checkbox
  mpCPUTimeCheckBox = new QCheckBox(tr("CPU Time"));
  // enable all warnings
  mpEnableAllWarningsCheckBox = new QCheckBox(tr("Enable All Warnings"));
  // Logging
  mpLoggingGroupBox = new QGroupBox(tr("Logging (Optional)"));
  // fetch the logging flags information
  QStringList logStreamNames, logSteamDescriptions;
  MainWindow::instance()->getOMCProxy()->getLogStreams(&logStreamNames, &logSteamDescriptions);
  // layout for logging group
  mpLoggingGroupLayout = new QGridLayout;
  // create log stream checkboxes
  int row = 0;
  int column = 0;
  for (int i = 0 ; i < logStreamNames.size() ; i++) {
    QCheckBox *pLogStreamCheckBox = new QCheckBox(logStreamNames[i]);
    pLogStreamCheckBox->setToolTip(logSteamDescriptions[i]);
    if (column == 0) {
      mpLoggingGroupLayout->addWidget(pLogStreamCheckBox, row, column++);
    } else if (column == 1) {
      mpLoggingGroupLayout->addWidget(pLogStreamCheckBox, row, column++);
    } else if (column == 2) {
      mpLoggingGroupLayout->addWidget(pLogStreamCheckBox, row, column);
      column = 0;
      row++;
    }
  }
  mpLoggingGroupBox->setLayout(mpLoggingGroupLayout);
  // additional simulation flags
  mpAdditionalSimulationFlagsLabel = new Label(tr("Additional Simulation Flags (Optional):"));
  mpAdditionalSimulationFlagsLabel->setToolTip(tr("Space separated list of simulation flags e.g., -abortSlowSimulation -alarm=0"));
  mpAdditionalSimulationFlagsTextBox = new QLineEdit;
  mpSimulationFlagsHelpButton = new QToolButton;
  mpSimulationFlagsHelpButton->setIcon(QIcon(":/Resources/icons/link-external.svg"));
  mpSimulationFlagsHelpButton->setToolTip(tr("Simulation flags help"));
  connect(mpSimulationFlagsHelpButton, SIGNAL(clicked()), SLOT(showSimulationFlagsHelp()));
  // additional simulation flags layout
  QHBoxLayout *pAdditionalSimulationFlagsTabLayout = new QHBoxLayout;
  pAdditionalSimulationFlagsTabLayout->addWidget(mpAdditionalSimulationFlagsTextBox);
  pAdditionalSimulationFlagsTabLayout->addWidget(mpSimulationFlagsHelpButton);
  // set SimulationFlags Tab Layout
  QGridLayout *pSimulationFlagsTabLayout = new QGridLayout;
  pSimulationFlagsTabLayout->setAlignment(Qt::AlignTop);
  pSimulationFlagsTabLayout->addWidget(mpModelSetupFileLabel, 0, 0);
  pSimulationFlagsTabLayout->addWidget(mpModelSetupFileTextBox, 0, 1);
  pSimulationFlagsTabLayout->addWidget(mpModelSetupFileBrowseButton, 0, 2);
  pSimulationFlagsTabLayout->addWidget(mpInitializationMethodLabel, 1, 0);
  pSimulationFlagsTabLayout->addWidget(mpInitializationMethodComboBox, 1, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpEquationSystemInitializationFileLabel, 2, 0);
  pSimulationFlagsTabLayout->addWidget(mpEquationSystemInitializationFileTextBox, 2, 1);
  pSimulationFlagsTabLayout->addWidget(mpEquationSystemInitializationFileBrowseButton, 2, 2);
  pSimulationFlagsTabLayout->addWidget(mpEquationSystemInitializationTimeLabel, 3, 0);
  pSimulationFlagsTabLayout->addWidget(mpEquationSystemInitializationTimeTextBox, 3, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpClockLabel, 4, 0);
  pSimulationFlagsTabLayout->addWidget(mpClockComboBox, 4, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpLinearSolverLabel, 5, 0);
  pSimulationFlagsTabLayout->addWidget(mpLinearSolverComboBox, 5, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpNonLinearSolverLabel, 6, 0);
  pSimulationFlagsTabLayout->addWidget(mpNonLinearSolverComboBox, 6, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpLinearizationTimeLabel, 7, 0);
  pSimulationFlagsTabLayout->addWidget(mpLinearizationTimeTextBox, 7, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpOutputVariablesLabel, 8, 0);
  pSimulationFlagsTabLayout->addWidget(mpOutputVariablesTextBox, 8, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpProfilingLabel, 9, 0);
  pSimulationFlagsTabLayout->addWidget(mpProfilingComboBox, 9, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpCPUTimeCheckBox, 10, 0, 1, 3);
  pSimulationFlagsTabLayout->addWidget(mpEnableAllWarningsCheckBox, 11, 0, 1, 3);
  pSimulationFlagsTabLayout->addWidget(mpLoggingGroupBox, 12, 0, 1, 3);
  pSimulationFlagsTabLayout->addWidget(mpAdditionalSimulationFlagsLabel, 13, 0);
  pSimulationFlagsTabLayout->addLayout(pAdditionalSimulationFlagsTabLayout, 13, 1, 1, 2);
  mpSimulationFlagsTab->setLayout(pSimulationFlagsTabLayout);
  // add Output Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpSimulationFlagsTabScrollArea, tr("Simulation Flags"));
  // Output Tab
  mpOutputTab = new QWidget;
  // Output Format
  mpOutputFormatLabel = new Label(tr("Output Format:"));
  mpOutputFormatComboBox = new QComboBox;
  mpOutputFormatComboBox->addItems(Helper::ModelicaSimulationOutputFormats.toLower().split(","));
  // single precision
  mpSinglePrecisionCheckBox = new QCheckBox(tr("Single Precision"));
  // Output filename
  mpFileNameLabel = new Label(tr("File Name Prefix (Optional):"));
  mpFileNameTextBox = new QLineEdit;
  mpFileNameTextBox->setToolTip(tr("The name is used as a prefix for the output files. This is just a name not the path.\n"
                                   "If you want to change the output path then update the working directory in Options/Preferences."));
  mpResultFileNameLabel = new Label(tr("Result File (Optional):"));
  mpResultFileNameTextBox = new QLineEdit;
  connect(mpOutputFormatComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(resultFileNameChanged(QString)));
  // Variable filter
  mpVariableFilterLabel = new Label(tr("Variable Filter (Optional):"));
  mpVariableFilterTextBox = new QLineEdit(".*");
  // Protected Variabels
  mpProtectedVariablesCheckBox = new QCheckBox(tr("Protected Variables"));
  // ignore hide result
  mpIgnoreHideResultCheckBox = new QCheckBox(tr("Ignore HideResult"));
  // Equidistant time grid
  mpEquidistantTimeGridCheckBox = new QCheckBox(tr("Equidistant Time Grid"));
  // store variables at events
  mpStoreVariablesAtEventsCheckBox = new QCheckBox(tr("Store Variables at Events"));
  // show generated files checkbox
  mpShowGeneratedFilesCheckBox = new QCheckBox(tr("Show Generated Files"));
  // set Output Tab Layout
  QGridLayout *pOutputTabLayout = new QGridLayout;
  pOutputTabLayout->setAlignment(Qt::AlignTop);
  pOutputTabLayout->addWidget(mpOutputFormatLabel, 0, 0);
  pOutputTabLayout->addWidget(mpOutputFormatComboBox, 0, 1);
  pOutputTabLayout->addWidget(mpSinglePrecisionCheckBox, 1, 0, 1, 2);
  pOutputTabLayout->addWidget(mpFileNameLabel, 2, 0);
  pOutputTabLayout->addWidget(mpFileNameTextBox, 2, 1);
  pOutputTabLayout->addWidget(mpResultFileNameLabel, 3, 0);
  pOutputTabLayout->addWidget(mpResultFileNameTextBox, 3, 1);
  pOutputTabLayout->addWidget(mpVariableFilterLabel, 4, 0);
  pOutputTabLayout->addWidget(mpVariableFilterTextBox, 4, 1);
  pOutputTabLayout->addWidget(mpProtectedVariablesCheckBox, 5, 0, 1, 2);
  pOutputTabLayout->addWidget(mpIgnoreHideResultCheckBox, 6, 0, 1, 2);
  pOutputTabLayout->addWidget(mpEquidistantTimeGridCheckBox, 7, 0, 1, 2);
  pOutputTabLayout->addWidget(mpStoreVariablesAtEventsCheckBox, 8, 0, 1, 2);
  pOutputTabLayout->addWidget(mpShowGeneratedFilesCheckBox, 9, 0, 1, 2);
  mpOutputTab->setLayout(pOutputTabLayout);
  // add Output Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpOutputTab, Helper::output);
  // Add the validators
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  mpStartTimeTextBox->setValidator(pDoubleValidator);
  mpStopTimeTextBox->setValidator(pDoubleValidator);
  mpIntervalTextBox->setValidator(pDoubleValidator);
  mpToleranceTextBox->setValidator(pDoubleValidator);
  QIntValidator *pIntValidator = new QIntValidator(this);
  pIntValidator->setRange(0, 65535);
  mpInteractiveSimulationPortNumberTextBox->setValidator(pIntValidator);
  // create checkboxes
  mpSaveExperimentAnnotationCheckBox = new QCheckBox(Helper::saveExperimentAnnotation);
  mpSaveSimulationFlagsAnnotationCheckBox = new QCheckBox(Helper::saveOpenModelicaSimulationFlagsAnnotation);
  mpSaveTranslationFlagsAnnotationCheckBox = new QCheckBox(Helper::saveOpenModelicaCommandLineOptionsAnnotation);
  mpSimulateCheckBox = new QCheckBox(Helper::simulate);
  mpSimulateCheckBox->setChecked(true);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(simulate()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  // adds buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->addWidget(mpSimulationHeading, 0, 0);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0);
  pMainLayout->addWidget(mpSimulationTabWidget, 2, 0);
  pMainLayout->addWidget(mpSaveExperimentAnnotationCheckBox, 3, 0);
  pMainLayout->addWidget(mpSaveTranslationFlagsAnnotationCheckBox, 4, 0);
  pMainLayout->addWidget(mpSaveSimulationFlagsAnnotationCheckBox, 5, 0);
  pMainLayout->addWidget(mpSimulateCheckBox, 6, 0);
  pMainLayout->addWidget(mpButtonBox, 7, 0);
  setLayout(pMainLayout);
}

/*!
  Validates the simulation values entered by the user.
  */
bool SimulationDialog::validate()
{
  if (mpStartTimeTextBox->text().isEmpty()) {
    mpStartTimeTextBox->setText("0");
  }
  if (mpStopTimeTextBox->text().isEmpty()) {
    mpStopTimeTextBox->setText("1");
  }
  if (mpIntervalRadioButton->isChecked() && mpIntervalTextBox->text().isEmpty()) {
    mpIntervalTextBox->setText("0.002");
  }
  if (mpStartTimeTextBox->text().toDouble() > mpStopTimeTextBox->text().toDouble()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::SIMULATION_STARTTIME_LESSTHAN_STOPTIME), Helper::ok);
    return false;
  }
  /* Ticket:5974
   * Check if there is already active simulation running of this model.
   */
  SimulationOutputWidget *pSimulationOutputWidget = MessagesWidget::instance()->getSimulationOutputWidget(mClassName);
  if (pSimulationOutputWidget && (pSimulationOutputWidget->isCompilationProcessRunning() || pSimulationOutputWidget->isSimulationProcessRunning())) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          tr("Simulation of model <b>%1</b> is already running. Please wait for it to finish or cancel it before running another simulation of the same model.")
                          .arg(mClassName), Helper::ok);
    return false;
  }
  return true;
}

/*!
  Initializes the simulation dialog with the default values.
  */
void SimulationDialog::initializeFields(bool isReSimulate, SimulationOptions simulationOptions)
{
  if (!isReSimulate) {
    mIsReSimulate = false;
    mClassName = mpLibraryTreeItem->getNameStructure();
    mFileName = mpLibraryTreeItem->getFileName();
    setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::simulationSetup).append(" - ").append(mClassName));
    mpSimulationHeading->setText(QString(Helper::simulationSetup).append(" - ").append(mClassName));
    // apply simulation options
    mpLibraryTreeItem->mSimulationOptions.setClassName(mClassName);
    /* Fix for ticket:5796
     * Set the file name prefix to the model name to avoid the long paths.
     */
    if (!mpLibraryTreeItem->mSimulationOptions.isValid()) {
      mpLibraryTreeItem->mSimulationOptions.setFileNamePrefix(StringHandler::getLastWordAfterDot(mClassName));
    }
    applySimulationOptions(mpLibraryTreeItem->mSimulationOptions);
    /* Fix for ticket:4975
     * If SimulationOptions is invalid it means we are going to simulate this class for the first time.
     * So in that case read the experiment and __OpenModelica_simulationFlags annotations and apply them on top of the default.
     * If SimulationOptions is valid that means we already simulated that class and in that case we applied the options last time set
     * by the user.
     */
    if (!mpLibraryTreeItem->mSimulationOptions.isValid()) {
      // if the class has experiment annotation then read it.
      if (MainWindow::instance()->getOMCProxy()->isExperiment(mClassName)) {
        // get the simulation options....
        OMCInterface::getSimulationOptions_res simulationOptions_res = MainWindow::instance()->getOMCProxy()->getSimulationOptions(mClassName);
        // since we always get simulationOptions so just get the values from array
        mpStartTimeTextBox->setText(QString::number(simulationOptions_res.startTime));
        mpStopTimeTextBox->setText(QString::number(simulationOptions_res.stopTime));
        mpToleranceTextBox->setText(QString::number(simulationOptions_res.tolerance));
        mpNumberofIntervalsSpinBox->setValue(simulationOptions_res.numberOfIntervals);
        mpIntervalTextBox->setText(QString::number(simulationOptions_res.interval));
      }
      // apply the global translation flags
      TranslationFlagsWidget *pGlobalTranslationFlagsWidget = OptionsDialog::instance()->getSimulationPage()->getTranslationFlagsWidget();
      mpTranslationFlagsWidget->getMatchingAlgorithmComboBox()->setCurrentIndex(pGlobalTranslationFlagsWidget->getMatchingAlgorithmComboBox()->currentIndex());
      mpTranslationFlagsWidget->getIndexReductionMethodComboBox()->setCurrentIndex(pGlobalTranslationFlagsWidget->getIndexReductionMethodComboBox()->currentIndex());
      mpTranslationFlagsWidget->getInitializationCheckBox()->setChecked(pGlobalTranslationFlagsWidget->getInitializationCheckBox()->isChecked());
      mpTranslationFlagsWidget->getEvaluateAllParametersCheckBox()->setChecked(pGlobalTranslationFlagsWidget->getEvaluateAllParametersCheckBox()->isChecked());
      mpTranslationFlagsWidget->getNLSanalyticJacobianCheckBox()->setChecked(pGlobalTranslationFlagsWidget->getNLSanalyticJacobianCheckBox()->isChecked());
      mpTranslationFlagsWidget->getParmodautoCheckBox()->setChecked(pGlobalTranslationFlagsWidget->getParmodautoCheckBox()->isChecked());
      mpTranslationFlagsWidget->getOldInstantiationCheckBox()->setChecked(pGlobalTranslationFlagsWidget->getOldInstantiationCheckBox()->isChecked());
      mpTranslationFlagsWidget->getAdditionalTranslationFlagsTextBox()->setText(pGlobalTranslationFlagsWidget->getAdditionalTranslationFlagsTextBox()->text());
      // if ignoreCommandLineOptionsAnnotation flag is not set then read the __OpenModelica_commandLineOptions annotation
      if (!OptionsDialog::instance()->getSimulationPage()->getIgnoreCommandLineOptionsAnnotationCheckBox()->isChecked()) {
        QStringList additionalTranslationFlagsList;
        QString commandLineOptions = MainWindow::instance()->getOMCProxy()->getNamedAnnotation(mClassName, "__OpenModelica_commandLineOptions");
        QStringList commandLineOptionsList = commandLineOptions.split(" ");
        foreach (QString commandLineOption, commandLineOptionsList) {
          QStringList commandLineOptionList = commandLineOption.split("=");
          QString commandLineOptionKey, commandLineOptionValues;
          if (commandLineOptionList.size() > 1) {
            commandLineOptionKey = commandLineOptionList.at(0);
            commandLineOptionValues = commandLineOptionList.at(1);
          } else {
            commandLineOptionKey = commandLineOption;
            commandLineOptionValues = "";
          }
          QString commandLineOptionKeyFiltered = QString(commandLineOptionKey).remove(QRegExp("\\-|\\--|\\+"));
          if (commandLineOptionKeyFiltered.compare("matchingAlgorithm") == 0) {
            int currentIndex = mpTranslationFlagsWidget->getMatchingAlgorithmComboBox()->findText(commandLineOptionValues);
            if (currentIndex > -1) {
              mpTranslationFlagsWidget->getMatchingAlgorithmComboBox()->setCurrentIndex(currentIndex);
            }
          } else if (commandLineOptionKeyFiltered.compare("indexReductionMethod") == 0) {
            int currentIndex = mpTranslationFlagsWidget->getIndexReductionMethodComboBox()->findText(commandLineOptionValues);
            if (currentIndex > -1) {
              mpTranslationFlagsWidget->getIndexReductionMethodComboBox()->setCurrentIndex(currentIndex);
            }
          } else if (commandLineOptionKeyFiltered.compare("d") == 0) { // check debug flags i.e., -d=evaluateAllParameters,initialization etc.
            QStringList commandLineOptionValuesList = commandLineOptionValues.split(",");
            QStringList additionalDebugFlagsList;
            foreach (QString commandLineOptionValue, commandLineOptionValuesList) {
              commandLineOptionValue = commandLineOptionValue.trimmed();
              if (commandLineOptionValue.compare("initialization") == 0) {
                mpTranslationFlagsWidget->getInitializationCheckBox()->setChecked(true);
              } else if (commandLineOptionValue.compare("evaluateAllParameters") == 0) {
                mpTranslationFlagsWidget->getEvaluateAllParametersCheckBox()->setChecked(true);
              } else if (commandLineOptionValue.compare("NLSanalyticJacobian") == 0) {
                mpTranslationFlagsWidget->getNLSanalyticJacobianCheckBox()->setChecked(true);
              } else if (commandLineOptionValue.compare("parmodauto") == 0) {
                mpTranslationFlagsWidget->getParmodautoCheckBox()->setChecked(true);
              } else if (commandLineOptionValue.compare("newInst") == 0) {
                mpTranslationFlagsWidget->getOldInstantiationCheckBox()->setChecked(false);
              } else {
                additionalDebugFlagsList.append(commandLineOptionValue);
              }
            }
            if (!additionalDebugFlagsList.isEmpty()) {
              additionalTranslationFlagsList.append(QString("-d=%1").arg(additionalDebugFlagsList.join(",")));
            }
          }
        }
        QString additionalTranslationFlagsText = mpTranslationFlagsWidget->getAdditionalTranslationFlagsTextBox()->text();
        if (additionalTranslationFlagsText.isEmpty()) {
          mpTranslationFlagsWidget->getAdditionalTranslationFlagsTextBox()->setText(additionalTranslationFlagsList.join(" "));
        } else {
          mpTranslationFlagsWidget->getAdditionalTranslationFlagsTextBox()->setText(QString("%1 %2").arg(additionalTranslationFlagsText)
                                                                                    .arg(additionalTranslationFlagsList.join(" ")));
        }
      }
      // if ignoreSimulationFlagsAnnotation flag is not set then read the __OpenModelica_simulationFlags annotation
      if (!OptionsDialog::instance()->getSimulationPage()->getIgnoreSimulationFlagsAnnotationCheckBox()->isChecked()) {
        QMap<QString, QString> additionalSimulationFlags;
        // if the class has __OpenModelica_simulationFlags annotation then use its values.
        QList<QString> simulationFlags = MainWindow::instance()->getOMCProxy()->getAnnotationNamedModifiers(mClassName, "__OpenModelica_simulationFlags");
        foreach (QString simulationFlag, simulationFlags) {
          QString value = MainWindow::instance()->getOMCProxy()->getAnnotationModifierValue(mClassName, "__OpenModelica_simulationFlags", simulationFlag);
          if (simulationFlag.compare("clock") == 0) {
            mpClockComboBox->setCurrentIndex(mpClockComboBox->findText(value));
          } else if (simulationFlag.compare("cpu") == 0) {
            mpCPUTimeCheckBox->setChecked(true);
          } else if (simulationFlag.compare("noRestart") == 0) {
            mpRestartAfterEventCheckBox->setChecked(false);
          } else if (simulationFlag.compare("noRootFinding") == 0) {
            mpRootFindingCheckBox->setChecked(false);
          } else if (simulationFlag.compare("single") == 0) {
            mpSinglePrecisionCheckBox->setChecked(true);
          } else if (simulationFlag.compare("emit_protected") == 0) {
            mpProtectedVariablesCheckBox->setChecked(true);
          } else if (simulationFlag.compare("ignoreHideResult") == 0) {
            mpIgnoreHideResultCheckBox->setChecked(true);
          } else if (simulationFlag.compare("f") == 0) {
            mpModelSetupFileTextBox->setText(value);
          } else if (simulationFlag.compare("iif") == 0) {
            mpEquationSystemInitializationFileTextBox->setText(value);
          } else if (simulationFlag.compare("iim") == 0) {
            mpInitializationMethodComboBox->setCurrentIndex(mpInitializationMethodComboBox->findText(value));
          } else if (simulationFlag.compare("iit") == 0) {
            mpEquationSystemInitializationTimeTextBox->setText(value);
          } else if (simulationFlag.compare("initialStepSize") == 0) {
            mpInitialStepSizeTextBox->setText(value);
          } else if (simulationFlag.compare("jacobian") == 0) {
            mpJacobianComboBox->setCurrentIndex(mpJacobianComboBox->findText(value));
          } else if (simulationFlag.compare("l") == 0) {
            mpLinearizationTimeTextBox->setText(value);
          } else if (simulationFlag.compare("ls") == 0) {
            mpLinearSolverComboBox->setCurrentIndex(mpLinearSolverComboBox->findText(value));
          } else if (simulationFlag.compare("maxIntegrationOrder") == 0) {
            mpMaxIntegrationOrderSpinBox->setValue(value.toInt());
          } else if (simulationFlag.compare("maxStepSize") == 0) {
            mpMaxStepSizeTextBox->setText(value);
          } else if (simulationFlag.compare("nls") == 0) {
            mpNonLinearSolverComboBox->setCurrentIndex(mpNonLinearSolverComboBox->findText(value));
          } else if (simulationFlag.compare("noEquidistantTimeGrid") == 0) {
            mpEquidistantTimeGridCheckBox->setChecked(false);
          } else if (simulationFlag.compare("noEventEmit") == 0) {
            mpStoreVariablesAtEventsCheckBox->setChecked(false);
          } else if (simulationFlag.compare("output") == 0) {
            mpOutputVariablesTextBox->setText(value);
          } else if (simulationFlag.compare("r") == 0) {
            mpResultFileNameTextBox->setText(value);
            QRegExp resultFilesRegExp(Helper::omResultFileTypesRegExp);
            if (resultFilesRegExp.indexIn(value) != -1) {
              int currentIndex = mpOutputFormatComboBox->findText(StringHandler::getLastWordAfterDot(value));
              if (currentIndex > -1) {
                mpOutputFormatComboBox->setCurrentIndex(currentIndex);
              }
            }
          } else if (simulationFlag.compare("s") == 0) {
            mpMethodComboBox->setCurrentIndex(mpMethodComboBox->findText(value));
          } else if (simulationFlag.compare("lv") == 0) {
#if (QT_VERSION >= QT_VERSION_CHECK(5, 14, 0))
            QStringList logStreams = value.split(",", Qt::SkipEmptyParts);
#else // QT_VERSION_CHECK
            QStringList logStreams = value.split(",", QString::SkipEmptyParts);
#endif // QT_VERSION_CHECK
            int i = 0;
            while (QLayoutItem* pLayoutItem = mpLoggingGroupLayout->itemAt(i)) {
              if (dynamic_cast<QCheckBox*>(pLayoutItem->widget())) {
                QCheckBox *pLogStreamCheckBox = dynamic_cast<QCheckBox*>(pLayoutItem->widget());
                if (logStreams.contains(pLogStreamCheckBox->text())) {
                  pLogStreamCheckBox->setChecked(true);
                }
              }
              i++;
            }
          } else if (simulationFlag.compare("reconcile") == 0)  {
            mpLibraryTreeItem->mSimulationOptions.setDataReconciliationAlgorithm("dataReconciliation");
          } else if (simulationFlag.compare("reconcileBoundaryConditions") == 0) {
            mpLibraryTreeItem->mSimulationOptions.setDataReconciliationAlgorithm("dataReconciliationBoundaryConditions");
          } else if (simulationFlag.compare("sx") == 0) {
            mpLibraryTreeItem->mSimulationOptions.setDataReconciliationMeasurementInputFile(value);
          } else if (simulationFlag.compare("cx") == 0) {
            mpLibraryTreeItem->mSimulationOptions.setDataReconciliationCorrelationMatrixInputFile(value);
          } else if (simulationFlag.compare("eps") == 0) {
            mpLibraryTreeItem->mSimulationOptions.setDataReconciliationEpsilon(value);
          } else { // put everything else in the Additional Simulation Flags textbox only if the simulation flag is valid
            bool isValidSimulationFlag = false;
            for (int i = FLAG_UNKNOWN + 1 ; i < FLAG_MAX ; i++) {
              if (QString(FLAG_NAME[i]).compare(simulationFlag) == 0) {
                additionalSimulationFlags.insert(simulationFlag, value);
                isValidSimulationFlag = true;
                break;
              }
            }
            if (!isValidSimulationFlag) {
              MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Ignoring unknown simulation flag: %1").arg(simulationFlag),
                                                                    Helper::simulationKind, Helper::warningLevel));
            }
          }
        }
        QStringList additionalSimulationFlagsList;
        QMapIterator<QString, QString> additionalSimulationFlagsIterator(additionalSimulationFlags);
        additionalSimulationFlagsIterator.toFront();
        while (additionalSimulationFlagsIterator.hasNext()) {
          additionalSimulationFlagsIterator.next();
          if (additionalSimulationFlagsIterator.value().compare("()") == 0) {
            additionalSimulationFlagsList.append(QString("-%1").arg(additionalSimulationFlagsIterator.key()));
          } else {
            additionalSimulationFlagsList.append(QString("-%1=%2")
                                                 .arg(additionalSimulationFlagsIterator.key())
                                                 .arg(additionalSimulationFlagsIterator.value()));
          }
        }
        mpAdditionalSimulationFlagsTextBox->setText(additionalSimulationFlagsList.join(" "));
      }
    }
    mpCflagsTextBox->setEnabled(true);
    mpFileNameTextBox->setEnabled(true);
    mpSaveExperimentAnnotationCheckBox->setVisible(true);
    mpSaveSimulationFlagsAnnotationCheckBox->setVisible(true);
    mpSaveTranslationFlagsAnnotationCheckBox->setVisible(true);
    mpSimulateCheckBox->setVisible(true);
  } else {
    mIsReSimulate = true;
    mClassName = simulationOptions.getClassName();
    mFileName = simulationOptions.getFileName();
    setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::reSimulation).append(" - ").append(mClassName));
    mpSimulationHeading->setText(QString(Helper::reSimulation).append(" - ").append(mClassName));
    // apply simulation options
    applySimulationOptions(simulationOptions);
    mpInteractiveSimulationGroupBox->setChecked(false);
    mpInteractiveSimulationGroupBox->setEnabled(false);
    mpCflagsTextBox->setDisabled(true);
    mpFileNameTextBox->setDisabled(true);
    // save simulation settings
    mpSaveExperimentAnnotationCheckBox->setVisible(false);
    mpSaveSimulationFlagsAnnotationCheckBox->setVisible(false);
    mpSaveTranslationFlagsAnnotationCheckBox->setVisible(false);
    mpSimulateCheckBox->setVisible(false);
  }
}

/*!
 * \brief SimulationDialog::applySimulationOptions
 * Apply the simulation options to the SimulationDialog.
 * \param simulationOptions
 */
void SimulationDialog::applySimulationOptions(SimulationOptions simulationOptions)
{
  // Simulation Interval
  mpStartTimeTextBox->setText(simulationOptions.getStartTime());
  mpStopTimeTextBox->setText(simulationOptions.getStopTime());
  // Number Of Intervals
  mpNumberofIntervalsSpinBox->setValue(simulationOptions.getNumberofIntervals());
  // Interval
  mpIntervalTextBox->setText(QString::number(simulationOptions.getStepSize()));
  // Interactive simulation
  QString targetLanguage = OptionsDialog::instance()->getSimulationPage()->getTargetLanguageComboBox()->currentText();
  if (targetLanguage.compare("C") == 0) {
    mpInteractiveSimulationGroupBox->setEnabled(true);
    mpInteractiveSimulationGroupBox->setChecked(simulationOptions.isInteractiveSimulation());
    mpInteractiveSimulationStepCheckBox->setChecked(simulationOptions.isInteractiveSimulationWithSteps());
    mpInteractiveSimulationPortNumberTextBox->setText(QString::number(simulationOptions.getInteractiveSimulationPortNumber()));
  } else {
    mpInteractiveSimulationGroupBox->setChecked(false);
    mpInteractiveSimulationGroupBox->setEnabled(false);
  }
  // Integration
  int currentIndex = mpMethodComboBox->findText(simulationOptions.getMethod(), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpMethodComboBox->setCurrentIndex(currentIndex);
  }
  // Tolerance
  mpToleranceTextBox->setText(simulationOptions.getTolerance());
  // dassl jacobian
  currentIndex = mpJacobianComboBox->findText(simulationOptions.getJacobian(), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpJacobianComboBox->setCurrentIndex(currentIndex);
  }
  // no root finding
  mpRootFindingCheckBox->setChecked(simulationOptions.getRootFinding());
  // no restart
  mpRestartAfterEventCheckBox->setChecked(simulationOptions.getRestartAfterEvent());
  // initial step size
  mpInitialStepSizeTextBox->setText(simulationOptions.getInitialStepSize());
  // max step size
  mpMaxStepSizeTextBox->setText(simulationOptions.getMaxStepSize());
  // max integration order
  mpMaxIntegrationOrderSpinBox->setValue(simulationOptions.getMaxIntegration());
  // Compiler Flags
  mpCflagsTextBox->setText(simulationOptions.getCflags());
  // Number of Processors
  mpNumberOfProcessorsSpinBox->setValue(simulationOptions.getNumberOfProcessors());
  // Launch Transformational Debugger checkbox
  mpLaunchTransformationalDebuggerCheckBox->setChecked(simulationOptions.getLaunchTransformationalDebugger());
  // Launch Algorithmic Debugger checkbox
  mpLaunchAlgorithmicDebuggerCheckBox->setChecked(simulationOptions.getLaunchAlgorithmicDebugger());
#if !defined(WITHOUT_OSG)
  // Simulate with Animation checkbox
  mpLaunchAnimationCheckBox->setChecked(simulationOptions.getSimulateWithAnimation());
#endif
  // build only
  mpBuildOnlyCheckBox->setChecked(simulationOptions.getBuildOnly());
  // Translation Flags
  mpTranslationFlagsWidget->applySimulationOptions(simulationOptions);
  // Model Setup File
  mpModelSetupFileTextBox->setText(simulationOptions.getModelSetupFile());
  // Initialization Methods
  currentIndex = mpInitializationMethodComboBox->findText(simulationOptions.getInitializationMethod(), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpInitializationMethodComboBox->setCurrentIndex(currentIndex);
  }
  // Equation System Initialization File
  mpEquationSystemInitializationFileTextBox->setText(simulationOptions.getEquationSystemInitializationFile());
  // Equation System time
  mpEquationSystemInitializationTimeTextBox->setText(simulationOptions.getEquationSystemInitializationTime());
  // clock
  currentIndex = mpClockComboBox->findText(simulationOptions.getClock(), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpClockComboBox->setCurrentIndex(currentIndex);
  }
  // Linear Solvers
  currentIndex = mpLinearSolverComboBox->findText(simulationOptions.getLinearSolver(), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpLinearSolverComboBox->setCurrentIndex(currentIndex);
  }
  // Non Linear Solvers
  currentIndex = mpNonLinearSolverComboBox->findText(simulationOptions.getNonLinearSolver(), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpNonLinearSolverComboBox->setCurrentIndex(currentIndex);
  }
  // time where the linearization of the model should be performed
  mpLinearizationTimeTextBox->setText(simulationOptions.getLinearizationTime());
  // output variables
  mpOutputVariablesTextBox->setText(simulationOptions.getOutputVariables());
  // measure simulation time checkbox
  currentIndex = mpProfilingComboBox->findText(simulationOptions.getProfiling(), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpProfilingComboBox->setCurrentIndex(currentIndex);
  }
  // cpu-time checkbox
  mpCPUTimeCheckBox->setChecked(simulationOptions.getCPUTime());
  // enable all warnings
  mpEnableAllWarningsCheckBox->setChecked(simulationOptions.getEnableAllWarnings());
  // Logging
  QStringList logStreams = simulationOptions.getLogStreams();
  int i = 0;
  while (QLayoutItem* pLayoutItem = mpLoggingGroupLayout->itemAt(i)) {
    if (dynamic_cast<QCheckBox*>(pLayoutItem->widget())) {
      QCheckBox *pLogStreamCheckBox = dynamic_cast<QCheckBox*>(pLayoutItem->widget());
      if (logStreams.contains(pLogStreamCheckBox->text())) {
        pLogStreamCheckBox->setChecked(true);
      } else {
        pLogStreamCheckBox->setChecked(false);
      }
    }
    i++;
  }
  mpAdditionalSimulationFlagsTextBox->setText(simulationOptions.getAdditionalSimulationFlags());
  // output format
  bool state = mpOutputFormatComboBox->blockSignals(true);
  currentIndex = mpOutputFormatComboBox->findText(simulationOptions.getOutputFormat(), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpOutputFormatComboBox->setCurrentIndex(currentIndex);
  }
  mpOutputFormatComboBox->blockSignals(state);
  // single precision
  mpSinglePrecisionCheckBox->setChecked(simulationOptions.getSinglePrecision());
  mpSinglePrecisionCheckBox->setEnabled(mpOutputFormatComboBox->currentText().compare("mat") == 0);
  // Output filename
  if (simulationOptions.getFileNamePrefix().startsWith("_omcQuot_")) {
    mpFileNameTextBox->setText(QByteArray::fromHex(simulationOptions.getFileNamePrefix().toUtf8()));
  } else {
    mpFileNameTextBox->setText(simulationOptions.getFileNamePrefix());
  }
  // Result filename
  mpResultFileNameTextBox->setPlaceholderText(QString("%1_res.%2").arg(mClassName, simulationOptions.getOutputFormat()));
  if (!simulationOptions.isInteractiveSimulation()) {
    mpResultFileNameTextBox->setText(simulationOptions.getResultFileName());
  }
  // Variable filter
  mpVariableFilterTextBox->setText(simulationOptions.getVariableFilter());
  // Protected Variabels
  mpProtectedVariablesCheckBox->setChecked(simulationOptions.getProtectedVariables());
  // ignore HideResult
  mpIgnoreHideResultCheckBox->setChecked(simulationOptions.getIgnoreHideResult());
  // Equidistant time grid
  mpEquidistantTimeGridCheckBox->setChecked(simulationOptions.getEquidistantTimeGrid());
  // store variables at events
  mpStoreVariablesAtEventsCheckBox->setChecked(simulationOptions.getStoreVariablesAtEvents());
  // show generated files checkbox
  mpShowGeneratedFilesCheckBox->setChecked(simulationOptions.getShowGeneratedFiles());
}

/*!
 * \brief SimulationDialog::translateModel
 * Sends the translateModel command to OMC.
 * \param simulationParameters
 * \return
 */
bool SimulationDialog::translateModel(QString simulationParameters)
{
  // clear flags before setting the new ones
  MainWindow::instance()->getOMCProxy()->clearCommandLineOptions();
  /* ticket:5456 We don't call OptionsDialog::instance()->saveSimulationSettings() here
   * instead we call local TranslationFlagsWidget::applyFlags() and OptionsDialog::instance()->saveGlobalSimulationSettings()
   * so that we apply the local translation flags and global simulation settings as well.
   */
  mpTranslationFlagsWidget->applyFlags();
  OptionsDialog::instance()->saveGlobalSimulationSettings();
  OptionsDialog::instance()->saveNFAPISettings();
  // set profiling
  MainWindow::instance()->getOMCProxy()->setCommandLineOptions("+profiling=" + mpProfilingComboBox->currentText());
  // set the infoXMLOperations flag
  if (OptionsDialog::instance()->getDebuggerPage()->getGenerateOperationsCheckBox()->isChecked()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("-d=infoXmlOperations");
  }
  // check reset messages number before simulation option
  if (OptionsDialog::instance()->getMessagesPage()->getResetMessagesNumberBeforeSimulationCheckBox()->isChecked()) {
    MessagesWidget::instance()->resetMessagesNumber();
  }
  // check clear messages browser before simulation option
  if (OptionsDialog::instance()->getMessagesPage()->getClearMessagesBrowserBeforeSimulationCheckBox()->isChecked()) {
    MessagesWidget::instance()->clearMessages();
  }
  /* save the model before translating */
  if (OptionsDialog::instance()->getSimulationPage()->getSaveClassBeforeSimulationCheckBox()->isChecked() &&
      !mpLibraryTreeItem->isSaved() &&
      !MainWindow::instance()->getLibraryWidget()->saveLibraryTreeItem(mpLibraryTreeItem)) {
    return false;
  }
  // set the debugging flag before translation
  if (mpLaunchAlgorithmicDebuggerCheckBox->isChecked()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("-d=gendebugsymbols");
  }
#if !defined(WITHOUT_OSG)
  // set the visulation flag before translation
  if (mpLaunchAnimationCheckBox->isChecked()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("-d=visxml");
  }
#endif
  if (mpLibraryTreeItem->mSimulationOptions.getEnableDataReconciliation()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions(QString("--preOptModules+=%1").arg(mpLibraryTreeItem->mSimulationOptions.getDataReconciliationAlgorithm()));
  }
  bool result = MainWindow::instance()->getOMCProxy()->translateModel(mClassName, simulationParameters);
  if (!result) {
    //! @todo Remove this once new frontend is used as default and old frontend is removed.
    bool newFrontendEnabled = true;
    QList<QString> options = MainWindow::instance()->getOMCProxy()->getCommandLineOptions();
    foreach (QString option, options) {
      if (option.contains("nonewInst")) {
        newFrontendEnabled = false;
        break;
      }
    }

    if (newFrontendEnabled) {
      QSettings *pSettings = Utilities::getApplicationSettings();
      int answer;
      QComboBox *pOldFrontendComboBox = OptionsDialog::instance()->getNotificationsPage()->getOldFrontendComboBox();
      if (pOldFrontendComboBox->itemData(pOldFrontendComboBox->currentIndex()) == NotificationsPage::AlwaysAskForOF) {
        QDialog *pOldFrontEndSelectionDialog = new QDialog;
        pOldFrontEndSelectionDialog->setAttribute(Qt::WA_DeleteOnClose);
        pOldFrontEndSelectionDialog->setWindowTitle(QString("%1 -%2").arg(Helper::applicationName, Helper::question));
        pOldFrontEndSelectionDialog->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
        // Icon
        Label *pPixmapLabel = new Label;
        QStyle *pStyle = this->style();
        int iconSize = pStyle->pixelMetric(QStyle::PM_MessageBoxIconSize, 0, this);
        pPixmapLabel->setPixmap(pStyle->standardIcon(QStyle::SP_MessageBoxQuestion, 0, this).pixmap(iconSize, iconSize));
        // Label
        Label *pMessageLabel = new Label(tr("The code generation process failed, see the Messages Browser for detailed diagnostic messages.<br /><br />"
                                            "Most likely this is due to some issues in the Modelica source code, but it could also be due to some issues with the new OpenModelica compiler frontend.<br />"
                                            "In this case, you may re-try the code generation with the old frontend, see also <b>%1->Simulation->Enable old frontend for code generation</b>.").arg(Helper::toolsOptionsPath));
        pMessageLabel->setTextFormat(Qt::RichText);
        pMessageLabel->setTextInteractionFlags(pMessageLabel->textInteractionFlags() | Qt::LinksAccessibleByMouse | Qt::LinksAccessibleByKeyboard);
        pMessageLabel->setOpenExternalLinks(true);
        // Checkbox
        QCheckBox *pRememberCheckBox = new QCheckBox(tr("Remember my decision and do not ask again"));
        // buttons
        QPushButton *pTryOnceButton = new QPushButton(tr("Try with old frontend once"));
        pTryOnceButton->setAutoDefault(false);
        connect(pTryOnceButton, SIGNAL(clicked()), pOldFrontEndSelectionDialog, SLOT(accept()));
        QSignalMapper signalMapper;
        QPushButton *pSwitchButton = new QPushButton(tr("Switch to old frontend permanently"));
        pSwitchButton->setAutoDefault(false);
        connect(pSwitchButton, SIGNAL(clicked()), &signalMapper, SLOT(map()));
        QPushButton *pKeepButton = new QPushButton(tr("Keep using new frontend"));
        pKeepButton->setAutoDefault(true);
        connect(pKeepButton, SIGNAL(clicked()), &signalMapper, SLOT(map()));
        signalMapper.setMapping(pSwitchButton, 2);
        signalMapper.setMapping(pKeepButton, 3);
        connect(&signalMapper, SIGNAL(mapped(int)), pOldFrontEndSelectionDialog, SLOT(done(int)));
        QDialogButtonBox *pButtonBox = new QDialogButtonBox(Qt::Horizontal);
        pButtonBox->addButton(pKeepButton, QDialogButtonBox::ActionRole);
        pButtonBox->addButton(pTryOnceButton, QDialogButtonBox::ActionRole);
        pButtonBox->addButton(pSwitchButton, QDialogButtonBox::ActionRole);
        // horizontal layout
        QHBoxLayout *pHorizontalLayout = new QHBoxLayout;
        pHorizontalLayout->addWidget(pPixmapLabel, 0, Qt::AlignTop);
        pHorizontalLayout->addWidget(pMessageLabel, 0, Qt::AlignTop);
        // main layout
        QGridLayout *pMainLayout = new QGridLayout;
        pMainLayout->addLayout(pHorizontalLayout, 0, 0, 1, 2, Qt::AlignTop | Qt::AlignLeft);
        pMainLayout->addWidget(pRememberCheckBox, 1, 0, Qt::AlignLeft | Qt::AlignBottom);
        pMainLayout->addWidget(pButtonBox, 1, 1, Qt::AlignRight | Qt::AlignBottom);
        pOldFrontEndSelectionDialog->setLayout(pMainLayout);
        answer = pOldFrontEndSelectionDialog->exec();
        if (answer > 1 && pRememberCheckBox->isChecked()) {
          pSettings->setValue("notifications/promptOldFrontend", answer);
          pOldFrontendComboBox->setCurrentIndex(pOldFrontendComboBox->findData(answer));
        }
      } else {
        answer = pOldFrontendComboBox->itemData(pOldFrontendComboBox->currentIndex()).toInt();
      }

      switch (answer) {
        case 1:
          MainWindow::instance()->getOMCProxy()->disableNewInstantiation();
          result = MainWindow::instance()->getOMCProxy()->translateModel(mClassName, simulationParameters);
          break;
        case 2:
          OptionsDialog::instance()->getSimulationPage()->getTranslationFlagsWidget()->getOldInstantiationCheckBox()->setChecked(true);
          mpTranslationFlagsWidget->getOldInstantiationCheckBox()->setChecked(true);
          if (mpLibraryTreeItem->mSimulationOptions.isValid()) {
            mpLibraryTreeItem->mSimulationOptions.setOldInstantiation(true);
          }
          MainWindow::instance()->getOMCProxy()->disableNewInstantiation();
          result = MainWindow::instance()->getOMCProxy()->translateModel(mClassName, simulationParameters);
          break;
        case 3:
          break;
        case 0:
        default:
          // user cancelled. Do nothing.
          break;
      }
    }
  }
  // reset simulation settings
  OptionsDialog::instance()->saveSimulationSettings();
  OptionsDialog::instance()->saveNFAPISettings();
  // set the infoXMLOperations flag
  if (OptionsDialog::instance()->getDebuggerPage()->getGenerateOperationsCheckBox()->isChecked()) {
    MainWindow::instance()->getOMCProxy()->setCommandLineOptions("-d=infoXmlOperations");
  }
  return result;
}

/*!
 * \brief SimulationDialog::createSimulationOptions
 * Creates the SimulationOptions
 * \return
 */
SimulationOptions SimulationDialog::createSimulationOptions()
{
  SimulationOptions simulationOptions = mpLibraryTreeItem->mSimulationOptions;
  simulationOptions.setClassName(mClassName);
  simulationOptions.setStartTime(mpStartTimeTextBox->text());
  simulationOptions.setStopTime(mpStopTimeTextBox->text());
  simulationOptions.setNumberofIntervals(mpNumberofIntervalsSpinBox->value());
  qreal startTime = mpStartTimeTextBox->text().toDouble();
  qreal stopTime = mpStopTimeTextBox->text().toDouble();
  if (mpNumberofIntervalsRadioButton->isChecked()) {
    simulationOptions.setStepSize((stopTime - startTime)/mpNumberofIntervalsSpinBox->value());
  } else {
    simulationOptions.setStepSize(mpIntervalTextBox->text().toDouble());
  }
  simulationOptions.setInteractiveSimulation(mpInteractiveSimulationGroupBox->isChecked());
  simulationOptions.setInteractiveSimulationWithSteps(mpInteractiveSimulationStepCheckBox->isChecked());
  simulationOptions.setMethod(mpMethodComboBox->currentText());
  simulationOptions.setTolerance(mpToleranceTextBox->text());
  simulationOptions.setJacobian(mpJacobianComboBox->currentText());
  simulationOptions.setRootFinding(mpRootFindingCheckBox->isChecked());
  simulationOptions.setRestartAfterEvent(mpRestartAfterEventCheckBox->isChecked());
  simulationOptions.setInitialStepSize(mpInitialStepSizeTextBox->text());
  simulationOptions.setMaxStepSize(mpMaxStepSizeTextBox->text());
  simulationOptions.setMaxIntegration(mpMaxIntegrationOrderSpinBox->value());
  simulationOptions.setCflags(mpCflagsTextBox->text());
  simulationOptions.setNumberOfProcessors(mpNumberOfProcessorsSpinBox->value());
  simulationOptions.setBuildOnly(mpBuildOnlyCheckBox->isChecked());
  simulationOptions.setLaunchTransformationalDebugger(mpLaunchTransformationalDebuggerCheckBox->isChecked());
  simulationOptions.setLaunchAlgorithmicDebugger(mpLaunchAlgorithmicDebuggerCheckBox->isChecked());
#if !defined(WITHOUT_OSG)
  simulationOptions.setSimulateWithAnimation(mpLaunchAnimationCheckBox->isChecked());
#endif

  mpTranslationFlagsWidget->createSimulationOptions(&simulationOptions);

  simulationOptions.setModelSetupFile(mpModelSetupFileTextBox->text());
  simulationOptions.setInitializationMethod(mpInitializationMethodComboBox->currentText());
  simulationOptions.setEquationSystemInitializationFile(mpEquationSystemInitializationFileTextBox->text());
  simulationOptions.setEquationSystemInitializationTime(mpEquationSystemInitializationTimeTextBox->text());
  simulationOptions.setClock(mpClockComboBox->currentText());
  simulationOptions.setLinearSolver(mpLinearSolverComboBox->currentText());
  simulationOptions.setNonLinearSolver(mpNonLinearSolverComboBox->currentText());
  simulationOptions.setLinearizationTime(mpLinearizationTimeTextBox->text());
  simulationOptions.setOutputVariables(mpOutputVariablesTextBox->text());
  simulationOptions.setProfiling(mpProfilingComboBox->currentText());
  simulationOptions.setCPUTime(mpCPUTimeCheckBox->isChecked());
  simulationOptions.setEnableAllWarnings(mpEnableAllWarningsCheckBox->isChecked());
  QStringList logStreams;
  int i = 0;
  while (QLayoutItem* pLayoutItem = mpLoggingGroupLayout->itemAt(i)) {
    if (dynamic_cast<QCheckBox*>(pLayoutItem->widget())) {
      QCheckBox *pLogStreamCheckBox = dynamic_cast<QCheckBox*>(pLayoutItem->widget());
      if (pLogStreamCheckBox->isChecked()) {
        logStreams << pLogStreamCheckBox->text();
      }
    }
    i++;
  }
  simulationOptions.setLogStreams(logStreams);
  simulationOptions.setAdditionalSimulationFlags(mpAdditionalSimulationFlagsTextBox->text());

  simulationOptions.setOutputFormat(mpOutputFormatComboBox->currentText());
  simulationOptions.setSinglePrecision(mpSinglePrecisionCheckBox->isChecked());
  if (!mpFileNameTextBox->text().isEmpty()) {
    if (mpFileNameTextBox->text().contains('\'')) {
      simulationOptions.setFileNamePrefix("_omcQuot_" + mpFileNameTextBox->text().toUtf8().toHex());
    } else {
      simulationOptions.setFileNamePrefix(mpFileNameTextBox->text());
    }
  } else if (mClassName.contains('\'')) {
    simulationOptions.setFileNamePrefix("_omcQuot_" + mClassName.toUtf8().toHex());
  }
  // result file should not be generated if an interactive simulation is selected
  if (!mpInteractiveSimulationGroupBox->isChecked()) {
    if (!mpResultFileNameTextBox->text().isEmpty()) {
      simulationOptions.setResultFileName(mpResultFileNameTextBox->text());
    }
  } else {
    // set an invalid result file name to avoid interactive simulations to destroy previous results
    simulationOptions.setResultFileName(QString(mClassName + "_res.int"));
  }
  simulationOptions.setVariableFilter(mpVariableFilterTextBox->text());
  simulationOptions.setProtectedVariables(mpProtectedVariablesCheckBox->isChecked());
  simulationOptions.setIgnoreHideResult(mpIgnoreHideResultCheckBox->isChecked());
  simulationOptions.setEquidistantTimeGrid(mpEquidistantTimeGridCheckBox->isChecked());
  simulationOptions.setStoreVariablesAtEvents(mpStoreVariablesAtEventsCheckBox->isChecked());
  simulationOptions.setShowGeneratedFiles(mpShowGeneratedFilesCheckBox->isChecked());
  // create a folder with model name to dump the files in it.
  QString modelDirectoryPath = QString("%1/%2").arg(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory(), mClassName);
  if (!QDir().exists(modelDirectoryPath)) {
    QDir().mkpath(modelDirectoryPath);
  }
  // set the folder as working directory
  QString modelDirectory = MainWindow::instance()->getOMCProxy()->changeDirectory(modelDirectoryPath);
  if (!modelDirectory.isEmpty()) {
    simulationOptions.setWorkingDirectory(modelDirectoryPath);
  } else {
    simulationOptions.setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
  }
  // setup simulation flags
  QStringList simulationFlags;
  simulationFlags.append(QString("-override=%1=%2,%3=%4,%5=%6,%7=%8,%9=%10,%11=%12,%13=%14")
                         .arg("startTime").arg(simulationOptions.getStartTime())
                         .arg("stopTime").arg(simulationOptions.getStopTime())
                         .arg("stepSize").arg(simulationOptions.getStepSize())
                         .arg("tolerance").arg(simulationOptions.getTolerance())
                         .arg("solver").arg(simulationOptions.getMethod())
                         .arg("outputFormat").arg(simulationOptions.getOutputFormat())
                         .arg("variableFilter").arg(simulationOptions.getVariableFilter()));
  simulationFlags.append(QString("-r=%1/%2").arg(simulationOptions.getWorkingDirectory(), simulationOptions.getFullResultFileName()));
  // jacobian
  if (!mpJacobianComboBox->currentText().isEmpty()) {
    simulationFlags.append(QString("-jacobian=").append(mpJacobianComboBox->currentText()));
  }
  // dassl/ida options
  if (mpDasslIdaOptionsGroupBox->isEnabled()) {
    // root finding
    if (!mpRootFindingCheckBox->isChecked()) {
      simulationFlags.append("-noRootFinding");
    }
    // restart after event
    if (!mpRestartAfterEventCheckBox->isChecked()) {
      simulationFlags.append("-noRestart");
    }
    // initial step size
    if (!mpInitialStepSizeTextBox->text().isEmpty()) {
      simulationFlags.append(QString("-initialStepSize=").append(mpInitialStepSizeTextBox->text()));
    }
    // max step size
    if (!mpMaxStepSizeTextBox->text().isEmpty()) {
      simulationFlags.append(QString("-maxStepSize=").append(mpMaxStepSizeTextBox->text()));
    }
    // max step size
    if (mpMaxIntegrationOrderSpinBox->value() != 5) {
      simulationFlags.append(QString("-maxIntegrationOrder=").append(QString::number(mpMaxIntegrationOrderSpinBox->value())));
    }
  }
  // single precision
  if ((simulationOptions.getOutputFormat().compare("mat") == 0) && mpSinglePrecisionCheckBox->isChecked()) {
    simulationFlags.append("-single");
  }
  // emit protected variables
  if (mpProtectedVariablesCheckBox->isChecked()) {
    simulationFlags.append("-emit_protected");
  }
  // ignoreHideResult
  if (mpIgnoreHideResultCheckBox->isChecked()) {
    simulationFlags.append("-ignoreHideResult");
  }
  // Equidistant time grid
  if (mpEquidistantTimeGridCheckBox->isEnabled() && !mpEquidistantTimeGridCheckBox->isChecked()) {
    simulationFlags.append("-noEquidistantTimeGrid");
  }
  // store variables at events
  if (!mpStoreVariablesAtEventsCheckBox->isChecked()) {
    simulationFlags.append("-noEventEmit");
  }
  // setup Model Setup file flag
  if (!mpModelSetupFileTextBox->text().isEmpty()) {
    simulationFlags.append(QString("-f=").append(mpModelSetupFileTextBox->text()));
  }
  // setup initiaization method flag
  if (!mpInitializationMethodComboBox->currentText().isEmpty()) {
    simulationFlags.append(QString("-iim=").append(mpInitializationMethodComboBox->currentText()));
  }
  // setup Equation System Initialization file flag
  if (!mpEquationSystemInitializationFileTextBox->text().isEmpty()) {
    simulationFlags.append(QString("-iif=").append(mpEquationSystemInitializationFileTextBox->text()));
  }
  // setup Equation System Initialization time flag
  if (!mpEquationSystemInitializationTimeTextBox->text().isEmpty()) {
    simulationFlags.append(QString("-iit=").append(mpEquationSystemInitializationTimeTextBox->text()));
  }
  // clock
  if (!mpClockComboBox->currentText().isEmpty()) {
    simulationFlags.append(QString("-clock=").append(mpClockComboBox->currentText()));
  }
  // linear solver
  if (!mpLinearSolverComboBox->currentText().isEmpty()) {
    simulationFlags.append(QString("-ls=").append(mpLinearSolverComboBox->currentText()));
  }
  // non linear solver
  if (!mpNonLinearSolverComboBox->currentText().isEmpty()) {
    simulationFlags.append(QString("-nls=").append(mpNonLinearSolverComboBox->currentText()));
  }
  // time where the linearization of the model should be performed
  if (!mpLinearizationTimeTextBox->text().isEmpty()) {
    simulationFlags.append(QString("-l=").append(mpLinearizationTimeTextBox->text()));
  }
  // output variables
  if (!mpOutputVariablesTextBox->text().isEmpty()) {
    simulationFlags.append(QString("-output=").append(mpOutputVariablesTextBox->text()));
  }
  // setup cpu time flag
  if (mpCPUTimeCheckBox->isChecked()) {
    simulationFlags.append("-cpu");
  }
  // setup enable all warnings flag
  if (mpEnableAllWarningsCheckBox->isChecked()) {
    simulationFlags.append("-w");
  }
  // setup data reconciliation
  if (simulationOptions.getEnableDataReconciliation()) {
    if (simulationOptions.getDataReconciliationAlgorithm().compare(QStringLiteral("dataReconciliation")) == 0) {
      simulationFlags.append("-reconcile");
    } else {
      simulationFlags.append("-reconcileBoundaryConditions");
    }
    if (!simulationOptions.getDataReconciliationMeasurementInputFile().isEmpty()) {
      simulationFlags.append(QString("-sx=%1").arg(simulationOptions.getDataReconciliationMeasurementInputFile()));
    }
    if (!simulationOptions.getDataReconciliationCorrelationMatrixInputFile().isEmpty()) {
      simulationFlags.append(QString("-cx=%1").arg(simulationOptions.getDataReconciliationCorrelationMatrixInputFile()));
    }
    if (!simulationOptions.getDataReconciliationEpsilon().isEmpty()) {
      simulationFlags.append(QString("-eps=%1").arg(simulationOptions.getDataReconciliationEpsilon()));
    }
  }
  // setup Logging flags
  if (logStreams.size() > 0) {
    simulationFlags.append(QString("-lv=").append(logStreams.join(",")));
  }
  if (!mpAdditionalSimulationFlagsTextBox->text().isEmpty()) {
    simulationFlags.append(StringHandler::splitStringWithSpaces(mpAdditionalSimulationFlagsTextBox->text()));
  }
  // setup interactive simulation server
  if (mpInteractiveSimulationGroupBox->isChecked()) {
    simulationFlags.append("-embeddedServer=opc-ua");
    // embedded server port
    if (mpInteractiveSimulationPortNumberTextBox->text().isEmpty()) {
      simulationFlags.append(QString("-embeddedServerPort=").append(QString::number(simulationOptions.getInteractiveSimulationPortNumber())));
    } else {
      bool isInt;
      int portNumber = mpInteractiveSimulationPortNumberTextBox->text().toInt(&isInt);
      if (isInt) {
        simulationOptions.setInteractiveSimulationPortNumber(portNumber);
        simulationFlags.append(QString("-embeddedServerPort=").append(QString::number(portNumber)));
        // if the user enters a used port
        if (mOpcUaClientsMap.contains(portNumber)) {
          killSimulationProcess(portNumber);
        }
      }
    }
  }
  simulationFlags.append(QString("-inputPath=%1").arg(simulationOptions.getWorkingDirectory()));
  simulationFlags.append(QString("-outputPath=%1").arg(simulationOptions.getWorkingDirectory()));
  simulationOptions.setSimulationFlags(simulationFlags);
  simulationOptions.setIsValid(true);
  simulationOptions.setReSimulate(mIsReSimulate);

  simulationOptions.setFileName(mFileName);
  simulationOptions.setTargetLanguage(OptionsDialog::instance()->getSimulationPage()->getTargetLanguageComboBox()->currentText());
  return simulationOptions;
}

/*!
 * \brief SimulationDialog::createAndShowSimulationOutputWidget
 * Creates the SimulationOutputWidget.
 * \param simulationOptions
 */
void SimulationDialog::createAndShowSimulationOutputWidget(SimulationOptions simulationOptions)
{
  /* If resimulation and show algorithmic debugger is checked then show algorithmic debugger.
   * Otherwise run the normal resimulation.
   */
  if (simulationOptions.isReSimulate() && simulationOptions.getLaunchAlgorithmicDebugger()) {
    showAlgorithmicDebugger(simulationOptions);
  } else {
    if (simulationOptions.isReSimulate() && simulationOptions.isInteractiveSimulation()) {
      removeVariablesFromTree(simulationOptions.getClassName());
    }
    SimulationOutputWidget *pSimulationOutputWidget = new SimulationOutputWidget(simulationOptions);
    MessagesWidget::instance()->addSimulationOutputTab(pSimulationOutputWidget, simulationOptions.getOutputFileName());
    if (OptionsDialog::instance()->getSimulationPage()->getSwitchToPlottingPerspectiveCheckBox()->isChecked()) {
      MainWindow::instance()->switchToPlottingPerspectiveSlot();
    } else {
      // stay in current perspective and show variables browser
      MainWindow::instance()->getVariablesDockWidget()->show();
    }
  }
}

/*!
 * \brief SimulationDialog::saveSimulationSettings
 * Saves the experiment annotation in the model.
 */
void SimulationDialog::saveExperimentAnnotation()
{
  if (mIsReSimulate) {
    return;
  }

  QString oldExperimentAnnotation = "annotate=experiment(";
  // if the class has experiment annotation then read it.
  if (MainWindow::instance()->getOMCProxy()->isExperiment(mpLibraryTreeItem->getNameStructure())) {
    // get the simulation options....
    OMCInterface::getSimulationOptions_res simulationOptions = MainWindow::instance()->getOMCProxy()->getSimulationOptions(mpLibraryTreeItem->getNameStructure());
    // since we always get simulationOptions so just get the values from array
    oldExperimentAnnotation.append("StartTime=").append(QString::number(simulationOptions.startTime)).append(",");
    oldExperimentAnnotation.append("StopTime=").append(QString::number(simulationOptions.stopTime)).append(",");
    oldExperimentAnnotation.append("Tolerance=").append(QString::number(simulationOptions.tolerance)).append(",");
    oldExperimentAnnotation.append("Interval=").append(QString::number(simulationOptions.interval));
  }
  oldExperimentAnnotation.append(")");
  QString newExperimentAnnotation;
  // create simulations options annotation
  newExperimentAnnotation.append("annotate=experiment(");
  newExperimentAnnotation.append("StartTime=").append(mpStartTimeTextBox->text()).append(",");
  newExperimentAnnotation.append("StopTime=").append(mpStopTimeTextBox->text()).append(",");
  newExperimentAnnotation.append("Tolerance=").append(mpToleranceTextBox->text()).append(",");
  double interval, stopTime, startTime;
  int numberOfIntervals;
  if (mpNumberofIntervalsRadioButton->isChecked()) {
    stopTime = mpStopTimeTextBox->text().toDouble();
    startTime = mpStartTimeTextBox->text().toDouble();
    numberOfIntervals = mpNumberofIntervalsSpinBox->value();
    interval = (numberOfIntervals == 0) ? 0 : (stopTime - startTime) / numberOfIntervals;
  } else {
    interval = mpIntervalTextBox->text().toDouble();
  }
  newExperimentAnnotation.append("Interval=").append(QString::number(interval));
  newExperimentAnnotation.append(")");
  // if we have ModelWidget for class then put the change on undo stack.
  if (mpLibraryTreeItem->getModelWidget()) {
    UpdateClassAnnotationCommand *pUpdateClassExperimentAnnotationCommand;
    pUpdateClassExperimentAnnotationCommand = new UpdateClassAnnotationCommand(mpLibraryTreeItem, oldExperimentAnnotation,
                                                                               newExperimentAnnotation);
    mpLibraryTreeItem->getModelWidget()->getUndoStack()->push(pUpdateClassExperimentAnnotationCommand);
    mpLibraryTreeItem->getModelWidget()->updateModelText();
  } else {
    // send the simulations options annotation to OMC
    MainWindow::instance()->getOMCProxy()->addClassAnnotation(mpLibraryTreeItem->getNameStructure(), newExperimentAnnotation);
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    pLibraryTreeModel->updateLibraryTreeItemClassText(mpLibraryTreeItem);
  }
}

/*!
 * \brief SimulationDialog::saveSimulationFlagsAnnotation
 * Saves the __OpenModelica_simulationFlags annotation in the model.
 */
void SimulationDialog::saveSimulationFlagsAnnotation()
{
  if (mIsReSimulate) {
    return;
  }
  // old simulation flags
  QString oldSimulationFlags = QString("annotate=%1").arg(MainWindow::instance()->getOMCProxy()->getSimulationFlagsAnnotation(mpLibraryTreeItem->getNameStructure()));
  // new simulation flags
  QMap<QString, QString> simulationFlags;
  if (!mpClockComboBox->currentText().isEmpty()) {
    simulationFlags.insert("clock", mpClockComboBox->currentText());
  }
  if (mpCPUTimeCheckBox->isChecked()) {
    simulationFlags.insert("cpu", "()");
  }
  if (!mpRestartAfterEventCheckBox->isChecked()) {
    simulationFlags.insert("noRestart", "()");
  }
  if (!mpRootFindingCheckBox->isChecked()) {
    simulationFlags.insert("noRootFinding", "()");
  }
  if ((mpOutputFormatComboBox->currentText().compare("mat") == 0) && mpSinglePrecisionCheckBox->isChecked()) {
    simulationFlags.insert("single", "()");
  }
  if (mpProtectedVariablesCheckBox->isChecked()) {
    simulationFlags.insert("emit_protected", "()");
  }
  if (mpIgnoreHideResultCheckBox->isChecked()) {
    simulationFlags.insert("ignoreHideResult", "()");
  }
  if (!mpModelSetupFileTextBox->text().isEmpty()) {
    simulationFlags.insert("f", mpModelSetupFileTextBox->text());
  }
  if (!mpEquationSystemInitializationFileTextBox->text().isEmpty()) {
    simulationFlags.insert("iif", mpEquationSystemInitializationFileTextBox->text());
  }
  if (!mpInitializationMethodComboBox->currentText().isEmpty()) {
    simulationFlags.insert("iim", mpInitializationMethodComboBox->currentText());
  }
  if (!mpEquationSystemInitializationTimeTextBox->text().isEmpty()) {
    simulationFlags.insert("iit", mpEquationSystemInitializationTimeTextBox->text());
  }
  if (!mpInitialStepSizeTextBox->text().isEmpty()) {
    simulationFlags.insert("initialStepSize", mpInitialStepSizeTextBox->text());
  }
  if (!mpJacobianComboBox->currentText().isEmpty()) {
    simulationFlags.insert("jacobian", mpJacobianComboBox->currentText());
  }
  if (!mpLinearizationTimeTextBox->text().isEmpty()) {
    simulationFlags.insert("l", mpLinearizationTimeTextBox->text());
  }
  if (!mpLinearSolverComboBox->currentText().isEmpty()) {
    simulationFlags.insert("ls", mpLinearSolverComboBox->currentText());
  }
  if (mpMaxIntegrationOrderSpinBox->value() != 5) {
    simulationFlags.insert("maxIntegrationOrder", QString::number(mpMaxIntegrationOrderSpinBox->value()));
  }
  if (!mpMaxStepSizeTextBox->text().isEmpty()) {
    simulationFlags.insert("maxStepSize", mpMaxStepSizeTextBox->text());
  }
  if (!mpNonLinearSolverComboBox->currentText().isEmpty()) {
    simulationFlags.insert("nls", mpNonLinearSolverComboBox->currentText());
  }
  if (mpEquidistantTimeGridCheckBox->isEnabled() && !mpEquidistantTimeGridCheckBox->isChecked()) {
    simulationFlags.insert("noEquidistantTimeGrid", "()");
  }
  if (!mpStoreVariablesAtEventsCheckBox->isChecked()) {
    simulationFlags.insert("noEventEmit", "()");
  }
  if (!mpOutputVariablesTextBox->text().isEmpty()) {
    simulationFlags.insert("output", mpOutputVariablesTextBox->text());
  }
  if (!mpResultFileNameTextBox->text().isEmpty()) {
    simulationFlags.insert("r", mpResultFileNameTextBox->text());
  }
  simulationFlags.insert("s", mpMethodComboBox->currentText());
  QStringList logStreams;
  int i = 0;
  while (QLayoutItem* pLayoutItem = mpLoggingGroupLayout->itemAt(i)) {
    if (dynamic_cast<QCheckBox*>(pLayoutItem->widget())) {
      QCheckBox *pLogStreamCheckBox = dynamic_cast<QCheckBox*>(pLayoutItem->widget());
      if (pLogStreamCheckBox->isChecked()) {
        logStreams << pLogStreamCheckBox->text();
      }
    }
    i++;
  }
  if (logStreams.size() > 0) {
    simulationFlags.insert("lv", logStreams.join(","));
  }
#if (QT_VERSION >= QT_VERSION_CHECK(5, 14, 0))
  QStringList additionalSimulationFlags = mpAdditionalSimulationFlagsTextBox->text().split(" ", Qt::SkipEmptyParts);
#else // QT_VERSION_CHECK
  QStringList additionalSimulationFlags = mpAdditionalSimulationFlagsTextBox->text().split(" ", QString::SkipEmptyParts);
#endif // QT_VERSION_CHECK
  foreach (QString additionalSimulationFlag, additionalSimulationFlags) {
    additionalSimulationFlag = additionalSimulationFlag.trimmed();
    if (additionalSimulationFlag.startsWith('-')) {
      additionalSimulationFlag.remove(0, 1);
    }
#if (QT_VERSION >= QT_VERSION_CHECK(5, 14, 0))
    QStringList nameValueList = additionalSimulationFlag.split("=", Qt::SkipEmptyParts);
#else // QT_VERSION_CHECK
    QStringList nameValueList = additionalSimulationFlag.split("=", QString::SkipEmptyParts);
#endif // QT_VERSION_CHECK
    if (nameValueList.size() < 2) {
      simulationFlags.insert(nameValueList.at(0), "()");
    } else {
      simulationFlags.insert(nameValueList.at(0), nameValueList.at(1));
    }
  }
  if (mpLibraryTreeItem->mSimulationOptions.getDataReconciliationAlgorithm().compare(QStringLiteral("dataReconciliation")) == 0 ) {
    simulationFlags.insert("reconcile", "()");
  } else if (mpLibraryTreeItem->mSimulationOptions.getDataReconciliationAlgorithm().compare(QStringLiteral("dataReconciliationBoundaryConditions")) == 0 ) {
    simulationFlags.insert("reconcileBoundaryConditions", "()");
  }
  if (!mpLibraryTreeItem->mSimulationOptions.getDataReconciliationMeasurementInputFile().isEmpty()) {
    simulationFlags.insert("sx", mpLibraryTreeItem->mSimulationOptions.getDataReconciliationMeasurementInputFile());
  }
  if (!mpLibraryTreeItem->mSimulationOptions.getDataReconciliationCorrelationMatrixInputFile().isEmpty()) {
    simulationFlags.insert("cx", mpLibraryTreeItem->mSimulationOptions.getDataReconciliationCorrelationMatrixInputFile());
  }
  if (!mpLibraryTreeItem->mSimulationOptions.getDataReconciliationEpsilon().isEmpty()) {
    simulationFlags.insert("eps", mpLibraryTreeItem->mSimulationOptions.getDataReconciliationEpsilon());
  }
  QStringList simulationFlagsList;
  QMapIterator<QString, QString> simulationFlagsIterator(simulationFlags);
  simulationFlagsIterator.toFront();
  while (simulationFlagsIterator.hasNext()) {
    simulationFlagsIterator.next();
    simulationFlagsList.append(QString("%1=\"%2\"").arg(simulationFlagsIterator.key(), simulationFlagsIterator.value()));
  }
  QString newSimulationFlags = QString("__OpenModelica_simulationFlags(%1)").arg(simulationFlagsList.join(","));
  // if we have ModelWidget for class then put the change on undo stack.
  if (mpLibraryTreeItem->getModelWidget()) {
    UpdateClassAnnotationCommand *pUpdateClassAnnotationCommand;
    pUpdateClassAnnotationCommand = new UpdateClassAnnotationCommand(mpLibraryTreeItem, oldSimulationFlags, newSimulationFlags);
    mpLibraryTreeItem->getModelWidget()->getUndoStack()->push(pUpdateClassAnnotationCommand);
    mpLibraryTreeItem->getModelWidget()->updateModelText();
  } else { // send the simulations flags annotation to OMC
    MainWindow::instance()->getOMCProxy()->addClassAnnotation(mpLibraryTreeItem->getNameStructure(), newSimulationFlags);
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    pLibraryTreeModel->updateLibraryTreeItemClassText(mpLibraryTreeItem);
  }
}

/*!
 * \brief SimulationDialog::saveTranslationFlagsAnnotation
 * Saves the __OpenModelica_commandLineOptions annotation in the model.
 */
void SimulationDialog::saveTranslationFlagsAnnotation()
{
  if (mIsReSimulate) {
    return;
  }
  // old translation flags
  QString oldCommandLineOptions = QString("__OpenModelica_commandLineOptions(\"%1\")")
                                  .arg(MainWindow::instance()->getOMCProxy()->getNamedAnnotation(mpLibraryTreeItem->getNameStructure(), "__OpenModelica_commandLineOptions"));
  // new translation flags
  QString newCommandLineOptions = QString("__OpenModelica_commandLineOptions(\"%1\")").arg(mpTranslationFlagsWidget->commandLineOptions());
  // if we have ModelWidget for class then put the change on undo stack.
  if (mpLibraryTreeItem->getModelWidget()) {
    UpdateClassAnnotationCommand *pUpdateClassAnnotationCommand;
    pUpdateClassAnnotationCommand = new UpdateClassAnnotationCommand(mpLibraryTreeItem, oldCommandLineOptions, newCommandLineOptions);
    mpLibraryTreeItem->getModelWidget()->getUndoStack()->push(pUpdateClassAnnotationCommand);
    mpLibraryTreeItem->getModelWidget()->updateModelText();
  } else { // send the translation flags annotation to OMC
    MainWindow::instance()->getOMCProxy()->addClassAnnotation(mpLibraryTreeItem->getNameStructure(), newCommandLineOptions);
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    pLibraryTreeModel->updateLibraryTreeItemClassText(mpLibraryTreeItem);
  }
}

void SimulationDialog::performSimulation()
{
  SimulationOptions simulationOptions;
  QString simulationParameters;
  /* build the simulation parameters */
  simulationParameters.append("startTime=").append(mpStartTimeTextBox->text());
  simulationParameters.append(", stopTime=").append(mpStopTimeTextBox->text());
  QString numberOfIntervals;
  if (mpNumberofIntervalsRadioButton->isChecked()) {
    numberOfIntervals = QString::number(mpNumberofIntervalsSpinBox->value());
  } else {
    qreal startTime = mpStartTimeTextBox->text().toDouble();
    qreal stopTime = mpStopTimeTextBox->text().toDouble();
    qreal interval = mpIntervalTextBox->text().toDouble();
    numberOfIntervals = QString::number((stopTime - startTime) / interval);
  }
  simulationParameters.append(", numberOfIntervals=").append(numberOfIntervals);
  simulationParameters.append(", method=").append("\"").append(mpMethodComboBox->currentText()).append("\"");
  if (!mpToleranceTextBox->text().isEmpty()) {
    simulationParameters.append(", tolerance=").append(mpToleranceTextBox->text());
  }
  simulationParameters.append(", outputFormat=").append("\"").append(mpOutputFormatComboBox->currentText()).append("\"");
  if (!mpFileNameTextBox->text().isEmpty()) {
    if (mpFileNameTextBox->text().contains('\'')) {
      simulationParameters.append(", fileNamePrefix=").append("\"_omcQuot_").append(mpFileNameTextBox->text().toUtf8().toHex()).append("\"");
    } else {
      simulationParameters.append(", fileNamePrefix=").append("\"").append(mpFileNameTextBox->text()).append("\"");
    }
  } else if (mClassName.contains('\'')) {
    simulationParameters.append(", fileNamePrefix=").append("\"_omcQuot_").append(mClassName.toUtf8().toHex()).append("\"");
  }
  if (!mpVariableFilterTextBox->text().isEmpty()) {
    simulationParameters.append(", variableFilter=").append("\"").append(mpVariableFilterTextBox->text()).append("\"");
  }
  if (!mpCflagsTextBox->text().isEmpty()) {
    simulationParameters.append(", cflags=").append("\"").append(mpCflagsTextBox->text()).append("\"");
  }
  simulationOptions = createSimulationOptions();
  // If we are not doing a re-simulation then save the new SimulationOptions in the class.
  if (!mIsReSimulate) {
    mpLibraryTreeItem->mSimulationOptions = simulationOptions;
  }
  // change the cursor to Qt::WaitCursor
  QApplication::setOverrideCursor(Qt::WaitCursor);
  // show the progress bar
  MainWindow::instance()->getStatusBar()->showMessage(tr("Translating %1.").arg(mClassName));
  MainWindow::instance()->getProgressBar()->setRange(0, 0);
  MainWindow::instance()->showProgressBar();
  bool isTranslationSuccessful = mIsReSimulate ? true : translateModel(simulationParameters);
  MainWindow::instance()->getOMCProxy()->changeDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
  // hide the progress bar
  MainWindow::instance()->hideProgressBar();
  MainWindow::instance()->getStatusBar()->clearMessage();
  // restore the cursor
  QApplication::restoreOverrideCursor();
  mIsReSimulate = false;
  if (isTranslationSuccessful) {
    // check if we can compile using the target build
    SimulationPage *pSimulationPage = OptionsDialog::instance()->getSimulationPage();
    QString targetBuild = pSimulationPage->getTargetBuildComboBox()->itemData(pSimulationPage->getTargetBuildComboBox()->currentIndex()).toString();
    if ((targetBuild.compare("vxworks69") == 0) || (targetBuild.compare("debugrt") == 0)) {
      QString msg = tr("Generated code for the target build <b>%1</b> at %2.").arg(targetBuild).arg(simulationOptions.getWorkingDirectory());
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg, Helper::scriptingKind, Helper::notificationLevel));
      return;
    }
    QString targetLanguage = pSimulationPage->getTargetLanguageComboBox()->currentText();
    // check if we can compile using the target language
    if ((targetLanguage.compare("C") == 0) || (targetLanguage.compare("Cpp") == 0)) {
      createAndShowSimulationOutputWidget(simulationOptions);
    } else {
      QString msg = tr("Generated code for the target language <b>%1</b> at %2.").arg(targetLanguage).arg(simulationOptions.getWorkingDirectory());
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg, Helper::scriptingKind, Helper::notificationLevel));
      return;
    }
  }
}

/*!
 * \brief SimulationDialog::saveDialogGeometry
 */
void SimulationDialog::saveDialogGeometry()
{
  /* save the window geometry. */
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()) {
    Utilities::getApplicationSettings()->setValue("SimulationDialog/geometry", saveGeometry());
  }
}

void SimulationDialog::reSimulate(SimulationOptions simulationOptions)
{
  createAndShowSimulationOutputWidget(simulationOptions);
}

void SimulationDialog::showAlgorithmicDebugger(SimulationOptions simulationOptions)
{
  // if not build only and launch the algorithmic debugger is true
  if (!simulationOptions.getBuildOnly() && simulationOptions.getLaunchAlgorithmicDebugger()) {
    QString fileName = simulationOptions.getOutputFileName();
    // start the executable
    fileName = QString(simulationOptions.getWorkingDirectory()).append("/").append(fileName);
    fileName = fileName.replace("//", "/");
    // run the simulation executable to create the result file
#ifdef WIN32
    fileName = fileName.append(".exe");
#endif
    // start the debugger
    if (GDBAdapter::instance()->isGDBRunning()) {
      QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                               GUIMessages::getMessage(GUIMessages::DEBUGGER_ALREADY_RUNNING), Helper::ok);
    } else {
      QString GDBPath = OptionsDialog::instance()->getDebuggerPage()->getGDBPath();
      GDBAdapter::instance()->launch(fileName, simulationOptions.getWorkingDirectory(), simulationOptions.getSimulationFlags(),
                                     GDBPath, simulationOptions);
      MainWindow::instance()->switchToAlgorithmicDebuggingPerspectiveSlot();
    }
  }
}

/*!
 * \brief SimulationDialog::simulationStarted
 * This slot makes a call for diabling parameter changes during a simulation \n
 * and update the control buttons. \n
 */
void SimulationDialog::simulationStarted()
{
  setInteractiveControls(false);
}

/*!
 * \brief SimulationDialog::simulationStarted
 * This slot makes a call for diabling parameter changes during a simulation \n
 * and update the control buttons. \n
 */
void SimulationDialog::simulationPaused()
{
  setInteractiveControls(true);
}

void SimulationDialog::updateInteractiveSimulationCurves()
{
  OMPlot::PlotWindow* window = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
  if (window) {
    window->updateCurves();
  }
}

void SimulationDialog::updateYAxis(double min, double max)
{
  OMPlot::PlotWindow* window = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
  if (window) {
    window->updateYAxis(qMakePair(min, max));
  }
}

void SimulationDialog::removeVariablesFromTree(QString className)
{
  MainWindow::instance()->getVariablesWidget()->getVariablesTreeModel()->removeVariableTreeItem(className);
}

/*!
 * \brief SimulationDialog::setInteractiveControls
 * \param enabled
 * Sets the graphical response depending on the parameter enabled. \n
 * true = started, false = paused \n
 */
void SimulationDialog::setInteractiveControls(bool enabled)
{
  int port = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow()->getInteractivePort();
  OpcUaClient *pOpcUaClient = getOpcUaClient(port);
  if (pOpcUaClient) {
    // control buttons
    pOpcUaClient->getTargetPlotWindow()->getStartSimulationButton()->setEnabled(enabled);
    pOpcUaClient->getTargetPlotWindow()->getPauseSimulationButton()->setEnabled(!enabled);
    //plotpicker
    pOpcUaClient->getTargetPlotWindow()->getPlot()->getPlotPicker()->setEnabled(enabled);
  }
}

/*!
 * \brief SimulationDialog::killSimulationProcess
 * \param port
 * If another executable is running over the port, kill it. \n
 */
void SimulationDialog::killSimulationProcess(int port)
{
  std::string endPoint = "opc.tcp://localhost:" + std::to_string(port);
  UA_Client *pClient = UA_Client_new(UA_ClientConfig_standard);
  UA_StatusCode returnValue = UA_Client_connect(pClient, endPoint.c_str());

  if (returnValue == UA_STATUSCODE_GOOD) {
    removeVariablesFromTree(mOpcUaClientsMap.value(port)->getSimulationOptions().getClassName());

    foreach (SimulationOutputWidget *pSimulationOutputWidget, mSimulationOutputWidgetsList) {
      if (pSimulationOutputWidget->getSimulationOptions().getInteractiveSimulationPortNumber() == port) {
        removeSimulationOutputWidget(pSimulationOutputWidget);
        break;
      }
    }
  }
  UA_Client_disconnect(pClient);
  UA_Client_delete(pClient);
}

/*!
 * \brief SimulationDialog::createOpcUaClient
 * \param simulationOptions
 * Creates a OpcUaClient object when embedded server is up and running. \n
 */
void SimulationDialog::createOpcUaClient(SimulationOptions simulationOptions)
{
  OpcUaClient *pOpcUaClient = new OpcUaClient(simulationOptions);
  if (pOpcUaClient->connectToServer()) {
    // create the sample thread
    OpcUaWorker *pOpcUaWorker = new OpcUaWorker(pOpcUaClient, simulationOptions.isInteractiveSimulationWithSteps());
    pOpcUaClient->setOpcUaWorker(pOpcUaWorker);
    pOpcUaWorker->moveToThread(pOpcUaClient->getSampleThread());
    pOpcUaClient->getSampleThread()->start();

    connect(pOpcUaWorker, SIGNAL(sendUpdateCurves()), SLOT(updateInteractiveSimulationCurves()));
    connect(pOpcUaWorker, SIGNAL(sendUpdateYAxis(double, double)), SLOT(updateYAxis(double, double)));
    connect(pOpcUaWorker, SIGNAL(sendAddMonitoredItem(int,QString)), pOpcUaWorker, SLOT(addMonitoredItem(int,QString)));
    connect(pOpcUaWorker, SIGNAL(sendRemoveMonitoredItem(QString)), pOpcUaWorker, SLOT(removeMonitoredItem(QString)));

    // insert the newly created OpcUaClient to the data structure
    mOpcUaClientsMap.insert(simulationOptions.getInteractiveSimulationPortNumber(), pOpcUaClient);

    // determine the model owner of the interactive plot window
    QString owner = simulationOptions.getClassName();
    PlotWindowContainer* pPlotWindowContainer = MainWindow::instance()->getPlotWindowContainer();
    OMPlot::PlotWindow* pInteractivePlotWindow = pPlotWindowContainer->addInteractivePlotWindow(true, owner, simulationOptions.getInteractiveSimulationPortNumber());
    connect(pInteractivePlotWindow->getStartSimulationButton(), SIGNAL(clicked()), pOpcUaWorker, SLOT(startInteractiveSimulation()));
    connect(pInteractivePlotWindow->getPauseSimulationButton(), SIGNAL(clicked()), pOpcUaWorker, SLOT(pauseInteractiveSimulation()));
    connect(pInteractivePlotWindow->getSimulationSpeedBox(), SIGNAL(editTextChanged(QString)), pOpcUaWorker, SLOT(setSpeed(QString)));

    // make graphical responses from the main thread
    connect(pInteractivePlotWindow->getStartSimulationButton(), SIGNAL(clicked(bool)), SLOT(simulationStarted()));
    connect(pInteractivePlotWindow->getPauseSimulationButton(), SIGNAL(clicked(bool)), SLOT(simulationPaused()));

    pOpcUaClient->setTargetPlotWindow(pInteractivePlotWindow);

    // fetch variables
    QStringList list = pOpcUaClient->fetchVariableNamesFromServer();
    VariablesWidget *pVariablesWidget = MainWindow::instance()->getVariablesWidget();
    // insert them into the tree structure
    pVariablesWidget->insertVariablesItemsToTree(simulationOptions.getClassName(), simulationOptions.getWorkingDirectory(), list, simulationOptions);
    // remember the variablestreeitem root pointer
    foreach (VariablesTreeItem *pVariablesTreeItem, pVariablesWidget->getVariablesTreeModel()->getRootVariablesTreeItem()->mChildren) {
      if (pVariablesTreeItem->getFileName() == simulationOptions.getClassName()) {
        pOpcUaWorker->setVariablesTreeItemRoot(pVariablesTreeItem);
      }
    }

    MainWindow::instance()->switchToPlottingPerspectiveSlot();
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "Could not connect to the embedded server.",
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
}

OpcUaClient* SimulationDialog::getOpcUaClient(int port)
{
  return mOpcUaClientsMap.value(port);
}

/*!
 * \brief SimulationDialog::simulationProcessFinished
 * \param simulationOptions
 * \param resultFileLastModifiedDateTime
 * Handles what should be done after the simulation process has finished.\n
 * Reads the result variables and inserts them into the variables browser.\n
 */
void SimulationDialog::simulationProcessFinished(SimulationOptions simulationOptions, QDateTime resultFileLastModifiedDateTime)
{
  // Simulation is over, the sampling thread should stop sampling...
  if (simulationOptions.isInteractiveSimulation()) {
    OpcUaClient *pOpcUaClient = getOpcUaClient(simulationOptions.getInteractiveSimulationPortNumber());
    if (pOpcUaClient && pOpcUaClient->getSampleThread()) {
      pOpcUaClient->getSampleThread()->exit();
    }
    if (pOpcUaClient && pOpcUaClient->getOpcUaWorker()) {
      pOpcUaClient->getOpcUaWorker()->pauseInteractiveSimulation();
    }
    return;
  }
  QString workingDirectory = simulationOptions.getWorkingDirectory();
  QRegExp regExp(Helper::omResultFileTypesRegExp);
  bool resultFileKnown = regExp.indexIn(simulationOptions.getFullResultFileName()) != -1;
  // read the result file
  QFileInfo resultFileInfo(QString(workingDirectory).append("/").append(simulationOptions.getFullResultFileName()));
  resultFileInfo.setCaching(false);
  QDateTime resultFileModificationTime = resultFileInfo.lastModified();
  bool resultFileExists = resultFileInfo.exists();
  // use secsTo as lastModified returns to second not to mili/nanoseconds, see #5251
  bool resultFileNewer = resultFileLastModifiedDateTime.secsTo(resultFileModificationTime) >= 0;
  /* ticket:4935 Check the simulation result size via readSimulationResultSize
   * If the result size is zero then don't switch to the plotting view.
   */
  bool resultFileNonZeroSize = MainWindow::instance()->getOMCProxy()->readSimulationResultSize(resultFileInfo.absoluteFilePath()) > 0;

  if (resultFileKnown && resultFileExists && resultFileNewer && resultFileNonZeroSize) {
    VariablesWidget *pVariablesWidget = MainWindow::instance()->getVariablesWidget();
    if (OptionsDialog::instance()->getSimulationPage()->getSwitchToPlottingPerspectiveCheckBox()->isChecked()) {
      MainWindow::instance()->switchToPlottingPerspectiveSlot();
    } else {
      // stay in current perspective and show variables browser
      MainWindow::instance()->getVariablesDockWidget()->show();
    }
    bool showPlotWindow = true;
#if !defined(WITHOUT_OSG)
    // if simulated with animation then open the animation directly.
    if (simulationOptions.getSimulateWithAnimation()) {
      showPlotWindow = false;
      if (simulationOptions.getFullResultFileName().endsWith(".mat")) {
        MainWindow::instance()->getPlotWindowContainer()->addAnimationWindow(MainWindow::instance()->getPlotWindowContainer()->subWindowList().isEmpty());
        AnimationWindow *pAnimationWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentAnimationWindow();
        if (pAnimationWindow) {
          pAnimationWindow->openAnimationFile(resultFileInfo.absoluteFilePath());
        }
      } else {
        QString msg = tr("Animation is only supported with mat result files.");
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg, Helper::scriptingKind, Helper::notificationLevel));
      }
    }
#endif
    if (showPlotWindow) {
      OMPlot::PlotWindow *pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getTopPlotWindow();
      if (pPlotWindow) {
        MainWindow::instance()->getPlotWindowContainer()->setTopPlotWindowActive();
      } else {
        MainWindow::instance()->getPlotWindowContainer()->addPlotWindow(true);
      }
    }
    pVariablesWidget->insertVariablesItemsToTree(simulationOptions.getFullResultFileName(), workingDirectory, QStringList(), simulationOptions);
  }
  if (OptionsDialog::instance()->getDebuggerPage()->getAlwaysShowTransformationsCheckBox()->isChecked() ||
      simulationOptions.getLaunchTransformationalDebugger() || simulationOptions.getProfiling() != "none") {
    MainWindow::instance()->showTransformationsWidget(simulationOptions.getWorkingDirectory() + "/" + simulationOptions.getOutputFileName() + "_info.json");
  }
  // Show the data reconciliation report
  if (simulationOptions.getEnableDataReconciliation()) {
    QString htmlPath;
    // read the data Reconciliation report file
    if (simulationOptions.getDataReconciliationAlgorithm().compare(QStringLiteral("dataReconciliation")) == 0) {
      htmlPath = QString("%1/%2.html").arg(workingDirectory, simulationOptions.getClassName());
    } else { // read the data Reconciliation Boundary Conditions report file
      htmlPath = QString("%1/%2_BoundaryConditions.html").arg(workingDirectory, simulationOptions.getClassName());
    }
    QFileInfo reportFileInfo(htmlPath);
    QUrl url = QString("file:///%1").arg(htmlPath);
    reportFileInfo.setCaching(false);
    QDateTime reportFileModificationTime = reportFileInfo.lastModified();
    bool reportFileExists = reportFileInfo.exists();
    // use secsTo as lastModified returns to second not to mili/nanoseconds, see #5251
    bool reportFileNewer = resultFileLastModifiedDateTime.secsTo(reportFileModificationTime) >= 0;
    if (reportFileExists && reportFileNewer) {
      QDesktopServices::openUrl(url);
    }
  }
}

/*!
 * \brief SimulationDialog::numberOfIntervalsRadioToggled
 * \param toggle
 */
void SimulationDialog::numberOfIntervalsRadioToggled(bool toggle)
{
  if (toggle) {
    mpNumberofIntervalsSpinBox->setEnabled(true);
    mpIntervalTextBox->setEnabled(false);
    if (validate()) {
      qreal startTime = mpStartTimeTextBox->text().toDouble();
      qreal stopTime = mpStopTimeTextBox->text().toDouble();
      qreal interval = mpIntervalTextBox->text().toDouble();
      qreal numberOfIntervals = (stopTime - startTime) / interval;
      mpNumberofIntervalsSpinBox->setValue(numberOfIntervals);
    }
  }
}

/*!
 * \brief SimulationDialog::intervalRadioToggled
 * \param toggle
 */
void SimulationDialog::intervalRadioToggled(bool toggle)
{
  if (toggle) {
    mpNumberofIntervalsSpinBox->setEnabled(false);
    mpIntervalTextBox->setEnabled(true);
    if (validate()) {
      qreal startTime = mpStartTimeTextBox->text().toDouble();
      qreal stopTime = mpStopTimeTextBox->text().toDouble();
      mpIntervalTextBox->setText(QString::number((stopTime - startTime) / mpNumberofIntervalsSpinBox->value()));
    }
  }
}

/*!
 * \brief SimulationDialog::enableDasslOptions
 * Slot activated when mpMethodComboBox currentIndexChanged signal is raised.\n
 * Enables/disables the Dassl options group box
 * \param method
 */
void SimulationDialog::enableDasslIdaOptions(QString method)
{
  if (method.compare("dassl") == 0 || method.compare("ida") == 0) {
    mpDasslIdaOptionsGroupBox->setEnabled(true);
    mpEquidistantTimeGridCheckBox->setEnabled(true);
  } else {
    mpDasslIdaOptionsGroupBox->setEnabled(false);
    mpEquidistantTimeGridCheckBox->setEnabled(false);
  }
}

/*!
 * \brief SimulationDialog::showIntegrationHelp
 * Slot activated when mpMehtodHelpButton clicked signal is raised.\n
 * Opens the simulationflags.html page of OpenModelica users guide.
 */
void SimulationDialog::showIntegrationHelp()
{
  QUrl integrationAlgorithmsPath (QString("file:///%1/share/doc/omc/OpenModelicaUsersGuide/simulationflags.html#integration-methods").arg(Helper::OpenModelicaHome));
  if (!QDesktopServices::openUrl(integrationAlgorithmsPath)) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(integrationAlgorithmsPath.toString()), Helper::ok);
  }
}

/*!
 * \brief SimulationDialog::buildOnly
 * Slot activated when mpBuildOnlyCheckBox checkbox is checked.\n
 * Makes sure that we only build the modelica model and don't run the simulation.
 * \param checked
 */
void SimulationDialog::buildOnly(bool checked)
{
  if (!mpInteractiveSimulationGroupBox->isChecked()) {
    mpLaunchAlgorithmicDebuggerCheckBox->setEnabled(!checked);
  }
#if !defined(WITHOUT_OSG)
  mpLaunchAnimationCheckBox->setEnabled(!checked);
#endif
  mpSimulationFlagsTab->setEnabled(!checked);
}

/*!
 * \brief SimulationDialog::interactiveSimulation
 * Slot activated when mpInteractiveSimulationGroupBox is checked.\n
 * Makes sure that interactive simulation cannot be started with bad options. \n
 * \param checked
 */
void SimulationDialog::interactiveSimulation(bool checked)
{
  mpLaunchAlgorithmicDebuggerCheckBox->setEnabled(!checked);
  mpLaunchTransformationalDebuggerCheckBox->setEnabled(!checked);
#if !defined(WITHOUT_OSG)
  mpLaunchAnimationCheckBox->setEnabled(!checked);
#endif
}

/*!
 * \brief SimulationDialog::browseModelSetupFile
 * Slot activated when mpModelSetupFileBrowseButton clicked signal is raised.\n
 * Allows user to select Model Setup File.
 */
void SimulationDialog::browseModelSetupFile()
{
  mpModelSetupFileTextBox->setText(StringHandler::getOpenFileName(this,QString(Helper::applicationName).append(" - ").append(Helper::chooseFile), NULL, Helper::xmlFileTypes, NULL));
}

/*!
 * \brief SimulationDialog::browseEquationSystemInitializationFile
 * Slot activated when mpEquationSystemInitializationFileBrowseButton clicked signal is raised.\n
 * Allows user to select Equation System Initialization File.
 */
void SimulationDialog::browseEquationSystemInitializationFile()
{
  mpEquationSystemInitializationFileTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, Helper::matFileTypes, NULL));
}

/*!
 * \brief SimulationDialog::showSimulationFlagsHelp
 * Slot activated when mpSimulationFlagsHelpButton clicked signal is raised.\n
 * Opens the simulationflags.html page of OpenModelica users guide.
 */
void SimulationDialog::showSimulationFlagsHelp()
{
  QUrl simulationflagsPath (QString("file:///%1/share/doc/omc/OpenModelicaUsersGuide/simulationflags.html").arg(Helper::OpenModelicaHome));
  if (!QDesktopServices::openUrl(simulationflagsPath)) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(simulationflagsPath.toString()), Helper::ok);
  }
}

/*!
 * \brief SimulationDialog::simulate
 * Slot activated when mpSimulateButton clicked signal is raised.\n
 * Reads the simulation options set by the user and sends them to OMC by calling buildModel.
 */
void SimulationDialog::simulate()
{
  if (validate()) {
    // interactive simulation
    if (mpInteractiveSimulationGroupBox->isChecked() || mIsReSimulate) {
      performSimulation();
    } else {
      // if no option is selected then show error message to user
      if (!(mpSaveExperimentAnnotationCheckBox->isChecked() ||
            mpSaveTranslationFlagsAnnotationCheckBox->isChecked() ||
            mpSaveSimulationFlagsAnnotationCheckBox->isChecked() ||
            mpSimulateCheckBox->isChecked())) {
        QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::information),
                                 GUIMessages::getMessage(GUIMessages::SELECT_SIMULATION_OPTION), Helper::ok);
        return;
      }
      if ((mpLibraryTreeItem->getModelWidget() && mpSaveExperimentAnnotationCheckBox->isChecked()) ||
          mpSaveTranslationFlagsAnnotationCheckBox->isChecked() || mpSaveSimulationFlagsAnnotationCheckBox->isChecked()) {
        mpLibraryTreeItem->getModelWidget()->beginMacro("Simulation settings");
      }
      if (mpSaveExperimentAnnotationCheckBox->isChecked()) {
        saveExperimentAnnotation();
      }
      if (mpSaveTranslationFlagsAnnotationCheckBox->isChecked()) {
        saveTranslationFlagsAnnotation();
      }
      if (mpSaveSimulationFlagsAnnotationCheckBox->isChecked()) {
        saveSimulationFlagsAnnotation();
      }
      if ((mpLibraryTreeItem->getModelWidget() && mpSaveExperimentAnnotationCheckBox->isChecked()) ||
          mpSaveTranslationFlagsAnnotationCheckBox->isChecked() || mpSaveSimulationFlagsAnnotationCheckBox->isChecked()) {
        mpLibraryTreeItem->getModelWidget()->endMacro();
      }
      if (mpSimulateCheckBox->isChecked()) {
        performSimulation();
      }
    }
    if (isVisible()) {
      saveDialogGeometry();
    }
    accept();
  }
}

/*!
 * \brief SimulationDialog::reject
 * Reimplementation of QDialog::reject().\n
 * Save the dialog geometry and then calls QDialog::reject().
 */
void SimulationDialog::reject()
{
  if (isVisible()) {
    saveDialogGeometry();
  }
  QDialog::reject();
}

/*!
 * \brief SimulationDialog::resultFileNameChanged
 * Slot activated when mpOutputFormatComboBox currentIndexChanged signal is raised.
 * \param text
 */
void SimulationDialog::resultFileNameChanged(QString text)
{
  Q_UNUSED(text);
  QComboBox *pComboBoxSender = qobject_cast<QComboBox*>(sender());
  if (pComboBoxSender) {
    mpSinglePrecisionCheckBox->setEnabled(mpOutputFormatComboBox->currentText().compare("mat") == 0);
    mpResultFileNameTextBox->setPlaceholderText(QString("%1_res.%2").arg(mClassName).arg(mpOutputFormatComboBox->currentText()));
  }
}

/*!
 * \class DataReconciliationDialog
 * \brief Interface for running data reconciliation.
 */
/*!
 * \brief DataReconciliationDialog::DataReconciliationDialog
 * \param pLibraryTreeItem
 * \param parent
 */
DataReconciliationDialog::DataReconciliationDialog(LibraryTreeItem *pLibraryTreeItem, QDialog *parent)
  : QDialog(parent)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, Helper::dataReconciliation, mpLibraryTreeItem->getNameStructure()));
  setMinimumWidth(400);
  Label *pHeadingLabel = Utilities::getHeadingLabel(QString("%1 - %2").arg(Helper::dataReconciliation, mpLibraryTreeItem->getNameStructure()));
  pHeadingLabel->setElideMode(Qt::ElideMiddle);
  QFrame *pHeadingLineFrame = Utilities::getHeadingLine();
  mpDataReconciliationAlgorithmLabel = new Label(tr("Algorithm:"));
  mpDataReconciliationAlgorithmComboBox = new QComboBox;
  mpDataReconciliationAlgorithmComboBox->addItem(tr("Data Reconciliation"), QString("dataReconciliation"));
  mpDataReconciliationAlgorithmComboBox->addItem(tr("Boundary Conditions"), QString("dataReconciliationBoundaryConditions"));
  mpDataReconciliationMeasurementInputFileLabel = new Label(tr("Measurement Input File:"));
  mpDataReconciliationMeasurementInputFileTextBox = new QLineEdit;
  mpDataReconciliationMeasurementInputFileBrowseButton = new QPushButton(Helper::browse);
  connect(mpDataReconciliationMeasurementInputFileBrowseButton, SIGNAL(clicked()), SLOT(browseDataReconciliationMeasurementInputFile()));
  mpDataReconciliationMeasurementInputFileBrowseButton->setAutoDefault(false);
  mpDataReconciliationCorrelationMatrixInputFileLabel = new Label(tr("Correlation Matrix Input File:"));
  mpDataReconciliationCorrelationMatrixInputFileTextBox = new QLineEdit;
  mpDataReconciliationCorrelationMatrixInputFileBrowseButton = new QPushButton(Helper::browse);
  connect(mpDataReconciliationCorrelationMatrixInputFileBrowseButton, SIGNAL(clicked()), SLOT(browseDataReconciliationCorrelationMatrixInputFile()));
  mpDataReconciliationCorrelationMatrixInputFileBrowseButton->setAutoDefault(false);
  mpDataReconciliationEpsilonLabel = new Label(tr("Epsilon:"));
  mpDataReconciliationEpsilonTextBox = new QLineEdit("1.e-10");
  // save settings
  mpSaveSettingsCheckBox = new QCheckBox(tr("Save Settings"));
  // Create the buttons
  mpCalculateButton = new QPushButton(tr("Calculate"));
  mpCalculateButton->setAutoDefault(true);
  connect(mpCalculateButton, SIGNAL(clicked()), SLOT(calculateDataReconciliation()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpCalculateButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // apply simulationOptions
  int currentIndex = mpDataReconciliationAlgorithmComboBox->findData(mpLibraryTreeItem->mSimulationOptions.getDataReconciliationAlgorithm());
  if (currentIndex > -1) {
    mpDataReconciliationAlgorithmComboBox->setCurrentIndex(currentIndex);
  }
  mpDataReconciliationMeasurementInputFileTextBox->setText(mpLibraryTreeItem->mSimulationOptions.getDataReconciliationMeasurementInputFile());
  mpDataReconciliationCorrelationMatrixInputFileTextBox->setText(mpLibraryTreeItem->mSimulationOptions.getDataReconciliationCorrelationMatrixInputFile());
  mpDataReconciliationEpsilonTextBox->setText(mpLibraryTreeItem->mSimulationOptions.getDataReconciliationEpsilon());
  mpSaveSettingsCheckBox->setChecked(mpLibraryTreeItem->mSimulationOptions.getDataReconciliationSaveSetting());
  if (!mpLibraryTreeItem->mSimulationOptions.isDataReconciliationInitialized()) {
    // if ignoreSimulationFlagsAnnotation flag is not set then read the __OpenModelica_simulationFlags annotation
    if (!OptionsDialog::instance()->getSimulationPage()->getIgnoreSimulationFlagsAnnotationCheckBox()->isChecked()) {
      // if the class has __OpenModelica_simulationFlags annotation then use its values.
      QList<QString> simulationFlags = MainWindow::instance()->getOMCProxy()->getAnnotationNamedModifiers(mpLibraryTreeItem->getNameStructure(), "__OpenModelica_simulationFlags");
      foreach (QString simulationFlag, simulationFlags) {
        QString value = MainWindow::instance()->getOMCProxy()->getAnnotationModifierValue(mpLibraryTreeItem->getNameStructure(), "__OpenModelica_simulationFlags", simulationFlag);
        if (simulationFlag.compare("reconcile") == 0) {
          mpDataReconciliationAlgorithmComboBox->setCurrentIndex(0);
        } else if (simulationFlag.compare("reconcileBoundaryConditions") == 0) {
          mpDataReconciliationAlgorithmComboBox->setCurrentIndex(1);
        } else if (simulationFlag.compare("sx") == 0) {
          mpDataReconciliationMeasurementInputFileTextBox->setText(value);
        } else if (simulationFlag.compare("cx") == 0) {
          mpDataReconciliationCorrelationMatrixInputFileTextBox->setText(value);
        } else if (simulationFlag.compare("eps") == 0) {
          mpDataReconciliationEpsilonTextBox->setText(value);
        }
      }
    }
  }
  // layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  int row = 0;
  pMainGridLayout->addWidget(pHeadingLabel, row++, 0, 1, 3);
  pMainGridLayout->addWidget(pHeadingLineFrame, row++, 0, 1, 3);
  pMainGridLayout->addWidget(mpDataReconciliationAlgorithmLabel, row, 0);
  pMainGridLayout->addWidget(mpDataReconciliationAlgorithmComboBox, row++, 1, 1, 2);
  pMainGridLayout->addWidget(mpDataReconciliationMeasurementInputFileLabel, row, 0);
  pMainGridLayout->addWidget(mpDataReconciliationMeasurementInputFileTextBox, row, 1);
  pMainGridLayout->addWidget(mpDataReconciliationMeasurementInputFileBrowseButton, row++, 2);
  pMainGridLayout->addWidget(mpDataReconciliationCorrelationMatrixInputFileLabel, row, 0);
  pMainGridLayout->addWidget(mpDataReconciliationCorrelationMatrixInputFileTextBox, row, 1);
  pMainGridLayout->addWidget(mpDataReconciliationCorrelationMatrixInputFileBrowseButton, row++, 2);
  pMainGridLayout->addWidget(mpDataReconciliationEpsilonLabel, row, 0);
  pMainGridLayout->addWidget(mpDataReconciliationEpsilonTextBox, row++, 1, 1, 2);
  pMainGridLayout->addWidget(mpSaveSettingsCheckBox, row, 0);
  pMainGridLayout->addWidget(mpButtonBox, row++, 1, 1, 2, Qt::AlignRight);
  setLayout(pMainGridLayout);
}

/*!
 * \brief DataReconciliationDialog::browseDataReconciliationMeasurementInputFile
 * Slot activated when mpDataReconciliationMeasurementInputFileBrowseButton clicked signal is raised.\n
 * Allows user to select data reconciliation measurement input file.
 */
void DataReconciliationDialog::browseDataReconciliationMeasurementInputFile()
{
  mpDataReconciliationMeasurementInputFileTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, Helper::csvFileTypes, NULL));
}

/*!
 * \brief DataReconciliationDialog::browseDataReconciliationCorrelationMatrixInputFile
 * Slot activated when mpDataReconciliationCorrelationMatrixInputFileBrowseButton clicked signal is raised.\n
 * Allows user to select data reconciliation correlation matrix input file.
 */
void DataReconciliationDialog::browseDataReconciliationCorrelationMatrixInputFile()
{
  mpDataReconciliationCorrelationMatrixInputFileTextBox->setText(StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, Helper::csvFileTypes, NULL));
}

/*!
 * \brief DataReconciliationDialog::calculateDataReconciliation
 * Sets the data reconciliation options to be used by simulation.
 */
void DataReconciliationDialog::calculateDataReconciliation()
{
  mpLibraryTreeItem->mSimulationOptions.setDataReconciliationInitialized(true);
  mpLibraryTreeItem->mSimulationOptions.setDataReconciliationAlgorithm(mpDataReconciliationAlgorithmComboBox->itemData(mpDataReconciliationAlgorithmComboBox->currentIndex()).toString());
  mpLibraryTreeItem->mSimulationOptions.setDataReconciliationMeasurementInputFile(mpDataReconciliationMeasurementInputFileTextBox->text());
  int currentIndex = mpDataReconciliationAlgorithmComboBox->findData(mpLibraryTreeItem->mSimulationOptions.getDataReconciliationAlgorithm());

  // Validate dataReconciliation Algorithm
  if (currentIndex == 0){
    if (mpLibraryTreeItem->mSimulationOptions.getDataReconciliationMeasurementInputFile().isEmpty()){
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                               "Measurement Input File not provided, Data Reconciliation cannot be computed!", Helper::ok);
      mpDataReconciliationMeasurementInputFileTextBox->setFocus(Qt::ActiveWindowFocusReason);
      return;
    }
  }
  mpLibraryTreeItem->mSimulationOptions.setDataReconciliationCorrelationMatrixInputFile(mpDataReconciliationCorrelationMatrixInputFileTextBox->text());

  // Validate Boundary Condition Algorithm
  if (currentIndex == 1){
    if (mpLibraryTreeItem->mSimulationOptions.getDataReconciliationMeasurementInputFile().isEmpty()){
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             "Measurement Input File not provided, Boundary Conditions cannot be computed!", Helper::ok);
      mpDataReconciliationMeasurementInputFileTextBox->setFocus(Qt::ActiveWindowFocusReason);
      return;
    }
    else if (mpLibraryTreeItem->mSimulationOptions.getDataReconciliationCorrelationMatrixInputFile().isEmpty()){
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             "Correlation Matrix Input File not provided, Boundary Conditions cannot be computed!", Helper::ok);
      mpDataReconciliationCorrelationMatrixInputFileTextBox->setFocus(Qt::ActiveWindowFocusReason);
      return;
    }
  }
  mpLibraryTreeItem->mSimulationOptions.setDataReconciliationEpsilon(mpDataReconciliationEpsilonTextBox->text());
  mpLibraryTreeItem->mSimulationOptions.setDataReconciliationSaveSetting(mpSaveSettingsCheckBox->isChecked());
  accept();
}
