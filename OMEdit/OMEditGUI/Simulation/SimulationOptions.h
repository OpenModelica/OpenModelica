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

#include <QString>
#include <QVariant>
#include <QStringList>

class SimulationOptions
{
public:
  SimulationOptions()
  {
    setClassName("");
    setStartTime("");
    setStopTime("");
    setMethod("");
    setTolerance("");
    setJacobian("");
    setDasslRootFinding(true);
    setDasslRestart(true);
    setDasslInitialStepSize("");
    setDasslMaxStepSize("");
    setDasslMaxIntegration(5);
    setCflags("");
    setNumberOfProcessors(1);
    setBuildOnly(false);
    setLaunchTransformationalDebugger(false);
    setLaunchAlgorithmicDebugger(false);
    setSimulateWithAnimation(false);
    setNumberofIntervals(500);
    setStepSize(0.002);
    setOutputFormat("mat");
    setFileNamePrefix("");
    setResultFileName("");
    setVariableFilter("");
    setProtectedVariables(false);
    setEquidistantTimeGrid(true);
    setStoreVariablesAtEvents(true);
    setShowGeneratedFiles(false);
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
    setLogStreams(QStringList());
    setAdditionalSimulationFlags("");
    setIsValid(false);
    setReSimulate(false);
    setWorkingDirectory("");
    setFileName("");
  }

  void setClassName(QString className) {mClassName = className;}
  QString getClassName() {return mClassName;}
  void setStartTime(QString startTime) {mStartTime = startTime;}
  QString getStartTime() {return mStartTime;}
  void setStopTime(QString stopTime) {mStopTime = stopTime;}
  QString getStopTime() {return mStopTime;}
  void setMethod(QString method) {mMethod = method;}
  QString getMethod() {return mMethod;}
  void setTolerance(QString tolerance) {mTolerance = tolerance;}
  QString getTolerance() {return mTolerance;}
  void setJacobian(QString jacobian) {mJacobian = jacobian;}
  QString getJacobian() {return mJacobian;}
  void setDasslRootFinding(bool dasslRootFinding) {mDasslRootFinding = dasslRootFinding;}
  bool getDasslRootFinding() {return mDasslRootFinding;}
  void setDasslRestart(bool dasslRestart) {mDasslRestart = dasslRestart;}
  bool getDasslRestart() {return mDasslRestart;}
  void setDasslInitialStepSize(QString dasslInitialStepSize) {mDasslInitialStepSize = dasslInitialStepSize;}
  QString getDasslInitialStepSize() {return mDasslInitialStepSize;}
  void setDasslMaxStepSize(QString dasslMaxStepSize) {mDasslMaxStepSize = dasslMaxStepSize;}
  QString getDasslMaxStepSize() {return mDasslMaxStepSize;}
  void setDasslMaxIntegration(int dasslMaxIntegration) {mDasslMaxIntegration = dasslMaxIntegration;}
  int getDasslMaxIntegration() {return mDasslMaxIntegration;}
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
  void setNumberofIntervals(int numberofIntervals) {mNumberofIntervals = numberofIntervals;}
  int getNumberofIntervals() {return mNumberofIntervals;}
  void setStepSize(qreal stepSize) {mStepSize = stepSize;}
  qreal getStepSize() {return mStepSize;}
  void setOutputFormat(QString outputFormat) {mOutputFormat = outputFormat;}
  QString getOutputFormat() {return mOutputFormat;}
  void setFileNamePrefix(QString fileNamePrefix) {mFileNamePrefix = fileNamePrefix;}
  QString getFileNamePrefix() {return mFileNamePrefix;}
  QString getOutputFileName() const {return mFileNamePrefix.isEmpty() ? mClassName : mFileNamePrefix;}
  void setResultFileName(QString resultFileName) {mResultFileName = resultFileName;}
  QString getResultFileName() {return mResultFileName.isEmpty() ? getOutputFileName() + "_res." + mOutputFormat : mResultFileName;}
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
  void setLogStreams(QStringList logStreams) {mLogStreams = logStreams;}
  QStringList getLogStreams() {return mLogStreams;}
  void setAdditionalSimulationFlags(QString additionalSimulationFlags) {mAdditionalSimulationFlags = additionalSimulationFlags;}
  QString getAdditionalSimulationFlags() {return mAdditionalSimulationFlags;}

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
private:
  QString mClassName;
  QString mStartTime;
  QString mStopTime;
  QString mMethod;
  QString mTolerance;
  QString mJacobian;
  bool mDasslRootFinding;
  bool mDasslRestart;
  QString mDasslInitialStepSize;
  QString mDasslMaxStepSize;
  int mDasslMaxIntegration;
  QString mCflags;
  int mNumberOfProcessors;
  bool mBuildOnly;
  bool mLaunchTransformationalDebugger;
  bool mLaunchAlgorithmicDebugger;
  bool mSimulateWithAnimation;
  int mNumberofIntervals;
  qreal mStepSize;
  QString mOutputFormat;
  QString mFileNamePrefix;
  QString mResultFileName;
  QString mVariableFilter;
  bool mProtectedVariables;
  bool mEquidistantTimeGrid;
  bool mStoreVariablesAtEvents;
  bool mShowGeneratedFiles;
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
  QStringList mLogStreams;
  QString mAdditionalSimulationFlags;

  QStringList mSimulationFlags;
  bool mValid;
  bool mReSimulate;
  QString mWorkingDirectory;
  QString mFileName;
};

#endif // SIMULATIONOPTIONS_H
