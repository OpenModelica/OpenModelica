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

#include <QTcpSocket>
#include <QTcpServer>

#include "SimulationDialog.h"
#include <limits>

/*!
  \class SimulationDialog
  \brief Displays a dialog with simulation options.
  */

/*!
  \param pParent - pointer to MainWindow.
  */
SimulationDialog::SimulationDialog(MainWindow *pParent)
  : QDialog(pParent, Qt::WindowTitleHint)
{
  setModal(true);
  mpMainWindow = pParent;
  resize(550, 550);
  setUpForm();
  mpProgressDialog = new ProgressDialog(this);
}

SimulationDialog::~SimulationDialog()
{
  qDeleteAll(mSimulationOutputWidgetsList.begin(), mSimulationOutputWidgetsList.end());
  mSimulationOutputWidgetsList.clear();
}

/*!
  Reimplementation of QDialog::show method.
  \param pLibraryTreeNode - pointer to LibraryTreeNode
  \param isInteractive - true indicates that the simulation is interacive.
  */
void SimulationDialog::show(LibraryTreeNode *pLibraryTreeNode, bool isInteractive)
{
  mIsInteractive = isInteractive;
  mpLibraryTreeNode = pLibraryTreeNode;
  initializeFields();
  setVisible(true);
}

/*!
  Creates all the controls and set their layout.
  */
