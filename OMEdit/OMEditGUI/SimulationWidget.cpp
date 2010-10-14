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
#include "ui_SimulationWidget.h"

SimulationWidget::SimulationWidget(MainWindow *parent)
    : QDialog(parent, Qt::WindowTitleHint), ui(new Ui::SimulationWidget)
{
    ui->setupUi(this);
    setWindowTitle(QString(Helper::applicationName).append(" - Simulation"));
    mpParentMainWindow = parent;

    ui->mpMethodComboBox->addItems(Helper::ModelicaSimulationMethods.toLower().split(","));

    QIntValidator *intValidator = new QIntValidator(this);
    intValidator->setBottom(0);
    ui->mpStartTimeTextBox->setValidator(intValidator);
    ui->mpStopTimeTextBox->setValidator(intValidator);
    ui->mpNumberofIntervalsTextBox->setValidator(intValidator);
    ui->mpOutputIntervalTextBox->setValidator(intValidator);

    QDoubleValidator *doubleValidator = new QDoubleValidator(this);
    doubleValidator->setBottom(0);
    ui->mpToleranceTextBox->setValidator(doubleValidator);
}

SimulationWidget::~SimulationWidget()
{
    delete ui;
}

void SimulationWidget::initializeFields()
{
    ui->mpStartTimeTextBox->setText(tr("0"));
    ui->mpStopTimeTextBox->setText(tr("1"));
    ui->mpNumberofIntervalsTextBox->setText(tr("500"));
    ui->mpOutputIntervalTextBox->clear();
    ui->mpMethodComboBox->clear();
    ui->mpMethodComboBox->addItems(Helper::ModelicaSimulationMethods.toLower().split(","));
    ui->mpToleranceTextBox->setText(tr("0.0001"));
    ui->mpFixedStepSizeTextBox->clear();
}

void SimulationWidget::show()
{
    initializeFields();
    setVisible(true);
}

void SimulationWidget::simulate()
{
    if (validate())
    {
        QString simualtionParameters;
        if (ui->mpStartTimeTextBox->text().isEmpty())
            simualtionParameters.append(tr("startTime=0"));
        else
            simualtionParameters.append(tr("startTime=")).append(ui->mpStartTimeTextBox->text());
        simualtionParameters.append(tr(", stopTime=")).append(ui->mpStopTimeTextBox->text());
        if (ui->mpNumberofIntervalsTextBox->text().isEmpty())
            simualtionParameters.append(tr(", numberOfIntervals=500"));
        else
            simualtionParameters.append(tr(", numberOfIntervals=")).append(ui->mpNumberofIntervalsTextBox->text());
        if (!ui->mpOutputIntervalTextBox->text().isEmpty())
            simualtionParameters.append(tr(", outputInterval=")).append(ui->mpOutputIntervalTextBox->text());
        simualtionParameters.append(tr(", method=")).append(ui->mpMethodComboBox->currentText());
        if (!ui->mpToleranceTextBox->text().isEmpty())
            simualtionParameters.append(tr(", tolerance=")).append(ui->mpToleranceTextBox->text());
        if (!ui->mpFixedStepSizeTextBox->text().isEmpty())
            simualtionParameters.append(tr(", fixedStepSize=")).append(ui->mpFixedStepSizeTextBox->text());

        ProjectTab *projectTab = mpParentMainWindow->mpProjectTabs->getCurrentTab();

        if (!projectTab)
        {
            mpParentMainWindow->mpMessageWidget->printGUIWarningMessage("There is no open Model to simulate.");
            accept();
            return;
        }

        // show simulation progress bar
        int endtime = ui->mpNumberofIntervalsTextBox->text().toInt() * ui->mpStopTimeTextBox->text().toInt();
        QProgressDialog progressBar(this, Qt::WindowTitleHint);
        progressBar.setMinimum(0);
        progressBar.setMaximum(endtime);
        progressBar.setLabelText(tr("Running Simulation"));
        progressBar.setCancelButton(0);
        progressBar.setWindowModality(Qt::WindowModal);
        progressBar.setWindowTitle(QString(Helper::applicationName).append(" - Simulation"));
        progressBar.show();
        progressBar.setValue(endtime/2);

        mpParentMainWindow->mpOMCProxy->changeDirectory(QString(qApp->applicationDirPath()).append("/../tmp"));
        if (!mpParentMainWindow->mpOMCProxy->simulate(projectTab->mModelFileStrucrure, simualtionParameters))
        {
            mpParentMainWindow->mpMessageWidget->printGUIErrorMessage("Enable to simulate the Model '" +
                                                                      projectTab->mModelFileStrucrure + "'");
            accept();
            return;
        }

        mpParentMainWindow->mpPlotWidget->readPlotVariables(QString(projectTab->mModelFileStrucrure).append("_res.plt"));
        mpParentMainWindow->plotdock->show();
        mpParentMainWindow->mpMessageWidget->printGUIMessage("Simulated '" +
                                                              projectTab->mModelFileStrucrure + "' successfully!");
        progressBar.setValue(endtime);
        progressBar.hide();
        accept();
    }
}

bool SimulationWidget::validate()
{
    if (ui->mpStartTimeTextBox->text().isEmpty())
        mpParentMainWindow->mpMessageWidget->printGUIWarningMessage(tr("Simulation Start Time is not defined. Default value (0) will be used."));

    if (ui->mpStopTimeTextBox->text().isEmpty())
    {
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(tr("Simulation Stop Time is not defined."));
        return false;
    }

    if (ui->mpStopTimeTextBox->text().toInt() <= ui->mpStartTimeTextBox->text().toInt())
    {
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(tr("Simulation Start Time should be less than Stop Time."));
        return false;
    }

    return true;
}
