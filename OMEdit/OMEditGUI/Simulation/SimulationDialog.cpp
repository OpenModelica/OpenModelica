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

#include "SimulationDialog.h"
#include "MainWindow.h"
#include "Options/OptionsDialog.h"
#include "Modeling/MessagesWidget.h"
#include "Debugger/GDB/GDBAdapter.h"
#include "Simulation/SimulationOutputWidget.h"
#include "Plotting/VariablesWidget.h"
#include "Plotting/PlotWindowContainer.h"
#include "Modeling/Commands.h"
#include "SimulationProcessThread.h"
#if !defined(WITHOUT_OSG)
#include "Animation/AnimationWindow.h"
#endif

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
  foreach (SimulationOutputWidget *pSimulationOutputWidget, mSimulationOutputWidgetsList) {
    SimulationProcessThread *pSimulationProcessThread = pSimulationOutputWidget->getSimulationProcessThread();
    /* If the SimulationProcessThread is running then we need to stop it i.e exit its event loop.
       Kill the compilation and simulation processes if they are running before exiting the SimulationProcessThread.
      */
    if (pSimulationProcessThread->isRunning()) {
      if (pSimulationProcessThread->isCompilationProcessRunning() && pSimulationProcessThread->getCompilationProcess()) {
        pSimulationProcessThread->getCompilationProcess()->kill();
      }
      if (pSimulationProcessThread->isSimulationProcessRunning() && pSimulationProcessThread->getSimulationProcess()) {
        pSimulationProcessThread->getSimulationProcess()->kill();
      }
      pSimulationProcessThread->exit();
      pSimulationProcessThread->wait();
      delete pSimulationOutputWidget;
    }
  }
  mSimulationOutputWidgetsList.clear();
}

/*!
 * \brief SimulationDialog::show
 * Reimplementation of QDialog::show method.
 * \param pLibraryTreeItem - pointer to LibraryTreeItem
 * \param isReSimulate
 * \param simulationOptions
 */
void SimulationDialog::show(LibraryTreeItem *pLibraryTreeItem, bool isReSimulate, SimulationOptions simulationOptions)
{
  /* restore the window geometry. */
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations() &&
      Utilities::getApplicationSettings()->contains("SimulationDialog/geometry")) {
    restoreGeometry(Utilities::getApplicationSettings()->value("SimulationDialog/geometry").toByteArray());
  }
  mpLibraryTreeItem = pLibraryTreeItem;
  initializeFields(isReSimulate, simulationOptions);
  setVisible(true);
}

/*!
 * \brief SimulationDialog::directSimulate
 * Directly simulates the model without showing the simulation dialog.
 * \param pLibraryTreeItem
 * \param launchTransformationalDebugger
 * \param launchAlgorithmicDebugger
 */