void SimulationDialog::setUpForm()
{
  // simulation widget heading
  mpSimulationHeading = new Label;
  mpSimulationHeading->setFont(QFont(Helper::systemFontInfo.family(), Helper::headingFontSize));
  // Horizontal separator
  mpHorizontalLine = new QFrame();
  mpHorizontalLine->setFrameShape(QFrame::HLine);
  mpHorizontalLine->setFrameShadow(QFrame::Sunken);
  // simulation tab widget
  mpSimulationTabWidget = new QTabWidget;
  // General Tab
  mpGeneralTab = new QWidget;
  // Simulation Interval
  mpSimulationIntervalGroupBox = new QGroupBox(tr("Simulation Interval"));
  mpStartTimeLabel = new Label(tr("Start Time:"));
  mpStartTimeSpinBox = new DoubleSpinBox(mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getGlobalPrecision());
  connect(mpMainWindow->getOptionsDialog()->getGeneralSettingsPage(), SIGNAL(globalPrecisionValueChanged(int)),
          mpStartTimeSpinBox, SLOT(handleGlobalPrecisionValueChange(int)));
  mpStartTimeSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpStartTimeSpinBox->setValue(0);
  mpStartTimeSpinBox->setSingleStep(0.1);
  mpStopTimeLabel = new Label(tr("Stop Time:"));
  mpStopTimeSpinBox = new DoubleSpinBox(mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getGlobalPrecision());
  connect(mpMainWindow->getOptionsDialog()->getGeneralSettingsPage(), SIGNAL(globalPrecisionValueChanged(int)),
          mpStopTimeSpinBox, SLOT(handleGlobalPrecisionValueChange(int)));
  mpStopTimeSpinBox->setValue(1);
  mpStopTimeSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpStopTimeSpinBox->setSingleStep(0.1);
  // set the layout for simulation interval groupbox
  QGridLayout *pSimulationIntervalGridLayout = new QGridLayout;
  pSimulationIntervalGridLayout->setColumnStretch(1, 1);
  pSimulationIntervalGridLayout->addWidget(mpStartTimeLabel, 0, 0);
  pSimulationIntervalGridLayout->addWidget(mpStartTimeSpinBox, 0, 1);
  pSimulationIntervalGridLayout->addWidget(mpStopTimeLabel, 1, 0);
  pSimulationIntervalGridLayout->addWidget(mpStopTimeSpinBox, 1, 1);
  mpSimulationIntervalGroupBox->setLayout(pSimulationIntervalGridLayout);
  // Integration
  mpIntegrationGroupBox = new QGroupBox(tr("Integration"));
  mpMethodLabel = new Label(tr("Method:"));
  mpMethodComboBox = new QComboBox;
  mpMethodComboBox->addItems(Helper::ModelicaSimulationMethods.split(","));
  mpToleranceLabel = new Label(tr("Tolerance:"));
  mpToleranceSpinBox = new DoubleSpinBox(mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getGlobalPrecision());
  connect(mpMainWindow->getOptionsDialog()->getGeneralSettingsPage(), SIGNAL(globalPrecisionValueChanged(int)),
          mpToleranceSpinBox, SLOT(handleGlobalPrecisionValueChange(int)));
  mpToleranceSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpToleranceSpinBox->setValue(0.000001);
  mpToleranceSpinBox->setSingleStep(0.000001);
  // set the layout for integration groupbox
  QGridLayout *pIntegrationGridLayout = new QGridLayout;
  pIntegrationGridLayout->setColumnStretch(1, 1);
  pIntegrationGridLayout->addWidget(mpMethodLabel, 0, 0);
  pIntegrationGridLayout->addWidget(mpMethodComboBox, 0, 1);
  pIntegrationGridLayout->addWidget(mpToleranceLabel, 1, 0);
  pIntegrationGridLayout->addWidget(mpToleranceSpinBox, 1, 1);
  mpIntegrationGroupBox->setLayout(pIntegrationGridLayout);
  // Compiler Flags
  mpCflagsLabel = new Label(tr("Compiler Flags (Optional):"));
  mpCflagsTextBox = new QLineEdit;
  // Number of Processors
  mpNumberOfProcessorsLabel = new Label(tr("Number of Processors:"));
  mpNumberOfProcessorsSpinBox = new QSpinBox;
  mpNumberOfProcessorsSpinBox->setSpecialValueText("<Auto>");
  // set General Tab Layout
  QGridLayout *pGeneralTabLayout = new QGridLayout;
  pGeneralTabLayout->setAlignment(Qt::AlignTop);
  pGeneralTabLayout->addWidget(mpSimulationIntervalGroupBox, 0, 0, 1, 2);
  pGeneralTabLayout->addWidget(mpIntegrationGroupBox, 1, 0, 1, 2);
  pGeneralTabLayout->addWidget(mpCflagsLabel, 2, 0);
  pGeneralTabLayout->addWidget(mpCflagsTextBox, 2, 1);
  pGeneralTabLayout->addWidget(mpNumberOfProcessorsLabel, 3, 0);
  pGeneralTabLayout->addWidget(mpNumberOfProcessorsSpinBox, 3, 1);
  mpGeneralTab->setLayout(pGeneralTabLayout);
  // add General Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpGeneralTab, Helper::general);
  // Output Tab
  mpOutputTab = new QWidget;
  // Output Interval
  mpNumberofIntervalLabel = new Label(tr("Number of Intervals:"));
  mpNumberofIntervalsSpinBox = new DoubleSpinBox(mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getGlobalPrecision());
  connect(mpMainWindow->getOptionsDialog()->getGeneralSettingsPage(), SIGNAL(globalPrecisionValueChanged(int)),
          mpNumberofIntervalsSpinBox, SLOT(handleGlobalPrecisionValueChange(int)));
  mpNumberofIntervalsSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpNumberofIntervalsSpinBox->setValue(500);
  mpNumberofIntervalsSpinBox->setSingleStep(100);
  // Output Format
  mpOutputFormatLabel = new Label(tr("Output Format:"));
  mpOutputFormatComboBox = new QComboBox;
  mpOutputFormatComboBox->addItems(Helper::ModelicaSimulationOutputFormats.toLower().split(","));
  // Output filename
  mpFileNameLabel = new Label(tr("File Name (Optional):"));
  mpFileNameTextBox = new QLineEdit;
  // Variable filter
  mpVariableFilterLabel = new Label(tr("Variable Filter (Optional):"));
  mpVariableFilterTextBox = new QLineEdit;
  // show generated files checkbox
  mpShowGeneratedFilesCheckBox = new QCheckBox(tr("Show Generated Files"));
  // set Output Tab Layout
  QGridLayout *pOutputTabLayout = new QGridLayout;
  pOutputTabLayout->setAlignment(Qt::AlignTop);
  pOutputTabLayout->addWidget(mpNumberofIntervalLabel, 0, 0);
  pOutputTabLayout->addWidget(mpNumberofIntervalsSpinBox, 0, 1);
  pOutputTabLayout->addWidget(mpOutputFormatLabel, 1, 0);
  pOutputTabLayout->addWidget(mpOutputFormatComboBox, 1, 1);
  pOutputTabLayout->addWidget(mpFileNameLabel, 2, 0);
  pOutputTabLayout->addWidget(mpFileNameTextBox, 2, 1);
  pOutputTabLayout->addWidget(mpVariableFilterLabel, 3, 0);
  pOutputTabLayout->addWidget(mpVariableFilterTextBox, 3, 1);
  pOutputTabLayout->addWidget(mpShowGeneratedFilesCheckBox, 4, 0, 1, 2);
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
  mpInitializationMethodComboBox = new QComboBox;
  mpInitializationMethodComboBox->addItems(Helper::ModelicaInitializationMethods.toLower().split(","));
  // Optimization Methods
  mpOptimizationMethodLabel = new Label(tr("Optimization Method (Optional):"));
  mpOptimizationMethodLabel->setToolTip(tr("Specifies the initialization optimization method."));
  mpOptimizationMethodComboBox = new QComboBox;
  mpOptimizationMethodComboBox->addItems(Helper::ModelicaOptimizationMethods.toLower().split(","));
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
  mpLinearSolverComboBox = new QComboBox;
  mpLinearSolverComboBox->addItems(Helper::linearSolvers.split(","));
  // Non Linear Solvers
  mpNonLinearSolverLabel = new Label(tr("Non Linear Solver (Optional):"));
  mpNonLinearSolverComboBox = new QComboBox;
  mpNonLinearSolverComboBox->addItems(Helper::nonLinearSolvers.split(","));
  // time where the linearization of the model should be performed
  mpLinearizationTimeLabel = new Label(tr("Linearization Time (Optional):"));
  mpLinearizationTimeTextBox = new QLineEdit;
  // output variables
  mpOutputVariablesLabel = new Label(tr("Output Variables (Optional):"));
  mpOutputVariablesLabel->setToolTip(tr("Comma separated list of variables. Output the variables at the end of the simulation to the standard output."));
  mpOutputVariablesTextBox = new QLineEdit;
  // measure simulation time checkbox
  mpProfilingCheckBox = new QCheckBox(tr("Profiling (~5-25% overhead)"));
  // cpu-time checkbox
  mpCPUTimeCheckBox = new QCheckBox(tr("CPU Time"));
  // enable all warnings
  mpEnableAllWarningsCheckBox = new QCheckBox(tr("Enable All Warnings"));
  mpEnableAllWarningsCheckBox->setChecked(true);
  // Logging
  mpLogDasslSolverCheckBox = new QCheckBox(tr("DASSL Solver Information"));
  mpLogDasslSolverCheckBox->setToolTip(tr("additional information about dassl solver"));
  mpLogDebugCheckBox = new QCheckBox(tr("Debug"));
  mpLogDebugCheckBox->setToolTip(tr("additional debug information"));
  mpLogDynamicStateSelectionCheckBox = new QCheckBox(tr("Dynamic State Selection Information"));
  mpLogDynamicStateSelectionCheckBox->setToolTip(tr("outputs information about dynamic state selection"));
  mpLogJacobianDynamicStateSelectionCheckBox = new QCheckBox(tr("Jacobians Dynamic State Selection Information"));
  mpLogJacobianDynamicStateSelectionCheckBox->setToolTip(tr("outputs jacobain of the dynamic state selection"));
  mpLogEventsCheckBox = new QCheckBox(tr("Event Iteration"));
  mpLogEventsCheckBox->setToolTip(tr("additional information during event iteration"));
  mpLogVerboseEventsCheckBox = new QCheckBox(tr("Verbose Event System"));
  mpLogVerboseEventsCheckBox->setToolTip(tr("verbose logging of event system"));
  mpLogInitializationCheckBox = new QCheckBox(tr("Initialization"));
  mpLogInitializationCheckBox->setToolTip(tr("additional information during initialization"));
  mpLogJacobianCheckBox = new QCheckBox(tr("Jacobian Matrix"));
  mpLogJacobianCheckBox->setToolTip(tr("outputs the jacobian matrix used by the integrator"));
  mpLogNonLinearSystemsCheckBox = new QCheckBox(tr("Non Linear Systems"));
  mpLogNonLinearSystemsCheckBox->setToolTip(tr("logging for nonlinear systems"));
  mpLogVerboseNonLinearSystemsCheckBox = new QCheckBox(tr("Verbose Non Linear Systems"));
  mpLogVerboseNonLinearSystemsCheckBox->setToolTip(tr("verbose logging of nonlinear systems"));
  mpLogJacobianNonLinearSystemsCheckBox = new QCheckBox(tr("Jacobian Non Linear Systems"));
  mpLogJacobianNonLinearSystemsCheckBox->setToolTip(tr("outputs the jacobian of nonlinear systems"));
  mpLogResidualsInitializationCheckBox = new QCheckBox(tr("Initialization Residuals"));
  mpLogResidualsInitializationCheckBox->setToolTip(tr("outputs residuals of the initialization"));
  mpLogSimulationCheckBox = new QCheckBox(tr("Simulation Process"));
  mpLogSimulationCheckBox->setToolTip(tr("additional information about simulation process"));
  mpLogSolverCheckBox = new QCheckBox(tr("Solver Process"));
  mpLogSolverCheckBox->setToolTip(tr("additional information about solver process"));
  mpLogFinalSolutionOfInitializationCheckBox = new QCheckBox(tr("Final Initialization Solution"));
  mpLogFinalSolutionOfInitializationCheckBox->setToolTip(tr("final solution of the initialization"));
  mpLogStatsCheckBox = new QCheckBox(tr("Timer/Events/Solver Statistics"));
  mpLogStatsCheckBox->setChecked(true);
  mpLogStatsCheckBox->setToolTip(tr("additional statistics about timer/events/solver"));
  mpLogUtilCheckBox = new QCheckBox(tr("Util"));
  mpLogUtilCheckBox->setToolTip(tr("outputs information about util"));
  mpLogZeroCrossingsCheckBox = new QCheckBox(tr("Zero Crossings"));
  mpLogZeroCrossingsCheckBox->setToolTip(tr("additional information about the zerocrossings"));
  // layout for logging group
  QGridLayout *pLoggingGroupLayout = new QGridLayout;
  pLoggingGroupLayout->addWidget(mpLogDasslSolverCheckBox, 0, 0);
  pLoggingGroupLayout->addWidget(mpLogDebugCheckBox, 0, 1);
  pLoggingGroupLayout->addWidget(mpLogDynamicStateSelectionCheckBox, 1, 0);
  pLoggingGroupLayout->addWidget(mpLogJacobianDynamicStateSelectionCheckBox, 1, 1);
  pLoggingGroupLayout->addWidget(mpLogEventsCheckBox, 2, 0);
  pLoggingGroupLayout->addWidget(mpLogVerboseEventsCheckBox, 2, 1);
  pLoggingGroupLayout->addWidget(mpLogInitializationCheckBox, 3, 0);
  pLoggingGroupLayout->addWidget(mpLogJacobianCheckBox, 3, 1);
  pLoggingGroupLayout->addWidget(mpLogNonLinearSystemsCheckBox, 4, 0);
  pLoggingGroupLayout->addWidget(mpLogVerboseNonLinearSystemsCheckBox, 4, 1);
  pLoggingGroupLayout->addWidget(mpLogJacobianNonLinearSystemsCheckBox, 5, 0);
  pLoggingGroupLayout->addWidget(mpLogResidualsInitializationCheckBox, 5, 1);
  pLoggingGroupLayout->addWidget(mpLogSimulationCheckBox, 6, 0);
  pLoggingGroupLayout->addWidget(mpLogSolverCheckBox, 6, 1);
  pLoggingGroupLayout->addWidget(mpLogFinalSolutionOfInitializationCheckBox, 7, 0);
  pLoggingGroupLayout->addWidget(mpLogStatsCheckBox, 7, 1);
  pLoggingGroupLayout->addWidget(mpLogUtilCheckBox, 8, 0);
  pLoggingGroupLayout->addWidget(mpLogZeroCrossingsCheckBox, 8, 1);
  mpLoggingGroupBox = new QGroupBox(tr("Logging (Optional)"));
  mpLoggingGroupBox->setLayout(pLoggingGroupLayout);
  mpAdditionalSimulationFlagsLabel = new Label(tr("Additional Simulation Flags (Optional):"));
  mpAdditionalSimulationFlagsLabel->setToolTip(tr("Space separated list of simulation flags"));
  mpAdditionalSimulationFlagsTextBox = new QLineEdit;
  // set Output Tab Layout
  QGridLayout *pSimulationFlagsTabLayout = new QGridLayout;
  pSimulationFlagsTabLayout->setAlignment(Qt::AlignTop);
  pSimulationFlagsTabLayout->addWidget(mpModelSetupFileLabel, 0, 0);
  pSimulationFlagsTabLayout->addWidget(mpModelSetupFileTextBox, 0, 1);
  pSimulationFlagsTabLayout->addWidget(mpModelSetupFileBrowseButton, 0, 2);
  pSimulationFlagsTabLayout->addWidget(mpInitializationMethodLabel, 1, 0);
  pSimulationFlagsTabLayout->addWidget(mpInitializationMethodComboBox, 1, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpOptimizationMethodLabel, 2, 0);
  pSimulationFlagsTabLayout->addWidget(mpOptimizationMethodComboBox, 2, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpEquationSystemInitializationFileLabel, 3, 0);
  pSimulationFlagsTabLayout->addWidget(mpEquationSystemInitializationFileTextBox, 3, 1);
  pSimulationFlagsTabLayout->addWidget(mpEquationSystemInitializationFileBrowseButton, 3, 2);
  pSimulationFlagsTabLayout->addWidget(mpEquationSystemInitializationTimeLabel, 4, 0);
  pSimulationFlagsTabLayout->addWidget(mpEquationSystemInitializationTimeTextBox, 4, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpClockLabel, 5, 0);
  pSimulationFlagsTabLayout->addWidget(mpClockComboBox, 5, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpLinearSolverLabel, 6, 0);
  pSimulationFlagsTabLayout->addWidget(mpLinearSolverComboBox, 6, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpNonLinearSolverLabel, 7, 0);
  pSimulationFlagsTabLayout->addWidget(mpNonLinearSolverComboBox, 7, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpLinearizationTimeLabel, 8, 0);
  pSimulationFlagsTabLayout->addWidget(mpLinearizationTimeTextBox, 8, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpOutputVariablesLabel, 9, 0);
  pSimulationFlagsTabLayout->addWidget(mpOutputVariablesTextBox, 9, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpProfilingCheckBox, 10, 0);
  pSimulationFlagsTabLayout->addWidget(mpCPUTimeCheckBox, 11, 0);
  pSimulationFlagsTabLayout->addWidget(mpEnableAllWarningsCheckBox, 12, 0);
  pSimulationFlagsTabLayout->addWidget(mpLoggingGroupBox, 13, 0, 1, 3);
  pSimulationFlagsTabLayout->addWidget(mpAdditionalSimulationFlagsLabel, 14, 0);
  pSimulationFlagsTabLayout->addWidget(mpAdditionalSimulationFlagsTextBox, 14, 1, 1, 2);
  mpSimulationFlagsTab->setLayout(pSimulationFlagsTabLayout);
  // add Output Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpSimulationFlagsTabScrollArea, tr("Simulation Flags"));
  // Create the buttons
  mpSimulateButton = new QPushButton(Helper::simulate);
  mpSimulateButton->setAutoDefault(true);
  connect(mpSimulateButton, SIGNAL(clicked()), this, SLOT(simulate()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  // save simulations options
  mpSaveSimulationCheckbox = new QCheckBox(tr("Save simulation settings inside model"));
  // adds buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpSimulateButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->addWidget(mpSimulationHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpSimulationTabWidget, 2, 0, 1, 2);
  pMainLayout->addWidget(mpSaveSimulationCheckbox, 3, 0);
  pMainLayout->addWidget(mpButtonBox, 3, 1);
  setLayout(pMainLayout);
}

/*!
  Validates the simulation values entered by the user.
  */
bool SimulationDialog::validate()
{
  if (mpStartTimeSpinBox->value() > mpStopTimeSpinBox->value())
  {
    QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::SIMULATION_STARTTIME_LESSTHAN_STOPTIME), Helper::ok);
    return false;
  }
  return true;
}

