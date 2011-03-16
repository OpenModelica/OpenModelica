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

SimulationWidget::SimulationWidget(MainWindow *pParent)
    : QDialog(pParent, Qt::WindowTitleHint)
{
    setWindowTitle(QString(Helper::applicationName).append(" - Simulation"));
    setMinimumSize(375, 350);
    mpParentMainWindow = pParent;

    setUpForm();

    mpProgressDialog = new ProgressDialog(this);
}

SimulationWidget::~SimulationWidget()
{
    delete mpProgressDialog;
}

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

    gridOutputIntervalLayout->addWidget(mpNumberofIntervalLabel, 0, 0);
    gridOutputIntervalLayout->addWidget(mpNumberofIntervalsTextBox, 0, 1);
    mpOutputIntervalGroup->setLayout(gridOutputIntervalLayout);

    // Integration Interval
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

    gridIntegrationLayout->addWidget(mpMethodLabel, 0, 0);
    gridIntegrationLayout->addWidget(mpMethodComboBox, 0, 1);
    gridIntegrationLayout->addWidget(mpToleranceLabel, 1, 0);
    gridIntegrationLayout->addWidget(mpToleranceTextBox, 1, 1);
    gridIntegrationLayout->addWidget(mpOutputFormatLabel, 2, 0);
    gridIntegrationLayout->addWidget(mpOutputFormatComboBox, 2, 1);
    gridIntegrationLayout->addWidget(mpFileNameLabel, 3, 0);
    gridIntegrationLayout->addWidget(mpFileNameTextBox, 3, 1);
    mpIntegrationGroup->setLayout(gridIntegrationLayout);

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
    connect(mpSimulateButton, SIGNAL(pressed()), this, SLOT(simulate()));
    mpCancelButton = new QPushButton(tr("Cancel"));
    mpCancelButton->setAutoDefault(false);
    connect(mpCancelButton, SIGNAL(pressed()), this, SLOT(reject()));

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
    mainLayout->addWidget(mpButtonBox, 5, 0);

    setLayout(mainLayout);
}

void SimulationWidget::initializeFields()
{
    // depending on the mIsInteractive flag change the heading and disable start and stop times
    if (mIsInteractive)
    {
        setWindowTitle(QString(Helper::applicationName).append(" - Interactive Simulation"));
        mpSimulationHeading->setText(tr("Interactive Simulation"));
        mpSimulationIntervalGroup->setDisabled(true);
        mpNumberofIntervalsTextBox->setText(tr("5"));
        mpMethodComboBox->setCurrentIndex(0);
        mpMethodComboBox->setDisabled(true);
        return;
    }
    else
    {
        setWindowTitle(QString(Helper::applicationName).append(" - Simulation"));
        mpSimulationHeading->setText(tr("Simulation"));
        mpSimulationIntervalGroup->setDisabled(false);
        mpMethodComboBox->setDisabled(false);
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
    mpMethodComboBox->setCurrentIndex(mpMethodComboBox->findText(StringHandler::removeFirstLastQuotes(
                                                                 simulationOptionsList.at(4))));
    mpFileNameTextBox->setText(tr(""));
}

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
            simualtionParameters.append(tr(", method=")).append("\"")
                    .append(mpMethodComboBox->currentText()).append("\"");
        if (!mpToleranceTextBox->text().isEmpty())
            simualtionParameters.append(tr(", tolerance=")).append(mpToleranceTextBox->text());
        simualtionParameters.append(tr(", outputFormat=")).append("\"")
                            .append(mpOutputFormatComboBox->currentText()).append("\"");
        if (!mpFileNameTextBox->text().isEmpty())
            simualtionParameters.append(tr(", fileNamePrefix=")).append("\"")
                            .append(mpFileNameTextBox->text()).append("\"");

        ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();

        if (!projectTab)
        {
            mpParentMainWindow->mpMessageWidget->printGUIWarningMessage(GUIMessages::getMessage(
                                                                        GUIMessages::NO_OPEN_MODEL));
            accept();
            return;
        }
        // show the progress bar
        mpProgressDialog->setText(Helper::running_Simulation);
        mpProgressDialog->show();
        mpParentMainWindow->mpProgressBar->setRange(0, 0);
        mpParentMainWindow->showProgressBar();
        mpParentMainWindow->mpStatusBar->showMessage(Helper::running_Simulation);

        if (mIsInteractive)
            buildModel(simualtionParameters);
        else
            simulateModel(simualtionParameters);

        mpParentMainWindow->mpStatusBar->clearMessage();
        mpParentMainWindow->hideProgressBar();
        mpProgressDialog->hide();
        accept();
    }
}

bool SimulationWidget::validate()
{
    if (mpStartTimeTextBox->text().isEmpty())
        mpParentMainWindow->mpMessageWidget->printGUIWarningMessage(GUIMessages::getMessage(
                                                                    GUIMessages::NO_SIMULATION_STARTTIME));

    if (mpStopTimeTextBox->text().isEmpty())
    {
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(
                                                                  GUIMessages::NO_SIMULATION_STOPTIME));
        return false;
    }

    if (mpStopTimeTextBox->text().toDouble() <= mpStartTimeTextBox->text().toDouble())
    {
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(
                                                                  GUIMessages::SIMULATION_STARTTIME_LESSTHAN_STOPTIME));
        return false;
    }

    return true;
}

