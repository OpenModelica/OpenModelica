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

#include "SimulationProcessThread.h"
#include "Options/OptionsDialog.h"

#include <QDir>

SimulationProcessThread::SimulationProcessThread(SimulationOutputWidget *pSimulationOutputWidget)
  : QThread(pSimulationOutputWidget), mpSimulationOutputWidget(pSimulationOutputWidget)
{
  mpCompilationProcess = 0;
  setCompilationProcessKilled(false);
  mIsCompilationProcessRunning = false;
  mpSimulationProcess = 0;
  setSimulationProcessKilled(false);
  mIsSimulationProcessRunning = false;
}

/*!
 * \brief SimulationProcessThread::run
 * Reimplementation of QThread::run()
 */
void SimulationProcessThread::run()
{
  if (!mpSimulationOutputWidget->getSimulationOptions().isReSimulate()) {
    compileModel();
  } else {
    runSimulationExecutable();
  }
  exec();
}

/*!
 * \brief SimulationProcessThread::compileModel
 * Compiles the simulation model.
 */
void SimulationProcessThread::compileModel()
{
  mpCompilationProcess = new QProcess;
  SimulationOptions simulationOptions = mpSimulationOutputWidget->getSimulationOptions();
  mpCompilationProcess->setWorkingDirectory(simulationOptions.getWorkingDirectory());
  qRegisterMetaType<QProcess::ProcessError>("QProcess::ProcessError");
  qRegisterMetaType<QProcess::ExitStatus>("QProcess::ExitStatus");
  connect(mpCompilationProcess, SIGNAL(started()), SLOT(compilationProcessStarted()), Qt::DirectConnection);
  connect(mpCompilationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readCompilationStandardOutput()), Qt::DirectConnection);
  connect(mpCompilationProcess, SIGNAL(readyReadStandardError()), SLOT(readCompilationStandardError()), Qt::DirectConnection);
#if (QT_VERSION >= QT_VERSION_CHECK(5, 6, 0))
  connect(mpCompilationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(compilationProcessError(QProcess::ProcessError)), Qt::DirectConnection);
#else
  connect(mpCompilationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(compilationProcessError(QProcess::ProcessError)), Qt::DirectConnection);
#endif
  connect(mpCompilationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(compilationProcessFinished(int,QProcess::ExitStatus)), Qt::DirectConnection);
  QString numProcs;
  if (simulationOptions.getNumberOfProcessors() == 0) {
    numProcs = QString::number(simulationOptions.getNumberOfProcessors());
  } else {
    numProcs = QString::number(simulationOptions.getNumberOfProcessors());
  }
  SimulationPage *pSimulationPage = OptionsDialog::instance()->getSimulationPage();
  QStringList args;
#ifdef WIN32
#if defined(__MINGW32__) && defined(__MINGW64__) /* on 64 bit */
  const char* omPlatform = "mingw64";
#else
  const char* omPlatform = "mingw32";
#endif
  args << simulationOptions.getOutputFileName()
       << pSimulationPage->getTargetBuildComboBox()->itemData(pSimulationPage->getTargetBuildComboBox()->currentIndex()).toString()
       << omPlatform << "parallel" << numProcs << "0";
  QString compilationProcessPath = QString(Helper::OpenModelicaHome) + "/share/omc/scripts/Compile.bat";
  emit sendCompilationOutput(QString("%1 %2\n").arg(compilationProcessPath).arg(args.join(" ")), Qt::blue);
  mpCompilationProcess->start(compilationProcessPath, args);
#else
  int numProcsInt = numProcs.toInt();
  if (numProcsInt > 1) {
    args << "-j" + numProcs;
  }
  args << "-f" << simulationOptions.getOutputFileName() + ".makefile";
  emit sendCompilationOutput(QString("%1 %2\n").arg("make").arg(args.join(" ")), Qt::blue);
  mpCompilationProcess->start("make", args);
#endif
}

/*!
 * \brief SimulationProcessThread::runSimulationExecutable
 * Runs the simulation executable.
 */
