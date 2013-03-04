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

/*
 * RCS: $Id$
 */

#include "SimulationWidget.h"
#include "OMCThread.h"

//! @class SimulationWidget
//! @brief Displays a dialog with simulation options for the current model.

//! Constructor
//! @param pParent is the pointer to MainWindow.
SimulationWidget::SimulationWidget(MainWindow *pParent)
  : QDialog(pParent, Qt::WindowTitleHint)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::simulation));
  mpParentMainWindow = pParent;
  resize(550, 550);
  setUpForm();
  mpProgressDialog = new ProgressDialog(this);
  connect(this, SIGNAL(showPlottingView()), mpParentMainWindow, SLOT(switchToPlottingView()));
}

//! Destructor
SimulationWidget::~SimulationWidget()
{
  delete mpProgressDialog;
}

//! Creates all the controls and set their layout.
void SimulationWidget::setUpForm()
{
  // simulation widget heading
  mpSimulationHeading = new QLabel(Helper::simulate);
  mpSimulationHeading->setFont(QFont("", Helper::headingFontSize));
  // Horizontal separator
  mpHorizontalLine = new QFrame();
  mpHorizontalLine->setFrameShape(QFrame::HLine);
  mpHorizontalLine->setFrameShadow(QFrame::Sunken);
  // simulation tab widget
  mpSimulationTabWidget = new QTabWidget;
  mpSimulationFlagsTab = new QWidget;
  // General Tab
  mpGeneralTab = new QWidget;
  // Simulation Interval
  QGridLayout *gridSimulationIntervalLayout = new QGridLayout;
  mpSimulationIntervalGroup = new QGroupBox(tr("Simulation Interval"));
  mpStartTimeLabel = new QLabel(tr("Start Time:"));
  mpStartTimeTextBox = new QLineEdit("0");
  mpStopTimeLabel = new QLabel(tr("Stop Time:"));
  mpStopTimeTextBox = new QLineEdit("1");
  // set the layout for simulation interval groupbox
  gridSimulationIntervalLayout->addWidget(mpStartTimeLabel, 0, 0);
  gridSimulationIntervalLayout->addWidget(mpStartTimeTextBox, 0, 1);
  gridSimulationIntervalLayout->addWidget(mpStopTimeLabel, 1, 0);
  gridSimulationIntervalLayout->addWidget(mpStopTimeTextBox, 1, 1);
  mpSimulationIntervalGroup->setLayout(gridSimulationIntervalLayout);
  // Integration
  QGridLayout *gridIntegrationLayout = new QGridLayout;
  mpIntegrationGroup = new QGroupBox(tr("Integration"));
  mpMethodLabel = new QLabel(tr("Method:"));
  mpMethodComboBox = new QComboBox;
  mpMethodComboBox->addItems(Helper::ModelicaSimulationMethods.split(","));
  mpToleranceLabel = new QLabel(tr("Tolerance:"));
  mpToleranceTextBox = new QLineEdit("0.0001");
  // set the layout for integration groupbox
  gridIntegrationLayout->addWidget(mpMethodLabel, 0, 0);
  gridIntegrationLayout->addWidget(mpMethodComboBox, 0, 1);
  gridIntegrationLayout->addWidget(mpToleranceLabel, 1, 0);
  gridIntegrationLayout->addWidget(mpToleranceTextBox, 1, 1);
  mpIntegrationGroup->setLayout(gridIntegrationLayout);
  // Compiler Flags
  mpCflagsLabel = new QLabel(tr("Compiler Flags (Optional):"));
  mpCflagsTextBox = new QLineEdit;
  // set General Tab Layout
  QGridLayout *pGeneralTabLayout = new QGridLayout;
  pGeneralTabLayout->setAlignment(Qt::AlignTop);
  pGeneralTabLayout->addWidget(mpSimulationIntervalGroup, 0, 0, 1, 2);
  pGeneralTabLayout->addWidget(mpIntegrationGroup, 1, 0, 1, 2);
  pGeneralTabLayout->addWidget(mpCflagsLabel, 2, 0);
  pGeneralTabLayout->addWidget(mpCflagsTextBox, 2, 1);
  mpGeneralTab->setLayout(pGeneralTabLayout);
  // add General Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpGeneralTab, Helper::general);
  // Output Tab
  mpOutputTab = new QWidget;
  // Output Interval
  mpNumberofIntervalLabel = new QLabel(tr("Number of Intervals:"));
  mpNumberofIntervalsTextBox = new QLineEdit("500");
  // Output Format
  mpOutputFormatLabel = new QLabel(tr("Output Format:"));
  mpOutputFormatComboBox = new QComboBox;
  mpOutputFormatComboBox->addItems(Helper::ModelicaSimulationOutputFormats.toLower().split(","));
  // Output filename
  mpFileNameLabel = new QLabel(tr("File Name (Optional):"));
  mpFileNameTextBox = new QLineEdit;
  // Variable filter
  mpVariableFilterLabel = new QLabel(tr("Variable Filter (Optional):"));
  mpVariableFilterTextBox = new QLineEdit;
  // set Output Tab Layout
  QGridLayout *pOutputTabLayout = new QGridLayout;
  pOutputTabLayout->setAlignment(Qt::AlignTop);
  pOutputTabLayout->addWidget(mpNumberofIntervalLabel, 0, 0);
  pOutputTabLayout->addWidget(mpNumberofIntervalsTextBox, 0, 1);
  pOutputTabLayout->addWidget(mpOutputFormatLabel, 1, 0);
  pOutputTabLayout->addWidget(mpOutputFormatComboBox, 1, 1);
  pOutputTabLayout->addWidget(mpFileNameLabel, 2, 0);
  pOutputTabLayout->addWidget(mpFileNameTextBox, 2, 1);
  pOutputTabLayout->addWidget(mpVariableFilterLabel, 3, 0);
  pOutputTabLayout->addWidget(mpVariableFilterTextBox, 3, 1);
  mpOutputTab->setLayout(pOutputTabLayout);
  // add Output Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpOutputTab, tr("Output"));
  // Simulation Flags Tab
  mpSimulationFlagsTab = new QWidget;
  // Simulation Flags Tab scroll area
  mpSimulationFlagsTabScrollArea = new QScrollArea;
  mpSimulationFlagsTabScrollArea->setFrameShape(QFrame::NoFrame);
  mpSimulationFlagsTabScrollArea->setBackgroundRole(QPalette::Base);
  mpSimulationFlagsTabScrollArea->setWidgetResizable(true);
  mpSimulationFlagsTabScrollArea->setWidget(mpSimulationFlagsTab);
  // Model Setup File
  mpModelSetupFileLabel = new QLabel(tr("Model Setup File (Optional):"));
  mpModelSetupFileTextBox = new QLineEdit;
  mpModelSetupFileBrowseButton = new QPushButton(Helper::browse);
  connect(mpModelSetupFileBrowseButton, SIGNAL(clicked()), SLOT(browseModelSetupFile()));
  // Initialization Methods
  mpInitializationMethodLabel = new QLabel(tr("Initialization Method (Optional):"));
  mpInitializationMethodComboBox = new QComboBox;
  mpInitializationMethodComboBox->addItems(Helper::ModelicaInitializationMethods.toLower().split(","));
  // Optimization Methods
  mpOptimizationMethodLabel = new QLabel(tr("Optimization Method (Optional):"));
  mpOptimizationMethodComboBox = new QComboBox;
  mpOptimizationMethodComboBox->addItems(Helper::ModelicaOptimizationMethods.toLower().split(","));
  // Equation System Initialization File
  mpEquationSystemInitializationFileLabel = new QLabel(tr("Equation System Initialization File (Optional):"));
  mpEquationSystemInitializationFileTextBox = new QLineEdit;
  mpEquationSystemInitializationFileBrowseButton = new QPushButton(Helper::browse);
  connect(mpEquationSystemInitializationFileBrowseButton, SIGNAL(clicked()), SLOT(browseEquationSystemInitializationFile()));
  // Equation System time
  mpEquationSystemInitializationTimeLabel = new QLabel(tr("Equation System Initialization Time (Optional):"));
  mpEquationSystemInitializationTimeTextBox = new QLineEdit;
  // Matching Algorithm
  mpMatchingAlgorithmLabel = new QLabel(tr("Matching Algorithm:"));
  QStringList matchingAlgorithmChoices, matchingAlgorithmComments;
  mpParentMainWindow->mpOMCProxy->getAvailableMatchingAlgorithms(&matchingAlgorithmChoices, &matchingAlgorithmComments);
  mpMatchingAlgorithmComboBox = new QComboBox;
  int i = 0;
  foreach (QString matchingAlgorithmChoice, matchingAlgorithmChoices)
  {
    mpMatchingAlgorithmComboBox->addItem(matchingAlgorithmChoice);
    mpMatchingAlgorithmComboBox->setItemData(i, matchingAlgorithmComments[i], Qt::ToolTipRole);
    i++;
  }
  mpMatchingAlgorithmComboBox->setCurrentIndex(mpMatchingAlgorithmComboBox->findText(mpParentMainWindow->mpOMCProxy->getMatchingAlgorithm()));
  // Index Reduction Method
  mpIndexReductionLabel = new QLabel(tr("Index Reduction Method:"));
  QStringList indexReductionChoices, indexReductionComments;
  mpParentMainWindow->mpOMCProxy->getAvailableIndexReductionMethods(&indexReductionChoices, &indexReductionComments);
  mpIndexReductionComboBox = new QComboBox;
  i = 0;
  foreach (QString indexReductionChoice, indexReductionChoices)
  {
    mpIndexReductionComboBox->addItem(indexReductionChoice);
    mpIndexReductionComboBox->setItemData(i, indexReductionComments[i], Qt::ToolTipRole);
    i++;
  }
  mpIndexReductionComboBox->setCurrentIndex(mpIndexReductionComboBox->findText(mpParentMainWindow->mpOMCProxy->getIndexReductionMethod()));
  // clock
  mpClockLabel = new QLabel(tr("Clock:"));
  mpClockComboBox = new QComboBox;
  mpClockComboBox->addItems(Helper::clockOptions.split(","));
  // Linear Solvers
  mpLinearSolverLabel = new QLabel(tr("Linear Solver:"));
  mpLinearSolverComboBox = new QComboBox;
  mpLinearSolverComboBox->addItems(Helper::linearSolvers.split(","));
  // Non Linear Solvers
  mpNonLinearSolverLabel = new QLabel(tr("Non Linear Solver:"));
  mpNonLinearSolverComboBox = new QComboBox;
  mpNonLinearSolverComboBox->addItems(Helper::nonLinearSolvers.split(","));
  // time where the linearization of the model should be performed
  mpLinearizationTimeLabel = new QLabel(tr("Linearization Time:"));
  mpLinearizationTimeTextBox = new QLineEdit;
  // output variables
  mpOutputVariablesLabel = new QLabel(tr("Output Variables:"));
  mpOutputVariablesTextBox = new QLineEdit;
  mpOutputVariablesTextBox->setToolTip(tr("Comma separated list of variables"));
  // Logging
  mpLogDasslSolverCheckBox = new QCheckBox(tr("DASSL Solver Information"));
  mpLogDebugCheckBox = new QCheckBox(tr("Debug"));
  mpLogDynamicStateSelectionCheckBox = new QCheckBox(tr("Dynamic State Selection Information"));
  mpLogJacobianDynamicStateSelectionCheckBox = new QCheckBox(tr("Jacobians Dynamic State Selection Information"));
  mpLogEventsCheckBox = new QCheckBox(tr("Event Iteration"));
  mpLogVerboseEventsCheckBox = new QCheckBox(tr("Verbose Event System"));
  mpLogInitializationCheckBox = new QCheckBox(tr("Initialization"));
  mpLogJacobianCheckBox = new QCheckBox(tr("Jacobians Matrix"));
  mpLogNonLinearSystemsCheckBox = new QCheckBox(tr("Non Linear Systems"));
  mpLogVerboseNonLinearSystemsCheckBox = new QCheckBox(tr("Verbose Non Linear Systems"));
  mpLogJacobianNonLinearSystemsCheckBox = new QCheckBox(tr("Jacobians Non Linear Systems"));
  mpLogResidualsInitializationCheckBox = new QCheckBox(tr("Initialization Residuals"));
  mpLogSimulationCheckBox = new QCheckBox(tr("Simulation Process"));
  mpLogSolverCheckBox = new QCheckBox(tr("Solver Process"));
  mpLogFinalSolutionOfInitializationCheckBox = new QCheckBox(tr("Final Initialization Solution"));
  mpLogStatsCheckBox = new QCheckBox(tr("Timer/Events/Solver Statistics"));
  mpLogUtilCheckBox = new QCheckBox(tr("Util"));
  mpLogZeroCrossingsCheckBox = new QCheckBox(tr("Zero Crossings"));
  // measure simulation time checkbox
  mpMeasureTimeCheckBox = new QCheckBox(tr("Measure simulation time (~5-25% overhead)"));
  // cpu-time checkbox
  mpCPUTimeCheckBox = new QCheckBox(tr("CPU time"));
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
  mpLoggingGroup = new QGroupBox(tr("Logging (Optional)"));
  mpLoggingGroup->setLayout(pLoggingGroupLayout);
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
  pSimulationFlagsTabLayout->addWidget(mpMatchingAlgorithmLabel, 5, 0);
  pSimulationFlagsTabLayout->addWidget(mpMatchingAlgorithmComboBox, 5, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpIndexReductionLabel, 6, 0);
  pSimulationFlagsTabLayout->addWidget(mpIndexReductionComboBox, 6, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpClockLabel, 7, 0);
  pSimulationFlagsTabLayout->addWidget(mpClockComboBox, 7, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpLinearSolverLabel, 8, 0);
  pSimulationFlagsTabLayout->addWidget(mpLinearSolverComboBox, 8, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpNonLinearSolverLabel, 9, 0);
  pSimulationFlagsTabLayout->addWidget(mpNonLinearSolverComboBox, 9, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpLinearizationTimeLabel, 10, 0);
  pSimulationFlagsTabLayout->addWidget(mpLinearizationTimeTextBox, 10, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpOutputVariablesLabel, 11, 0);
  pSimulationFlagsTabLayout->addWidget(mpOutputVariablesTextBox, 11, 1, 1, 2);
  pSimulationFlagsTabLayout->addWidget(mpMeasureTimeCheckBox, 12, 0);
  pSimulationFlagsTabLayout->addWidget(mpCPUTimeCheckBox, 13, 0);
  pSimulationFlagsTabLayout->addWidget(mpLoggingGroup, 14, 0, 1, 3);
  mpSimulationFlagsTab->setLayout(pSimulationFlagsTabLayout);
  // add Output Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpSimulationFlagsTabScrollArea, tr("Simulation Flags"));
  // Add the validators
  QDoubleValidator *doubleValidator = new QDoubleValidator(this);
  doubleValidator->setBottom(0);
  mpStartTimeTextBox->setValidator(doubleValidator);
  mpStopTimeTextBox->setValidator(doubleValidator);
  mpToleranceTextBox->setValidator(doubleValidator);
  QIntValidator *intValidator = new QIntValidator(this);
  intValidator->setBottom(1);
  mpNumberofIntervalsTextBox->setValidator(intValidator);
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

//! Initializes the simulation dialog with the default values.
void SimulationWidget::initializeFields()
{
  // depending on the mIsInteractive flag change the heading and disable start and stop times
  if (mIsInteractive)
  {
    setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::interactiveSimulation));
    mpSimulationHeading->setText(Helper::interactiveSimulation);
    mpSimulationIntervalGroup->setDisabled(true);
    return;
  }
  else
  {
    setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::simulation));
    mpSimulationHeading->setText(Helper::simulation);
    mpSimulationIntervalGroup->setDisabled(false);
  }
  ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();
  if (!projectTab)
  {
    return;
  }
  // if project tab is available...
  // get the simulation options....
  QString result = mpParentMainWindow->mpOMCProxy->getSimulationOptions(projectTab->mModelNameStructure);
  result = StringHandler::removeFirstLastCurlBrackets(StringHandler::removeComment(result));
  QStringList simulationOptionsList = StringHandler::getStrings(result);
  // since we always get simulationOptions so just get the values from array
  mpStartTimeTextBox->setText(simulationOptionsList.at(0));
  mpStopTimeTextBox->setText(simulationOptionsList.at(1));
  mpNumberofIntervalsTextBox->setText(simulationOptionsList.at(2));
  mpToleranceTextBox->setText(QString::number(simulationOptionsList.at(3).toFloat(), 'f'));
  mpMethodComboBox->setCurrentIndex(mpMethodComboBox->findText(StringHandler::removeFirstLastQuotes(simulationOptionsList.at(4))));
  mpFileNameTextBox->setText("");
  mpCflagsTextBox->setText("");
}

