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

#ifndef SIMULATIONWIDGET_H
#define SIMULATIONWIDGET_H

#include "mainwindow.h"

class MainWindow;
class ProgressDialog;

class SimulationWidget : public QDialog
{
    Q_OBJECT
public:
    SimulationWidget(MainWindow *pParent = 0);
    ~SimulationWidget();
    void setUpForm();
    void show(bool isInteractive);
    bool validate();
    void initializeFields();
    void simulateModel(QString simulationParameters);
    void buildModel(QString simulationParameters);
    void saveSimulationOptions();

    MainWindow *mpParentMainWindow;
private:
    QLabel *mpSimulationHeading;
    QFrame *line;
    QGroupBox *mpSimulationIntervalGroup;
    QLabel *mpStartTimeLabel;
    QLineEdit *mpStartTimeTextBox;
    QLabel *mpStopTimeLabel;
    QLineEdit *mpStopTimeTextBox;
    QGroupBox *mpOutputIntervalGroup;
    QLabel *mpNumberofIntervalLabel;
    QLineEdit *mpNumberofIntervalsTextBox;
    QGroupBox *mpIntegrationGroup;
    QLabel *mpMethodLabel;
    QComboBox *mpMethodComboBox;
    QLabel *mpToleranceLabel;
    QLineEdit *mpToleranceTextBox;
    QLabel *mpOutputFormatLabel;
    QComboBox *mpOutputFormatComboBox;
    QLabel *mpFileNameLabel;
    QLineEdit *mpFileNameTextBox;
    QLabel *mpVariableFilterLabel;
    QLineEdit *mpVariableFilterTextBox;
    QLabel *mpCflagsLabel;
    QLineEdit *mpCflagsTextBox;
    QGroupBox *mpSaveSimulationGroup;
    QCheckBox *mpSaveSimulationCheckbox;
    QPushButton *mpCancelButton;
    QPushButton *mpSimulateButton;
    QDialogButtonBox *mpButtonBox;
    ProgressDialog *mpProgressDialog;
    QProcess *mpSimulationProcess;
    bool mIsInteractive;
signals:
    void showPlottingView();
public slots:
    void simulate();
    void cancelSimulation();
};

class ProgressDialog : public QDialog
{
public:
    ProgressDialog(SimulationWidget *pParent = 0);
    QPushButton *mpCancelSimulationButton;
    void setText(QString text);
private:
    QLabel *mpText;
};

#endif // SIMULATIONWIDGET_H