void SimulationDialog::directSimulate(LibraryTreeItem *pLibraryTreeItem, bool launchTransformationalDebugger,
                                      bool launchAlgorithmicDebugger, bool launchAnimation)
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
  simulate();
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
  mpStartTimeLabel = new Label(tr("Start Time:"));
  mpStartTimeTextBox = new QLineEdit("0");
  mpStopTimeLabel = new Label(tr("Stop Time:"));
  mpStopTimeTextBox = new QLineEdit("1");
  // Output Interval
  mpNumberofIntervalsRadioButton = new QRadioButton(tr("Number of Intervals:"));
  mpNumberofIntervalsRadioButton->setChecked(true);
  connect(mpNumberofIntervalsRadioButton, SIGNAL(toggled(bool)), SLOT(numberOfIntervalsRadioToggled(bool)));
  mpNumberofIntervalsSpinBox = new QSpinBox;
  mpNumberofIntervalsSpinBox->setRange(0, std::numeric_limits<int>::max());
  mpNumberofIntervalsSpinBox->setSingleStep(100);
  mpNumberofIntervalsSpinBox->setValue(500);
  // Interval
  mpIntervalRadioButton = new QRadioButton(tr("Interval:"));
  connect(mpIntervalRadioButton, SIGNAL(toggled(bool)), SLOT(intervalRadioToggled(bool)));
  mpIntervalTextBox = new QLineEdit("0.002");
  mpIntervalTextBox->setEnabled(false);
  // set the layout for simulation interval groupbox
  QGridLayout *pSimulationIntervalGridLayout = new QGridLayout;
  pSimulationIntervalGridLayout->setColumnStretch(1, 1);
  pSimulationIntervalGridLayout->addWidget(mpStartTimeLabel, 0, 0);
  pSimulationIntervalGridLayout->addWidget(mpStartTimeTextBox, 0, 1);
  pSimulationIntervalGridLayout->addWidget(mpStopTimeLabel, 1, 0);
  pSimulationIntervalGridLayout->addWidget(mpStopTimeTextBox, 1, 1);
  pSimulationIntervalGridLayout->addWidget(mpNumberofIntervalsRadioButton, 2, 0);
  pSimulationIntervalGridLayout->addWidget(mpNumberofIntervalsSpinBox, 2, 1);
  pSimulationIntervalGridLayout->addWidget(mpIntervalRadioButton, 3, 0);
  pSimulationIntervalGridLayout->addWidget(mpIntervalTextBox, 3, 1);
  mpSimulationIntervalGroupBox->setLayout(pSimulationIntervalGridLayout);
  // Integration
  mpIntegrationGroupBox = new QGroupBox(tr("Integration"));
  mpMethodLabel = new Label(tr("Method:"));
  // get the solver methods
  QStringList solverMethods, solverMethodsDesc;
  MainWindow::instance()->getOMCProxy()->getSolverMethods(&solverMethods, &solverMethodsDesc);
  mpMethodComboBox = new QComboBox;
  mpMethodComboBox->addItems(solverMethods);
  for (int i = 0 ; i < solverMethodsDesc.size() ; i++) {
    mpMethodComboBox->setItemData(i, solverMethodsDesc.at(i), Qt::ToolTipRole);
  }
  connect(mpMethodComboBox, SIGNAL(currentIndexChanged(int)), SLOT(updateMethodToolTip(int)));
  // make dassl default solver method.
  int currentIndex = mpMethodComboBox->findText("dassl", Qt::MatchExactly);
  if (currentIndex > -1) {
    mpMethodComboBox->setCurrentIndex(currentIndex);
  }
  connect(mpMethodComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(enableDasslOptions(QString)));
  mpMehtodHelpButton = new QToolButton;
  mpMehtodHelpButton->setIcon(QIcon(":/Resources/icons/link-external.svg"));
  mpMehtodHelpButton->setToolTip(tr("Integration help"));
  connect(mpMehtodHelpButton, SIGNAL(clicked()), SLOT(showIntegrationHelp()));
  // Tolerance
  mpToleranceLabel = new Label(tr("Tolerance:"));
  mpToleranceTextBox = new QLineEdit("1e-6");
  // jacobian
  mpJacobianLabel = new Label(tr("Jacobian:"));
  mpJacobianLabel->setToolTip(MainWindow::instance()->getOMCProxy()->getJacobianFlagDetailedDescription());
  QStringList jacobianMethods, jacobianMethodsDesc;
  MainWindow::instance()->getOMCProxy()->getJacobianMethods(&jacobianMethods, &jacobianMethodsDesc);
  mpJacobianComboBox = new QComboBox;
  mpJacobianComboBox->addItems(jacobianMethods);
  for (int i = 0 ; i < jacobianMethodsDesc.size() ; i++) {
    mpJacobianComboBox->setItemData(i, jacobianMethodsDesc.at(i), Qt::ToolTipRole);
  }
  connect(mpJacobianComboBox, SIGNAL(currentIndexChanged(int)), SLOT(updateJacobianToolTip(int)));
  updateJacobianToolTip(0);
  // dassl options
  mpDasslOptionsGroupBox = new QGroupBox(tr("DASSL Options"));
  // no root finding
  mpDasslRootFindingCheckBox = new QCheckBox(tr("Root Finding"));
  mpDasslRootFindingCheckBox->setToolTip(tr("Activates the internal root finding procedure of dassl"));
  mpDasslRootFindingCheckBox->setChecked(true);
  // no restart
  mpDasslRestartCheckBox = new QCheckBox(tr("Restart After Event"));
  mpDasslRestartCheckBox->setToolTip(tr("Activates the restart of dassl after an event is performed"));
  mpDasslRestartCheckBox->setChecked(true);
  // initial step size
  mpDasslInitialStepSizeLabel = new Label(tr("Initial Step Size:"));
  mpDasslInitialStepSizeTextBox = new QLineEdit;
  // max step size
  mpDasslMaxStepSizeLabel = new Label(tr("Maximum Step Size:"));
  mpDasslMaxStepSizeTextBox = new QLineEdit;
  // max integration order
  mpDasslMaxIntegrationOrderLabel = new Label(tr("Maximum Integration Order:"));
  mpDasslMaxIntegrationOrderSpinBox = new QSpinBox;
  mpDasslMaxIntegrationOrderSpinBox->setValue(5);
  // set the layout for DASSL options groupbox
  QGridLayout *pDasslOptionsGridLayout = new QGridLayout;
  pDasslOptionsGridLayout->setColumnStretch(1, 1);
  pDasslOptionsGridLayout->addWidget(mpDasslRootFindingCheckBox, 0, 0, 1, 2);
  pDasslOptionsGridLayout->addWidget(mpDasslRestartCheckBox, 1, 0, 1, 2);
  pDasslOptionsGridLayout->addWidget(mpDasslInitialStepSizeLabel, 2, 0);
  pDasslOptionsGridLayout->addWidget(mpDasslInitialStepSizeTextBox, 2, 1);
  pDasslOptionsGridLayout->addWidget(mpDasslMaxStepSizeLabel, 3, 0);
  pDasslOptionsGridLayout->addWidget(mpDasslMaxStepSizeTextBox, 3, 1);
  pDasslOptionsGridLayout->addWidget(mpDasslMaxIntegrationOrderLabel, 4, 0);
  pDasslOptionsGridLayout->addWidget(mpDasslMaxIntegrationOrderSpinBox, 4, 1);
  mpDasslOptionsGroupBox->setLayout(pDasslOptionsGridLayout);
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
  pIntegrationGridLayout->addWidget(mpDasslOptionsGroupBox, 3, 0, 1, 3);
  mpIntegrationGroupBox->setLayout(pIntegrationGridLayout);
  // Compiler Flags
  mpCflagsLabel = new Label(tr("Compiler Flags (Optional):"));
  mpCflagsTextBox = new QLineEdit;
  // Number of Processors
  mpNumberOfProcessorsLabel = new Label(tr("Number of Processors:"));
  mpNumberOfProcessorsSpinBox = new QSpinBox;
  mpNumberOfProcessorsSpinBox->setMinimum(1);
  mpNumberOfProcessorsSpinBox->setValue(MainWindow::instance()->getOMCProxy()->numProcessors());
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
  pGeneralTabLayout->addWidget(mpBuildOnlyCheckBox, 4, 0, 1, 3);
  pGeneralTabLayout->addWidget(mpLaunchTransformationalDebuggerCheckBox, 5, 0, 1, 3);
  pGeneralTabLayout->addWidget(mpLaunchAlgorithmicDebuggerCheckBox, 6, 0, 1, 3);
#if !defined(WITHOUT_OSG)
  pGeneralTabLayout->addWidget(mpLaunchAnimationCheckBox, 7, 0, 1, 3);
