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
    setEvaluateAllParameters(true);
    setNLSanalyticJacobian(true);
    setPedantic(false);
    setParmodauto(false);
    setNewInstantiation(false);
    setDataReconciliation(false);
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
    setReconcile(false);
    setDataReconciliationInputFile("");
    setDataReconciliationEpsilon("");
    setLogStreams(QStringList() << "LOG_STATS");
    setAdditionalSimulationFlags("");
    // Output
    setOutputFormat("mat");
    setSinglePrecision(false);
    setFileNamePrefix("");
    setResultFileName("");
    setVariableFilter(".*");
    setProtectedVariables(false);
    setEquidistantTimeGrid(true);
    setStoreVariablesAtEvents(true);
    setShowGeneratedFiles(false);

    setSimulationFlags(QStringList());
    setIsValid(false);
    setReSimulate(false);
    setWorkingDirectory("");
    setFileName("");
    setTargetLanguage("C");
  }

  void setClassName(QString className) {mClassName = className;}
  QString getClassName() {return mClassName;}
  void setStartTime(QString startTime) {mStartTime = startTime;}
  QString getStartTime() {return mStartTime;}
  void setStopTime(QString stopTime) {mStopTime = stopTime;}
  QString getStopTime() {return mStopTime;}
  void setNumberofIntervals(int numberofIntervals) {mNumberofIntervals = numberofIntervals;}
  int getNumberofIntervals() {return mNumberofIntervals;}
  void setStepSize(qreal stepSize) {mStepSize = stepSize;}
  qreal getStepSize() {return mStepSize;}
  void setInteractiveSimulation(bool interactiveSim) {mInteractiveSimulation = interactiveSim;}
  bool isInteractiveSimulation() {return mInteractiveSimulation;}
  void setInteractiveSimulationWithSteps(bool withSteps) {mInteractiveSimulationWithSteps = withSteps;}
  bool isInteractiveSimulationWithSteps() {return mInteractiveSimulationWithSteps;}
  void setInteractiveSimulationPortNumber(int port) { mInteractiveSimulationPortNumber = port;}
  int getInteractiveSimulationPortNumber() {return mInteractiveSimulationPortNumber;}
  void setMethod(QString method) {mMethod = method;}
  QString getMethod() {return mMethod;}
  void setTolerance(QString tolerance) {mTolerance = tolerance;}
  QString getTolerance() {return mTolerance;}
  void setJacobian(QString jacobian) {mJacobian = jacobian;}
  QString getJacobian() {return mJacobian;}
  void setRootFinding(bool rootFinding) {mRootFinding = rootFinding;}
  bool getRootFinding() {return mRootFinding;}
  void setRestartAfterEvent(bool restartAfterEvent) {mRestartAfterEvent = restartAfterEvent;}
  bool getRestartAfterEvent() {return mRestartAfterEvent;}
  void setInitialStepSize(QString initialStepSize) {mInitialStepSize = initialStepSize;}
  QString getInitialStepSize() {return mInitialStepSize;}
  void setMaxStepSize(QString maxStepSize) {mMaxStepSize = maxStepSize;}
  QString getMaxStepSize() {return mMaxStepSize;}
  void setMaxIntegration(int maxIntegration) {mMaxIntegration = maxIntegration;}
  int getMaxIntegration() {return mMaxIntegration;}
  void setCflags(QString cflags) {mCflags = cflags;}
  QString getCflags() {return mCflags;}
  void setNumberOfProcessors(int numberOfProcessors) {mNumberOfProcessors = numberOfProcessors;}
  int getNumberOfProcessors() {return mNumberOfProcessors;}
  void setBuildOnly(bool buildOnly) {mBuildOnly = buildOnly;}
  bool getBuildOnly() {return mBuildOnly;}
  void setLaunchTransformationalDebugger(bool launchTransformationalDebugger) {mLaunchTransformationalDebugger = launchTransformationalDebugger;}
  bool getLaunchTransformationalDebugger() {return mLaunchTransformationalDebugger;}
  void setLaunchAlgorithmicDebugger(bool launchAlgorithmicDebugger) {mLaunchAlgorithmicDebugger = launchAlgorithmicDebugger;}
  bool getLaunchAlgorithmicDebugger() {return mLaunchAlgorithmicDebugger;}
  void setSimulateWithAnimation(bool simulateWithAnimation) {mSimulateWithAnimation = simulateWithAnimation;}
  bool getSimulateWithAnimation() {return mSimulateWithAnimation;}

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
  void setPedantic(bool pedantic) {mPedantic = pedantic;}
  bool getPedantic() const {return mPedantic;}
  void setParmodauto(bool parmodauto) {mParmodauto = parmodauto;}
  bool getParmodauto() const {return mParmodauto;}
  void setNewInstantiation(bool newInstantiation) {mNewInstantiation = newInstantiation;}
  bool getNewInstantiation() const {return mNewInstantiation;}
  void setDataReconciliation(bool dataReconciliation) {mDataReconciliation = dataReconciliation;}
  bool getDataReconciliation() const {return mDataReconciliation;}
  void setAdditionalTranslationFlags(QString additionalTranslationFlags) {mAdditionalTranslationFlags = additionalTranslationFlags;}
  QString getAdditionalTranslationFlags() const {return mAdditionalTranslationFlags;}

  void setModelSetupFile(QString modelSetupFile) {mModelSetupFile = modelSetupFile;}
  QString getModelSetupFile() {return mModelSetupFile;}
  void setInitializationMethod(QString initializationMethod) {mInitializationMethod = initializationMethod;}
  QString getInitializationMethod() {return mInitializationMethod;}
  void setEquationSystemInitializationFile(QString equationSystemInitializationFile) {mEquationSystemInitializationFile = equationSystemInitializationFile;}
  QString getEquationSystemInitializationFile() {return mEquationSystemInitializationFile;}
  void setEquationSystemInitializationTime(QString equationSystemInitializationTime) {mEquationSystemInitializationTime = equationSystemInitializationTime;}
  QString getEquationSystemInitializationTime() {return mEquationSystemInitializationTime;}
  void setClock(QString clock) {mClock = clock;}
  QString getClock() {return mClock;}
  void setLinearSolver(QString linearSolver) {mLinearSolver = linearSolver;}
  QString getLinearSolver() {return mLinearSolver;}
  void setNonLinearSolver(QString nonLinearSolver) {mNonLinearSolver = nonLinearSolver;}
  QString getNonLinearSolver() {return mNonLinearSolver;}
  void setLinearizationTime(QString linearizationTime) {mLinearizationTime = linearizationTime;}
  QString getLinearizationTime() {return mLinearizationTime;}
  void setOutputVariables(QString outputVariables) {mOutputVariables = outputVariables;}
  QString getOutputVariables() {return mOutputVariables;}
  void setProfiling(QString profiling) {mProfiling = profiling;}
  QString getProfiling() {return mProfiling;}
  void setCPUTime(bool cpuTime) {mCPUTime = cpuTime;}
  bool getCPUTime() {return mCPUTime;}
  void setEnableAllWarnings(bool enableAllWarnings) {mEnableAllWarnings = enableAllWarnings;}
  bool getEnableAllWarnings() {return mEnableAllWarnings;}
  void setReconcile(bool reconcile) {mReconcile = reconcile;}
  bool getReconcile() {return mReconcile;}
  void setDataReconciliationInputFile(QString dataReconciliationInputFile) {mDataReconciliationInputFile = dataReconciliationInputFile;}
  QString getDataReconciliationInputFile() {return mDataReconciliationInputFile;}
  void setDataReconciliationEpsilon(QString dataReconciliationEpsilon) {mDataReconciliationEpsilon = dataReconciliationEpsilon;}
  QString getDataReconciliationEpsilon() {return mDataReconciliationEpsilon;}
  void setLogStreams(QStringList logStreams) {mLogStreams = logStreams;}
  QStringList getLogStreams() {return mLogStreams;}
  void setAdditionalSimulationFlags(QString additionalSimulationFlags) {mAdditionalSimulationFlags = additionalSimulationFlags;}
  QString getAdditionalSimulationFlags() {return mAdditionalSimulationFlags;}

  void setOutputFormat(QString outputFormat) {mOutputFormat = outputFormat;}
  QString getOutputFormat() {return mOutputFormat;}
  void setSinglePrecision(bool singlePrecision) {mSinglePrecision = singlePrecision;}
  bool getSinglePrecision() {return mSinglePrecision;}
  void setFileNamePrefix(QString fileNamePrefix) {mFileNamePrefix = fileNamePrefix;}
  QString getFileNamePrefix() {return mFileNamePrefix;}
  QString getOutputFileName() const {return mFileNamePrefix.isEmpty() ? mClassName : mFileNamePrefix;}
  void setResultFileName(QString resultFileName) {mResultFileName = resultFileName;}
  QString getResultFileName() {return mResultFileName;}
  QString getFullResultFileName() {return mResultFileName.isEmpty() ? getOutputFileName() + "_res." + mOutputFormat : mResultFileName;}
  void setVariableFilter(QString variableFilter) {mVariableFilter = variableFilter;}
  QString getVariableFilter() {return mVariableFilter.isEmpty() ? ".*" : mVariableFilter;}
  void setProtectedVariables(bool protectedVariables) {mProtectedVariables = protectedVariables;}
  bool getProtectedVariables() {return mProtectedVariables;}
  void setEquidistantTimeGrid(bool equidistantTimeGrid) {mEquidistantTimeGrid = equidistantTimeGrid;}
  bool getEquidistantTimeGrid() {return mEquidistantTimeGrid;}
  void setStoreVariablesAtEvents(bool storeVariablesAtEvents) {mStoreVariablesAtEvents = storeVariablesAtEvents;}
  bool getStoreVariablesAtEvents() {return mStoreVariablesAtEvents;}
  void setShowGeneratedFiles(bool showGeneratedFiles) {mShowGeneratedFiles = showGeneratedFiles;}
  bool getShowGeneratedFiles() {return mShowGeneratedFiles;}

  void setSimulationFlags(QStringList simulationFlags) {mSimulationFlags = simulationFlags;}
  QStringList getSimulationFlags() {return mSimulationFlags;}
  void setIsValid(bool isValid) {mValid = isValid;}
  bool isValid() {return mValid;}
  void setReSimulate(bool reSimulate) {mReSimulate = reSimulate;}
  bool isReSimulate() {return mReSimulate;}
  void setWorkingDirectory(QString workingDirectory) {mWorkingDirectory = workingDirectory;}
  QString getWorkingDirectory() const {return mWorkingDirectory;}
  void setFileName(QString fileName) {mFileName = fileName;}
  QString getFileName() const {return mFileName;}
  void setTargetLanguage(QString targetLanguage) {mTargetLanguage = targetLanguage;}
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
  bool mPedantic;
  bool mParmodauto;
  bool mNewInstantiation;
  bool mDataReconciliation;
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
  bool mReconcile;
  QString mDataReconciliationInputFile;
  QString mDataReconciliationEpsilon;
  QStringList mLogStreams;
  QString mAdditionalSimulationFlags;
  // output
  QString mOutputFormat;
  bool mSinglePrecision;
  QString mFileNamePrefix;
  QString mResultFileName;
  QString mVariableFilter;
  bool mProtectedVariables;
  bool mEquidistantTimeGrid;
  bool mStoreVariablesAtEvents;
  bool mShowGeneratedFiles;

  QStringList mSimulationFlags;
  bool mValid;
  bool mReSimulate;
  QString mWorkingDirectory;
  QString mFileName;
  QString mTargetLanguage;
};

#endif // SIMULATIONOPTIONS_H