/*!
  Initializes the simulation dialog with the default values.
  */
void SimulationDialog::initializeFields()
{
  // depending on the mIsInteractive flag change the heading and disable start and stop times
  if (mIsInteractive)
  {
    setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::interactiveSimulation)
                   .append(" - ").append(mpLibraryTreeNode->getNameStructure()));
    QString headingStr = QString(Helper::interactiveSimulation).append(" - ").append(mpLibraryTreeNode->getNameStructure());
    QFont font = mpSimulationHeading->font();
    QFontMetrics fontMetrics = QFontMetrics(font);
    int maxWidth = mpSimulationHeading->width();
    QString elidedHeadingStr = fontMetrics.elidedText(headingStr, Qt::ElideMiddle, maxWidth);
    mpSimulationHeading->setText(elidedHeadingStr);
    mpSimulationIntervalGroupBox->setDisabled(true);
    return;
  }
  else
  {
    setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::simulation)
                   .append(" - ").append(mpLibraryTreeNode->getNameStructure()));
    QString headingStr = QString(Helper::simulation).append(" - ").append(mpLibraryTreeNode->getNameStructure());
    QFont font = mpSimulationHeading->font();
    QFontMetrics fontMetrics = QFontMetrics(font);
    int maxWidth = mpSimulationHeading->width();
    QString elidedHeadingStr = fontMetrics.elidedText(headingStr, Qt::ElideMiddle, maxWidth);
    mpSimulationHeading->setText(elidedHeadingStr);
    mpSimulationIntervalGroupBox->setDisabled(false);
  }
  // if the class has experiment annotation then read it.
  if (mpMainWindow->getOMCProxy()->isExperiment(mpLibraryTreeNode->getNameStructure()))
  {
    // get the simulation options....
    QString result = mpMainWindow->getOMCProxy()->getSimulationOptions(mpLibraryTreeNode->getNameStructure());
    result = StringHandler::removeFirstLastCurlBrackets(StringHandler::removeComment(result));
    QStringList simulationOptionsList = StringHandler::getStrings(result);
    // since we always get simulationOptions so just get the values from array
    mpStartTimeSpinBox->setValue(simulationOptionsList.at(0).toFloat());
    mpStopTimeSpinBox->setValue(simulationOptionsList.at(1).toFloat());
    mpToleranceSpinBox->setValue(simulationOptionsList.at(3).toFloat());
  }
}

