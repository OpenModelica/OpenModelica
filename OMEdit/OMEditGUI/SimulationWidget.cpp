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

#include "SimulationWidget.h"
#include "OMCThread.h"

//! @class SimulationWidget
//! @brief Displays a dialog with simulation options for the current model.

//! Constructor
//! @param pParent is the pointer to MainWindow.
SimulationWidget::SimulationWidget(MainWindow *pParent)
    : QDialog(pParent, Qt::WindowTitleHint)
{
    setWindowTitle(QString(Helper::applicationName).append(" - Simulation"));
    setMinimumSize(375, 440);
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
    mpSimulationHeading = new QLabel(tr("Simulation"));
    mpSimulationHeading->setFont(QFont("", Helper::headingFontSize));
    line = new QFrame();
    line->setFrameShape(QFrame::HLine);
    line->setFrameShadow(QFrame::Sunken);
    // Simulation Interval
    QGridLayout *gridSimulationIntervalLayout = new QGridLayout;
    mpSimulationIntervalGroup = new QGroupBox(tr("Simulation Interval"));
    mpStartTimeLabel = new QLabel(tr("Start Time:"));
    mpStartTimeTextBox = new QLineEdit(tr("0"));
    mpStopTimeLabel = new QLabel(tr("Stop Time:"));
    mpStopTimeTextBox = new QLineEdit(tr("1"));
    // set the layout for simulation interval groupbox
    gridSimulationIntervalLayout->addWidget(mpStartTimeLabel, 0, 0);
    gridSimulationIntervalLayout->addWidget(mpStartTimeTextBox, 0, 1);
    gridSimulationIntervalLayout->addWidget(mpStopTimeLabel, 1, 0);
    gridSimulationIntervalLayout->addWidget(mpStopTimeTextBox, 1, 1);
    mpSimulationIntervalGroup->setLayout(gridSimulationIntervalLayout);
    // Output Interval
    QGridLayout *gridOutputIntervalLayout = new QGridLayout;
    mpOutputIntervalGroup = new QGroupBox(tr("Output Interval"));
    mpNumberofIntervalLabel = new QLabel(tr("Number of Intervals:"));
    mpNumberofIntervalsTextBox = new QLineEdit(tr("500"));
    // set the layout for output interval groupbox
    gridOutputIntervalLayout->addWidget(mpNumberofIntervalLabel, 0, 0);
    gridOutputIntervalLayout->addWidget(mpNumberofIntervalsTextBox, 0, 1);
    mpOutputIntervalGroup->setLayout(gridOutputIntervalLayout);
    // Integration
    QGridLayout *gridIntegrationLayout = new QGridLayout;
    mpIntegrationGroup = new QGroupBox(tr("Integration"));
    mpMethodLabel = new QLabel(tr("Method:"));
    mpMethodComboBox = new QComboBox;
    mpMethodComboBox->addItems(Helper::ModelicaSimulationMethods.toLower().split(","));
    mpToleranceLabel = new QLabel(tr("Tolerance:"));
    mpToleranceTextBox = new QLineEdit(tr("0.0001"));
    mpOutputFormatLabel = new QLabel(tr("Output Format:"));
    mpOutputFormatComboBox = new QComboBox;
    mpOutputFormatComboBox->addItems(Helper::ModelicaSimulationOutputFormats.toLower().split(","));
    mpFileNameLabel = new QLabel(tr("File Name (Optional):"));
    mpFileNameTextBox = new QLineEdit(tr(""));
    mpVariableFilterLabel = new QLabel(tr("Variable Filter (Optional):"));
    mpVariableFilterTextBox = new QLineEdit(tr(""));
    mpCflagsLabel = new QLabel(tr("Compiler Flags (Optional):"));
    mpCflagsTextBox = new QLineEdit(tr(""));
    // set the layout for integration groupbox
    gridIntegrationLayout->addWidget(mpMethodLabel, 0, 0);
    gridIntegrationLayout->addWidget(mpMethodComboBox, 0, 1);
    gridIntegrationLayout->addWidget(mpToleranceLabel, 1, 0);
    gridIntegrationLayout->addWidget(mpToleranceTextBox, 1, 1);
    gridIntegrationLayout->addWidget(mpOutputFormatLabel, 2, 0);
    gridIntegrationLayout->addWidget(mpOutputFormatComboBox, 2, 1);
    gridIntegrationLayout->addWidget(mpFileNameLabel, 3, 0);
    gridIntegrationLayout->addWidget(mpFileNameTextBox, 3, 1);
    gridIntegrationLayout->addWidget(mpVariableFilterLabel, 4, 0);
    gridIntegrationLayout->addWidget(mpVariableFilterTextBox, 4, 1);
    gridIntegrationLayout->addWidget(mpCflagsLabel, 5, 0);
    gridIntegrationLayout->addWidget(mpCflagsTextBox, 5, 1);
    mpIntegrationGroup->setLayout(gridIntegrationLayout);
    // save simulations options
    QGridLayout *gridSaveSimulationLayout = new QGridLayout;
    mpSaveSimulationGroup = new QGroupBox(tr("Save Simulation"));
    mpSaveSimulationCheckbox = new QCheckBox(tr("Save simulation settings inside model"));
    // set the layout for save simulation groupbox
    gridSaveSimulationLayout->addWidget(mpSaveSimulationCheckbox, 0, 0);
    mpSaveSimulationGroup->setLayout(gridSaveSimulationLayout);
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
    mpSimulateButton = new QPushButton(tr("Simulate!"));
    mpSimulateButton->setAutoDefault(true);
    connect(mpSimulateButton, SIGNAL(clicked()), this, SLOT(simulate()));
    mpCancelButton = new QPushButton(tr("Cancel"));
    mpCancelButton->setAutoDefault(false);
    connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
    // adds buttons to the button box
    mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    mpButtonBox->addButton(mpSimulateButton, QDialogButtonBox::ActionRole);
    mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
    // Create a layout
    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->addWidget(mpSimulationHeading, 0, 0);
    mainLayout->addWidget(line, 1, 0);
    mainLayout->addWidget(mpSimulationIntervalGroup, 2, 0);
    mainLayout->addWidget(mpOutputIntervalGroup, 3, 0);
    mainLayout->addWidget(mpIntegrationGroup, 4, 0);
    mainLayout->addWidget(mpSaveSimulationGroup, 5, 0);
    mainLayout->addWidget(mpButtonBox, 6, 0);
    setLayout(mainLayout);
}

