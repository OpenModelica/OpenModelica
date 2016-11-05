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
#include <QTcpSocket>
#include <QTcpServer>

SimulationProcessThread::SimulationProcessThread(SimulationOutputWidget *pSimulationOutputWidget)
  : QThread(pSimulationOutputWidget), mpSimulationOutputWidget(pSimulationOutputWidget)
{
  mpCompilationProcess = 0;
  mIsCompilationProcessRunning = false;
  mpSimulationProcess = 0;
  mIsSimulationProcessRunning = false;
}

void SimulationProcessThread::run()
{
  if (!mpSimulationOutputWidget->getSimulationOptions().isReSimulate()) {
    compileModel();
  } else {
    runSimulationExecutable();
  }
  exec();
}

void SimulationProcessThread::compileModel()
{
  mpCompilationProcess = new QProcess;
  SimulationOptions simulationOptions = mpSimulationOutputWidget->getSimulationOptions();
  mpCompilationProcess->setWorkingDirectory(simulationOptions.getWorkingDirectory());
  qRegisterMetaType<QProcess::ExitStatus>("QProcess::ExitStatus");
  connect(mpCompilationProcess, SIGNAL(started()), SLOT(compilationProcessStarted()));
  connect(mpCompilationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readCompilationStandardOutput()));
  connect(mpCompilationProcess, SIGNAL(readyReadStandardError()), SLOT(readCompilationStandardError()));
  connect(mpCompilationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(compilationProcessFinished(int,QProcess::ExitStatus)));
  QString numProcs;
  if (simulationOptions.getNumberOfProcessors() == 0) {
    numProcs = QString::number(simulationOptions.getNumberOfProcessors());
  } else {
    numProcs = QString::number(simulationOptions.getNumberOfProcessors());
  }
  SimulationPage *pSimulationPage = mpSimulationOutputWidget->getMainWindow()->getOptionsDialog()->getSimulationPage();
  QStringList args;
#ifdef WIN32
#if defined(__MINGW32__) && defined(__MINGW64__) /* on 64 bit */
  const char* omPlatform = "mingw64";
#else
  const char* omPlatform = "mingw32";
#endif
  args << simulationOptions.getOutputFileName() << pSimulationPage->getTargetCompilerComboBox()->currentText() << omPlatform << "parallel" << numProcs << "0";
  QString compilationProcessPath = QString(Helper::OpenModelicaHome) + "/share/omc/scripts/Compile.bat";
  mpCompilationProcess->start(compilationProcessPath, args);
  emit sendCompilationOutput(QString("%1 %2\n").arg(compilationProcessPath).arg(args.join(" ")), Qt::blue);
#else
  int numProcsInt = numProcs.toInt();
  if (numProcsInt > 1) {
    args << "-j" + numProcs;
  }
  args << "-f" << simulationOptions.getOutputFileName() + ".makefile";
  mpCompilationProcess->start("make", args);
  emit sendCompilationOutput(QString("%1 %2\n").arg("make").arg(args.join(" ")), Qt::blue);
#endif
}

void SimulationProcessThread::runSimulationExecutable()
{
  mpSimulationProcess = new QProcess;
  SimulationOptions simulationOptions = mpSimulationOutputWidget->getSimulationOptions();
  mpSimulationProcess->setWorkingDirectory(simulationOptions.getWorkingDirectory());
  qRegisterMetaType<StringHandler::SimulationMessageType>("StringHandler::SimulationMessageType");
  connect(mpSimulationProcess, SIGNAL(started()), SLOT(simulationProcessStarted()));
  connect(mpSimulationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readSimulationStandardOutput()));
  connect(mpSimulationProcess, SIGNAL(readyReadStandardError()), SLOT(readSimulationStandardError()));
  connect(mpSimulationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(simulationProcessFinished(int,QProcess::ExitStatus)));
  QTcpServer *pTcpServer = new QTcpServer;
  pTcpServer->listen(QHostAddress(QHostAddress::LocalHost));
  connect(pTcpServer, SIGNAL(newConnection()), SLOT(createSimulationProgressSocket()));
  QStringList args(QString("-port=").append(QString::number(pTcpServer->serverPort())));
  args << "-logFormat=xml" << simulationOptions.getSimulationFlags();
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
  mpSimulationProcess->start(fileName, args);
  emit sendSimulationOutput(QString("%1 %2").arg(fileName).arg(args.join(" ")), StringHandler::OMEditInfo, true);
}

/*!
  Slot activated when mpCompilationProcess started signal is raised.\n
  Notifies SimulationOutputWidget about the start of the compilation by emitting the sendCompilationStarted SIGNAL.
  */
void SimulationProcessThread::compilationProcessStarted()
{
  mIsCompilationProcessRunning = true;
  emit sendCompilationStarted();
}

/*!
  Slot activated when mpCompilationProcess readyReadStandardOutput signal is raised.\n
  Notifies SimulationOutputWidget about the standard output of the compilation process by emitting the sendCompilationOutput SIGNAL.
  */
