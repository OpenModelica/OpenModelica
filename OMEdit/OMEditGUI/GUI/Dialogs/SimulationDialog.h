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

#ifndef SIMULATIONDIALOG_H
#define SIMULATIONDIALOG_H

#include "MainWindow.h"

class MainWindow;
class ProgressDialog;

class SimulationDialog : public QDialog
{
  Q_OBJECT
public:
  SimulationDialog(MainWindow *pParent = 0);
  ~SimulationDialog();
  void setUpForm();
  void show(LibraryTreeNode *pLibraryTreeNode, bool isInteractive);
  bool validate();
  void initializeFields();
  void buildModel(QString simulationParameters, QStringList simulationFlags);
  void saveSimulationOptions();
private:
  MainWindow *mpMainWindow;
  Label *mpSimulationHeading;
  QFrame *mpHorizontalLine;
  QTabWidget *mpSimulationTabWidget;
  // General Tab
  QWidget *mpGeneralTab;
  QGroupBox *mpSimulationIntervalGroupBox;
  Label *mpStartTimeLabel;
  QDoubleSpinBox *mpStartTimeSpinBox;
  Label *mpStopTimeLabel;
  QDoubleSpinBox *mpStopTimeSpinBox;
  QGroupBox *mpIntegrationGroupBox;
  Label *mpMethodLabel;
  QComboBox *mpMethodComboBox;
  Label *mpToleranceLabel;
  QDoubleSpinBox *mpToleranceSpinBox;
  QCheckBox *mpSaveSimulationCheckbox;
  Label *mpCflagsLabel;
  QLineEdit *mpCflagsTextBox;
  // Output Tab
  QWidget *mpOutputTab;
  Label *mpNumberofIntervalLabel;
  QDoubleSpinBox *mpNumberofIntervalsSpinBox;
  Label *mpOutputFormatLabel;
  QComboBox *mpOutputFormatComboBox;
  Label *mpFileNameLabel;
  QLineEdit *mpFileNameTextBox;
  Label *mpVariableFilterLabel;
  QLineEdit *mpVariableFilterTextBox;
  QCheckBox *mpShowGeneratedFilesCheckBox;
  // Simulation Flags Tab
  QWidget *mpSimulationFlagsTab;
  QScrollArea *mpSimulationFlagsTabScrollArea;
  Label *mpModelSetupFileLabel;
  QLineEdit *mpModelSetupFileTextBox;
  QPushButton *mpModelSetupFileBrowseButton;
  Label *mpInitializationMethodLabel;
  QComboBox *mpInitializationMethodComboBox;
  Label *mpOptimizationMethodLabel;
  QComboBox *mpOptimizationMethodComboBox;
  Label *mpEquationSystemInitializationFileLabel;
  QLineEdit *mpEquationSystemInitializationFileTextBox;
  QPushButton *mpEquationSystemInitializationFileBrowseButton;
  Label *mpEquationSystemInitializationTimeLabel;
  QLineEdit *mpEquationSystemInitializationTimeTextBox;
  Label *mpClockLabel;
  QComboBox *mpClockComboBox;
  Label *mpLinearSolverLabel;
  QComboBox *mpLinearSolverComboBox;
  Label *mpNonLinearSolverLabel;
  QComboBox *mpNonLinearSolverComboBox;
  Label *mpLinearizationTimeLabel;
  QLineEdit *mpLinearizationTimeTextBox;
  Label *mpOutputVariablesLabel;
  QLineEdit *mpOutputVariablesTextBox;
  QCheckBox *mpProfilingCheckBox;
  QCheckBox *mpCPUTimeCheckBox;
  QCheckBox *mpEnableAllWarningsCheckBox;
  QGroupBox *mpLoggingGroupBox;
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
  Label *mpAdditionalSimulationFlagsLabel;
  QLineEdit *mpAdditionalSimulationFlagsTextBox;
  // buttons
  QPushButton *mpCancelButton;
  QPushButton *mpSimulateButton;
  QDialogButtonBox *mpButtonBox;
  ProgressDialog *mpProgressDialog;
  QProcess *mpSimulationProcess;
  QList<QWidget*> mSimulationOutputWidgetsList;
  bool mIsSimulationProcessFinished;
  bool mIsInteractive;
  LibraryTreeNode *mpLibraryTreeNode;
public slots:
  void browseModelSetupFile();
  void browseEquationSystemInitializationFile();
  void simulate();
  void simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void cancelSimulation();
};

class ProgressDialog : public QDialog
{
  Q_OBJECT
public:
  ProgressDialog(SimulationDialog *pParent = 0);
  QProgressBar* getProgressBar();
  QPushButton* getCancelSimulationButton();
  void setText(QString text);
private:
  QProgressBar *mpProgressBar;
  Label *mpProgressLabel;
  QPushButton *mpCancelSimulationButton;
};

class SimulationOutputWidget : public QWidget
{
  Q_OBJECT
public:
  SimulationOutputWidget(QString className, QString outputFile, bool showGeneratedFiles, QProcess *pSimulationProcess,
                         MainWindow *pParent);
  QPlainTextEdit* getSimulationOutputTextBox();
  void addGeneratedFileTab(QString fileName);
private:
  QProcess *mpSimulationProcess;
  MainWindow *mpMainWindow;
  QTabWidget *mpGeneratedFilesTabWidget;
  QPlainTextEdit *mpSimulationOutputTextBox;
public slots:
  void writeSimulationOutput();
  void showSimulationOutputDialog();
};

#endif // SIMULATIONDIALOG_H