/*!
  Used for non-interactive simulation.\n
  Sends the translateModel command to OMC.
  */
void SimulationDialog::translateModel()
{
  if (mpMainWindow->getOMCProxy()->translateModel(mpLibraryTreeNode->getNameStructure(), mSimulationParameters))
  {
    mIsCancelled = false;
    compileModel();
  }
}

void SimulationDialog::compileModel()
{
  mpCompilationProcess = new QProcess;
#ifdef WIN32
  setProcessEnvironment(mpCompilationProcess);
#endif
  mpCompilationProcess->setWorkingDirectory(mpMainWindow->getOMCProxy()->changeDirectory());
  QString outputFile;
  if (mpFileNameTextBox->text().isEmpty())
    outputFile = mpLibraryTreeNode->getNameStructure();
  else
    outputFile = mpFileNameTextBox->text();
  SimulationOutputWidget *pSimulationOutputWidget;
  pSimulationOutputWidget = new SimulationOutputWidget(mpLibraryTreeNode->getNameStructure(), outputFile,
                                                       mpShowGeneratedFilesCheckBox->isChecked(), mpMainWindow);
  mSimulationOutputWidgetsList.append(pSimulationOutputWidget);
  connect(mpCompilationProcess, SIGNAL(readyReadStandardOutput()), SLOT(writeCompilationStandardOutput()));
  connect(mpCompilationProcess, SIGNAL(readyReadStandardError()), SLOT(writeCompilationStandardError()));
  connect(mpCompilationProcess, SIGNAL(readyRead()), SLOT(showSimulationOutputWidget()));
  connect(mpCompilationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(compilationProcessFinished(int,QProcess::ExitStatus)));
  connect(mpCompilationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(compilationProcessError(QProcess::ProcessError)));
  mpProgressDialog->getCancelSimulationButton()->setText(tr("Cancel Compilation"));
  mpProgressDialog->getCancelSimulationButton()->setEnabled(true);
  mpProgressDialog->setText(tr("Compiling <b>%1</b>.<br />Please wait for a while.").arg(mpLibraryTreeNode->getNameStructure()));
  QString numProcs;
  if (mpNumberOfProcessorsSpinBox->value() == 0)
    numProcs = mpMainWindow->getOMCProxy()->numProcessors();
  else
    numProcs = QString::number(mpNumberOfProcessorsSpinBox->value());
  QStringList args;
  QString fileName;
  if (mpFileNameTextBox->text().isEmpty())
    fileName = mpLibraryTreeNode->getNameStructure();
  else
    fileName = mpFileNameTextBox->text();
  args << "-j" + numProcs << "-f" << fileName + ".makefile";
  mIsCompilationProcessRunning = true;
#ifdef WIN32
  mpCompilationProcess->start(mCompilationProcessPath, args);
#else
  mpCompilationProcess->start("make", args);
#endif
  while (mpCompilationProcess->state() == QProcess::Starting || mpCompilationProcess->state() == QProcess::Running)
  {
    if (!mIsCompilationProcessRunning)
      break;
    QEventLoop eventLoop;
    QTimer timer;
    connect(&timer, SIGNAL(timeout()), &eventLoop, SLOT(quit()));
    timer.start(1000);
    eventLoop.exec();
    qApp->processEvents();
  }
}

void SimulationDialog::setProcessEnvironment(QProcess *pProcess)
{
#ifdef WIN32
  QProcessEnvironment environment;
  const char *omdev = getenv("OMDEV");
  if (QString(omdev).isEmpty())
  {
    environment.insert("PATH", QString(Helper::OpenModelicaHome).append("MinGW\\bin") + ";" + QString(Helper::OpenModelicaHome).append("MinGW\\libexec\\gcc\\mingw32\\4.4.0"));
    mCompilationProcessPath = QString(Helper::OpenModelicaHome).append("MinGW\\bin\\mingw32-make.exe");
  }
  else
  {
    environment.insert("PATH", QString(omdev).append(QDir::separator()).append("tools\\mingw\\bin") + ";" + QString(omdev).append(QDir::separator()).append("tools\\mingw\\libexec\\gcc\\mingw32\\4.4.0"));
    mCompilationProcessPath = QString(omdev).append(QDir::separator()).append("tools\\mingw\\bin\\mingw32-make.exe");
  }
  pProcess->setProcessEnvironment(environment);
#endif
}

/*!
  Starts the simulation executable with -port argument.\n
  Creates a TCP server and starts listening for the simulation runtime progress messages.
  */
