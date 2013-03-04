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
  void simulateModel(QString simulationParameters, QStringList simulationFlags);
  void buildModel(QString simulationParameters, QStringList simulationFlags);
  void saveSimulationOptions();

  MainWindow *mpParentMainWindow;
private:
  QLabel *mpSimulationHeading;
  QFrame *mpHorizontalLine;
  QTabWidget *mpSimulationTabWidget;
  // General Tab
  QWidget *mpGeneralTab;
  QGroupBox *mpSimulationIntervalGroup;
  QLabel *mpStartTimeLabel;
  QLineEdit *mpStartTimeTextBox;
  QLabel *mpStopTimeLabel;
  QLineEdit *mpStopTimeTextBox;
  QGroupBox *mpIntegrationGroup;
  QLabel *mpMethodLabel;
  QComboBox *mpMethodComboBox;
  QLabel *mpToleranceLabel;
  QLineEdit *mpToleranceTextBox;
  QCheckBox *mpSaveSimulationCheckbox;
  QLabel *mpCflagsLabel;
  QLineEdit *mpCflagsTextBox;
  // Output Tab
  QWidget *mpOutputTab;
  QLabel *mpNumberofIntervalLabel;
  QLineEdit *mpNumberofIntervalsTextBox;
  QLabel *mpOutputFormatLabel;
  QComboBox *mpOutputFormatComboBox;
  QLabel *mpFileNameLabel;
  QLineEdit *mpFileNameTextBox;
  QLabel *mpVariableFilterLabel;
  QLineEdit *mpVariableFilterTextBox;
  // Simulation Flags Tab
  QWidget *mpSimulationFlagsTab;
  QScrollArea *mpSimulationFlagsTabScrollArea;
  QLabel *mpModelSetupFileLabel;
  QLineEdit *mpModelSetupFileTextBox;
  QPushButton *mpModelSetupFileBrowseButton;
  QLabel *mpInitializationMethodLabel;
  QComboBox *mpInitializationMethodComboBox;
  QLabel *mpOptimizationMethodLabel;
  QComboBox *mpOptimizationMethodComboBox;
  QLabel *mpEquationSystemInitializationFileLabel;
  QLineEdit *mpEquationSystemInitializationFileTextBox;
  QPushButton *mpEquationSystemInitializationFileBrowseButton;
  QLabel *mpEquationSystemInitializationTimeLabel;
  QLineEdit *mpEquationSystemInitializationTimeTextBox;
  QLabel *mpMatchingAlgorithmLabel;
  QComboBox *mpMatchingAlgorithmComboBox;
  QLabel *mpIndexReductionLabel;
  QComboBox *mpIndexReductionComboBox;
  QLabel *mpClockLabel;
  QComboBox *mpClockComboBox;
  QLabel *mpLinearSolverLabel;
  QComboBox *mpLinearSolverComboBox;
  QLabel *mpNonLinearSolverLabel;
  QComboBox *mpNonLinearSolverComboBox;
  QLabel *mpLinearizationTimeLabel;
  QLineEdit *mpLinearizationTimeTextBox;
  QLabel *mpOutputVariablesLabel;
  QLineEdit *mpOutputVariablesTextBox;
  QGroupBox *mpLoggingGroup;
  QCheckBox *mpLogDasslSolverCheckBox;
  QCheckBox *mpLogDebugCheckBox;
  QCheckBox *mpLogDynamicStateSelectionCheckBox;
  QCheckBox *mpLogJacobianDynamicStateSelectionCheckBox;
  QCheckBox *mpLogEventsCheckBox;
  QCheckBox *mpLogVerboseEventsCheckBox;
  QCheckBox *mpLogInitializationCheckBox;
  QCheckBox *mpLogJacobianCheckBox;
  QCheckBox *mpLogNonLinearSystemsCheckBox;
  QCheckBox *mpLogVerboseNonLinearSystemsCheckBox;
  QCheckBox *mpLogJacobianNonLinearSystemsCheckBox;
  QCheckBox *mpLogResidualsInitializationCheckBox;
  QCheckBox *mpLogSimulationCheckBox;
  QCheckBox *mpLogSolverCheckBox;
  QCheckBox *mpLogFinalSolutionOfInitializationCheckBox;
  QCheckBox *mpLogStatsCheckBox;
  QCheckBox *mpLogUtilCheckBox;
  QCheckBox *mpLogZeroCrossingsCheckBox;
  QCheckBox *mpMeasureTimeCheckBox;
  QCheckBox *mpCPUTimeCheckBox;
  // buttons
  QPushButton *mpCancelButton;
  QPushButton *mpSimulateButton;
  QDialogButtonBox *mpButtonBox;
  ProgressDialog *mpProgressDialog;
  QProcess *mpSimulationProcess;
  bool mIsInteractive;
signals:
  void showPlottingView();
public slots:
  void browseModelSetupFile();
  void browseEquationSystemInitializationFile();
  void simulate();
  void cancelSimulation();
};

class ProgressDialog : public QDialog
{
  Q_OBJECT
public:
  ProgressDialog(SimulationWidget *pParent = 0);
  QProgressBar* getProgressBar();
  QPushButton* getCancelSimulationButton();
  void setText(QString text);
private:
  QProgressBar *mpProgressBar;
  QLabel *mpText;
  QPushButton *mpCancelSimulationButton;
};

class SimulationOutputDialog : public QDialog
{
  Q_OBJECT
public:
  SimulationOutputDialog(QString modelName, QString simulationOutput, QWidget *pParent = 0);
private:
  QPlainTextEdit *mpSimulationOutputTextBox;
  QPushButton *mpCloseButton;
};

#endif // SIMULATIONWIDGET_H
