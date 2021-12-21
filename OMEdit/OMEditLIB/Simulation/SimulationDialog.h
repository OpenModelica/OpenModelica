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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef SIMULATIONDIALOG_H
#define SIMULATIONDIALOG_H

#include "Util/Helper.h"
#include "SimulationOptions.h"
#include "OpcUaClient.h"

#include <QDialog>
#include <QTreeWidget>
#include <QScrollArea>
#include <QGroupBox>
#include <QRadioButton>
#include <QSpinBox>
#include <QComboBox>
#include <QToolButton>
#include <QCheckBox>
#include <QPushButton>
#include <QDialogButtonBox>
#include <QGridLayout>
#include <QDateTime>

class Label;
class SimulationOutputWidget;
class LibraryTreeItem;
class TranslationFlagsWidget;

class SimulationDialog : public QDialog
{
  Q_OBJECT
public:
  SimulationDialog(QWidget *pParent = 0);
  ~SimulationDialog();
  void show(LibraryTreeItem *pLibraryTreeItem, bool isReSimulate, SimulationOptions simulationOptions);
  void directSimulate(LibraryTreeItem *pLibraryTreeItem, bool launchTransformationalDebugger, bool launchAlgorithmicDebugger, bool launchAnimation, bool enableDataReconciliation);
  OpcUaClient* getOpcUaClient(int port);
  void removeSimulationOutputWidget(SimulationOutputWidget* pSimulationOutputWidget);
private:
  Label *mpSimulationHeading;
  QFrame *mpHorizontalLine;
  QTabWidget *mpSimulationTabWidget;
  // General Tab
  QWidget *mpGeneralTab;
  QScrollArea *mpGeneralTabScrollArea;
  QGroupBox *mpSimulationIntervalGroupBox;
  Label *mpStartTimeLabel;
  QLineEdit *mpStartTimeTextBox;
  Label *mpStopTimeLabel;
  QLineEdit *mpStopTimeTextBox;
  QRadioButton *mpNumberofIntervalsRadioButton;
  QSpinBox *mpNumberofIntervalsSpinBox;
  QRadioButton *mpIntervalRadioButton;
  QLineEdit *mpIntervalTextBox;
  QGroupBox *mpIntegrationGroupBox;
  Label *mpMethodLabel;
  QComboBox *mpMethodComboBox;
  QToolButton *mpMehtodHelpButton;
  Label *mpToleranceLabel;
  QLineEdit *mpToleranceTextBox;
  Label *mpJacobianLabel;
  QComboBox *mpJacobianComboBox;
  QGroupBox *mpDasslIdaOptionsGroupBox;
  QCheckBox *mpRootFindingCheckBox;
  QCheckBox *mpRestartAfterEventCheckBox;
  Label *mpInitialStepSizeLabel;
  QLineEdit *mpInitialStepSizeTextBox;
  Label *mpMaxStepSizeLabel;
  QLineEdit *mpMaxStepSizeTextBox;
  Label *mpMaxIntegrationOrderLabel;
  QSpinBox *mpMaxIntegrationOrderSpinBox;
  Label *mpCflagsLabel;
  QLineEdit *mpCflagsTextBox;
  Label *mpNumberOfProcessorsLabel;
  QSpinBox *mpNumberOfProcessorsSpinBox;
  Label *mpNumberOfProcessorsNoteLabel;
  QCheckBox *mpBuildOnlyCheckBox;
  QCheckBox *mpLaunchTransformationalDebuggerCheckBox;
  QCheckBox *mpLaunchAlgorithmicDebuggerCheckBox;
#if !defined(WITHOUT_OSG)
  QCheckBox *mpLaunchAnimationCheckBox;
#endif
  // Interactive Simulation Tab
  QWidget *mpInteractiveSimulationTab;
  // Translation Tab
  QWidget *mpTranslationTab;
  TranslationFlagsWidget *mpTranslationFlagsWidget;
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
  Label  *mpProfilingLabel;
  QComboBox *mpProfilingComboBox;
  QCheckBox *mpCPUTimeCheckBox;
  QCheckBox *mpEnableAllWarningsCheckBox;
  QGroupBox *mpLoggingGroupBox;
  QGridLayout *mpLoggingGroupLayout;
  Label *mpAdditionalSimulationFlagsLabel;
  QLineEdit *mpAdditionalSimulationFlagsTextBox;
  QToolButton *mpSimulationFlagsHelpButton;
  QGroupBox *mpInteractiveSimulationGroupBox;
  Label *mpInteractiveSimulationPortLabel;
  QLineEdit *mpInteractiveSimulationPortNumberTextBox;
  QCheckBox *mpInteractiveSimulationStepCheckBox;
  // Output Tab
  QWidget *mpOutputTab;
  Label *mpOutputFormatLabel;
  QComboBox *mpOutputFormatComboBox;
  QCheckBox *mpSinglePrecisionCheckBox;
  Label *mpFileNameLabel;
  QLineEdit *mpFileNameTextBox;
  Label *mpResultFileNameLabel;
  QLineEdit *mpResultFileNameTextBox;
  Label *mpVariableFilterLabel;
  QLineEdit *mpVariableFilterTextBox;
  QCheckBox *mpProtectedVariablesCheckBox;
  QCheckBox *mpIgnoreHideResultCheckBox;
  QCheckBox *mpEquidistantTimeGridCheckBox;
  QCheckBox *mpStoreVariablesAtEventsCheckBox;
  QCheckBox *mpShowGeneratedFilesCheckBox;
  // checkboxes
  QCheckBox *mpSaveExperimentAnnotationCheckBox;
  QCheckBox *mpSaveSimulationFlagsAnnotationCheckBox;
  QCheckBox *mpSaveTranslationFlagsAnnotationCheckBox;
  QCheckBox *mpSimulateCheckBox;
  // buttons
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  QList<SimulationOutputWidget*> mSimulationOutputWidgetsList;
  LibraryTreeItem *mpLibraryTreeItem;
  QString mClassName;
  QString mFileName;
  bool mIsReSimulate;
  // interactive simulation
  QMap<int, OpcUaClient*> mOpcUaClientsMap;

