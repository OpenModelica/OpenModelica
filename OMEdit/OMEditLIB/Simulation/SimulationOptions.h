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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef SIMULATIONOPTIONS_H
#define SIMULATIONOPTIONS_H

#include "MainWindow.h"
#include "OMC/OMCProxy.h"

#include <QString>
#include <QVariant>
#include <QStringList>

class SimulationOptions
{
public:
  SimulationOptions()
  {
    // General
    setClassName("");
    setStartTime("0");
    setStopTime("1");
    setNumberofIntervals(500);
    setStepSize(0.002);
    setInteractiveSimulation(false);
    setInteractiveSimulationWithSteps(false);
    setInteractiveSimulationPortNumber(4841);
    setMethod("dassl");
    setTolerance("1e-6");
    setJacobian("");
    setRootFinding(true);
    setRestartAfterEvent(true);
    setInitialStepSize("");
    setMaxStepSize("");
    setMaxIntegration(5);
    setCflags("");
    setNumberOfProcessors(MainWindow::instance()->getNumberOfProcessors());
    setBuildOnly(false);
    setLaunchTransformationalDebugger(false);
    setLaunchAlgorithmicDebugger(false);
    setSimulateWithAnimation(false);
    // Translation
    setMatchingAlgorithm("PFPlusExt");
    setIndexReductionMethod("dynamicStateSelection");
    setInitialization(true);
    setEvaluateAllParameters(false);
    setNLSanalyticJacobian(true);
    setParmodauto(false);
    setOldInstantiation(false);
    setAdditionalTranslationFlags("");
    // Simulation
    setModelSetupFile("");
    setInitializationMethod("");
    setEquationSystemInitializationFile("");
    setEquationSystemInitializationTime("");
    setClock("");
    setLinearSolver("");
    setNonLinearSolver("");
    setLinearizationTime("");
    setOutputVariables("");
    setProfiling("none");
    setCPUTime(false);
    setEnableAllWarnings(true);
    setEnableDataReconciliation(false);
    setDataReconciliationAlgorithm("");
    setDataReconciliationMeasurementInputFile("");
    setBoundaryConditionMeasurementInputFile("");
    setDataReconciliationCorrelationMatrixInputFile("");
    setBoundaryConditionCorrelationMatrixInputFile("");
    setDataReconciliationEpsilon("");
    setDataReconciliationSaveSetting(false);
    setLogStreams(QStringList() << "LOG_STATS");
    setAdditionalSimulationFlags("");
    // Output
    setOutputFormat("mat");
    setSinglePrecision(false);
    setFileNamePrefix("");
    setResultFileName("");
    setVariableFilter(".*");
    setProtectedVariables(false);
    setIgnoreHideResult(false);
    setEquidistantTimeGrid(true);
    setStoreVariablesAtEvents(true);
    setShowGeneratedFiles(false);

    setSimulationFlags(QStringList());
    setIsValid(false);
    setDataReconciliationInitialized(false);
    setReSimulate(false);
    setWorkingDirectory("");
    setFileName("");
    setTargetLanguage("C");
  }