#endif
  mpGeneralTab->setLayout(pGeneralTabLayout);
  // add General Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpGeneralTabScrollArea, Helper::general);
  // Output Tab
  mpOutputTab = new QWidget;
  // Output Format
  mpOutputFormatLabel = new Label(tr("Output Format:"));
  mpOutputFormatComboBox = new QComboBox;
  mpOutputFormatComboBox->addItems(Helper::ModelicaSimulationOutputFormats.toLower().split(","));
  // Output filename
  mpFileNameLabel = new Label(tr("File Name Prefix (Optional):"));
  mpFileNameTextBox = new QLineEdit;
  mpFileNameTextBox->setToolTip(tr("The name is used as a prefix for the output files. This is just a name not the path.\n"
                                   "If you want to change the output path then update the working directory in Options/Preferences."));
  mpResultFileNameLabel = new Label(tr("Result File (Optional):"));
  mpResultFileNameTextBox = new QLineEdit;
  mpResultFileName = new Label;
  connect(mpResultFileNameTextBox, SIGNAL(textEdited(QString)), SLOT(resultFileNameChanged(QString)));
  connect(mpOutputFormatComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(resultFileNameChanged(QString)));
  // Variable filter
  mpVariableFilterLabel = new Label(tr("Variable Filter (Optional):"));
  mpVariableFilterTextBox = new QLineEdit(".*");
  // Protected Variabels
  mpProtectedVariablesCheckBox = new QCheckBox(tr("Protected Variables"));
  // Equidistant time grid
  mpEquidistantTimeGridCheckBox = new QCheckBox(tr("Equidistant Time Grid"));
  mpEquidistantTimeGridCheckBox->setChecked(true);
  // store variables at events
  mpStoreVariablesAtEventsCheckBox = new QCheckBox(tr("Store Variables at Events"));
  mpStoreVariablesAtEventsCheckBox->setChecked(true);
  // show generated files checkbox
  mpShowGeneratedFilesCheckBox = new QCheckBox(tr("Show Generated Files"));
  // set Output Tab Layout
  QGridLayout *pOutputTabLayout = new QGridLayout;
  pOutputTabLayout->setAlignment(Qt::AlignTop);
  pOutputTabLayout->addWidget(mpOutputFormatLabel, 0, 0);
  pOutputTabLayout->addWidget(mpOutputFormatComboBox, 0, 1, 1, 2);
  pOutputTabLayout->addWidget(mpFileNameLabel, 1, 0);
  pOutputTabLayout->addWidget(mpFileNameTextBox, 1, 1, 1, 2);
  pOutputTabLayout->addWidget(mpResultFileNameLabel, 2, 0);
  pOutputTabLayout->addWidget(mpResultFileNameTextBox, 2, 1);
  pOutputTabLayout->addWidget(mpResultFileName, 2, 2);
  pOutputTabLayout->addWidget(mpVariableFilterLabel, 3, 0);
  pOutputTabLayout->addWidget(mpVariableFilterTextBox, 3, 1, 1, 2);
  pOutputTabLayout->addWidget(mpProtectedVariablesCheckBox, 4, 0, 1, 3);
  pOutputTabLayout->addWidget(mpEquidistantTimeGridCheckBox, 5, 0, 1, 3);
  pOutputTabLayout->addWidget(mpStoreVariablesAtEventsCheckBox, 6, 0, 1, 3);
  pOutputTabLayout->addWidget(mpShowGeneratedFilesCheckBox, 7, 0, 1, 3);
  mpOutputTab->setLayout(pOutputTabLayout);
  // add Output Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpOutputTab, Helper::output);
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
  for (int i = 0 ; i < initializationMethodsDesc.size() ; i++) {
    mpInitializationMethodComboBox->setItemData(i, initializationMethodsDesc.at(i), Qt::ToolTipRole);
  }
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
  for (int i = 0 ; i < linearSolverMethodsDesc.size() ; i++) {
    mpLinearSolverComboBox->setItemData(i, linearSolverMethodsDesc.at(i), Qt::ToolTipRole);
  }
  // Non Linear Solvers
  mpNonLinearSolverLabel = new Label(tr("Non Linear Solver (Optional):"));
  // get the non-linear solvers
  QStringList nonLinearSolverMethods, nonLinearSolverMethodsDesc;
  MainWindow::instance()->getOMCProxy()->getNonLinearSolvers(&nonLinearSolverMethods, &nonLinearSolverMethodsDesc);
  nonLinearSolverMethods.prepend("");
  nonLinearSolverMethodsDesc.prepend("");
  mpNonLinearSolverComboBox = new QComboBox;
  mpNonLinearSolverComboBox->addItems(nonLinearSolverMethods);
  for (int i = 0 ; i < nonLinearSolverMethodsDesc.size() ; i++) {
    mpNonLinearSolverComboBox->setItemData(i, nonLinearSolverMethodsDesc.at(i), Qt::ToolTipRole);
  }
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
  mpProfilingComboBox->setToolTip(profiling.mainDescription);
  int i = 0;
  foreach (QString description, profiling.descriptions) {
    mpProfilingComboBox->setItemData(i, description, Qt::ToolTipRole);
    i++;
  }
  // cpu-time checkbox
  mpCPUTimeCheckBox = new QCheckBox(tr("CPU Time"));
  // enable all warnings
  mpEnableAllWarningsCheckBox = new QCheckBox(tr("Enable All Warnings"));
  mpEnableAllWarningsCheckBox->setChecked(true);
  // Logging
  mpLoggingGroupBox = new QGroupBox(tr("Logging (Optional)"));
  // fetch the logging flags information
  QStringList logStreamNames, logSteamDescriptions;
  MainWindow::instance()->getOMCProxy()->getLogStreams(&logStreamNames, &logSteamDescriptions);
  // layout for logging group
  mpLoggingGroupLayout = new QGridLayout;
  // create log stream checkboxes
  int row = 0;
  for (int i = 0 ; i < logStreamNames.size() ; i++) {
    QCheckBox *pLogStreamCheckBox = new QCheckBox(logStreamNames[i]);
    pLogStreamCheckBox->setToolTip(logSteamDescriptions[i]);
    // enable the stats logging by default
    if (logStreamNames[i].compare("LOG_STATS") == 0) {
      pLogStreamCheckBox->setChecked(true);
    }
    if (i % 2 == 0) {
      mpLoggingGroupLayout->addWidget(pLogStreamCheckBox, row, 0);
    } else {
      mpLoggingGroupLayout->addWidget(pLogStreamCheckBox, row, 1);
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
  pSimulationFlagsTabLayout->addWidget(mpCPUTimeCheckBox, 10, 0);
  pSimulationFlagsTabLayout->addWidget(mpEnableAllWarningsCheckBox, 11, 0);
  pSimulationFlagsTabLayout->addWidget(mpLoggingGroupBox, 12, 0, 1, 3);
  pSimulationFlagsTabLayout->addWidget(mpAdditionalSimulationFlagsLabel, 13, 0);
  pSimulationFlagsTabLayout->addLayout(pAdditionalSimulationFlagsTabLayout, 13, 1, 1, 2);
  mpSimulationFlagsTab->setLayout(pSimulationFlagsTabLayout);
  // add Output Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpSimulationFlagsTabScrollArea, tr("Simulation Flags"));
  // Archived Simulations tab
  mpArchivedSimulationsTab = new QWidget;
  mpArchivedSimulationsTreeWidget = new QTreeWidget;
  mpArchivedSimulationsTreeWidget->setItemDelegate(new ItemDelegate(mpArchivedSimulationsTreeWidget));
  mpArchivedSimulationsTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpArchivedSimulationsTreeWidget->setColumnCount(4);
  QStringList headers;
  headers << tr("Class") << tr("DateTime") << tr("Start Time") << tr("Stop Time") << tr("Status");
  mpArchivedSimulationsTreeWidget->setHeaderLabels(headers);
  mpArchivedSimulationsTreeWidget->setIndentation(0);
  connect(mpArchivedSimulationsTreeWidget, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(showArchivedSimulation(QTreeWidgetItem*)));
  QGridLayout *pArchivedSimulationsTabLayout = new QGridLayout;
  pArchivedSimulationsTabLayout->setAlignment(Qt::AlignTop);
  pArchivedSimulationsTabLayout->addWidget(mpArchivedSimulationsTreeWidget, 0, 0);
  mpArchivedSimulationsTab->setLayout(pArchivedSimulationsTabLayout);
  // add Archived simulations Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpArchivedSimulationsTab, tr("Archived Simulations"));
  // Add the validators
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  mpStartTimeTextBox->setValidator(pDoubleValidator);
  mpStopTimeTextBox->setValidator(pDoubleValidator);
  mpIntervalTextBox->setValidator(pDoubleValidator);
  mpToleranceTextBox->setValidator(pDoubleValidator);
  // create checkboxes
  mpSaveExperimentAnnotationCheckBox = new QCheckBox(Helper::saveExperimentAnnotation);
  mpSaveSimulationFlagsAnnotationCheckBox = new QCheckBox(Helper::saveOpenModelicaSimulationFlagsAnnotation);
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
  pMainLayout->addWidget(mpSaveSimulationFlagsAnnotationCheckBox, 4, 0);
  pMainLayout->addWidget(mpSimulateCheckBox, 5, 0);
  pMainLayout->addWidget(mpButtonBox, 6, 0);
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
    QMessageBox::critical(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::SIMULATION_STARTTIME_LESSTHAN_STOPTIME), Helper::ok);
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
    // if the class has experiment annotation then read it.
    if (MainWindow::instance()->getOMCProxy()->isExperiment(mClassName)) {
      // get the simulation options....
      OMCInterface::getSimulationOptions_res simulationOptions = MainWindow::instance()->getOMCProxy()->getSimulationOptions(mClassName);
      // since we always get simulationOptions so just get the values from array
      mpStartTimeTextBox->setText(QString::number(simulationOptions.startTime));
      mpStopTimeTextBox->setText(QString::number(simulationOptions.stopTime));
      mpToleranceTextBox->setText(QString::number(simulationOptions.tolerance));
      mpNumberofIntervalsSpinBox->setValue(simulationOptions.numberOfIntervals);
      mpIntervalTextBox->setText(QString::number(simulationOptions.interval));
    }
    // if ignoreSimulationFlagsAnnotation flag is not set then read the __OpenModelica_simulationFlags annotation
    if (!OptionsDialog::instance()->getSimulationPage()->getIgnoreSimulationFlagsAnnotationCheckBox()->isChecked()) {
      // if the class has __OpenModelica_simulationFlags annotation then use its values.
      QList<QString> simulationFlags = MainWindow::instance()->getOMCProxy()->getAnnotationNamedModifiers(mClassName, "__OpenModelica_simulationFlags");
      foreach (QString simulationFlag, simulationFlags) {
        QString value = MainWindow::instance()->getOMCProxy()->getAnnotationModifierValue(mClassName, "__OpenModelica_simulationFlags", simulationFlag);
        if (simulationFlag.compare("clock") == 0) {
          mpClockComboBox->setCurrentIndex(mpClockComboBox->findText(value));
        } else if (simulationFlag.compare("cpu") == 0) {
          mpCPUTimeCheckBox->setChecked(true);
        } else if (simulationFlag.compare("dasslnoRestart") == 0) {
          mpDasslRestartCheckBox->setChecked(false);
        } else if (simulationFlag.compare("dasslnoRootFinding") == 0) {
          mpDasslRootFindingCheckBox->setChecked(false);
        } else if (simulationFlag.compare("emit_protected") == 0) {
          mpProtectedVariablesCheckBox->setChecked(true);
        } else if (simulationFlag.compare("f") == 0) {
          mpModelSetupFileTextBox->setText(value);
        } else if (simulationFlag.compare("iif") == 0) {
          mpEquationSystemInitializationFileTextBox->setText(value);
        } else if (simulationFlag.compare("iim") == 0) {
          mpInitializationMethodComboBox->setCurrentIndex(mpInitializationMethodComboBox->findText(value));
        } else if (simulationFlag.compare("iit") == 0) {
          mpEquationSystemInitializationTimeTextBox->setText(value);
        } else if (simulationFlag.compare("initialStepSize") == 0) {
          mpDasslInitialStepSizeTextBox->setText(value);
        } else if (simulationFlag.compare("jacobian") == 0) {
          mpJacobianComboBox->setCurrentIndex(mpJacobianComboBox->findText(value));
        } else if (simulationFlag.compare("l") == 0) {
          mpLinearizationTimeTextBox->setText(value);
        } else if (simulationFlag.compare("ls") == 0) {
          mpLinearSolverComboBox->setCurrentIndex(mpLinearSolverComboBox->findText(value));
        } else if (simulationFlag.compare("maxIntegrationOrder") == 0) {
          mpDasslMaxIntegrationOrderSpinBox->setValue(value.toInt());
        } else if (simulationFlag.compare("maxStepSize") == 0) {
          mpDasslMaxStepSizeTextBox->setText(value);
        } else if (simulationFlag.compare("nls") == 0) {
          mpNonLinearSolverComboBox->setCurrentIndex(mpNonLinearSolverComboBox->findText(value));
        } else if (simulationFlag.compare("noEquidistantTimeGrid") == 0) {
          mpEquidistantTimeGridCheckBox->setChecked(false);
        } else if (simulationFlag.compare("noEventEmit") == 0) {
          mpStoreVariablesAtEventsCheckBox->setChecked(false);
        } else if (simulationFlag.compare("output") == 0) {
          mpOutputVariablesTextBox->setText(value);
        } else if (simulationFlag.compare("r") == 0) {
          mpResultFileName->setText(value);
        } else if (simulationFlag.compare("s") == 0) {
          mpMethodComboBox->setCurrentIndex(mpMethodComboBox->findText(value));
        } else if (simulationFlag.compare("lv") == 0) {
          QStringList logStreams = value.split(",", QString::SkipEmptyParts);
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
        }
      }
    }
    mpCflagsTextBox->setEnabled(true);
    mpFileNameTextBox->setEnabled(true);
    mpSaveExperimentAnnotationCheckBox->setVisible(true);
    mpSaveSimulationFlagsAnnotationCheckBox->setVisible(true);
    mpSimulateCheckBox->setVisible(true);
  } else {
    mIsReSimulate = true;
    mClassName = simulationOptions.getClassName();
    mFileName = simulationOptions.getFileName();
    setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::reSimulation).append(" - ").append(mClassName));
    mpSimulationHeading->setText(QString(Helper::reSimulation).append(" - ").append(mClassName));
    // Simulation Interval
    mpStartTimeTextBox->setText(simulationOptions.getStartTime());
    mpStopTimeTextBox->setText(simulationOptions.getStopTime());
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
    mpDasslRootFindingCheckBox->setChecked(simulationOptions.getDasslRootFinding());
    // no restart
    mpDasslRestartCheckBox->setChecked(simulationOptions.getDasslRestart());
    // initial step size
    mpDasslInitialStepSizeTextBox->setText(simulationOptions.getDasslInitialStepSize());
    // max step size
    mpDasslMaxStepSizeTextBox->setText(simulationOptions.getDasslMaxStepSize());
    // max integration order
    mpDasslMaxIntegrationOrderSpinBox->setValue(simulationOptions.getDasslMaxIntegration());
    // Compiler Flags
    mpCflagsTextBox->setDisabled(true);
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
    // Number Of Intervals
    mpNumberofIntervalsSpinBox->setValue(simulationOptions.getNumberofIntervals());
    // Interval
    mpIntervalTextBox->setText(QString::number(simulationOptions.getStepSize()));
    // Output filename
    mpFileNameTextBox->setDisabled(true);
    // Variable filter
    mpVariableFilterTextBox->setText(simulationOptions.getVariableFilter());
    // Protected Variabels
    mpProtectedVariablesCheckBox->setChecked(simulationOptions.getProtectedVariables());
    // Equidistant time grid
    mpEquidistantTimeGridCheckBox->setChecked(simulationOptions.getEquidistantTimeGrid());
    // store variables at events
    mpStoreVariablesAtEventsCheckBox->setChecked(simulationOptions.getStoreVariablesAtEvents());
    // show generated files checkbox
    mpShowGeneratedFilesCheckBox->setChecked(simulationOptions.getShowGeneratedFiles());
    // Model Setup File
    mpModelSetupFileTextBox->setText(simulationOptions.getModelSetupFile());
    // Initialization Methods
    mpInitializationMethodLabel = new Label(tr("Initialization Method (Optional):"));
    mpInitializationMethodLabel->setToolTip(tr("Specifies the initialization method."));
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
    // save simulation settings
    mpSaveExperimentAnnotationCheckBox->setVisible(false);
    mpSaveSimulationFlagsAnnotationCheckBox->setVisible(false);
    mpSimulateCheckBox->setVisible(false);
  }
}