  void setUpForm();
  bool validate();
  void initializeFields(bool isReSimulate, SimulationOptions simulationOptions);
  void applySimulationOptions(SimulationOptions simulationOptions);
  bool translateModel(QString simulationParameters);
  SimulationOptions createSimulationOptions();
  void createAndShowSimulationOutputWidget(SimulationOptions simulationOptions);
  void showSimulationOutputWidget(SimulationOutputWidget *pSimulationOutputWidget);
  void saveExperimentAnnotation();
  void saveSimulationFlagsAnnotation();
  void saveTranslationFlagsAnnotation();
  void performSimulation();
  void saveDialogGeometry();
  void killSimulationProcess(int port);
  void removeVariablesFromTree(QString className);
  void setInteractiveControls(bool enabled);
public:
  void reSimulate(SimulationOptions simulationOptions);
  void showAlgorithmicDebugger(SimulationOptions simulationOptions);
  void simulationProcessFinished(SimulationOptions simulationOptions, QDateTime resultFileLastModifiedDateTime);
  void createOpcUaClient(SimulationOptions simulationOptions);
public slots:
  void numberOfIntervalsRadioToggled(bool toggle);
  void intervalRadioToggled(bool toggle);
  void enableDasslIdaOptions(QString method);
  void showIntegrationHelp();
  void buildOnly(bool checked);
  void interactiveSimulation(bool checked);
  void browseModelSetupFile();
  void browseEquationSystemInitializationFile();
  void showSimulationFlagsHelp();
  void simulate();
  void reject();
  void updateInteractiveSimulationCurves();
  void updateYAxis(double min, double max);
private slots:
  void resultFileNameChanged(QString text);
  void simulationStarted();
  void simulationPaused();
};

class DataReconciliationDialog : public QDialog
{
  Q_OBJECT
public:
  explicit DataReconciliationDialog(LibraryTreeItem *pLibraryTreeItem, QDialog *parent = nullptr);
private:
  LibraryTreeItem *mpLibraryTreeItem;
  Label *mpDataReconciliationAlgorithmLabel;
  QComboBox *mpDataReconciliationAlgorithmComboBox;
  Label *mpDataReconciliationMeasurementInputFileLabel;
  QLineEdit *mpDataReconciliationMeasurementInputFileTextBox;
  QPushButton *mpDataReconciliationMeasurementInputFileBrowseButton;
  Label *mpDataReconciliationCorrelationMatrixInputFileLabel;
  QLineEdit *mpDataReconciliationCorrelationMatrixInputFileTextBox;
  QPushButton *mpDataReconciliationCorrelationMatrixInputFileBrowseButton;

  Label *mpBoundaryConditionMeasurementInputFileLabel;
  QLineEdit *mpBoundaryConditionMeasurementInputFileTextBox;
  QPushButton *mpBoundaryConditionMeasurementInputFileBrowseButton;
  Label *mpBoundaryConditionCorrelationMatrixInputFileLabel;
  QLineEdit *mpBoundaryConditionCorrelationMatrixInputFileTextBox;
  QPushButton *mpBoundaryConditionCorrelationMatrixInputFileBrowseButton;

  Label *mpDataReconciliationEpsilonLabel;
  QLineEdit *mpDataReconciliationEpsilonTextBox;
  QCheckBox *mpSaveSettingsCheckBox;
  QPushButton *mpCalculateButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  QStackedWidget  *mpDataReconciliationStackedWidget;
private slots:
  void browseDataReconciliationMeasurementInputFile();
  void browseDataReconciliationCorrelationMatrixInputFile();
  void browseBoundaryConditionMeasurementInputFile();
  void browseBoundaryConditionCorrelationMatrixInputFile();
  void calculateDataReconciliation();
  void switchAlgorithmPage(int index);
};

#endif // SIMULATIONDIALOG_H