void SimulationWidget::simulateModel(QString simulationParameters)
{
    ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();

    if (!mpParentMainWindow->mpOMCProxy->simulate(projectTab->mModelNameStructure, simulationParameters))
    {
        QString result = mpParentMainWindow->mpOMCProxy->getResult();
        int startPos = result.indexOf("messages");
        int endPos = result.indexOf("timeFrontend");
        // add 10 to startPos to remove 'messages = ' word and remove -16 to remove timeFrontend from the end
        QString message = result.mid(startPos + 10, (endPos - startPos) - 16);
        message = StringHandler::removeFirstLastQuotes(message).trimmed();
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(QString("Unable to simulate the Model '")
                                                                  .append(projectTab->mModelNameStructure)
                                                                  .append("'\n")
                                                                  .append(QString(GUIMessages::getMessage(
                                                                  GUIMessages::ERROR_OCCURRED))
                                                                  .arg(message)));
    }
    else
    {
        QString result = mpParentMainWindow->mpOMCProxy->getResult();
        int startPos = result.indexOf("messages");
        int endPos = result.indexOf("timeFrontend");
        // add 10 to startPos to remove 'messages = ' word and remove -16 to remove timeFrontend from the end
        QString message = result.mid(startPos + 10, (endPos - startPos) - 16);
        message = StringHandler::removeFirstLastQuotes(message).trimmed();
        if (!message.isEmpty())
            message = QString(" with message:\n").append(message);

        QString output_file = projectTab->mModelNameStructure;
        if (!mpFileNameTextBox->text().isEmpty())
            output_file = mpFileNameTextBox->text().trimmed();
        // if simualtion output format is not plt and mat then dont show plot window.
        // only show user the message that result file is created.
        QRegExp regExp("\\b(mat|plt)\\b");
        if (regExp.indexIn(mpOutputFormatComboBox->currentText()) != -1)
        {
            PlotWidget *pPlotWidget = mpParentMainWindow->mpPlotWidget;
            OMCProxy *pOMCProxy = mpParentMainWindow->mpOMCProxy;
            QList<QString> list = pOMCProxy->readSimulationResultVars(QString(output_file).append("_res.")
                                                                     .append(mpOutputFormatComboBox->currentText()));
            pPlotWidget->addPlotVariablestoTree(QString(output_file).append("_res.")
                                                .append(mpOutputFormatComboBox->currentText()),list);
            mpParentMainWindow->plotdock->show();
            mpParentMainWindow->mpMessageWidget->printGUIInfoMessage(QString("Simulated '").append(projectTab->mModelNameStructure)
                                                                     .append("' successfully!").append(message));
        }
        else if (mpOutputFormatComboBox->currentText().compare("empty") != 0)
        {
            mpParentMainWindow->mpMessageWidget->printGUIInfoMessage(QString("Simulation result file is created at ")
                                                                     .append(StringHandler::removeFirstLastQuotes(mpParentMainWindow->mpOMCProxy->changeDirectory()))
                                                                     .append("/").append(output_file).append("_res.")
                                                                     .append(mpOutputFormatComboBox->currentText())
                                                                     .append(message));
        }
    }
}

void SimulationWidget::buildModel(QString simulationParameters)
{
    ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();

    if (!mpParentMainWindow->mpOMCProxy->buildModel(projectTab->mModelNameStructure, simulationParameters))
    {
        QString result = StringHandler::removeFirstLastQuotes(mpParentMainWindow->mpOMCProxy->getResult());
        int startPos = result.indexOf("Error:");
        // add 7 to startPos to remove 'Error: ' word
        QString message = result.mid(startPos + 7);
        message = StringHandler::removeFirstLastQuotes(message).trimmed();
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(QString("Unable to simulate the Model '")
                                                                  .append(projectTab->mModelNameStructure)
                                                                  .append("'\n")
                                                                  .append(QString(GUIMessages::getMessage(
                                                                  GUIMessages::ERROR_OCCURRED))
                                                                  .arg(message)));
    }
    else
    {
        mpProgressDialog->setText(Helper::starting_interactive_simulation_server);
        mpParentMainWindow->mpStatusBar->showMessage(Helper::starting_interactive_simulation_server);

        // read the file path according to the file prefix variable
        QString file;
        if (mpFileNameTextBox->text().isEmpty())
        {
            file = QString(Helper::tmpPath.replace("\\", "/")).append("/").append(projectTab->mModelNameStructure);
        }
        else
        {
            file = QString(Helper::tmpPath.replace("\\", "/")).append("/").append(mpFileNameTextBox->text());
        }

        file = file.replace("//", "/");
        // if built is successfull create a tab of interactive simulation
        InteractiveSimulationTab *pInteractiveSimulationTab;
        pInteractiveSimulationTab = new InteractiveSimulationTab(file,
                                                                 mpParentMainWindow->mpInteractiveSimualtionTabWidget);
        if (mpFileNameTextBox->text().isEmpty())
            mpParentMainWindow->mpInteractiveSimualtionTabWidget->addNewInteractiveSimulationTab(pInteractiveSimulationTab,
                                                                                                 projectTab->mModelNameStructure);
        else
            mpParentMainWindow->mpInteractiveSimualtionTabWidget->addNewInteractiveSimulationTab(pInteractiveSimulationTab,
                                                                                                 mpFileNameTextBox->text());
    }
}