//! Initializes the simulation dialog with the default values.
void SimulationWidget::initializeFields()
{
    // depending on the mIsInteractive flag change the heading and disable start and stop times
    if (mIsInteractive)
    {
        setWindowTitle(QString(Helper::applicationName).append(" - Interactive Simulation"));
        mpSimulationHeading->setText(tr("Interactive Simulation"));
        mpSimulationIntervalGroup->setDisabled(true);
        return;
    }
    else
    {
        setWindowTitle(QString(Helper::applicationName).append(" - Simulation"));
        mpSimulationHeading->setText(tr("Simulation"));
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
    mpFileNameTextBox->setText(tr(""));
    mpCflagsTextBox->setText(tr(""));
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

//! Slot activated when mpSimulateButton clicked signal is raised.
//! Reads the simulation options set by the user and sends them to OMC by calling buildModel.
void SimulationWidget::simulate()
{
    // check if user is already running one interactive simultation or not
    // beacuse only interactive simulation is required.
    if (mIsInteractive)
    {
        if (mpParentMainWindow->mpInteractiveSimualtionTabWidget->count() > 0)
        {
            QMessageBox::information(mpParentMainWindow, Helper::applicationName + " - Information",
                                     GUIMessages::getMessage(GUIMessages::INTERACTIVE_SIMULATION_RUNNIG), "OK");
            return;
        }
    }

    if (validate())
    {
        QString simualtionParameters;
        // if user is performing a simple simulation then take start and stop times
        if (!mIsInteractive)
        {
            if (mpStartTimeTextBox->text().isEmpty())
                simualtionParameters.append(tr("startTime=0.0"));
            else
                simualtionParameters.append(tr("startTime=")).append(mpStartTimeTextBox->text());
            simualtionParameters.append(tr(", stopTime=")).append(mpStopTimeTextBox->text()).append(",");
        }
        if (mpNumberofIntervalsTextBox->text().isEmpty())
            simualtionParameters.append(tr(" numberOfIntervals=500"));
        else
            simualtionParameters.append(tr(" numberOfIntervals=")).append(mpNumberofIntervalsTextBox->text());
        if (mpMethodComboBox->currentText().isEmpty())
            simualtionParameters.append(tr(", method=\"dassl\""));
        else
            simualtionParameters.append(tr(", method=")).append("\"").append(mpMethodComboBox->currentText()).append("\"");
        if (!mpToleranceTextBox->text().isEmpty())
            simualtionParameters.append(tr(", tolerance=")).append(mpToleranceTextBox->text());
        simualtionParameters.append(tr(", outputFormat=")).append("\"").append(mpOutputFormatComboBox->currentText()).append("\"");
        if (!mpFileNameTextBox->text().isEmpty())
            simualtionParameters.append(tr(", fileNamePrefix=")).append("\"").append(mpFileNameTextBox->text()).append("\"");
        if (!mpVariableFilterTextBox->text().isEmpty())
            simualtionParameters.append(tr(", variableFilter=")).append("\"").append(mpVariableFilterTextBox->text()).append("\"");
        if (!mpCflagsTextBox->text().isEmpty())
            simualtionParameters.append(tr(", cflags=")).append("\"").append(mpCflagsTextBox->text()).append("\"");

        ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();
        if (!projectTab)
        {
            mpParentMainWindow->mpMessageWidget->addGUIProblem(new ProblemItem("", false, 0, 0, 0, 0,
                                                                               GUIMessages::getMessage(GUIMessages::NO_OPEN_MODEL)
                                                                               .arg("simulate"), Helper::simulationKind, Helper::warningLevel,
                                                                               0, mpParentMainWindow->mpMessageWidget->mpProblem));
            accept();
            return;
        }
        // before simulating save the simulation options
        saveSimulationOptions();
        // show the progress bar
        mpProgressDialog->setText(Helper::compiling_Model_text);
        mpProgressDialog->getCancelSimulationButton()->setEnabled(false);
        mpProgressDialog->getProgressBar()->setRange(0, 0);
        mpProgressDialog->getProgressBar()->setTextVisible(false);
        mpProgressDialog->show();
        mpParentMainWindow->mpProgressBar->setRange(0, 0);
        mpParentMainWindow->showProgressBar();
        mpParentMainWindow->mpStatusBar->showMessage(Helper::compiling_Model);
        // interactive or non interactive
        if (mIsInteractive)
            buildModel(simualtionParameters);
        else
            simulateModel(simualtionParameters);
        // hide the progress bar
        mpParentMainWindow->mpStatusBar->clearMessage();
        mpParentMainWindow->hideProgressBar();
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
void SimulationWidget::simulateModel(QString simulationParameters)
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
        mpProgressDialog->setText(Helper::running_Simulation_text);
        // set progress bar range
        mpProgressDialog->getProgressBar()->setRange(0, 100);       // the simulation runtime sends double value until 100.
        mpProgressDialog->getProgressBar()->setTextVisible(true);
        mpParentMainWindow->mpStatusBar->showMessage(Helper::running_Simulation);
        // start the executable with the tcp server so it can listen to the simulation progress messages
        QTcpSocket *sock = 0;
        QTcpServer server;
        const int SOCKMAXLEN = 4096;
        char buf[SOCKMAXLEN];
        server.listen(QHostAddress("127.0.0.1"));
        QStringList args("-port");
        args << QString::number(server.serverPort());
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
        
        // we set the Progress Dialog box to hide when we cancel the simulation, so don't show user the plottin view just return.
        if (mpProgressDialog->isHidden())
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
            emit showPlottingView();
            pPlotWidget->addPlotVariablestoTree(QString(output_file).append("_res.").append(mpOutputFormatComboBox->currentText()),list);
            mpParentMainWindow->plotdock->show();
        }
    }
}

//! Used for interactive simulation
//! Sends the buildModel command to OMC.
//! @param simulationParameters a comma seperated list of simulation parameters.
void SimulationWidget::buildModel(QString simulationParameters)
{
    ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();
    if (mpParentMainWindow->mpOMCProxy->buildModel(projectTab->mModelNameStructure, simulationParameters))
    {
        mpProgressDialog->setText(Helper::starting_interactive_simulation_server);
        mpParentMainWindow->mpStatusBar->showMessage(Helper::starting_interactive_simulation_server);

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
    setWindowTitle(QString(Helper::applicationName).append(" - Simulation"));
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