//! Reimplementation of QDialog::show method.
//! @param isInteractive decides whether the dialog is used for interactive simulation or normal simulation.
void SimulationWidget::show(bool isInteractive)
{
  mIsInteractive = isInteractive;
  // validate the modelica text before simulating the model
  ProjectTab *pCurrentTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();
  if (pCurrentTab)
  {
    if (!pCurrentTab->mpModelicaEditor->validateText())
      return;
  }
  initializeFields();
  setVisible(true);
}

//! Slot activated when mpModelSetupFileBrowseButton clicked signal is raised.
//! Allows user to select Model Setup File.
void SimulationWidget::browseModelSetupFile()
{
  mpModelSetupFileTextBox->setText(StringHandler::getOpenFileName(this, Helper::chooseFile, NULL, Helper::xmlFileTypes, NULL));
}

//! Slot activated when mpEquationSystemInitializationFileBrowseButton clicked signal is raised.
//! Allows user to select Equation System Initialization File.
void SimulationWidget::browseEquationSystemInitializationFile()
{
  mpEquationSystemInitializationFileTextBox->setText(StringHandler::getOpenFileName(this, Helper::chooseFile, NULL, Helper::matFileTypes, NULL));
}

//! Slot activated when mpSimulateButton clicked signal is raised.
//! Reads the simulation options set by the user and sends them to OMC by calling buildModel.
void SimulationWidget::simulate()
{
  // check if user is already running one interactive simultation or not
  // beacuse only one interactive simulation is allowed.
  if (mIsInteractive)
  {
    if (mpParentMainWindow->mpInteractiveSimualtionTabWidget->count() > 0)
    {
      QMessageBox::information(mpParentMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::information),
                               GUIMessages::getMessage(GUIMessages::INTERACTIVE_SIMULATION_RUNNIG), Helper::ok);
      return;
    }
  }

  if (validate())
  {
    QString simulationParameters;
    QStringList simulationFlags;
    bool show_profile = false;
    // if user is performing a simple simulation then take start and stop times
    if (!mIsInteractive)
    {
      if (mpStartTimeTextBox->text().isEmpty())
        simulationParameters.append("startTime=0.0");
      else
        simulationParameters.append("startTime=").append(mpStartTimeTextBox->text());
      simulationParameters.append(", stopTime=").append(mpStopTimeTextBox->text()).append(",");
    }
    if (mpNumberofIntervalsTextBox->text().isEmpty())
      simulationParameters.append(" numberOfIntervals=500");
    else
      simulationParameters.append(" numberOfIntervals=").append(mpNumberofIntervalsTextBox->text());
    if (mpMethodComboBox->currentText().isEmpty())
      simulationParameters.append(", method=\"dassl\"");
    else
      simulationParameters.append(", method=").append("\"").append(mpMethodComboBox->currentText()).append("\"");
    if (!mpToleranceTextBox->text().isEmpty())
      simulationParameters.append(", tolerance=").append(mpToleranceTextBox->text());
    simulationParameters.append(", outputFormat=").append("\"").append(mpOutputFormatComboBox->currentText()).append("\"");
    if (!mpFileNameTextBox->text().isEmpty())
      simulationParameters.append(", fileNamePrefix=").append("\"").append(mpFileNameTextBox->text()).append("\"");
    if (!mpVariableFilterTextBox->text().isEmpty())
      simulationParameters.append(", variableFilter=").append("\"").append(mpVariableFilterTextBox->text()).append("\"");
    if (!mpCflagsTextBox->text().isEmpty())
      simulationParameters.append(", cflags=").append("\"").append(mpCflagsTextBox->text()).append("\"");
    if (mpMeasureTimeCheckBox->isChecked())
    {
      show_profile = true;
      simulationParameters.append(", measureTime=true");
    }

    ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();
    if (!projectTab)
    {
      mpParentMainWindow->mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                                         GUIMessages::getMessage(GUIMessages::NO_OPEN_MODEL)
                                                                         .arg(Helper::simulate), Helper::simulationKind, Helper::warningLevel,
                                                                         0, mpParentMainWindow->mpMessageWidget->mpProblem));
      accept();
      return;
    }
    // setup simulation flags
    // setup Model Setup file flag
    if (!mpModelSetupFileTextBox->text().isEmpty())
    {
      simulationFlags.append(QString("-f=").append(mpModelSetupFileTextBox->text()));
    }
    // setup initiaization method flag
    if (!mpInitializationMethodComboBox->currentText().isEmpty())
    {
      simulationFlags.append(QString("-iim=").append(mpInitializationMethodComboBox->currentText()));
    }
    // setup Optimization Method flag
    if (!mpOptimizationMethodComboBox->currentText().isEmpty())
    {
      simulationFlags.append(QString("-iom=").append(mpOptimizationMethodComboBox->currentText()));
    }
    // setup Equation System Initialization file flag
    if (!mpEquationSystemInitializationFileTextBox->text().isEmpty())
    {
      simulationFlags.append(QString("-iif=").append(mpEquationSystemInitializationFileTextBox->text()));
    }
    // setup Equation System Initialization time flag
    if (!mpEquationSystemInitializationTimeTextBox->text().isEmpty())
    {
      simulationFlags.append(QString("-iit=").append(mpEquationSystemInitializationTimeTextBox->text()));
    }
    // clock
    if (!mpClockComboBox->currentText().isEmpty())
    {
      simulationFlags.append(QString("-clock=").append(mpClockComboBox->currentText()));
    }
    // linear solver
    if (!mpLinearSolverComboBox->currentText().isEmpty())
    {
      simulationFlags.append(QString("-ls=").append(mpLinearSolverComboBox->currentText()));
    }
    // non linear solver
    if (!mpNonLinearSolverComboBox->currentText().isEmpty())
    {
      simulationFlags.append(QString("-nls=").append(mpNonLinearSolverComboBox->currentText()));
    }
    // time where the linearization of the model should be performed
    if (!mpLinearizationTimeTextBox->text().isEmpty())
    {
      simulationFlags.append(QString("-l=").append(mpLinearizationTimeTextBox->text()));
    }
    // output variables
    if (!mpOutputVariablesTextBox->text().isEmpty())
    {
      simulationFlags.append(QString("-output=").append(mpOutputVariablesTextBox->text()));
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
      if (mpLogStatsCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_UTIL") : loggingFlagValues.append(",LOG_UTIL");
      if (mpLogZeroCrossingsCheckBox->isChecked())
        loggingFlagValues.isEmpty() ? loggingFlagValues.append("LOG_ZEROCROSSINGS") : loggingFlagValues.append(",LOG_ZEROCROSSINGS");

      simulationFlags.append(QString(loggingFlagName).append(loggingFlagValues));
    }
    // setup cpu time flag
    if (mpCPUTimeCheckBox->isChecked())
    {
      simulationFlags.append("-cpu");
    }
    // before simulating save the simulation options and set the matching algorithm & index reduction.
    saveSimulationOptions();
    mpParentMainWindow->mpOMCProxy->setMatchingAlgorithm(mpMatchingAlgorithmComboBox->currentText());
    mpParentMainWindow->mpOMCProxy->setIndexReductionMethod(mpIndexReductionComboBox->currentText());
    // show the progress bar
    mpProgressDialog->setText(tr("Compiling Model.\nPlease wait for a while."));
    mpProgressDialog->getCancelSimulationButton()->setEnabled(false);
    mpProgressDialog->getProgressBar()->setRange(0, 0);
    mpProgressDialog->getProgressBar()->setTextVisible(false);
    mpProgressDialog->show();
    mpParentMainWindow->mpStatusBar->showMessage(tr("Compiling Model"));
    // interactive or non interactive
    if (mIsInteractive)
      buildModel(simulationParameters, simulationFlags);
    else
      simulateModel(simulationParameters, simulationFlags);
    // hide the progress bar
    mpParentMainWindow->mpStatusBar->clearMessage();
    mpProgressDialog->hide();
    if (show_profile)
      QDesktopServices::openUrl(QUrl(QDir::tempPath() + "/OpenModelica/OMEdit/" + projectTab->mModelNameStructure + "_prof.html"));
    accept();
  }
}

