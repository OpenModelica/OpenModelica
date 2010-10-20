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

SimulationWidget::SimulationWidget(MainWindow *parent)
    : QDialog(parent, Qt::WindowTitleHint)
{
    setWindowTitle(QString(Helper::applicationName).append(" - Simulation"));
    setMinimumSize(375, 370);
    mpParentMainWindow = parent;
}

SimulationWidget::~SimulationWidget()
{

}

void SimulationWidget::setUpForm()
{
    mpSimulationHeading = new QLabel(tr("Simulation Center"));
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
    mpOutputIntervalLabel = new QLabel(tr("Output Interval:"));
    mpOutputIntervalTextBox = new QLineEdit;

    gridOutputIntervalLayout->addWidget(mpNumberofIntervalLabel, 0, 0);
    gridOutputIntervalLayout->addWidget(mpNumberofIntervalsTextBox, 0, 1);
    gridOutputIntervalLayout->addWidget(mpOutputIntervalLabel, 1, 0);
    gridOutputIntervalLayout->addWidget(mpOutputIntervalTextBox, 1, 1);
    mpOutputIntervalGroup->setLayout(gridOutputIntervalLayout);
    // Integration Interval
    QGridLayout *gridIntegrationLayout = new QGridLayout;
    mpIntegrationGroup = new QGroupBox(tr("Integration"));
    mpMethodLabel = new QLabel(tr("Method:"));
    mpMethodComboBox = new QComboBox;
    mpMethodComboBox->addItems(Helper::ModelicaSimulationMethods.toLower().split(","));
    mpToleranceLabel = new QLabel(tr("Tolerance:"));
    mpToleranceTextBox = new QLineEdit(tr("0.0001"));
    mpFixedStepSizeLabel = new QLabel(tr("Fixed Step Size:"));
    mpFixedStepSizeTextBox = new QLineEdit;

    gridIntegrationLayout->addWidget(mpMethodLabel, 0, 0);
    gridIntegrationLayout->addWidget(mpMethodComboBox, 0, 1);
    gridIntegrationLayout->addWidget(mpToleranceLabel, 1, 0);
    gridIntegrationLayout->addWidget(mpToleranceTextBox, 1, 1);
    gridIntegrationLayout->addWidget(mpFixedStepSizeLabel, 2, 0);
    gridIntegrationLayout->addWidget(mpFixedStepSizeTextBox, 2, 1);
    mpIntegrationGroup->setLayout(gridIntegrationLayout);

    // Add the validators
    QDoubleValidator *doubleValidator = new QDoubleValidator(this);
    doubleValidator->setBottom(0);
    mpStartTimeTextBox->setValidator(doubleValidator);
    mpStopTimeTextBox->setValidator(doubleValidator);
    mpNumberofIntervalsTextBox->setValidator(doubleValidator);
    mpOutputIntervalTextBox->setValidator(doubleValidator);
    mpToleranceTextBox->setValidator(doubleValidator);

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

void SimulationWidget::show()
{
    setVisible(true);
}

void SimulationWidget::simulate()
{
    if (validate())
    {
        QString simualtionParameters;
        if (mpStartTimeTextBox->text().isEmpty())
            simualtionParameters.append(tr("startTime=0"));
        else
            simualtionParameters.append(tr("startTime=")).append(mpStartTimeTextBox->text());
        simualtionParameters.append(tr(", stopTime=")).append(mpStopTimeTextBox->text());
        if (mpNumberofIntervalsTextBox->text().isEmpty())
            simualtionParameters.append(tr(", numberOfIntervals=500"));
        else
            simualtionParameters.append(tr(", numberOfIntervals=")).append(mpNumberofIntervalsTextBox->text());
        if (!mpOutputIntervalTextBox->text().isEmpty())
            simualtionParameters.append(tr(", outputInterval=")).append(mpOutputIntervalTextBox->text());
        simualtionParameters.append(tr(", method=")).append(mpMethodComboBox->currentText());
        if (!mpToleranceTextBox->text().isEmpty())
            simualtionParameters.append(tr(", tolerance=")).append(mpToleranceTextBox->text());
        if (!mpFixedStepSizeTextBox->text().isEmpty())
            simualtionParameters.append(tr(", fixedStepSize=")).append(mpFixedStepSizeTextBox->text());

        ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();

        if (!projectTab)
        {
            mpParentMainWindow->mpMessageWidget->printGUIWarningMessage(GUIMessages::getMessage(
                                                                        GUIMessages::NO_OPEN_MODEL));
            accept();
            return;
        }

        // show simulation progress bar
        int endtime = mpNumberofIntervalsTextBox->text().toInt() * mpStopTimeTextBox->text().toInt();
        QProgressDialog progressBar(this, Qt::WindowTitleHint);
        progressBar.setMinimum(0);
        progressBar.setMaximum(endtime);
        progressBar.setLabelText(tr("Running Simulation"));
        progressBar.setCancelButton(0);
        progressBar.setWindowModality(Qt::WindowModal);
        progressBar.setWindowTitle(QString(Helper::applicationName).append(" - Simulation"));
        progressBar.show();
        progressBar.setValue(endtime/2);

        mpParentMainWindow->mpOMCProxy->changeDirectory(QString(Helper::OpenModelicaHome).append("\\tmp"));
        if (!mpParentMainWindow->mpOMCProxy->simulate(projectTab->mModelNameStructure, simualtionParameters))
        {
            mpParentMainWindow->mpMessageWidget->printGUIErrorMessage("Enable to simulate the Model '" +
                                                                      projectTab->mModelNameStructure + "'");
            accept();
        }
        else
        {
            mpParentMainWindow->mpPlotWidget->readPlotVariables(QString(projectTab->mModelNameStructure).append("_res.plt"));
            mpParentMainWindow->plotdock->show();
            mpParentMainWindow->mpMessageWidget->printGUIMessage("Simulated '" +
                                                                  projectTab->mModelNameStructure + "' successfully!");
            progressBar.setValue(endtime);
            progressBar.hide();
            accept();
        }
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

    if (mpStopTimeTextBox->text().toInt() <= mpStartTimeTextBox->text().toInt())
    {
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(
                                                                  GUIMessages::SIMULATION_STARTTIME_LESSTHAN_STOPTIME));
        return false;
    }

    return true;
}