void SimulationProcessThread::readCompilationStandardOutput()
{
  emit sendCompilationOutput(QString(mpCompilationProcess->readAllStandardOutput()), Qt::black);
}

/*!
  Slot activated when mpCompilationProcess readyReadStandardError signal is raised.\n
  Notifies SimulationOutputWidget about the standard error of the compilation process by emitting the sendCompilationOutput SIGNAL.
  */
void SimulationProcessThread::readCompilationStandardError()
{
  emit sendCompilationOutput(QString(mpCompilationProcess->readAllStandardError()), Qt::red);
}

/*!
  Slot activated when mpCompilationProcess finished signal is raised.\n
  Notifies SimulationOutputWidget about the exit status by emitting the sendCompilationOutput SIGNAL.\n
  If the mpCompilationProcess finished normally then run the simulation executable.
  */
void SimulationProcessThread::compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsCompilationProcessRunning = false;
  // Read the log file
//  SimulationOptions simulationOptions = mpSimulationOutputWidget->getSimulationOptions();
//  QString fileName = QString("%1/%2.log").arg(simulationOptions.getWorkingDirectory()).arg(simulationOptions.getOutputFileName());
//  QFile logFile(fileName);
//  if (logFile.open(QIODevice::ReadOnly)) {
//    emit sendCompilationOutput(QString(logFile.readAll()), Qt::black);
//    logFile.close();
//  } else {
//    emit sendCompilationOutput(QString("Error reading the file %1. %2").arg(fileName).arg(logFile.errorString()), Qt::red);
//  }
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
  Slot activated when mpSimulationProcess started signal is raised.\n
  Notifies SimulationOutputWidget about the start of the simulation by emitting the sendCompilationStarted SIGNAL.
  */
void SimulationProcessThread::simulationProcessStarted()
{
  mIsSimulationProcessRunning = true;
  emit sendSimulationStarted();
}

/*!
  Slot activated when mpSimulationProcess readyReadStandardOutput signal is raised.\n
  Notifies SimulationOutputWidget about the standard output of the simulation process by emitting the sendSimulationStarted SIGNAL.
  */
void SimulationProcessThread::readSimulationStandardOutput()
{
  emit sendSimulationOutput(QString(mpSimulationProcess->readAllStandardOutput()), StringHandler::Unknown, false);
}

/*!
  Slot activated when mpSimulationProcess readyReadStandardError signal is raised.\n
  Notifies SimulationOutputWidget about the standard error of the simulation process by emitting the sendSimulationOutput SIGNAL.
  */
void SimulationProcessThread::readSimulationStandardError()
{
  emit sendSimulationOutput(QString(mpSimulationProcess->readAllStandardError()), StringHandler::Error, true);
}

/*!
  Slot activated when mpSimulationProcess finished signal is raised.\n
  Notifies SimulationOutputWidget about the exit status by emitting the sendSimulationFinished SIGNAL.
  */
void SimulationProcessThread::simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsSimulationProcessRunning = false;
  QString exitCodeStr = tr("Simulation process failed. Exited with code %1.").arg(QString::number(exitCode));
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    emit sendSimulationOutput(tr("Simulation process finished successfully."), StringHandler::OMEditInfo, true);
  } else if (mpSimulationProcess->error() == QProcess::UnknownError) {
    emit sendSimulationOutput(exitCodeStr, StringHandler::Error, true);
  } else {
    emit sendSimulationOutput(mpSimulationProcess->errorString() + "\n" + exitCodeStr, StringHandler::Error, true);
  }
  emit sendSimulationFinished(exitCode, exitStatus);
}

void SimulationProcessThread::createSimulationProgressSocket()
{
  if (sender()) {
    QTcpServer *pTcpServer = qobject_cast<QTcpServer*>(const_cast<QObject*>(sender()));
    if (pTcpServer && pTcpServer->hasPendingConnections()) {
      QTcpSocket *pTcpSocket = pTcpServer->nextPendingConnection();
      connect(pTcpSocket, SIGNAL(readyRead()), SLOT(readSimulationProgress()));
      disconnect(pTcpServer, SIGNAL(newConnection()), this, SLOT(createSimulationProgressSocket()));
    }
  }
}

void SimulationProcessThread::readSimulationProgress()
{
  if (sender()) {
    QTcpSocket *pTcpSocket = qobject_cast<QTcpSocket*>(const_cast<QObject*>(sender()));
    if (pTcpSocket) {
      const int SOCKMAXLEN = 4096;
      char buf[SOCKMAXLEN];
      if (pTcpSocket->readLine(buf,SOCKMAXLEN) > 0) {
        char *msg = 0;
        double d = strtod(buf, &msg);
        if (msg == buf || *msg != ' ') {
          // do we really need to take care of this communication error?????
          //fprintf(stderr, "TODO: OMEdit GUI: COMM ERROR '%s'", buf);
        } else {
          emit sendSimulationProgress(d/100.0);
          //fprintf(stderr, "TODO: OMEdit GUI: Display progress (%g%%) and message: %s", d/100.0, msg+1);
        }
      }
    }
  }
}
