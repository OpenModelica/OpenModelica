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

#include "FetchInterfaceDataThread.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Options/OptionsDialog.h"

#include <QDir>

FetchInterfaceDataThread::FetchInterfaceDataThread(FetchInterfaceDataDialog *pFetchInterfaceDataDialog)
  : QThread(pFetchInterfaceDataDialog), mpFetchInterfaceDataDialog(pFetchInterfaceDataDialog)
{
  mpManagerProcess = 0;
  mManagerProcessId = 0;
  setIsManagerProcessRunning(false);
}

/*!
 * \brief FetchInterfaceDataThread::run
 * Reimplentation of QThread::run() function. Starts the Manager process to fetch the interface data.
 */
void FetchInterfaceDataThread::run()
{
  mpManagerProcess = new QProcess;
  QFileInfo fileInfo(mpFetchInterfaceDataDialog->getLibraryTreeItem()->getFileName());
  mpManagerProcess->setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  qRegisterMetaType<QProcess::ExitStatus>("QProcess::ExitStatus");
  qRegisterMetaType<StringHandler::SimulationMessageType>("StringHandler::SimulationMessageType");
  connect(mpManagerProcess, SIGNAL(started()), SLOT(managerProcessStarted()));
  connect(mpManagerProcess, SIGNAL(readyReadStandardOutput()), SLOT(readManagerStandardOutput()));
  connect(mpManagerProcess, SIGNAL(readyReadStandardError()), SLOT(readManagerStandardError()));
  connect(mpManagerProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(managerProcessFinished(int,QProcess::ExitStatus)));
  QStringList args;
  args << "-r";
  QString singleModel = mpFetchInterfaceDataDialog->getSingleModel();
  if(!singleModel.isEmpty()) {
      args << "-s" << singleModel;
  }
  args << fileInfo.absoluteFilePath();
  TLMPage *pTLMPage = OptionsDialog::instance()->getTLMPage();
  QProcessEnvironment environment;
#ifdef WIN32
  environment = StringHandler::simulationProcessEnvironment();
  environment.insert("PATH", pTLMPage->getOMTLMSimulatorPath() + ";" + environment.value("PATH"));
#else
  environment = QProcessEnvironment::systemEnvironment();
  environment.insert("PATH", pTLMPage->getTLMPluginPathTextBox()->text() + ":" + environment.value("PATH"));
#endif
  environment.insert("TLMPluginPath", pTLMPage->getOMTLMSimulatorPath());
  mpManagerProcess->setProcessEnvironment(environment);
  mpManagerProcess->start(pTLMPage->getOMTLMSimulatorManagerPath(), args);
  mManagerProcessId = Utilities::getProcessId(mpManagerProcess);
  emit sendManagerOutput(QString("%1 %2").arg(pTLMPage->getOMTLMSimulatorManagerPath()).arg(args.join(" ")), StringHandler::OMEditInfo);
  exec();
}

/*!
 * \brief FetchInterfaceDataThread::managerProcessStarted
 * Slot activated when mpManagerProcess started signal is raised.\n
 * Notifies FetchInterfaceDataDialog about the start of the manager by emitting the sendManagerStarted SIGNAL.
 */
void FetchInterfaceDataThread::managerProcessStarted()
{
  setIsManagerProcessRunning(true);
  emit sendManagerStarted();
}

/*!
 * \brief FetchInterfaceDataThread::readManagerStandardOutput
 * Slot activated when mpManagerProcess readyReadStandardOutput signal is raised.\n
 * Notifies FetchInterfaceDataDialog about the standard output of the manager process by emitting the sendManagerOutput SIGNAL.
 */
void FetchInterfaceDataThread::readManagerStandardOutput()
{
  emit sendManagerOutput(QString(mpManagerProcess->readAllStandardOutput()), StringHandler::Unknown);
}

/*!
 * \brief FetchInterfaceDataThread::readManagerStandardError
 * Slot activated when mpManagerProcess readyReadStandardError signal is raised.\n
 * Notifies FetchInterfaceDataDialog about the standard error of the manager process by emitting the sendManagerOutput SIGNAL.
 */
void FetchInterfaceDataThread::readManagerStandardError()
{
  emit sendManagerOutput(QString(mpManagerProcess->readAllStandardError()), StringHandler::Error);
}

/*!
 * \brief FetchInterfaceDataThread::managerProcessFinished
 * \param exitCode
 * \param exitStatus
 * Slot activated when mpManagerProcess finished signal is raised.\n
 * Notifies FetchInterfaceDataDialog about the exit status by emitting the sendManagerFinished SIGNAL.
 */
void FetchInterfaceDataThread::managerProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  setIsManagerProcessRunning(false);
  QString exitCodeStr = tr("TLMManager process failed. Exited with code %1.").arg(QString::number(exitCode));
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    emit sendManagerOutput(tr("TLMManager process finished successfully."), StringHandler::OMEditInfo);
  } else if (mpManagerProcess->error() == QProcess::UnknownError) {
    emit sendManagerOutput(exitCodeStr, StringHandler::Error);
  } else {
    emit sendManagerOutput(mpManagerProcess->errorString() + "\n" + exitCodeStr, StringHandler::Error);
  }
  emit sendManagerFinished(exitCode, exitStatus);
#ifdef WIN32
  Utilities::killProcessTreeWindows(mManagerProcessId);
#else
  /*! @todo do similar stuff for Linux! */
#endif /*  WIN32 */
  quit();
}