void SimulationProcessThread::runSimulationExecutable()
{
  mpSimulationProcess = new QProcess;
  SimulationOptions simulationOptions = mpSimulationOutputWidget->getSimulationOptions();
  /* Ticket:4583
   * Use the OMEdit working directory so users can put their input files there.
   */
//  mpSimulationProcess->setWorkingDirectory(simulationOptions.getWorkingDirectory());
  mpSimulationProcess->setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
  qRegisterMetaType<StringHandler::SimulationMessageType>("StringHandler::SimulationMessageType");
  connect(mpSimulationProcess, SIGNAL(started()), SLOT(simulationProcessStarted()), Qt::DirectConnection);
  connect(mpSimulationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readSimulationStandardOutput()), Qt::DirectConnection);
  connect(mpSimulationProcess, SIGNAL(readyReadStandardError()), SLOT(readSimulationStandardError()), Qt::DirectConnection);
#if (QT_VERSION >= QT_VERSION_CHECK(5, 6, 0))
  connect(mpSimulationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(simulationProcessError(QProcess::ProcessError)), Qt::DirectConnection);
#else
  connect(mpSimulationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(simulationProcessError(QProcess::ProcessError)), Qt::DirectConnection);
#endif
  connect(mpSimulationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(simulationProcessFinished(int,QProcess::ExitStatus)), Qt::DirectConnection);
  QStringList args(QString("-port=").append(QString::number(mpSimulationOutputWidget->getTcpServer()->serverPort())));
  args << "-logFormat=xmltcp" << simulationOptions.getSimulationFlags();
  // start the executable
  QString fileName = QString(simulationOptions.getWorkingDirectory()).append("/").append(simulationOptions.getOutputFileName());
  fileName = fileName.replace("//", "/");
  // run the simulation executable to create the result file
#ifdef WIN32
  fileName = fileName.append(".exe");
  QFileInfo fileInfo(simulationOptions.getFileName());
  QProcessEnvironment processEnvironment = StringHandler::simulationProcessEnvironment();
  processEnvironment.insert("PATH", fileInfo.absoluteDir().absolutePath() + ";" + processEnvironment.value("PATH"));
  mpSimulationProcess->setProcessEnvironment(processEnvironment);
#endif
  emit sendSimulationOutput(QString("%1 %2").arg(fileName).arg(args.join(" ")), StringHandler::OMEditInfo, true);
  mpSimulationProcess->start(fileName, args);
}

/*!
 * \brief SimulationProcessThread::compilationProcessStarted
 * Slot activated when mpCompilationProcess started signal is raised.\n
 * Notifies SimulationOutputWidget about the start of the compilation by emitting the sendCompilationStarted SIGNAL.
 */
void SimulationProcessThread::compilationProcessStarted()
{
  mIsCompilationProcessRunning = true;
  emit sendCompilationStarted();
}

/*!
 * \brief SimulationProcessThread::readCompilationStandardOutput
 * Slot activated when mpCompilationProcess readyReadStandardOutput signal is raised.\n
 * Notifies SimulationOutputWidget about the standard output of the compilation process by emitting the sendCompilationOutput SIGNAL.
 */
void SimulationProcessThread::readCompilationStandardOutput()
{
  emit sendCompilationOutput(QString(mpCompilationProcess->readAllStandardOutput()), Qt::black);
}

/*!
 * \brief SimulationProcessThread::readCompilationStandardError
 * Slot activated when mpCompilationProcess readyReadStandardError signal is raised.\n
 * Notifies SimulationOutputWidget about the standard error of the compilation process by emitting the sendCompilationOutput SIGNAL.
 */
void SimulationProcessThread::readCompilationStandardError()
{
  emit sendCompilationOutput(QString(mpCompilationProcess->readAllStandardError()), Qt::red);
}

/*!
 * \brief SimulationProcessThread::compilationProcessError
 * Slot activated when mpCompilationProcess errorOccurred signal is raised.\n
 * Notifies the SimulationOutputWidget about the erro by emitting the sendCompilationOutput signal.
 * \param error
 */
void SimulationProcessThread::compilationProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mIsCompilationProcessRunning = false;
  /* this signal is raised when we kill the compilation process forcefully. */
  if (isCompilationProcessKilled()) {
    return;
  }
  emit sendCompilationOutput(mpCompilationProcess->errorString(), Qt::red);
}

/*!
 * \brief SimulationProcessThread::compilationProcessFinished
 * Slot activated when mpCompilationProcess finished signal is raised.\n
 * Notifies SimulationOutputWidget about the exit status by emitting the sendCompilationOutput SIGNAL.\n
 * If the mpCompilationProcess finished normally then run the simulation executable.
 * \param exitCode
 * \param exitStatus
 */