//! Slot activated when mpCancelSimulationButton clicked signal is raised.
//! Cancels a running simulation by killing the simulation executable.
void SimulationWidget::cancelSimulation()
{
  mpSimulationProcess->kill();
  mpProgressDialog->hide();
}

//! Validates the simulation values entered by the user.
bool SimulationWidget::validate()
{
  if (mpStartTimeTextBox->text().isEmpty())
    mpParentMainWindow->mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                                       GUIMessages::getMessage(GUIMessages::NO_SIMULATION_STARTTIME),
                                                                       Helper::simulationKind, Helper::warningLevel, 0,
                                                                       mpParentMainWindow->mpMessageWidget->mpProblem));
  if (mpStopTimeTextBox->text().isEmpty())
  {
    mpParentMainWindow->mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                                       GUIMessages::getMessage(GUIMessages::NO_SIMULATION_STOPTIME),
                                                                       Helper::simulationKind, Helper::warningLevel, 0,
                                                                       mpParentMainWindow->mpMessageWidget->mpProblem));
    return false;
  }
  if (mpStartTimeTextBox->text().toDouble() > mpStopTimeTextBox->text().toDouble())
  {
    mpParentMainWindow->mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                                       GUIMessages::getMessage(GUIMessages::SIMULATION_STARTTIME_LESSTHAN_STOPTIME),
                                                                       Helper::simulationKind, Helper::warningLevel, 0,
                                                                       mpParentMainWindow->mpMessageWidget->mpProblem));
    return false;
  }
  return true;
}

