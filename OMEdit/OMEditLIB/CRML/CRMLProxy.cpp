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

#include "CRMLProxy.h"
#include "Util/Helper.h"
#include "MainWindow.h"
#include "Util/Utilities.h"

#include <QTime>

#define LOG_COMMAND(command,args) \
  QElapsedTimer commandTime; \
  commandTime.start(); \
  command = QString("%1(%2)").arg(command, args.join(",")); \
  logCommand(command);


/*!
 * \class CRMLProxy
 * \brief Interface for call CRML Compiler logs API.
 */

CRMLProxy *CRMLProxy::mpInstance = 0;

/*!
 * \brief CRMLProxy::create
 */
void CRMLProxy::create()
{
  if (!mpInstance) {
    mpInstance = new CRMLProxy;
  }
}

/*!
 * \brief CRMLProxy::destroy
 */
void CRMLProxy::destroy()
{
  mpInstance->deleteLater();
  mpInstance = 0;
}

/*!
 * \brief CRMLProxy::CRMLProxy
 */
CRMLProxy::CRMLProxy()
{
  /* create a file to write CRML Compiler communication log */
  QString communicationLogFilePath = QString("%1crmlcommunication.log").arg(Utilities::tempDirectory());
#ifdef Q_OS_WIN
  mpCommunicationLogFile = _wfopen((wchar_t*)communicationLogFilePath.utf16(), L"w");
#else
  mpCommunicationLogFile = fopen(communicationLogFilePath.toUtf8().constData(), "w");
#endif
  mTotalCRMLCallsTime = 0.0;
  // CRML Compiler global settings
  setLogFile(QString(Utilities::tempDirectory() + "/omslog.txt"));
  setTempDirectory(Utilities::tempDirectory());
  qRegisterMetaType<MessageItem>("MessageItem");
  connect(this, SIGNAL(logGUIMessage(MessageItem)), MessagesWidget::instance(), SLOT(addGUIMessage(MessageItem)));
}

CRMLProxy::~CRMLProxy()
{
  if (mpCommunicationLogFile) {
    fclose(mpCommunicationLogFile);
  }
}

/*!
 * \brief CRMLProxy::logCommand
 * Writes the command to the omscommunication.log file.
 * \param command - the command to write
 */
void CRMLProxy::logCommand(QString command)
{
  // write the log to communication log file
  if (mpCommunicationLogFile) {
    fputs(QString("%1 %2\n").arg(command, QTime::currentTime().toString("hh:mm:ss:zzz")).toUtf8().constData(), mpCommunicationLogFile);
  }
}

/*!
 * \brief CRMLProxy::logResponse
 * Writes the response to the omscommunication.log file.
 * \param response - the response to write
 * \param status - execution status of the command
 * \param responseTime - the response end time
 */
void CRMLProxy::logResponse(QString response, int status, QElapsedTimer *responseTime)
{
  double elapsed = (double)responseTime->elapsed() / 1000.0;
  QString firstLine("");
  for (int i = 0; i < response.length(); i++) {
    if (response[i] != '\n') {
      firstLine.append(response[i]);
    } else {
      break;
    }
  }

  // write the log to communication log file
  if (mpCommunicationLogFile) {
    mTotalCRMLCallsTime += elapsed;
    fputs(QString("%1 %2\n").arg(status).arg(QTime::currentTime().toString("hh:mm:ss:zzz")).toUtf8().constData(), mpCommunicationLogFile);
    fputs(QString("#s#; %1; %2; \'%3\'\n\n").arg(QString::number(elapsed, 'f', 6)).arg(QString::number(mTotalCRMLCallsTime, 'f', 6)).arg(firstLine).toUtf8().constData(),  mpCommunicationLogFile);
  }

  // flush the logs if --Debug=true
  if (MainWindow::instance()->isDebug()) {
    fflush(NULL);
  }

  MainWindow::instance()->printStandardOutAndErrorFilesMessages();
}


/*!
 * \brief CRMLProxy::newModel
 * \param cref
 * \return
 */
bool CRMLProxy::newModel(QString cref)
{
  QString command = "crml_newModel";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  logResponse(command, 1, &commandTime);
  return true;
}

/*!
 * \brief CRMLProxy::crmlDelete
 * \param cref
 * \return
 */
bool CRMLProxy::crmlDelete(QString cref)
{
  QString command = "crml_delete";
  QStringList args;
  args << "\"" + cref + "\"";
  LOG_COMMAND(command, args);
  logResponse(command, 1, &commandTime);
  return true;
}

/*!
 * \brief CRMLProxy::setLogFile
 * Sets the log file.
 * \param filename
 */
void CRMLProxy::setLogFile(QString filename)
{
  QString command = "crml_setLogFile";
  QStringList args;
  args << "\"" + filename + "\"";
  LOG_COMMAND(command, args);
  logResponse(command, 1, &commandTime);
}


/*!
 * \brief CRMLProxy::setTempDirectory
 * Sets the temp directory.
 * \param path
 */
void CRMLProxy::setTempDirectory(QString path)
{
  QString command = "crml_setTempDirectory";
  QStringList args;
  args << "\"" + path + "\"";
  LOG_COMMAND(command, args);
  logResponse(command, 1, &commandTime);
}