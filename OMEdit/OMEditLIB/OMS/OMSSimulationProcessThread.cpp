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

#include "OMSSimulationProcessThread.h"
#include "Options/OptionsDialog.h"

#include "zmq.h"

OMSSimulationSubscriberThread::OMSSimulationSubscriberThread(QObject *parent)
  : QThread(parent)
{
  mpContext = zmq_ctx_new();
  mpSubscriberSocket = zmq_socket(mpContext, ZMQ_SUB);
  int rc = zmq_bind(mpSubscriberSocket, "tcp://127.0.0.1:*");
  if (rc != 0) {
    mIsFinished = true;
    mEndPoint = "";
    mBindError = QString("Error creating ZeroMQ subscriber socket. zmq_bind failed: %1\n").arg(strerror(errno));
  } else {
    mIsFinished = false;
    // get the end point
    const size_t endPointSize = 30;
    char endPoint[endPointSize];
    zmq_getsockopt(mpSubscriberSocket, ZMQ_LAST_ENDPOINT, &endPoint, (size_t *)&endPointSize);
    mEndPoint = QString(endPoint);
    zmq_setsockopt(mpSubscriberSocket, ZMQ_SUBSCRIBE, "", 0);
    mBindError = "";
  }
}

OMSSimulationSubscriberThread::~OMSSimulationSubscriberThread()
{
  zmq_close(mpSubscriberSocket);
  zmq_ctx_destroy(mpContext);
}

void OMSSimulationSubscriberThread::run()
{
  while (!mIsFinished) {
    zmq_msg_t replyMsg;
    zmq_msg_init(&replyMsg);
    int size = zmq_msg_recv(&replyMsg, mpSubscriberSocket, ZMQ_DONTWAIT);
    if (size > -1) {
      // copy the zmq_msg_t to char*
      char *reply = (char*)malloc(size + 1);
      memcpy(reply, zmq_msg_data(&replyMsg), size);
      reply[size] = 0;
      emit sendProgressJson(QString(reply));
    }
    // release the zmq_msg_t
    zmq_msg_close(&replyMsg);
  }
}

OMSSimulationProcessThread::OMSSimulationProcessThread(const QString &fileName, QObject *parent)
  : QThread(parent), mFileName(fileName)
{
  mpSimulationProcess = 0;
  mIsSimulationProcessKilled = 0;
  mIsSimulationProcessRunning = 0;
}

OMSSimulationProcessThread::~OMSSimulationProcessThread()
{
  if (mpOMSSimulationSubscriberThread) {
    mpOMSSimulationSubscriberThread->setIsFinished(true);
    delete mpOMSSimulationSubscriberThread;
  }
}

void OMSSimulationProcessThread::run()
{
  mpOMSSimulationSubscriberThread = new OMSSimulationSubscriberThread;
  connect(mpOMSSimulationSubscriberThread, SIGNAL(sendProgressJson(QString)), SIGNAL(sendProgressJson(QString)));
  mpOMSSimulationSubscriberThread->start();
  // Start the process if subscriber socket is listening
  if (!mpOMSSimulationSubscriberThread->getEndPoint().isEmpty()) {
    mpSimulationProcess = new QProcess;
    mpSimulationProcess->setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
    connect(mpSimulationProcess, SIGNAL(started()), SLOT(simulationProcessStarted()), Qt::DirectConnection);
    connect(mpSimulationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readSimulationStandardOutput()), Qt::DirectConnection);
    connect(mpSimulationProcess, SIGNAL(readyReadStandardError()), SLOT(readSimulationStandardError()), Qt::DirectConnection);
  #if (QT_VERSION >= QT_VERSION_CHECK(5, 6, 0))
    connect(mpSimulationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(simulationProcessError(QProcess::ProcessError)), Qt::DirectConnection);
  #else
    connect(mpSimulationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(simulationProcessError(QProcess::ProcessError)), Qt::DirectConnection);
  #endif
    connect(mpSimulationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(simulationProcessFinished(int,QProcess::ExitStatus)), Qt::DirectConnection);
    QStringList args(QString("C:/OpenModelica/OMSimulator/src/OMSimulatorServer/OMSimulatorServer.py"));
    args << QString("--endpoint-pub=%1").arg(mpOMSSimulationSubscriberThread->getEndPoint());
    args << QString("--model=%1").arg(mFileName);
    // start the executable
    QString fileName = QString("%1/bin/OMSimulatorPython3").arg(Helper::OpenModelicaHome);
  #ifdef WIN32
    fileName = fileName.append(".bat");
  #endif
    // run the simulation executable to create the result file
    emit sendSimulationOutput(QString("%1 %2\n").arg(fileName).arg(args.join(" ")), StringHandler::OMEditInfo, true);
    mpSimulationProcess->start(fileName, args);
    QThread::run();
  } else {
    emit sendSimulationOutput(mpOMSSimulationSubscriberThread->getBindError(), StringHandler::Error, true);
    emit sendSimulationFinished(1, QProcess::NormalExit);
  }
}

void OMSSimulationProcessThread::simulationProcessStarted()
{
  mIsSimulationProcessRunning = true;
  emit sendSimulationStarted();
}

void OMSSimulationProcessThread::readSimulationStandardOutput()
{
  emit sendSimulationOutput(QString(mpSimulationProcess->readAllStandardOutput()), StringHandler::Unknown, true);
}

void OMSSimulationProcessThread::readSimulationStandardError()
{
  emit sendSimulationOutput(QString(mpSimulationProcess->readAllStandardError()), StringHandler::Error, true);
}

void OMSSimulationProcessThread::simulationProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mIsSimulationProcessRunning = false;
  /* this signal is raised when we kill the simulation process forcefully. */
  if (!isSimulationProcessKilled()) {
    emit sendSimulationOutput(mpSimulationProcess->errorString(), StringHandler::Error, true);
  }
  mpOMSSimulationSubscriberThread->setIsFinished(true);
  exit();
}

void OMSSimulationProcessThread::simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
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
  mpOMSSimulationSubscriberThread->setIsFinished(true);
  exit();
}