void SimulationDialog::runSimulationExecutable()
{
  QString workingDirectory = mpMainWindow->getOMCProxy()->changeDirectory();
  mLastModifiedDateTime = QDateTime::currentDateTime();
  QString outputFile;
  QRegExp regExp("\\b(mat|plt|csv)\\b");
  if (regExp.indexIn(mpOutputFormatComboBox->currentText()) != -1)
  {
    outputFile = mpLibraryTreeNode->getNameStructure();
    if (!mpFileNameTextBox->text().isEmpty())
      outputFile = mpFileNameTextBox->text().trimmed();
    QFileInfo resultFileInfo(QString(workingDirectory).append("/").append(outputFile).append("_res.").append(mpOutputFormatComboBox->currentText()));
    if (resultFileInfo.exists())
    {
      mLastModifiedDateTime = resultFileInfo.lastModified();
    }
  }
  // read the file path according to the file prefix variable
  QString fileName;
  if (mpFileNameTextBox->text().isEmpty())
    fileName = QString(workingDirectory).append("/").append(mpLibraryTreeNode->getNameStructure());
  else
    fileName = QString(workingDirectory).append("/").append(mpFileNameTextBox->text());
  fileName = fileName.replace("//", "/");
  // run the simulation executable to create the result file
#ifdef WIN32
  fileName = fileName.append(".exe");
#endif
  // start the process
  mpSimulationProcess = new QProcess();
#ifdef WIN32
  setProcessEnvironment(mpSimulationProcess);
#endif
  mpSimulationProcess->setWorkingDirectory(workingDirectory);
  SimulationOutputWidget *pSimulationOutputWidget = qobject_cast<SimulationOutputWidget*>(mSimulationOutputWidgetsList.last());
  if (pSimulationOutputWidget)
  {
    connect(mpSimulationProcess, SIGNAL(readyReadStandardOutput()), SLOT(writeSimulationStandardOutput()));
    connect(mpSimulationProcess, SIGNAL(readyReadStandardError()), SLOT(writeSimulationStandardError()));
    connect(mpSimulationProcess, SIGNAL(readyRead()), SLOT(showSimulationOutputWidget()));
  }
  connect(mpSimulationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(simulationProcessFinished(int,QProcess::ExitStatus)));
  connect(mpSimulationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(simulationProcessError(QProcess::ProcessError)));
  mpProgressDialog->getCancelSimulationButton()->setText(tr("Cancel Simulation"));
  mpProgressDialog->getCancelSimulationButton()->setEnabled(true);
  mpProgressDialog->setText(tr("Running Simulation of <b>%1</b>.<br />Please wait for a while.").arg(mpLibraryTreeNode->getNameStructure()));
  // set progress bar range
  mpProgressDialog->getProgressBar()->setRange(0, 100);       // the simulation runtime sends double value until 100.
  mpProgressDialog->getProgressBar()->setTextVisible(true);
  // start the executable with the tcp server so it can listen to the simulation progress messages
  QTcpSocket *sock = 0;
  QTcpServer server;
  const int SOCKMAXLEN = 4096;
  char buf[SOCKMAXLEN];
  server.listen(QHostAddress(QHostAddress::LocalHost));
  QStringList args(QString("-port=").append(QString::number(server.serverPort())));
  args << mSimulationFlags;
  // start the executable
  mIsSimulationProcessRunning = true;
  mpSimulationProcess->start(fileName, args);
  while (mpSimulationProcess->state() == QProcess::Starting || mpSimulationProcess->state() == QProcess::Running)
  {
    if (!mIsSimulationProcessRunning)
      break;
    if (!sock && server.hasPendingConnections()) {
      sock = server.nextPendingConnection();
    } else if (!sock) {
      QEventLoop eventLoop;
      QTimer timer;   /* in case we don't get any newConnection() from simulation executable we must quit the event loop.*/
      connect(&timer, SIGNAL(timeout()), &eventLoop, SLOT(quit()));
      connect(&server, SIGNAL(newConnection()), &eventLoop, SLOT(quit()));
      timer.start(1000);
      eventLoop.exec();
      //server.waitForNewConnection(100,0);
    } else {
      sock->waitForReadyRead(100);
      while (sock->readLine(buf,SOCKMAXLEN) > 0) {
        char *msg = 0;
        double d = strtod(buf, &msg);
        if (msg == buf || *msg != ' ') {
          // do we really need to take care of this communication error?????
          //fprintf(stderr, "TODO: OMEdit GUI: COMM ERROR '%s'", buf);
        } else {
          mpProgressDialog->getProgressBar()->setValue(d/100.0);
          //fprintf(stderr, "TODO: OMEdit GUI: Display progress (%g%%) and message: %s", d/100.0, msg+1);
        }
      }
    }
    qApp->processEvents();
  }
  if (sock) delete sock;
  server.close();
}

/*!
  Saves the simulation options in the model.
  */
void SimulationDialog::saveSimulationOptions()
{
  if (!mpSaveSimulationCheckbox->isChecked())
    return;

  QString annotationString;
  // create simulations options annotation
  annotationString.append("annotate=experiment(");
  annotationString.append("StartTime=").append(QString::number(mpStartTimeSpinBox->value())).append(",");
  annotationString.append("StopTime=").append(QString::number(mpStopTimeSpinBox->value())).append(",");
  annotationString.append("Tolerance=").append(QString::number(mpToleranceSpinBox->value()));
  annotationString.append(")");
  // send the simulations options annotation to OMC
  mpMainWindow->getOMCProxy()->addClassAnnotation(mpLibraryTreeNode->getNameStructure(), annotationString);
  // make the model modified
  if (mpLibraryTreeNode->getModelWidget())
  {
    mpLibraryTreeNode->getModelWidget()->setModelModified();
    if (mpLibraryTreeNode->getModelWidget()->getModelicaTextWidget()->isVisible())
      mpLibraryTreeNode->getModelWidget()->getModelicaTextWidget()->getModelicaTextEdit()->setPlainText(mpMainWindow->getOMCProxy()->list(mpLibraryTreeNode->getNameStructure()));
  }
}

/*!
  Writes the compilation standard output & standard error.
  */
void SimulationDialog::writeCompilationOutput(QString output, QColor color)
{
  SimulationOutputWidget *pSimulationOutputWidget = qobject_cast<SimulationOutputWidget*>(mSimulationOutputWidgetsList.last());
  if (pSimulationOutputWidget)
  {
    /* move the cursor down before adding to the logger. */
    QTextCursor textCursor = pSimulationOutputWidget->getCompilationOutputTextBox()->textCursor();
    textCursor.movePosition(QTextCursor::End);
    pSimulationOutputWidget->getCompilationOutputTextBox()->setTextCursor(textCursor);
    /* set the text color red */
    QTextCharFormat charFormat = pSimulationOutputWidget->getCompilationOutputTextBox()->currentCharFormat();
    charFormat.setForeground(color);
    pSimulationOutputWidget->getCompilationOutputTextBox()->setCurrentCharFormat(charFormat);
    /* append the output */
    pSimulationOutputWidget->getCompilationOutputTextBox()->insertPlainText(output);
    /* move the cursor */
    textCursor.movePosition(QTextCursor::End);
    pSimulationOutputWidget->getCompilationOutputTextBox()->setTextCursor(textCursor);
    /* make the compilation tab the current one */
    pSimulationOutputWidget->getGeneratedFilesTabWidget()->setCurrentIndex(1);
  }
}

/*!
  Writes the simulation standard output & standard error.
  */
void SimulationDialog::writeSimulationOutput(QString output, QColor color)
{
  SimulationOutputWidget *pSimulationOutputWidget = qobject_cast<SimulationOutputWidget*>(mSimulationOutputWidgetsList.last());
  if (pSimulationOutputWidget)
  {
    pSimulationOutputWidget->getGeneratedFilesTabWidget()->setTabEnabled(0, true);
    /* move the cursor down before adding to the logger. */
    QTextCursor textCursor = pSimulationOutputWidget->getSimulationOutputTextBox()->textCursor();
    textCursor.movePosition(QTextCursor::End);
    pSimulationOutputWidget->getSimulationOutputTextBox()->setTextCursor(textCursor);
    /* set the text color red */
    QTextCharFormat charFormat = pSimulationOutputWidget->getSimulationOutputTextBox()->currentCharFormat();
    charFormat.setForeground(color);
    pSimulationOutputWidget->getSimulationOutputTextBox()->setCurrentCharFormat(charFormat);
    /* append the output */
    pSimulationOutputWidget->getSimulationOutputTextBox()->insertPlainText(output);
    /* move the cursor */
    textCursor.movePosition(QTextCursor::End);
    pSimulationOutputWidget->getSimulationOutputTextBox()->setTextCursor(textCursor);
    /* make the compilation tab the current one */
    pSimulationOutputWidget->getGeneratedFilesTabWidget()->setCurrentIndex(0);
  }
}

/*!
  Slot activated when mpModelSetupFileBrowseButton clicked signal is raised.\n
  Allows user to select Model Setup File.
  */
void SimulationDialog::browseModelSetupFile()
{
  mpModelSetupFileTextBox->setText(StringHandler::getOpenFileName(this,QString(Helper::applicationName).append(" - ").append(Helper::chooseFile), NULL, Helper::xmlFileTypes, NULL));
}

/*!
  Slot activated when mpEquationSystemInitializationFileBrowseButton clicked signal is raised.\n
  Allows user to select Equation System Initialization File.
  */
void SimulationDialog::browseEquationSystemInitializationFile()
{
  mpEquationSystemInitializationFileTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile), NULL, Helper::matFileTypes, NULL));
}