  void setClassName(const QString &className) {mClassName = className;}
  QString getClassName() const {return mClassName;}
  void setStartTime(const QString &startTime) {mStartTime = startTime;}
  QString getStartTime() const {return mStartTime;}
  void setStopTime(const QString &stopTime) {mStopTime = stopTime;}
  QString getStopTime() const {return mStopTime;}
  void setNumberofIntervals(int numberofIntervals) {mNumberofIntervals = numberofIntervals;}
  int getNumberofIntervals() const {return mNumberofIntervals;}
  void setStepSize(qreal stepSize) {mStepSize = stepSize;}
  qreal getStepSize() const {return mStepSize;}
  void setInteractiveSimulation(bool interactiveSim) {mInteractiveSimulation = interactiveSim;}
  bool isInteractiveSimulation() const {return mInteractiveSimulation;}
  void setInteractiveSimulationWithSteps(bool withSteps) {mInteractiveSimulationWithSteps = withSteps;}
  bool isInteractiveSimulationWithSteps() const {return mInteractiveSimulationWithSteps;}
  void setInteractiveSimulationPortNumber(int port) { mInteractiveSimulationPortNumber = port;}
  int getInteractiveSimulationPortNumber() const {return mInteractiveSimulationPortNumber;}
  void setMethod(const QString &method) {mMethod = method;}
  QString getMethod() const {return mMethod;}
  void setTolerance(const QString &tolerance) {mTolerance = tolerance;}
  QString getTolerance() const {return mTolerance;}
  void setJacobian(const QString &jacobian) {mJacobian = jacobian;}
  QString getJacobian() const {return mJacobian;}
  void setRootFinding(bool rootFinding) {mRootFinding = rootFinding;}
  bool getRootFinding() const {return mRootFinding;}
  void setRestartAfterEvent(bool restartAfterEvent) {mRestartAfterEvent = restartAfterEvent;}
  bool getRestartAfterEvent() const {return mRestartAfterEvent;}
  void setInitialStepSize(const QString &initialStepSize) {mInitialStepSize = initialStepSize;}
  QString getInitialStepSize() const {return mInitialStepSize;}
  void setMaxStepSize(const QString &maxStepSize) {mMaxStepSize = maxStepSize;}
  QString getMaxStepSize() const {return mMaxStepSize;}
  void setMaxIntegration(int maxIntegration) {mMaxIntegration = maxIntegration;}
  int getMaxIntegration() const {return mMaxIntegration;}
  void setCflags(const QString &cflags) {mCflags = cflags;}
  QString getCflags() const {return mCflags;}
  void setNumberOfProcessors(int numberOfProcessors) {mNumberOfProcessors = numberOfProcessors;}
  int getNumberOfProcessors() const {return mNumberOfProcessors;}
  void setBuildOnly(bool buildOnly) {mBuildOnly = buildOnly;}
  bool getBuildOnly() const {return mBuildOnly;}
  void setLaunchTransformationalDebugger(bool launchTransformationalDebugger) {mLaunchTransformationalDebugger = launchTransformationalDebugger;}
  bool getLaunchTransformationalDebugger() const {return mLaunchTransformationalDebugger;}
  void setLaunchAlgorithmicDebugger(bool launchAlgorithmicDebugger) {mLaunchAlgorithmicDebugger = launchAlgorithmicDebugger;}
  bool getLaunchAlgorithmicDebugger() const {return mLaunchAlgorithmicDebugger;}
  void setSimulateWithAnimation(bool simulateWithAnimation) {mSimulateWithAnimation = simulateWithAnimation;}
  bool getSimulateWithAnimation() const {return mSimulateWithAnimation;}

  void setMatchingAlgorithm(const QString &matchingAlgorithm) {mMatchingAlgorithm = matchingAlgorithm;}
  QString getMatchingAlgorithm() const {return mMatchingAlgorithm;}
  void setIndexReductionMethod(const QString &indexReductionMethod) {mIndexReductionMethod = indexReductionMethod;}
  QString getIndexReductionMethod() const {return mIndexReductionMethod;}
  void setInitialization(bool initialization) {mInitialization = initialization;}
  bool getInitialization() const {return mInitialization;}
  void setEvaluateAllParameters(bool evaluateAllParameters) {mEvaluateAllParameters = evaluateAllParameters;}
  bool getEvaluateAllParameters() const {return mEvaluateAllParameters;}
  void setNLSanalyticJacobian(bool nlsAnalyticJacobian) {mNLSanalyticJacobian = nlsAnalyticJacobian;}
  bool getNLSanalyticJacobian() const {return mNLSanalyticJacobian;}
  void setParmodauto(bool parmodauto) {mParmodauto = parmodauto;}
  bool getParmodauto() const {return mParmodauto;}
  void setOldInstantiation(bool oldInstantiation) {mOldInstantiation = oldInstantiation;}
  bool getOldInstantiation() const {return mOldInstantiation;}
  void setAdditionalTranslationFlags(const QString &additionalTranslationFlags) {mAdditionalTranslationFlags = additionalTranslationFlags;}
  QString getAdditionalTranslationFlags() const {return mAdditionalTranslationFlags;}

