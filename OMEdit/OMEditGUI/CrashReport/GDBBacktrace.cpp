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

#include "GDBBacktrace.h"
#ifdef WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif
#include "Util/Utilities.h"
#include "Util/Helper.h"
#include "CrashReportDialog.h"

#include <QTemporaryFile>
#include <QFile>

/*!
 * \class GDBBacktrace
 * \brief Prints the backtrace of the program using the GDB backtrace feature.
 */
/*!
 * \brief GDBBacktrace::GDBBacktrace
 * \param parent
 */
GDBBacktrace::GDBBacktrace(QObject *parent)
  : QObject(parent)
{
  // GDB process
  mpGDBProcess = new QProcess;
  connect(mpGDBProcess, SIGNAL(readyRead()), SLOT(readGDBOutput()));
#if (QT_VERSION >= QT_VERSION_CHECK(5, 6, 0))
  connect(mpGDBProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(handleGDBProcessError(QProcess::ProcessError)));
#else
  connect(mpGDBProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(handleGDBProcessError(QProcess::ProcessError)));
#endif
  connect(mpGDBProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(handleGDBProcessFinished(int,QProcess::ExitStatus)));
  connect(mpGDBProcess, SIGNAL(finished(int,QProcess::ExitStatus)), mpGDBProcess, SLOT(deleteLater()));
  mpGDBProcess->setProcessChannelMode(QProcess::MergedChannels);
  QString program = QLatin1String("gdb");
#ifdef WIN32
  program = Utilities::getGDBPath();
  const qint64 processId = GetCurrentProcessId();
#else
  const qint64 processId = getpid();
#endif
  mGDBArguments.clear();
  mGDBArguments << "-q" << "--nw" << "--nx" << "--batch" << "--command" << createTemporaryCommandsFile() << "--pid" << QString::number(processId);
  mOutput.clear();
  mErrorOccurred = false;
  mpGDBProcess->start(program, mGDBArguments);
  mpGDBProcess->waitForFinished(-1);
}

/*!
 * \brief GDBBacktrace::createTemporaryCommandsFile
 * Creates a temporary file for GDB commands.
 * \return
 */
QString GDBBacktrace::createTemporaryCommandsFile()
{
  QTemporaryFile *pCommandsFile = new QTemporaryFile;
  if (!pCommandsFile->open()) {
    mOutput.append("Error: Could not create temporary commands file.");
    return QString();
  }
  connect(this, SIGNAL(finished()), pCommandsFile, SLOT(deleteLater()));
  const char GdbBatchCommands[] =
      "set height 0\n"
      "set width 0\n"
      "thread\n"
      "thread apply all bt full\n";
  if (pCommandsFile->write(GdbBatchCommands) == -1) {
    pCommandsFile->close();
    mOutput.append("Error: Could not write temporary commands file.");
    return QString();
  }
  pCommandsFile->close();
  return pCommandsFile->fileName();
}

/*!
 * \brief GDBBacktrace::showCrashReportDialog
 * Writes the stack trace file and shows the CrashReportDialog
 */
void GDBBacktrace::showCrashReportDialog()
{
  // Dump a stack trace to a file.
  QFile stackTraceFile;
  stackTraceFile.setFileName(QString("%1/openmodelica.stacktrace.%2").arg(Utilities::tempDirectory()).arg(Helper::OMCServerName));
  if (stackTraceFile.open(QIODevice::WriteOnly)) {
    QTextStream out(&stackTraceFile);
    out.setCodec(Helper::utf8.toStdString().data());
    out.setGenerateByteOrderMark(false);
    out << mOutput;
    out.flush();
    stackTraceFile.close();
  }
  CrashReportDialog *pCrashReportDialog = new CrashReportDialog;
  pCrashReportDialog->exec();
  emit finished();
}

/*!
 * \brief GDBBacktrace::readGDBOutput
 * Reads the GDB output.
 */
void GDBBacktrace::readGDBOutput()
{
  QString msg = QString(mpGDBProcess->readAll());
  // if we are unable to attach then set error occurred to true.
  if (msg.startsWith("Could not attach to process", Qt::CaseInsensitive)) {
    mErrorOccurred = true;
  }
  mOutput.append(msg);
}

/*!
 * \brief GDBBacktrace::handleGDBProcessError
 * Handles the GDB process error.
 * \param error
 */
void GDBBacktrace::handleGDBProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mErrorOccurred = true;
  mOutput.append(GUIMessages::getMessage(GUIMessages::GDB_ERROR).arg(mpGDBProcess->errorString()).arg(mGDBArguments.join(" ")));
}

/*!
 * \brief GDBBacktrace::handleGDBProcessFinished
 * Handles the GDB process finished.
 * \param exitCode
 * \param exitStatus
 */
void GDBBacktrace::handleGDBProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  QString exitCodeStr = tr("GDB process failed. Exited with code %1.").arg(exitCode);
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    if (!mErrorOccurred) {
      showCrashReportDialog();
    }
  } else {
    mErrorOccurred = true;
    mOutput.append(mpGDBProcess->errorString() + "\n" + exitCodeStr);
  }
}