ProgressDialog::ProgressDialog(SimulationWidget *pParent)
    : QDialog(pParent, Qt::FramelessWindowHint | Qt::WindowTitleHint)
{
    setWindowModality(Qt::WindowModal);
    setWindowTitle(QString(Helper::applicationName).append(" - Simulation"));
    // create heading label
    mpText = new QLabel;
    mpText->setAlignment((Qt::AlignHCenter));
    QProgressBar *progressBar = new QProgressBar;
    progressBar->setRange(0, 0);
    progressBar->setTextVisible(false);
    progressBar->setAlignment(Qt::AlignHCenter);
    // layout the items
    QVBoxLayout *mainLayout = new QVBoxLayout;
    mainLayout->addWidget(mpText);
    mainLayout->addWidget(progressBar);
    setLayout(mainLayout);
}

void ProgressDialog::setText(QString text)
{
    mpText->setText(text);
    update();
}
/*
ComponentBrowserNode::ComponentBrowserNode(QString name, QString className, QString parentName, QTreeWidget *pParent)
    : QTreeWidgetItem(pParent)
{
    mName = name;
    mClassName = className;
    mParentName = parentName;
    mNameStructure = mParentName + mName;

    setText(0, mName);
    setToolTip(0, mClassName);
    setChildIndicatorPolicy(QTreeWidgetItem::ShowIndicator);
}

QString ComponentBrowserNode::getName()
{
    return mName;
}

QString ComponentBrowserNode::getClassName()
{
    return mClassName;
}

QString ComponentBrowserNode::getParentName()
{
    return mParentName;
}

QString ComponentBrowserNode::getNameStructure()
{
    return mNameStructure;
}

ComponentBrowser::ComponentBrowser(MainWindow *pParent)
    : QTreeWidget(pParent)
{
    mpParentMainWindow = pParent;

    setFrameShape(QFrame::NoFrame);
    setHeaderHidden(true);
    setColumnCount(1);
    setIndentation(Helper::treeIndentation);

    connect(this, SIGNAL(itemExpanded(QTreeWidgetItem*)), SLOT(getComponents(QTreeWidgetItem*)));
}

ComponentBrowser::~ComponentBrowser()
{

}

void ComponentBrowser::addComponents(QString className, QString parentStructure)
{
    QList<ComponentsProperties*> components = mpParentMainWindow->mpOMCProxy->getComponents(className);

    foreach (ComponentsProperties *pComponent, components)
    {
        ComponentBrowserNode *newTreePost;
        if (parentStructure.isEmpty())
        {
            newTreePost = new ComponentBrowserNode(pComponent->getName(), pComponent->getClassName(),
                                                   tr(""), this);
            insertTopLevelItem(0, newTreePost);
        }
        else
        {
            newTreePost = new ComponentBrowserNode(pComponent->getName(), pComponent->getClassName(),
                                                   parentStructure);
            ComponentBrowserNode *treeNode = getNode(parentStructure);
            treeNode->addChild(newTreePost);
        }
        if (mpParentMainWindow->mpOMCProxy->getComponents(pComponent->getClassName()).isEmpty())
        {
            newTreePost->setChildIndicatorPolicy(QTreeWidgetItem::DontShowIndicator);
            newTreePost->setFlags(Qt::ItemIsUserCheckable | Qt::ItemIsEnabled);
            newTreePost->setCheckState(0, Qt::Unchecked);
        }
        mComponentBrowserNodesList.append(newTreePost);
    }
}

ComponentBrowserNode* ComponentBrowser::getNode(QString name)
{
    foreach (ComponentBrowserNode *node, mComponentBrowserNodesList)
    {
        if (node->getNameStructure().compare(name) == 0)
            return node;
    }
    return 0;
}

bool ComponentBrowser::isTreeItemLoaded(ComponentBrowserNode *item)
{
    foreach (ComponentBrowserNode *node, mExpandedNodesList)
        if (node == item)
            return true;
    return false;
}

void ComponentBrowser::getComponents(QTreeWidgetItem *item)
{
    ComponentBrowserNode *node = dynamic_cast<ComponentBrowserNode*>(item);
    if (!isTreeItemLoaded(node))
    {
        mExpandedNodesList.append(node);
        addComponents(node->getClassName(), node->getNameStructure());
    }
}
*/