  void setModelSetupFile(const QString &modelSetupFile) {mModelSetupFile = modelSetupFile;}
  QString getModelSetupFile() const {return mModelSetupFile;}
  void setInitializationMethod(const QString &initializationMethod) {mInitializationMethod = initializationMethod;}
  QString getInitializationMethod() const {return mInitializationMethod;}
  void setEquationSystemInitializationFile(const QString &equationSystemInitializationFile) {mEquationSystemInitializationFile = equationSystemInitializationFile;}
  QString getEquationSystemInitializationFile() const {return mEquationSystemInitializationFile;}
  void setEquationSystemInitializationTime(const QString &equationSystemInitializationTime) {mEquationSystemInitializationTime = equationSystemInitializationTime;}
  QString getEquationSystemInitializationTime() const {return mEquationSystemInitializationTime;}
  void setClock(const QString &clock) {mClock = clock;}
  QString getClock() const {return mClock;}
  void setLinearSolver(const QString &linearSolver) {mLinearSolver = linearSolver;}
  QString getLinearSolver() const {return mLinearSolver;}
  void setNonLinearSolver(const QString &nonLinearSolver) {mNonLinearSolver = nonLinearSolver;}
  QString getNonLinearSolver() const {return mNonLinearSolver;}
  void setLinearizationTime(const QString &linearizationTime) {mLinearizationTime = linearizationTime;}
  QString getLinearizationTime() const {return mLinearizationTime;}
  void setOutputVariables(const QString &outputVariables) {mOutputVariables = outputVariables;}
  QString getOutputVariables() const {return mOutputVariables;}
  void setProfiling(const QString &profiling) {mProfiling = profiling;}
  QString getProfiling() const {return mProfiling;}
  void setCPUTime(bool cpuTime) {mCPUTime = cpuTime;}
  bool getCPUTime() const {return mCPUTime;}
  void setEnableAllWarnings(bool enableAllWarnings) {mEnableAllWarnings = enableAllWarnings;}
  bool getEnableAllWarnings() const {return mEnableAllWarnings;}
  void setEnableDataReconciliation(bool dataReconciliation) {mEnableDataReconciliation = dataReconciliation;}
  bool getEnableDataReconciliation() const {return mEnableDataReconciliation;}
  void setDataReconciliationAlgorithm(const QString &dataReconciliationAlgorithm) {mDataReconciliationAlgorithm = dataReconciliationAlgorithm;}
  QString getDataReconciliationAlgorithm() const {return mDataReconciliationAlgorithm;}
  void setDataReconciliationMeasurementInputFile(const QString &dataReconciliationMeasurementInputFile) {mDataReconciliationMeasurementInputFile = dataReconciliationMeasurementInputFile;}
  QString getDataReconciliationMeasurementInputFile() const {return mDataReconciliationMeasurementInputFile;}
  void setBoundaryConditionMeasurementInputFile(const QString &boundaryConditionMeasurementInputFile) {mBoundaryConditionMeasurementInputFile = boundaryConditionMeasurementInputFile;}
  QString getBoundaryConditionMeasurementInputFile() const {return mBoundaryConditionMeasurementInputFile;}
  void setDataReconciliationCorrelationMatrixInputFile(const QString &dataReconciliationCorrelationMatrixInputFile) {mDataReconciliationCorrelationMatrixInputFile = dataReconciliationCorrelationMatrixInputFile;}
  QString getDataReconciliationCorrelationMatrixInputFile() const {return mDataReconciliationCorrelationMatrixInputFile;}
  void setBoundaryConditionCorrelationMatrixInputFile(const QString &boundaryConditionCorrelationMatrixInputFile) {mBoundaryConditionCorrelationMatrixInputFile = boundaryConditionCorrelationMatrixInputFile;}
  QString getBoundaryConditionCorrelationMatrixInputFile() const {return mBoundaryConditionCorrelationMatrixInputFile;}
  void setDataReconciliationEpsilon(const QString &dataReconciliationEpsilon) {mDataReconciliationEpsilon = dataReconciliationEpsilon;}
  QString getDataReconciliationEpsilon() const {return mDataReconciliationEpsilon;}
  void setDataReconciliationSaveSetting(bool dataReconciliationSaveSetting) {mDataReconciliationSaveSetting = dataReconciliationSaveSetting;}
  bool getDataReconciliationSaveSetting() const {return mDataReconciliationSaveSetting;}
  void setLogStreams(QStringList logStreams) {mLogStreams = logStreams;}
  QStringList getLogStreams() const {return mLogStreams;}
  void setAdditionalSimulationFlags(const QString &additionalSimulationFlags) {mAdditionalSimulationFlags = additionalSimulationFlags;}
  QString getAdditionalSimulationFlags() const {return mAdditionalSimulationFlags;}

  void setOutputFormat(const QString &outputFormat) {mOutputFormat = outputFormat;}
  QString getOutputFormat() const {return mOutputFormat;}
  void setSinglePrecision(bool singlePrecision) {mSinglePrecision = singlePrecision;}
  bool getSinglePrecision() const {return mSinglePrecision;}
  void setFileNamePrefix(const QString &fileNamePrefix) {mFileNamePrefix = fileNamePrefix;}
  QString getFileNamePrefix() const {return mFileNamePrefix;}
  QString getOutputFileName() const {return mFileNamePrefix.isEmpty() ? mClassName : mFileNamePrefix;}
  void setResultFileName(const QString &resultFileName) {mResultFileName = resultFileName;}
  QString getResultFileName() const {return mResultFileName;}
  QString getFullResultFileName() const {return mResultFileName.isEmpty() ? getOutputFileName() + "_res." + mOutputFormat : mResultFileName;}
  void setVariableFilter(const QString &variableFilter) {mVariableFilter = variableFilter;}
  QString getVariableFilter() const {return mVariableFilter.isEmpty() ? ".*" : mVariableFilter;}
  void setProtectedVariables(bool protectedVariables) {mProtectedVariables = protectedVariables;}
  bool getProtectedVariables() const {return mProtectedVariables;}
  void setIgnoreHideResult(bool ignoreHideResult) {mIgnoreHideResult = ignoreHideResult;}
  bool getIgnoreHideResult() const {return mIgnoreHideResult;}
  void setEquidistantTimeGrid(bool equidistantTimeGrid) {mEquidistantTimeGrid = equidistantTimeGrid;}
  bool getEquidistantTimeGrid() const {return mEquidistantTimeGrid;}
  void setStoreVariablesAtEvents(bool storeVariablesAtEvents) {mStoreVariablesAtEvents = storeVariablesAtEvents;}
  bool getStoreVariablesAtEvents() const {return mStoreVariablesAtEvents;}
  void setShowGeneratedFiles(bool showGeneratedFiles) {mShowGeneratedFiles = showGeneratedFiles;}
  bool getShowGeneratedFiles() const {return mShowGeneratedFiles;}