/*!
  Slot activated when mpSimulateButton clicked signal is raised.\n
  Reads the simulation options set by the user and sends them to OMC by calling buildModel.
  */
void SimulationDialog::simulate()
{
  // check if user is already running one interactive simultation or not
  // beacuse only one interactive simulation is allowed.
//  if (mIsInteractive)
//  {
//    if (mpMainWindow->mpInteractiveSimualtionTabWidget->count() > 0)
//    {
//      QMessageBox::information(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
//                               GUIMessages::getMessage(GUIMessages::INTERACTIVE_SIMULATION_RUNNIG), Helper::ok);
//      return;
//    }
//  }

  if (validate())
  {
    mSimulationParameters.clear();
    mSimulationFlags.clear();
    // if user is performing a simple simulation then take start and stop times
    if (!mIsInteractive)
    {
      mSimulationParameters.append("startTime=").append(QString::number(mpStartTimeSpinBox->value()));
      mSimulationParameters.append(", stopTime=").append(QString::number(mpStopTimeSpinBox->value())).append(",");
    }
    mSimulationParameters.append(" numberOfIntervals=").append(QString::number(mpNumberofIntervalsSpinBox->value()));
    if (mpMethodComboBox->currentText().isEmpty())
      mSimulationParameters.append(", method=\"dassl\"");
    else
      mSimulationParameters.append(", method=").append("\"").append(mpMethodComboBox->currentText()).append("\"");
    mSimulationParameters.append(", tolerance=").append(QString::number(mpToleranceSpinBox->value()));
    mSimulationParameters.append(", outputFormat=").append("\"").append(mpOutputFormatComboBox->currentText()).append("\"");
    if (!mpFileNameTextBox->text().isEmpty())
      mSimulationParameters.append(", fileNamePrefix=").append("\"").append(mpFileNameTextBox->text()).append("\"");
    if (!mpVariableFilterTextBox->text().isEmpty())
      mSimulationParameters.append(", variableFilter=").append("\"").append(mpVariableFilterTextBox->text()).append("\"");
    if (!mpCflagsTextBox->text().isEmpty())
      mSimulationParameters.append(", cflags=").append("\"").append(mpCflagsTextBox->text()).append("\"");
    if (mpProfilingCheckBox->isChecked())
      mSimulationParameters.append(", measureTime=true");
    // setup simulation flags
    // setup Model Setup file flag
    if (!mpModelSetupFileTextBox->text().isEmpty())
    {
      mSimulationFlags.append(QString("-f=").append(mpModelSetupFileTextBox->text()));
    }
    // setup initiaization method flag
    if (!mpInitializationMethodComboBox->currentText().isEmpty())
    {
      mSimulationFlags.append(QString("-iim=").append(mpInitializationMethodComboBox->currentText()));
    }
    // setup Optimization Method flag
    if (!mpOptimizationMethodComboBox->currentText().isEmpty())
    {
      mSimulationFlags.append(QString("-iom=").append(mpOptimizationMethodComboBox->currentText()));
    }
    // setup Equation System Initialization file flag
    if (!mpEquationSystemInitializationFileTextBox->text().isEmpty())
    {
      mSimulationFlags.append(QString("-iif=").append(mpEquationSystemInitializationFileTextBox->text()));
    }
    // setup Equation System Initialization time flag
    if (!mpEquationSystemInitializationTimeTextBox->text().isEmpty())
    {
      mSimulationFlags.append(QString("-iit=").append(mpEquationSystemInitializationTimeTextBox->text()));
    }
    // clock
    if (!mpClockComboBox->currentText().isEmpty())
    {
      mSimulationFlags.append(QString("-clock=").append(mpClockComboBox->currentText()));
    }
    // linear solver
    if (!mpLinearSolverComboBox->currentText().isEmpty())
    {
      mSimulationFlags.append(QString("-ls=").append(mpLinearSolverComboBox->currentText()));
    }
    // non linear solver
    if (!mpNonLinearSolverComboBox->currentText().isEmpty())
    {
      mSimulationFlags.append(QString("-nls=").append(mpNonLinearSolverComboBox->currentText()));
    }
    // time where the linearization of the model should be performed
    if (!mpLinearizationTimeTextBox->text().isEmpty())
    {
      mSimulationFlags.append(QString("-l=").append(mpLinearizationTimeTextBox->text()));
    }
    // output variables
    if (!mpOutputVariablesTextBox->text().isEmpty())
    {
      mSimulationFlags.append(QString("-output=").append(mpOutputVariablesTextBox->text()));
    }
    // setup cpu time flag
    if (mpCPUTimeCheckBox->isChecked())
    {
      mSimulationFlags.append("-cpu");
    }
    // setup enable all warnings flag
    if (mpEnableAllWarningsCheckBox->isChecked())
    {
      mSimulationFlags.append("-w");
    }
    // setup Logging flags
    if (mpLogDasslSolverCheckBox->isChecked() ||
        mpLogDebugCheckBox->isChecked() ||
        mpLogDynamicStateSelectionCheckBox->isChecked() ||
        mpLogJacobianDynamicStateSelectionCheckBox->isChecked() ||
        mpLogEventsCheckBox->isChecked() ||
        mpLogVerboseEventsCheckBox->isChecked() ||
        mpLogInitializationCheckBox->isChecked() ||
        mpLogJacobianCheckBox->isChecked() ||
        mpLogNonLinearSystemsCheckBox->isChecked() ||
        mpLogVerboseNonLinearSystemsCheckBox->isChecked() ||
        mpLogJacobianNonLinearSystemsCheckBox->isChecked() ||
        mpLogResidualsInitializationCheckBox->isChecked() ||
        mpLogSimulationCheckBox->isChecked() ||
        mpLogSolverCheckBox->isChecked() ||
        mpLogFinalSolutionOfInitializationCheckBox->isChecked() ||
        mpLogStatsCheckBox->isChecked() ||
        mpLogStatsCheckBox->isChecked() ||
        mpLogZeroCrossingsCheckBox->isChecked())
    {
      QString loggingFlagName, loggingFlagValues;
      loggingFlagName.append("-lv=");
      if (mpLogDasslSolverCheckBox->isChecked())
        loggingFlagValues.append("LOG_DDASRT");
      if (mpLogDebugCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_DEBUG") : loggingFlagValues.append(",LOG_DEBUG");
      if (mpLogDynamicStateSelectionCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_DSS") : loggingFlagValues.append(",LOG_DSS");
      if (mpLogJacobianDynamicStateSelectionCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_DSS_JAC") : loggingFlagValues.append(",LOG_DSS_JAC");
      if (mpLogEventsCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_EVENTS") : loggingFlagValues.append(",LOG_EVENTS");
      if (mpLogVerboseEventsCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_EVENTS_V") : loggingFlagValues.append(",LOG_EVENTS_V");
      if (mpLogInitializationCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_INIT") : loggingFlagValues.append(",LOG_INIT");
      if (mpLogJacobianCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_JAC") : loggingFlagValues.append(",LOG_JAC");
      if (mpLogNonLinearSystemsCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_NLS") : loggingFlagValues.append(",LOG_NLS");
      if (mpLogVerboseNonLinearSystemsCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_NLS_V") : loggingFlagValues.append(",LOG_NLS_V");
      if (mpLogJacobianNonLinearSystemsCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_NLS_JAC") : loggingFlagValues.append(",LOG_NLS_JAC");
      if (mpLogResidualsInitializationCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_RES_INIT") : loggingFlagValues.append(",LOG_RES_INIT");
      if (mpLogSimulationCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_SIMULATION") : loggingFlagValues.append(",LOG_SIMULATION");
      if (mpLogSolverCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_SOLVER") : loggingFlagValues.append(",LOG_SOLVER");
      if (mpLogFinalSolutionOfInitializationCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_SOTI") : loggingFlagValues.append(",LOG_SOTI");
      if (mpLogStatsCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_STATS") : loggingFlagValues.append(",LOG_STATS");
      if (mpLogUtilCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_UTIL") : loggingFlagValues.append(",LOG_UTIL");
      if (mpLogZeroCrossingsCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_ZEROCROSSINGS") : loggingFlagValues.append(",LOG_ZEROCROSSINGS");

      mSimulationFlags.append(QString(loggingFlagName).append(loggingFlagValues));
    }
    if (!mpAdditionalSimulationFlagsTextBox->text().isEmpty())
    {
      mSimulationFlags.append(StringHandler::splitStringWithSpaces(mpAdditionalSimulationFlagsTextBox->text()));
    }
    // before simulating save the simulation options.
    saveSimulationOptions();
    // show the progress bar
    mpProgressDialog->setText(tr("Translating <b>%1</b>.<br />Please wait for a while.").arg(mpLibraryTreeNode->getNameStructure()));
    mpProgressDialog->getCancelSimulationButton()->setEnabled(false);
    mpProgressDialog->getProgressBar()->setRange(0, 0);
    mpProgressDialog->getProgressBar()->setTextVisible(false);
    mpProgressDialog->show();
    // interactive or non interactive
    int numberOfSimulationOutputWidgets = mSimulationOutputWidgetsList.size();
    if (mIsInteractive)
      translateModel();
    else
      translateModel();
    // hide the progress bar
    mpProgressDialog->hide();
    if (mpProfilingCheckBox->isChecked())
    {
      if (mpFileNameTextBox->text().isEmpty())
        QDesktopServices::openUrl(QUrl(mpMainWindow->getOMCProxy()->changeDirectory() + "/" + mpLibraryTreeNode->getNameStructure() + "_prof.html"));
      else
        QDesktopServices::openUrl(QUrl(mpMainWindow->getOMCProxy()->changeDirectory() + "/" + mpFileNameTextBox->text() + "_prof.html"));
    }
    accept();
    /* if we have a new SimulationOutputWidget then make it the active window. */
    if (mSimulationOutputWidgetsList.size() > numberOfSimulationOutputWidgets)
    {
      QWidget *pSimulationOutputWidget = mSimulationOutputWidgetsList.last();
      showSimulationOutputWidget();
      pSimulationOutputWidget->raise();
      pSimulationOutputWidget->activateWindow();
    }
  }
}

/*!
  Slot activated when mpCompilationProcess finished signal is raised.\n
  Writes the error if mpCompilationProcess has crashed.\n
  If the mpCompilationProcess finished normally then run the simulation executable.
  */
void SimulationDialog::compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  Q_UNUSED(exitCode);
  mIsCompilationProcessRunning = false;
  if (exitStatus == QProcess::NormalExit && exitCode == 0)
  {
    runSimulationExecutable();
  }
  else if (!mIsCancelled)
  {
    writeCompilationOutput(mpCompilationProcess->errorString(), Qt::red);
  }
}

/*!
  Slot activated when mpCompilationProcess error signal is raised.\n
  Writes the mpCompilationProcess error string.
  */
void SimulationDialog::compilationProcessError(QProcess::ProcessError processError)
{
  Q_UNUSED(processError);
  mIsCompilationProcessRunning = false;
  if (!mIsCancelled)
  {
    switch (processError)
    {
      case QProcess::FailedToStart:
        writeCompilationOutput(mpCompilationProcess->errorString() + " " + mCompilationProcessPath, Qt::red);
        break;
      default:
        writeCompilationOutput(mpCompilationProcess->errorString(), Qt::red);
        break;
    }
  }
}

/*!
  Slot activated when mpCompilationProcess readyReadStandardOutput signal is raised.\n
  Writes the available standard output bytes to the compilation output text box.
  */
void SimulationDialog::writeCompilationStandardOutput()
{
  writeCompilationOutput(QString(mpCompilationProcess->readAllStandardOutput()), Qt::black);
}

/*!
  Slot activated when mpCompilationProcess readyReadStandardError signal is raised.\n
  Writes the available error output bytes to the compilation output text box.
  */
void SimulationDialog::writeCompilationStandardError()
{
  writeCompilationOutput(QString(mpCompilationProcess->readAllStandardError()), Qt::red);
}

/*!
  Slot activated when mpCompilationProcess/mpSimulationProcess readyRead signal is raised.\n
  Shows the simulation output widget.\n
  Since readyRead signal can be emitted many times depending on the compilation process output and we only want this slot to be
  activated only once. So we have to disconnect it from the readyRead signal only if the sender is the compilation process.
  */
void SimulationDialog::showSimulationOutputWidget()
{
  if (sender())
  {
    QProcess *pProcess = qobject_cast<QProcess*>(const_cast<QObject*>(sender()));
    if (pProcess)
      disconnect(pProcess, SIGNAL(readyRead()), this, SLOT(showSimulationOutputWidget()));
  }
  SimulationOutputWidget *pSimulationOutputWidget = qobject_cast<SimulationOutputWidget*>(mSimulationOutputWidgetsList.last());
  int xPos = mpMainWindow->width() < 550 ? x() : mpMainWindow->width() - 550;
  int yPos = mpMainWindow->height() < 300 ? y() : mpMainWindow->height() - 300;
  pSimulationOutputWidget->setGeometry(xPos, yPos, 550, 300);
  pSimulationOutputWidget->show();
}

/*!
  Slot activated when mpSimulationProcess finished signal is raised.\n
  Writes the error if mpSimulationProcess has crashed.\n
  If the mpSimulationProcess finished normally then read the simulation result file and switch to plotting view.
  */
void SimulationDialog::simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  Q_UNUSED(exitCode);
  mIsSimulationProcessRunning = false;
  // If user has cancelled the simulation then don't show the plotting view.
  if (mIsCancelled)
    return;
  if (exitStatus == QProcess::CrashExit)
  {
    writeSimulationOutput(mpSimulationProcess->errorString(), Qt::red);
  }
  QString workingDirectory = mpMainWindow->getOMCProxy()->changeDirectory();
  // read the result file
  QString outputFile;
  if (mpFileNameTextBox->text().isEmpty())
    outputFile = mpLibraryTreeNode->getNameStructure();
  else
    outputFile = mpFileNameTextBox->text();
  QFileInfo resultFileInfo(QString(workingDirectory).append("/").append(outputFile).append("_res.").append(mpOutputFormatComboBox->currentText()));
  QRegExp regExp("\\b(mat|plt|csv)\\b");
  if (regExp.indexIn(mpOutputFormatComboBox->currentText()) != -1 && resultFileInfo.exists() && mLastModifiedDateTime < resultFileInfo.lastModified())
  {
    VariablesWidget *pVariablesWidget = mpMainWindow->getVariablesWidget();
    OMCProxy *pOMCProxy = mpMainWindow->getOMCProxy();
    QString resultFileName = QString(outputFile).append("_res.").append(mpOutputFormatComboBox->currentText());
    QStringList list = pOMCProxy->readSimulationResultVars(resultFileName);
    // close the simulation result file.
    pOMCProxy->closeSimulationResultFile();
    mpMainWindow->getPerspectiveTabBar()->setCurrentIndex(2);
    pVariablesWidget->addPlotVariablestoTree(resultFileName, pOMCProxy->changeDirectory(), list);
    mpMainWindow->getVariablesDockWidget()->show();
  }
}

/*!
  Slot activated when mpSimulationProcess error signal is raised.\n
  Writes the mpSimulationProcess error string.
  */
void SimulationDialog::simulationProcessError(QProcess::ProcessError processError)
{
  Q_UNUSED(processError);
  mIsSimulationProcessRunning = false;
  if (!mIsCancelled)
  {
    writeSimulationOutput(mpSimulationProcess->errorString(), Qt::red);
  }
}

/*!
  Slot activated when mpSimulationProcess readyReadStandardOutput signal is raised.\n
  Writes the available output bytes to the simulation output text box.
  */
void SimulationDialog::writeSimulationStandardOutput()
{
  writeSimulationOutput(QString(mpSimulationProcess->readAllStandardOutput()), Qt::black);
}

/*!
  Slot activated when mpSimulationProcess readyReadStandardError signal is raised.\n
  Writes the available output bytes to the simulation output text box.
  */
void SimulationDialog::writeSimulationStandardError()
{
  writeSimulationOutput(QString(mpSimulationProcess->readAllStandardError()), Qt::red);
}

/*!
  Slot activated when mpCancelSimulationButton clicked signal is raised.\n
  Cancels a running simulation by killing the simulation executable.
  */
void SimulationDialog::cancelSimulation()
{
  mIsCancelled = true;
  if (mIsCompilationProcessRunning)
    mpCompilationProcess->kill();
  else
    mpSimulationProcess->kill();
  mpProgressDialog->hide();
}

/*!
  \class ProgressDialog
  \brief Shows a progress dialog while compiling and running a simulation.
  */

/*!
  \param pParent - pointer to SimulationWidget.
  */
ProgressDialog::ProgressDialog(SimulationDialog *pParent)
  : QDialog(pParent, Qt::FramelessWindowHint | Qt::WindowTitleHint)
{
  setWindowModality(Qt::WindowModal);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::simulation));
  // create heading label
  mpProgressLabel = new Label;
  mpProgressLabel->setAlignment((Qt::AlignHCenter));
  mpCancelSimulationButton = new QPushButton(tr("Cancel Translation"));
  connect(mpCancelSimulationButton, SIGNAL(clicked()), pParent, SLOT(cancelSimulation()));
  mpProgressBar = new QProgressBar;
  mpProgressBar->setRange(0, 0);
  mpProgressBar->setTextVisible(false);
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  // layout the items
  QVBoxLayout *mainLayout = new QVBoxLayout;
  mainLayout->addWidget(mpProgressLabel);
  mainLayout->addWidget(mpProgressBar);
  mainLayout->addWidget(mpCancelSimulationButton, 0, Qt::AlignRight);
  setLayout(mainLayout);
}

/*!
  \return the pointer to mpProgressBar
  */
QProgressBar* ProgressDialog::getProgressBar()
{
  return mpProgressBar;
}

/*!
  \return the pointer to mpCancelSimulationButton
  */
QPushButton* ProgressDialog::getCancelSimulationButton()
{
  return mpCancelSimulationButton;
}

/*!
  Sets the text message for progress dialog
  \param text the message to set.
  */
void ProgressDialog::setText(QString text)
{
  mpProgressLabel->setText(text);
  update();
}

/*!
  \class SimulationOutputDialog
  \brief Creates a dialog that shows the current simulation output.
  */

/*!
  \param modelName - the name of the simulating model.
  \param pSimulationProcess - the simulation process.
  \param pParent - pointer to MainWindow.
  */
SimulationOutputWidget::SimulationOutputWidget(QString className, QString outputFile, bool showGeneratedFiles, MainWindow *pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(className).append(" ").append(tr("Simulation Output")));
  setWindowFlags(windowFlags() | Qt::WindowStaysOnTopHint);
  mpMainWindow = pParent;
  // Generated Files tab widget
  mpGeneratedFilesTabWidget = new QTabWidget;
  mpGeneratedFilesTabWidget->setMovable(true);
  // Simulation Output TextBox
  mpSimulationOutputTextBox = new QPlainTextEdit;
  mpSimulationOutputTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  mpGeneratedFilesTabWidget->addTab(mpSimulationOutputTextBox, Helper::output);
  mpGeneratedFilesTabWidget->setTabEnabled(0, false);
  // Compilation Output TextBox
  mpCompilationOutputTextBox = new QPlainTextEdit;
  mpCompilationOutputTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  mpGeneratedFilesTabWidget->addTab(mpCompilationOutputTextBox, tr("Compilation"));
  if (showGeneratedFiles)
  {
    QString workingDirectory = mpMainWindow->getOMCProxy()->changeDirectory();
    /* className.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append(".c"));
    /* className_01exo.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_01exo.c"));
    /* className_02nls.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_02nls.c"));
    /* className_03lsy.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_03lsy.c"));
    /* className_04set.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_04set.c"));
    /* className_05evt.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_05evt.c"));
    /* className_06inz.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_06inz.c"));
    /* className_07dly.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_07dly.c"));
    /* className_08bnd.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_08bnd.c"));
    /* className_09alg.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_09alg.c"));
    /* className_10asr.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_10asr.c"));
    /* className_11mix.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_11mix.c"));
    /* className_11mix.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_11mix.h"));
    /* className_12jac.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_12jac.c"));
    /* className_12jac.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_12jac.h"));
    /* className_13opt.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_13opt.c"));
    /* className_14lnz.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_14lnz.c"));
    /* className_functions.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_functions.c"));
    /* className_functions.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_functions.h"));
    /* className_info.xml tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_info.xml"));
    /* className_init.xml tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_init.xml"));
    /* className_literals.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_literals.h"));
    /* className_model.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_model.h"));
    /* className_records.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_records.c"));
  }
  // layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->addWidget(mpGeneratedFilesTabWidget);
  setLayout(pMainLayout);
}

/*!
  Returns the pointer to mpGeneratedFilesTabWidget.
  \return the generated files tab widget.
  */
QTabWidget* SimulationOutputWidget::getGeneratedFilesTabWidget()
{
  return mpGeneratedFilesTabWidget;
}

/*!
  Returns the pointer to mpSimulationOutputTextBox.
  \return the Simulation Output text box.
  */
QPlainTextEdit* SimulationOutputWidget::getSimulationOutputTextBox()
{
  return mpSimulationOutputTextBox;
}

/*!
  Returns the pointer to mpCompilationOutputTextBox.
  \return the Compilation Output text box.
  */
QPlainTextEdit* SimulationOutputWidget::getCompilationOutputTextBox()
{
  return mpCompilationOutputTextBox;
}

void SimulationOutputWidget::addGeneratedFileTab(QString fileName)
{
  QFile file(fileName);
  QFileInfo fileInfo(fileName);
  if (file.exists())
  {
    file.open(QIODevice::ReadOnly);
    QPlainTextEdit *pPlainTextEdit = new QPlainTextEdit(QString(file.readAll()));
    pPlainTextEdit->setFont(QFont(Helper::monospacedFontInfo.family()));
    mpGeneratedFilesTabWidget->addTab(pPlainTextEdit, fileInfo.fileName());
    file.close();
  }
}
