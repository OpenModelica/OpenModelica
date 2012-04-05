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
  setMinimumSize(400, 475);
  mpParentMainWindow = pParent;
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
  mpMethodComboBox->addItems(Helper::ModelicaSimulationMethods.toLower().split(","));
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
  mpSimulationTabWidget->addTab(mpOutputTab, Helper::output);
  // Simulation Flags Tab
  mpSimulationFlagsTab = new QWidget;
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
  // Logging
  mpLogStatsCheckBox = new QCheckBox(tr("Stats"));
  mpLogInitializationCheckBox = new QCheckBox(tr("Initialization"));
  mpLogResultInitializationCheckBox = new QCheckBox(tr("Result Initialization"));
  mpLogSolverCheckBox = new QCheckBox(tr("Solver"));
  mpLogEventsCheckBox = new QCheckBox(tr("Events"));
  mpLogNonLinearSystemsCheckBox = new QCheckBox(tr("Non Linear Systems"));
  mpLogZeroCrossingsCheckBox = new QCheckBox(tr("Zero Crossings"));
  mpLogDebugCheckBox = new QCheckBox(tr("Debug"));
  // layout for logging group
  QGridLayout *pLoggingGroupLayout = new QGridLayout;
  pLoggingGroupLayout->addWidget(mpLogStatsCheckBox);
  pLoggingGroupLayout->addWidget(mpLogInitializationCheckBox);
  pLoggingGroupLayout->addWidget(mpLogResultInitializationCheckBox);
  pLoggingGroupLayout->addWidget(mpLogSolverCheckBox);
  pLoggingGroupLayout->addWidget(mpLogEventsCheckBox);
  pLoggingGroupLayout->addWidget(mpLogNonLinearSystemsCheckBox);
  pLoggingGroupLayout->addWidget(mpLogZeroCrossingsCheckBox);
  pLoggingGroupLayout->addWidget(mpLogDebugCheckBox);
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
  pSimulationFlagsTabLayout->addWidget(mpLoggingGroup, 5, 0, 1, 3);
  mpSimulationFlagsTab->setLayout(pSimulationFlagsTabLayout);
  // add Output Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpSimulationFlagsTab, tr("Simulation Flags"));
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
      simulationFlags.append("-f");
      simulationFlags.append(mpModelSetupFileTextBox->text());
    }
    // setup initiaization method flag
    if (!mpInitializationMethodComboBox->currentText().isEmpty())
    {
      simulationFlags.append("-iim");
      simulationFlags.append(mpInitializationMethodComboBox->currentText());
    }
    // setup Optimization Method flag
    if (!mpOptimizationMethodComboBox->currentText().isEmpty())
    {
      simulationFlags.append("-iom");
      simulationFlags.append(mpOptimizationMethodComboBox->currentText());
    }
    // setup Equation System Initialization file flag
    if (!mpEquationSystemInitializationFileTextBox->text().isEmpty())
    {
      simulationFlags.append("-iif");
      simulationFlags.append(mpEquationSystemInitializationFileTextBox->text());
    }
    // setup Equation System Initialization time flag
    if (!mpEquationSystemInitializationTimeTextBox->text().isEmpty())
    {
      simulationFlags.append("-iit");
      simulationFlags.append(mpEquationSystemInitializationTimeTextBox->text());
    }
    // setup Logging flags
    if (mpLogStatsCheckBox->isChecked() || mpLogInitializationCheckBox->isChecked() || mpLogResultInitializationCheckBox->isChecked()
        || mpLogSolverCheckBox->isChecked() || mpLogEventsCheckBox->isChecked() || mpLogNonLinearSystemsCheckBox->isChecked()
        || mpLogZeroCrossingsCheckBox->isChecked() || mpLogDebugCheckBox->isChecked())
    {
      simulationFlags.append("-lv");
      if (mpLogStatsCheckBox->isChecked())
        simulationFlags.append("LOG_STATS");
      if (mpLogInitializationCheckBox->isChecked())
        simulationFlags.append("LOG_INIT");
      if (mpLogResultInitializationCheckBox->isChecked())
        simulationFlags.append("LOG_RES_INIT");
      if (mpLogSolverCheckBox->isChecked())
        simulationFlags.append("LOG_SOLVER");
      if (mpLogEventsCheckBox->isChecked())
        simulationFlags.append("LOG_EVENTS");
      if (mpLogNonLinearSystemsCheckBox->isChecked())
        simulationFlags.append("LOG_NONLIN_SYS");
      if (mpLogZeroCrossingsCheckBox->isChecked())
        simulationFlags.append("LOG_ZEROCROSSINGS");
      if (mpLogDebugCheckBox->isChecked())
        simulationFlags.append("LOG_DEBUG");
    }
    // before simulating save the simulation options
    saveSimulationOptions();
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
    server.listen(QHostAddress("127.0.0.1"));
    QStringList args("-port");
    args << QString::number(server.serverPort()) << simulationFlags;
    // start the executable
    mpSimulationProcess->start(file,args);
    while (mpSimulationProcess->state() == QProcess::Starting || mpSimulationProcess->state() == QProcess::Running)
    {
      if (!sock && server.hasPendingConnections()) {
        sock = server.nextPendingConnection();
      } else if (!sock) {
        server.waitForNewConnection(100,0);
      } else {
        while (sock->readLine(buf,SOCKMAXLEN) > 0) {
          char *msg = 0;
          double d = strtod(buf, &msg);
          if (msg == buf || *msg != ' ') {
            // do we really need to take care of this communication error?????
            //fprintf(stderr, "TODO: OMEdit GUI: COMM ERROR '%s'", sg);
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

    // we set the Progress Dialog box to hide when we cancel the simulation, so don't show user the plotting view just return.
    if (mpProgressDialog->isHidden())
      return;
    if (mpSimulationProcess->exitCode() != 0 || mpSimulationProcess->exitStatus() == QProcess::CrashExit)
    {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED)
                            .arg(mpSimulationProcess->errorString().append(" ").append(mpSimulationProcess->readAllStandardError())),Helper::ok);
      return;
    }
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