//! Used for non-interactive simulation
//! Sends the buildModel command to OMC.
//! Starts the simulation executable with -port argument.
//! Creates a TCP server and starts listening for the simulation runtime progress messages.
//! @param simulationParameters a comma seperated list of simulation parameters.
//! @param simulationFlags a list of simulation flags for the simulation executable.
void SimulationWidget::simulateModel(QString simulationParameters, QStringList simulationFlags)
{
  ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();
  if (mpParentMainWindow->mpOMCProxy->buildModel(projectTab->mModelNameStructure, simulationParameters))
  {
    // read the file path according to the file prefix variable
    QString file;
    if (mpFileNameTextBox->text().isEmpty())
      file = QString(mpParentMainWindow->mpOMCProxy->changeDirectory()).append("/").append(projectTab->mModelNameStructure);
    else
      file = QString(mpParentMainWindow->mpOMCProxy->changeDirectory()).append("/").append(mpFileNameTextBox->text());

    file = file.replace("//", "/");
    // run the simulation executable to create the result file
#ifdef WIN32
    file = file.append(".exe");
#endif
    QFileInfo fileInfo(file);
    // start the process
    mpSimulationProcess = new QProcess();
#ifdef WIN32
    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert("PATH", environment.value("Path") + ";" + QString(Helper::OpenModelicaHome).append("MinGW\\bin"));
    mpSimulationProcess->setProcessEnvironment(environment);
#endif
    mpSimulationProcess->setWorkingDirectory(fileInfo.absolutePath());
    mpSimulationProcess->setProcessChannelMode(QProcess::MergedChannels);
    mpProgressDialog->getCancelSimulationButton()->setEnabled(true);
    mpProgressDialog->setText(tr("Running Simulation.\nPlease wait for a while."));
    // set progress bar range
    mpProgressDialog->getProgressBar()->setRange(0, 100);       // the simulation runtime sends double value until 100.
    mpProgressDialog->getProgressBar()->setTextVisible(true);
    mpParentMainWindow->mpStatusBar->showMessage(tr("Running Simulation"));
    // start the executable with the tcp server so it can listen to the simulation progress messages
    QTcpSocket *sock = 0;
    QTcpServer server;
    const int SOCKMAXLEN = 4096;
    char buf[SOCKMAXLEN];
    server.listen(QHostAddress(QHostAddress::LocalHost));
    QStringList args(QString("-port=").append(QString::number(server.serverPort())));
    args << simulationFlags;
    // start the executable
    mpSimulationProcess->start(file,args);
    while (mpSimulationProcess->state() == QProcess::Starting || mpSimulationProcess->state() == QProcess::Running)
    {
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
    // show simulation output
    QString standardOutput = QString(mpSimulationProcess->readAllStandardOutput());
    if (!standardOutput.isEmpty())
    {
      SimulationOutputDialog *pSimulationOutputDialog;
      if (mpSimulationProcess->error() != QProcess::UnknownError)
        standardOutput = QString(mpSimulationProcess->errorString()).append("\n\n").append(standardOutput);
      pSimulationOutputDialog = new SimulationOutputDialog(projectTab->mModelNameStructure, standardOutput, mpParentMainWindow);
      int x = mpParentMainWindow->width() < 550 ? pSimulationOutputDialog->x() : mpParentMainWindow->width() - 550;
      int y = mpParentMainWindow->height() < 300 ? pSimulationOutputDialog->y() : mpParentMainWindow->height() - 300;
      pSimulationOutputDialog->setGeometry(x, y, pSimulationOutputDialog->width(), pSimulationOutputDialog->height());
      pSimulationOutputDialog->show();
    }
    // we set the Progress Dialog box to hide when we cancel the simulation, so don't show user the plotting view just return.
    if (mpProgressDialog->isHidden() || mpSimulationProcess->exitStatus() != QProcess::NormalExit)
      return;
    // read the output file
    QString output_file = projectTab->mModelNameStructure;
    if (!mpFileNameTextBox->text().isEmpty())
      output_file = mpFileNameTextBox->text().trimmed();
    // if simualtion output format is not plt, csv and mat then dont show plot window.
    QRegExp regExp("\\b(mat|plt|csv)\\b");
    if (regExp.indexIn(mpOutputFormatComboBox->currentText()) != -1)
    {
      PlotWidget *pPlotWidget = mpParentMainWindow->mpPlotWidget;
      OMCProxy *pOMCProxy = mpParentMainWindow->mpOMCProxy;
      QList<QString> list;
      list = pOMCProxy->readSimulationResultVars(QString(output_file).append("_res.").append(mpOutputFormatComboBox->currentText()));
      // close the simulation result file.
      pOMCProxy->closeSimulationResultFile();
      emit showPlottingView();
      pPlotWidget->addPlotVariablestoTree(QString(output_file).append("_res.").append(mpOutputFormatComboBox->currentText()),list);
      mpParentMainWindow->mpPlotDockWidget->show();
    }
  }
}

//! Used for interactive simulation
//! Sends the buildModel command to OMC.
//! @param simulationParameters a comma seperated list of simulation parameters.
//! @param simulationFlags a list of simulation flags for the simulation executable.
void SimulationWidget::buildModel(QString simulationParameters, QStringList simulationFlags)
{
  ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();
  if (mpParentMainWindow->mpOMCProxy->buildModel(projectTab->mModelNameStructure, simulationParameters))
  {
    QString msg = tr("Starting Interactive Simulation Server");
    mpProgressDialog->setText(msg);
    mpParentMainWindow->mpStatusBar->showMessage(msg);
    // read the file path according to the file prefix variable
    QString file;
    if (mpFileNameTextBox->text().isEmpty())
    {
      file = QString(mpParentMainWindow->mpOMCProxy->changeDirectory()).append("/").append(projectTab->mModelNameStructure);
    }
    else
    {
      file = QString(mpParentMainWindow->mpOMCProxy->changeDirectory()).append("/").append(mpFileNameTextBox->text());
    }

    file = file.replace("//", "/");
    // if built is successfull create a tab of interactive simulation
    InteractiveSimulationTab *pInteractiveSimulationTab;
    pInteractiveSimulationTab = new InteractiveSimulationTab(file, mpParentMainWindow->mpInteractiveSimualtionTabWidget);
    if (mpFileNameTextBox->text().isEmpty())
      mpParentMainWindow->mpInteractiveSimualtionTabWidget->addNewInteractiveSimulationTab(pInteractiveSimulationTab,
                                                                                           projectTab->mModelNameStructure);
    else
      mpParentMainWindow->mpInteractiveSimualtionTabWidget->addNewInteractiveSimulationTab(pInteractiveSimulationTab,
                                                                                           mpFileNameTextBox->text());
  }
}

//! Saves the simulation options in the model.
void SimulationWidget::saveSimulationOptions()
{
  if (!mpSaveSimulationCheckbox->isChecked())
    return;

  ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();
  QString annotationString;

  // create simulations options annotation
  annotationString.append("annotate=experiment(");
  annotationString.append("StartTime=").append(mpStartTimeTextBox->text()).append(",");
  annotationString.append("StopTime=").append(mpStopTimeTextBox->text()).append(",");
  annotationString.append("Tolerance=").append(mpToleranceTextBox->text());
  annotationString.append(")");
  // send the simulations options annotation to OMC
  mpParentMainWindow->mpOMCProxy->addClassAnnotation(projectTab->mModelNameStructure, annotationString);
  projectTab->mpModelicaEditor->setPlainText(mpParentMainWindow->mpOMCProxy->list(projectTab->mModelNameStructure));
}

//! @class ProgressDialog
//! @brief Shows a progress dialog while compiling and running a simulation.

//! Constructor
//! @param pParent is the pointer to SimulationWidget.
ProgressDialog::ProgressDialog(SimulationWidget *pParent)
  : QDialog(pParent, Qt::FramelessWindowHint | Qt::WindowTitleHint)
{
  setWindowModality(Qt::WindowModal);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::simulation));
  // create heading label
  mpText = new QLabel;
  mpText->setAlignment((Qt::AlignHCenter));
  mpCancelSimulationButton = new QPushButton(tr("Cancel Simulation"));
  connect(mpCancelSimulationButton, SIGNAL(clicked()), pParent, SLOT(cancelSimulation()));
  mpProgressBar = new QProgressBar;
  mpProgressBar->setRange(0, 0);
  mpProgressBar->setTextVisible(false);
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  // layout the items
  QVBoxLayout *mainLayout = new QVBoxLayout;
  mainLayout->addWidget(mpText);
  mainLayout->addWidget(mpProgressBar);
  mainLayout->addWidget(mpCancelSimulationButton, 0, Qt::AlignRight);
  setLayout(mainLayout);
}

//! @return the pointer to mpProgressBar
QProgressBar* ProgressDialog::getProgressBar()
{
  return mpProgressBar;
}

//! @return the pointer to mpCancelSimulationButton
QPushButton* ProgressDialog::getCancelSimulationButton()
{
  return mpCancelSimulationButton;
}

//! Sets the text message for progress dialog
//! @param text the message to set.
void ProgressDialog::setText(QString text)
{
  mpText->setText(text);
  update();
}

SimulationOutputDialog::SimulationOutputDialog(QString modelName, QString simulationOutput, QWidget *pParent)
  : QDialog(pParent, Qt::WindowTitleHint)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(modelName).append(" ").append(tr("Simulation Output")));
  setMinimumSize(550, 300);
  // Simulation Output TextBox
  mpSimulationOutputTextBox = new QPlainTextEdit;
  mpSimulationOutputTextBox->setPlainText(simulationOutput);
  // Close Button
  mpCloseButton = new QPushButton(tr("Close"));
  connect(mpCloseButton, SIGNAL(clicked()), SLOT(close()));
  // layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->addWidget(mpSimulationOutputTextBox);
  pMainLayout->addWidget(mpCloseButton, 0, Qt::AlignRight);
  setLayout(pMainLayout);
}