void SimulationProcessThread::compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsCompilationProcessRunning = false;
  QString exitCodeStr = tr("Compilation process failed. Exited with code %1.").arg(exitCode);
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    emit sendCompilationOutput(tr("Compilation process finished successfully."), Qt::blue);
    emit sendCompilationFinished(exitCode, exitStatus);
    // if not build only and launch the algorithmic debugger is false then run the simulation process.
    SimulationOptions simulationOptions = mpSimulationOutputWidget->getSimulationOptions();
    if (!simulationOptions.getBuildOnly() && !simulationOptions.getLaunchAlgorithmicDebugger()) {
      runSimulationExecutable();
    }
  } else if (mpCompilationProcess->error() == QProcess::UnknownError) {
    emit sendCompilationOutput(exitCodeStr, Qt::red);
    emit sendCompilationFinished(exitCode, exitStatus);
  } else {
    emit sendCompilationOutput(mpCompilationProcess->errorString() + "\n" + exitCodeStr, Qt::red);
    emit sendCompilationFinished(exitCode, exitStatus);
  }
}

/*!
 * \brief SimulationProcessThread::simulationProcessStarted
 * Slot activated when mpSimulationProcess started signal is raised.\n
 * Notifies SimulationOutputWidget about the start of the simulation by emitting the sendCompilationStarted SIGNAL.
 */
void SimulationProcessThread::simulationProcessStarted()
{
  mIsSimulationProcessRunning = true;
  emit sendSimulationStarted();
}

/*!
 * \brief SimulationProcessThread::readSimulationStandardOutput
 * Slot activated when mpSimulationProcess readyReadStandardOutput signal is raised.\n
 * Notifies SimulationOutputWidget about the standard output of the simulation process by emitting the sendSimulationStarted SIGNAL.
 */
void SimulationProcessThread::readSimulationStandardOutput()
{
  /* The remote embedded server does not currently disconnect connected clients when a simulation finishes.
   * This check hides the mazy network message of an open connection at shutdown.
   */
  QRegExp rx("info/network");
  QString stdOutput = mpSimulationProcess->readAllStandardOutput();
  if (!stdOutput.contains(rx)) {
    emit sendSimulationOutput(stdOutput, StringHandler::Unknown, true);
  }
}

/*!
 * \brief SimulationProcessThread::readSimulationStandardError
 * Slot activated when mpSimulationProcess readyReadStandardError signal is raised.\n
 * Notifies SimulationOutputWidget about the standard error of the simulation process by emitting the sendSimulationOutput SIGNAL.
 */
void SimulationProcessThread::readSimulationStandardError()
{
  emit sendSimulationOutput(QString(mpSimulationProcess->readAllStandardError()), StringHandler::Error, true);
}

/*!
 * \brief SimulationProcessThread::simulationProcessError
 * Slot activated when mpSimulationProcess errorOccurred signal is raised.\n
 * Notifies the SimulationOutputWidget about the erro by emitting the sendSimulationOutput signal.
 * \param error
 */
void SimulationProcessThread::simulationProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mIsSimulationProcessRunning = false;
  /* this signal is raised when we kill the simulation process forcefully. */
  if (isSimulationProcessKilled()) {
    return;
  }
  emit sendSimulationOutput(mpSimulationProcess->errorString(), StringHandler::Error, true);
}

/*!
 * \brief SimulationProcessThread::simulationProcessFinished
 * Slot activated when mpSimulationProcess finished signal is raised.\n
 * Notifies SimulationOutputWidget about the exit status by emitting the sendSimulationFinished SIGNAL.
 * \param exitCode
 * \param exitStatus
 */
void SimulationProcessThread::simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  while (!mpSimulationOutputWidget->isSocketDisconnected()) {
    Sleep::msleep(1);
  }
  mIsSimulationProcessRunning = false;
  QString exitCodeStr = tr("Simulation process failed. Exited with code %1.").arg(QString::number(exitCode));
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    /* Ticket:4486
     * Don't print the success message since omc now outputs the success information.
     */
    //emit sendSimulationOutput(tr("Simulation process finished successfully."), StringHandler::OMEditInfo, true);
  } else if (mpSimulationProcess->error() == QProcess::UnknownError) {
    emit sendSimulationOutput(exitCodeStr, StringHandler::Error, true);
  } else {
    emit sendSimulationOutput(mpSimulationProcess->errorString() + "\n" + exitCodeStr, StringHandler::Error, true);
  }
  emit sendSimulationFinished(exitCode, exitStatus);
}