  void setSimulationFlags(QStringList simulationFlags) {mSimulationFlags = simulationFlags;}
  QStringList getSimulationFlags() const {return mSimulationFlags;}
  void setIsValid(bool isValid) {mValid = isValid;}
  bool isValid() const {return mValid;}
  void setDataReconciliationInitialized(bool dataReconciliationInitialized) {mDataReconciliationInitialized = dataReconciliationInitialized;}
  bool isDataReconciliationInitialized() const {return mDataReconciliationInitialized;}
  void setReSimulate(bool reSimulate) {mReSimulate = reSimulate;}
  bool isReSimulate() const {return mReSimulate;}
  void setWorkingDirectory(const QString &workingDirectory) {mWorkingDirectory = workingDirectory;}
  QString getWorkingDirectory() const {return mWorkingDirectory;}
  void setFileName(const QString &fileName) {mFileName = fileName;}
  QString getFileName() const {return mFileName;}
  void setTargetLanguage(const QString &targetLanguage) {mTargetLanguage = targetLanguage;}
  QString getTargetLanguage() const {return mTargetLanguage;}
private:
  QString mClassName;
  QString mStartTime;
  QString mStopTime;
  int mNumberofIntervals;
  qreal mStepSize;
  bool mInteractiveSimulation;
  bool mInteractiveSimulationWithSteps;
  int mInteractiveSimulationPortNumber;
  QString mMethod;
  QString mTolerance;
  QString mJacobian;
  bool mRootFinding;
  bool mRestartAfterEvent;
  QString mInitialStepSize;
  QString mMaxStepSize;
  int mMaxIntegration;
  QString mCflags;
  int mNumberOfProcessors;
  bool mBuildOnly;
  bool mLaunchTransformationalDebugger;
  bool mLaunchAlgorithmicDebugger;
  bool mSimulateWithAnimation;
  // Translation
  QString mMatchingAlgorithm;
  QString mIndexReductionMethod;
  bool mInitialization;
  bool mEvaluateAllParameters;
  bool mNLSanalyticJacobian;
  bool mParmodauto;
  bool mOldInstantiation;
  QString mAdditionalTranslationFlags;
  // simulation flags
  QString mModelSetupFile;
  QString mInitializationMethod;
  QString mEquationSystemInitializationFile;
  QString mEquationSystemInitializationTime;
  QString mClock;
  QString mLinearSolver;
  QString mNonLinearSolver;
  QString mLinearizationTime;
  QString mOutputVariables;
  QString mProfiling;
  bool mCPUTime;
  bool mEnableAllWarnings;
  bool mEnableDataReconciliation;
  QString mDataReconciliationAlgorithm;
  QString mDataReconciliationMeasurementInputFile;
  QString mDataReconciliationCorrelationMatrixInputFile;
  QString mBoundaryConditionMeasurementInputFile;
  QString mBoundaryConditionCorrelationMatrixInputFile;
  QString mDataReconciliationEpsilon;
  bool mDataReconciliationSaveSetting;
  QStringList mLogStreams;
  QString mAdditionalSimulationFlags;
  // output
  QString mOutputFormat;
  bool mSinglePrecision;
  QString mFileNamePrefix;
  QString mResultFileName;
  QString mVariableFilter;
  bool mProtectedVariables;
  bool mIgnoreHideResult;
  bool mEquidistantTimeGrid;
  bool mStoreVariablesAtEvents;
  bool mShowGeneratedFiles;

  QStringList mSimulationFlags;
  bool mValid;
  bool mDataReconciliationInitialized;
  bool mReSimulate;
  QString mWorkingDirectory;
  QString mFileName;
  QString mTargetLanguage;
};

#endif // SIMULATIONOPTIONS_H