/*!
 * \brief SimulationDialog::translateModel
 * Sends the translateModel command to OMC.
 * \param simulationParameters
 * \return
 */
bool SimulationDialog::translateModel(QString simulationParameters)
{
  // check reset messages number before simulation option
  if (OptionsDialog::instance()->getMessagesPage()->getResetMessagesNumberBeforeSimulationCheckBox()->isChecked()) {
    MessagesWidget::instance()->resetMessagesNumber();
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
  bool result = MainWindow::instance()->getOMCProxy()->translateModel(mClassName, simulationParameters);
  // reset simulation setting
  OptionsDialog::instance()->saveSimulationSettings();
  return result;
}

SimulationOptions SimulationDialog::createSimulationOptions()
{
  SimulationOptions simulationOptions;
  simulationOptions.setClassName(mClassName);
  simulationOptions.setStartTime(mpStartTimeTextBox->text());
  simulationOptions.setStopTime(mpStopTimeTextBox->text());
  simulationOptions.setMethod(mpMethodComboBox->currentText());
  simulationOptions.setTolerance(mpToleranceTextBox->text());
  simulationOptions.setJacobian(mpJacobianComboBox->itemData(mpJacobianComboBox->currentIndex()).toString());
  simulationOptions.setDasslRootFinding(mpDasslRootFindingCheckBox->isChecked());
  simulationOptions.setDasslRestart(mpDasslRestartCheckBox->isChecked());
  simulationOptions.setDasslInitialStepSize(mpDasslInitialStepSizeTextBox->text());
  simulationOptions.setDasslMaxStepSize(mpDasslMaxStepSizeTextBox->text());
  simulationOptions.setDasslMaxIntegration(mpDasslMaxIntegrationOrderSpinBox->value());
  simulationOptions.setCflags(mpCflagsTextBox->text());
  simulationOptions.setNumberOfProcessors(mpNumberOfProcessorsSpinBox->value());
  simulationOptions.setBuildOnly(mpBuildOnlyCheckBox->isChecked());
  simulationOptions.setLaunchTransformationalDebugger(mpLaunchTransformationalDebuggerCheckBox->isChecked());
  simulationOptions.setLaunchAlgorithmicDebugger(mpLaunchAlgorithmicDebuggerCheckBox->isChecked());
#if !defined(WITHOUT_OSG)
  simulationOptions.setSimulateWithAnimation(mpLaunchAnimationCheckBox->isChecked());
#endif
  simulationOptions.setNumberofIntervals(mpNumberofIntervalsSpinBox->value());
  qreal startTime = mpStartTimeTextBox->text().toDouble();
  qreal stopTime = mpStopTimeTextBox->text().toDouble();
  if (mpNumberofIntervalsRadioButton->isChecked()) {
    simulationOptions.setStepSize((stopTime - startTime)/mpNumberofIntervalsSpinBox->value());
  } else {
    simulationOptions.setStepSize(mpIntervalTextBox->text().toDouble());
  }
  simulationOptions.setOutputFormat(mpOutputFormatComboBox->currentText());
  if (!mpFileNameTextBox->text().isEmpty()) {
    simulationOptions.setFileNamePrefix(mpFileNameTextBox->text());
  } else if (mClassName.contains('\'')) {
    simulationOptions.setFileNamePrefix("_omcQuot_" + QByteArray(mClassName.toStdString().c_str()).toHex());
  }
  simulationOptions.setResultFileName(mpResultFileName->text());
  simulationOptions.setVariableFilter(mpVariableFilterTextBox->text());
  simulationOptions.setProtectedVariables(mpProtectedVariablesCheckBox->isChecked());
  simulationOptions.setEquidistantTimeGrid(mpEquidistantTimeGridCheckBox->isChecked());
  simulationOptions.setStoreVariablesAtEvents(mpStoreVariablesAtEventsCheckBox->isChecked());
  simulationOptions.setShowGeneratedFiles(mpShowGeneratedFilesCheckBox->isChecked());
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
  simulationFlags.append(QString("-r=").append(simulationOptions.getResultFileName()));
  // jacobian
  simulationFlags.append(QString("-jacobian=").append(mpJacobianComboBox->currentText()));
  // dassl options
  if (mpDasslOptionsGroupBox->isEnabled()) {
    // dassl root finding
    if (!mpDasslRootFindingCheckBox->isChecked()) {
      simulationFlags.append("-dasslnoRootFinding");
    }
    // dassl restart
    if (!mpDasslRestartCheckBox->isChecked()) {
      simulationFlags.append("-dasslnoRestart");
    }
    // dassl initial step size
    if (!mpDasslInitialStepSizeTextBox->text().isEmpty()) {
      simulationFlags.append(QString("-initialStepSize=").append(mpDasslInitialStepSizeTextBox->text()));
    }
    // dassl max step size
    if (!mpDasslMaxStepSizeTextBox->text().isEmpty()) {
      simulationFlags.append(QString("-maxStepSize=").append(mpDasslMaxStepSizeTextBox->text()));
    }
    // dassl max step size
    if (mpDasslMaxIntegrationOrderSpinBox->value() != 5) {
      simulationFlags.append(QString("-maxIntegrationOrder=").append(QString::number(mpDasslMaxIntegrationOrderSpinBox->value())));
    }
  }
  // emit protected variables
  if (mpProtectedVariablesCheckBox->isChecked()) {
    simulationFlags.append("-emit_protected");
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
  // setup Logging flags
  if (logStreams.size() > 0) {
    simulationFlags.append(QString("-lv=").append(logStreams.join(",")));
  }
  if (!mpAdditionalSimulationFlagsTextBox->text().isEmpty()) {
    simulationFlags.append(StringHandler::splitStringWithSpaces(mpAdditionalSimulationFlagsTextBox->text()));
  }
  simulationOptions.setSimulationFlags(simulationFlags);
  simulationOptions.setIsValid(true);
  simulationOptions.setReSimulate(mIsReSimulate);
  simulationOptions.setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
  simulationOptions.setFileName(mFileName);
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
    SimulationOutputWidget *pSimulationOutputWidget = new SimulationOutputWidget(simulationOptions);
    mSimulationOutputWidgetsList.append(pSimulationOutputWidget);
    int xPos = QApplication::desktop()->availableGeometry().width() - pSimulationOutputWidget->frameSize().width() - 20;
    int yPos = QApplication::desktop()->availableGeometry().height() - pSimulationOutputWidget->frameSize().height() - 20;
    pSimulationOutputWidget->setGeometry(xPos, yPos, pSimulationOutputWidget->width(), pSimulationOutputWidget->height());
    pSimulationOutputWidget->show();
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
  QStringList simulationFlags;
  if (!mpClockComboBox->currentText().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("clock").arg(mpClockComboBox->currentText()));
  }
  if (mpCPUTimeCheckBox->isChecked()) {
    simulationFlags.append(QString("%1=\"()\"").arg("cpu"));
  }
  if (!mpDasslRestartCheckBox->isChecked()) {
    simulationFlags.append(QString("%1=\"()\"").arg("dasslnoRestart"));
  }
  if (!mpDasslRootFindingCheckBox->isChecked()) {
    simulationFlags.append(QString("%1=\"()\"").arg("dasslnoRootFinding"));
  }
  if (mpProtectedVariablesCheckBox->isChecked()) {
    simulationFlags.append(QString("%1=\"()\"").arg("emit_protected"));
  }
  if (!mpModelSetupFileTextBox->text().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("f").arg(mpModelSetupFileTextBox->text()));
  }
  if (!mpEquationSystemInitializationFileTextBox->text().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("iif").arg(mpEquationSystemInitializationFileTextBox->text()));
  }
  if (!mpInitializationMethodComboBox->currentText().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("iim").arg(mpInitializationMethodComboBox->currentText()));
  }
  if (!mpEquationSystemInitializationTimeTextBox->text().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("iit").arg(mpEquationSystemInitializationTimeTextBox->text()));
  }
  if (!mpDasslInitialStepSizeTextBox->text().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("initialStepSize").arg(mpDasslInitialStepSizeTextBox->text()));
  }
  simulationFlags.append(QString("%1=\"%2\"").arg("jacobian").arg(mpJacobianComboBox->currentText()));
  if (!mpLinearizationTimeTextBox->text().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("l").arg(mpLinearizationTimeTextBox->text()));
  }
  if (!mpLinearSolverComboBox->currentText().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("ls").arg(mpLinearSolverComboBox->currentText()));
  }
  if (mpDasslMaxIntegrationOrderSpinBox->value() != 5) {
    simulationFlags.append(QString("%1=\"%2\"").arg("maxIntegrationOrder").arg(mpDasslMaxIntegrationOrderSpinBox->value()));
  }
  if (!mpDasslMaxStepSizeTextBox->text().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("maxStepSize").arg(mpDasslMaxStepSizeTextBox->text()));
  }
  if (!mpNonLinearSolverComboBox->currentText().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("nls").arg(mpNonLinearSolverComboBox->currentText()));
  }
  if (mpEquidistantTimeGridCheckBox->isEnabled() && !mpEquidistantTimeGridCheckBox->isChecked()) {
    simulationFlags.append(QString("%1=\"()\"").arg("noEquidistantTimeGrid"));
  }
  if (!mpStoreVariablesAtEventsCheckBox->isChecked()) {
    simulationFlags.append(QString("%1=\"()\"").arg("noEventEmit"));
  }
  if (!mpOutputVariablesTextBox->text().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("output").arg(mpOutputVariablesTextBox->text()));
  }
  if (!mpResultFileName->text().isEmpty()) {
    simulationFlags.append(QString("%1=\"%2\"").arg("r").arg(mpResultFileName->text()));
  }
  simulationFlags.append(QString("%1=\"%2\"").arg("s").arg(mpMethodComboBox->currentText()));
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
    simulationFlags.append(QString("%1=\"%2\"").arg("lv").arg(logStreams.join(",")));
  }
  QString newSimulationFlags = QString("__OpenModelica_simulationFlags(%1)").arg(simulationFlags.join(","));
  // if we have ModelWidget for class then put the change on undo stack.
  if (mpLibraryTreeItem->getModelWidget()) {
    UpdateClassSimulationFlagsAnnotationCommand *pUpdateClassSimulationFlagsAnnotationCommand;
    pUpdateClassSimulationFlagsAnnotationCommand = new UpdateClassSimulationFlagsAnnotationCommand(mpLibraryTreeItem, oldSimulationFlags,
                                                                                                   newSimulationFlags);
    mpLibraryTreeItem->getModelWidget()->getUndoStack()->push(pUpdateClassSimulationFlagsAnnotationCommand);
    mpLibraryTreeItem->getModelWidget()->updateModelText();
  } else {
    // send the simulations flags annotation to OMC
    MainWindow::instance()->getOMCProxy()->addClassAnnotation(mpLibraryTreeItem->getNameStructure(), newSimulationFlags);
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
    simulationParameters.append(", fileNamePrefix=").append("\"").append(mpFileNameTextBox->text()).append("\"");
  } else if (mClassName.contains('\'')) {
    simulationParameters.append(", fileNamePrefix=").append("\"_omcQuot_").append(QByteArray(mClassName.toStdString().c_str()).toHex()).append("\"");
  }
  if (!mpVariableFilterTextBox->text().isEmpty()) {
    simulationParameters.append(", variableFilter=").append("\"").append(mpVariableFilterTextBox->text()).append("\"");
  }
  if (!mpCflagsTextBox->text().isEmpty()) {
    simulationParameters.append(", cflags=").append("\"").append(mpCflagsTextBox->text()).append("\"");
  }
  MainWindow::instance()->getOMCProxy()->setCommandLineOptions("+profiling=" + mpProfilingComboBox->currentText());
  simulationOptions = createSimulationOptions();
  // show the progress bar
  MainWindow::instance()->getStatusBar()->showMessage(tr("Translating %1.").arg(mClassName));
  MainWindow::instance()->getProgressBar()->setRange(0, 0);
  MainWindow::instance()->showProgressBar();
  bool isTranslationSuccessful = mIsReSimulate ? true : translateModel(simulationParameters);
  // hide the progress bar
  MainWindow::instance()->hideProgressBar();
  MainWindow::instance()->getStatusBar()->clearMessage();
  mIsReSimulate = false;
  if (isTranslationSuccessful) {
    // check if we can compile using the target compiler
    SimulationPage *pSimulationPage = OptionsDialog::instance()->getSimulationPage();
    QString targetCompiler = pSimulationPage->getTargetCompilerComboBox()->currentText();
    if ((targetCompiler.compare("vxworks69") == 0) || (targetCompiler.compare("debugrt") == 0)) {
      QString msg = tr("Generated code for the target compiler <b>%1</b> at %2.").arg(targetCompiler)
          .arg(simulationOptions.getWorkingDirectory());
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                            Helper::notificationLevel));
      return;
    }
    QString targetLanguage = pSimulationPage->getTargetLanguageComboBox()->currentText();
    // check if we can compile using the target language
    if ((targetLanguage.compare("C") == 0) || (targetLanguage.compare("Cpp") == 0)) {
      createAndShowSimulationOutputWidget(simulationOptions);
    } else {
      QString msg = tr("Generated code for the target language <b>%1</b> at %2.").arg(targetLanguage)
          .arg(simulationOptions.getWorkingDirectory());
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                            Helper::notificationLevel));
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
      MainWindow::instance()->getPerspectiveTabBar()->setCurrentIndex(3);
    }
  }
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
  QString workingDirectory = simulationOptions.getWorkingDirectory();
  // read the result file
  QFileInfo resultFileInfo(QString(workingDirectory).append("/").append(simulationOptions.getResultFileName()));
  QRegExp regExp("\\b(mat|plt|csv)\\b");
  if (regExp.indexIn(simulationOptions.getResultFileName()) != -1 &&
      resultFileInfo.exists() && resultFileLastModifiedDateTime <= resultFileInfo.lastModified()) {
    VariablesWidget *pVariablesWidget = MainWindow::instance()->getVariablesWidget();
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    QStringList list = pOMCProxy->readSimulationResultVars(simulationOptions.getResultFileName());
    // close the simulation result file.
    pOMCProxy->closeSimulationResultFile();
    if (list.size() > 0) {
      if (OptionsDialog::instance()->getSimulationPage()->getSwitchToPlottingPerspectiveCheckBox()->isChecked()) {
#if !defined(WITHOUT_OSG)
        // if simulated with animation then open the animation directly.
        if (mpLaunchAnimationCheckBox->isChecked()) {
          if (simulationOptions.getResultFileName().endsWith(".mat")) {
            MainWindow::instance()->getPlotWindowContainer()->addAnimationWindow(MainWindow::instance()->getPlotWindowContainer()->subWindowList().isEmpty());
            AnimationWindow *pAnimationWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentAnimationWindow();
            if (pAnimationWindow) {
              pAnimationWindow->openAnimationFile(simulationOptions.getResultFileName());
            }
          } else {
            QString msg = tr("Animation is only supported with mat result files.");
            MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                                  Helper::notificationLevel));
          }
        }
#endif
        MainWindow::instance()->getPerspectiveTabBar()->setCurrentIndex(2);
      } else {
        // stay in current perspective and show variables browser
        MainWindow::instance()->getVariablesDockWidget()->show();
      }
      pVariablesWidget->insertVariablesItemsToTree(simulationOptions.getResultFileName(), workingDirectory, list, simulationOptions);
    }
  }
  if (OptionsDialog::instance()->getDebuggerPage()->getAlwaysShowTransformationsCheckBox()->isChecked() ||
      simulationOptions.getLaunchTransformationalDebugger() || simulationOptions.getProfiling() != "none") {
    MainWindow::instance()->showTransformationsWidget(simulationOptions.getWorkingDirectory() + "/" + simulationOptions.getOutputFileName() + "_info.json");
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
 * \brief SimulationDialog::updateMethodToolTip
 * Updates the Method combobox tooltip.
 * \param index
 */
void SimulationDialog::updateMethodToolTip(int index)
{
  mpMethodComboBox->setToolTip(mpMethodComboBox->itemData(index, Qt::ToolTipRole).toString());
}

/*!
 * \brief SimulationDialog::enableDasslOptions
 * Slot activated when mpMethodComboBox currentIndexChanged signal is raised.\n
 * Enables/disables the Dassl options group box
 * \param method
 */
void SimulationDialog::enableDasslOptions(QString method)
{
  if (method.compare("dassl") == 0) {
    mpDasslOptionsGroupBox->setEnabled(true);
    mpEquidistantTimeGridCheckBox->setEnabled(true);
  } else {
    mpDasslOptionsGroupBox->setEnabled(false);
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
  QUrl integrationAlgorithmsPath (QString("file:///").append(QString(Helper::OpenModelicaHome).replace("\\", "/"))
                                  .append("/share/doc/omc/OpenModelicaUsersGuide/simulationflags.html#integration-methods"));
  if (!QDesktopServices::openUrl(integrationAlgorithmsPath)) {
    QString errorMessage = GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(integrationAlgorithmsPath.toString());
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, errorMessage,
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief SimulationDialog::updateJacobianToolTip
 * Updates the Jacobian combobox tooltip.
 * \param index
 */
void SimulationDialog::updateJacobianToolTip(int index)
{
  mpJacobianComboBox->setToolTip(mpJacobianComboBox->itemData(index, Qt::ToolTipRole).toString());
}

/*!
 * \brief SimulationDialog::buildOnly
 * Slot activated when mpBuildOnlyCheckBox checkbox is checked.\n
 * Makes sure that we only build the modelica model and don't run the simulation.
 * \param checked
 */
void SimulationDialog::buildOnly(bool checked)
{
  mpLaunchAlgorithmicDebuggerCheckBox->setEnabled(!checked);
#if !defined(WITHOUT_OSG)
  mpLaunchAnimationCheckBox->setEnabled(!checked);
#endif
  mpSimulationFlagsTab->setEnabled(!checked);
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
  mpEquationSystemInitializationFileTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile), NULL, Helper::matFileTypes, NULL));
}

/*!
 * \brief SimulationDialog::showSimulationFlagsHelp
 * Slot activated when mpSimulationFlagsHelpButton clicked signal is raised.\n
 * Opens the simulationflags.html page of OpenModelica users guide.
 */
void SimulationDialog::showSimulationFlagsHelp()
{
  QUrl integrationAlgorithmsPath (QString("file:///").append(QString(Helper::OpenModelicaHome).replace("\\", "/"))
                                  .append("/share/doc/omc/OpenModelicaUsersGuide/simulationflags.html"));
  if (!QDesktopServices::openUrl(integrationAlgorithmsPath)) {
    QString errorMessage = GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(integrationAlgorithmsPath.toString());
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, errorMessage,
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief SimulationDialog::showArchivedSimulation
 * Slot activated when mpArchivedSimulationsListWidget itemDoubleClicked signal is raised.\n
 * Shows the archived SimulationOutputWidget.
 * \param pTreeWidgetItem
 */
void SimulationDialog::showArchivedSimulation(QTreeWidgetItem *pTreeWidgetItem)
{
  ArchivedSimulationItem *pArchivedSimulationItem = dynamic_cast<ArchivedSimulationItem*>(pTreeWidgetItem);
  if (pArchivedSimulationItem) {
    SimulationOutputWidget *pSimulationOutputWidget = pArchivedSimulationItem->getSimulationOutputWidget();
    pSimulationOutputWidget->show();
    pSimulationOutputWidget->raise();
    pSimulationOutputWidget->setWindowState(pSimulationOutputWidget->windowState() & (~Qt::WindowMinimized));
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
    if (mIsReSimulate) {
      performSimulation();
    } else {
      // if no option is selected then show error message to user
      if (!(mpSaveExperimentAnnotationCheckBox->isChecked() ||
            mpSaveSimulationFlagsAnnotationCheckBox->isChecked() ||
            mpSimulateCheckBox->isChecked())) {
        QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::information),
                                 GUIMessages::getMessage(GUIMessages::SELECT_SIMULATION_OPTION), Helper::ok);
        return;
      }
      if ((mpLibraryTreeItem->getModelWidget() && mpSaveExperimentAnnotationCheckBox->isChecked()) ||
          mpSaveSimulationFlagsAnnotationCheckBox->isChecked()) {
        mpLibraryTreeItem->getModelWidget()->getUndoStack()->beginMacro("Simulation settings");
      }
      if (mpSaveExperimentAnnotationCheckBox->isChecked()) {
        saveExperimentAnnotation();
      }
      if (mpSaveSimulationFlagsAnnotationCheckBox->isChecked()) {
        saveSimulationFlagsAnnotation();
      }
      if ((mpLibraryTreeItem->getModelWidget() && mpSaveExperimentAnnotationCheckBox->isChecked()) ||
          mpSaveSimulationFlagsAnnotationCheckBox->isChecked()) {
        mpLibraryTreeItem->getModelWidget()->getUndoStack()->endMacro();
      }
      if (mpSimulateCheckBox->isChecked()) {
        performSimulation();
      }
    }
    saveDialogGeometry();
    accept();
  }
}

/*!
 * \brief SimulationDialog::resultFileNameChanged
 * \param text
 * Slot activated when mpResultFileNameTextBox textEdited OR mpOutputFormatComboBox currentIndexChanged signal is raised.\n
 * Sets the result file name label.
 */
void SimulationDialog::resultFileNameChanged(QString text)
{
  QLineEdit *pLineEditSender = qobject_cast<QLineEdit*>(sender());
  QComboBox *pComboBoxSender = qobject_cast<QComboBox*>(sender());

  if (pLineEditSender) {
    if (text.isEmpty()) {
      mpResultFileName->clear();
    } else {
      mpResultFileName->setText(QString("%1_res.%2").arg(text).arg(mpOutputFormatComboBox->currentText()));
    }
  } else if (pComboBoxSender && !mpResultFileNameTextBox->text().isEmpty()) {
    mpResultFileName->setText(QString("%1_res.%2").arg(mpResultFileNameTextBox->text()).arg(mpOutputFormatComboBox->currentText()));
  }
}
