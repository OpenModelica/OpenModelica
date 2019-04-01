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

#include <QProcess>
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
  QString program = QLatin1String("gdb");
#ifdef WIN32
  program = Utilities::getGDBPath();
  const qint64 processId = GetCurrentProcessId();
#else
  const qint64 processId = getpid();
#endif
  QStringList gdbArguments;
  QString errorString;
  QString gdbCommandsFilePath = createCommandsFile(&errorString);
  if (gdbCommandsFilePath.isEmpty()) {
    mOutput = errorString;
    mErrorOccurred = true;
  } else {
    // GDB process
    QProcess gdbProcess;
    gdbProcess.setProcessChannelMode(QProcess::MergedChannels);
    gdbProcess.setStandardOutputFile(QString("%1/openmodelica.stacktrace.%2").arg(Utilities::tempDirectory()).arg(Helper::OMCServerName));
    gdbArguments << "-q" << "--nw" << "--nx" << "--batch" << "--command" << gdbCommandsFilePath << "--pid" << QString::number(processId);
    gdbProcess.start(program, gdbArguments);
    gdbProcess.waitForFinished(-1);
    if (gdbProcess.exitStatus() == QProcess::NormalExit && gdbProcess.exitCode() == 0) {
      mOutput = "";
      mErrorOccurred = false;
    } else {
      mOutput = gdbProcess.errorString();
      mErrorOccurred = true;
    }
  }
}

/*!
 * \brief GDBBacktrace::createTemporaryCommandsFile
 * Creates a temporary file for GDB commands.
 * \return
 */
QString GDBBacktrace::createCommandsFile(QString *errorString)
{
  const char gdbBatchCommands[] = "set height 0\n"
                                  "set width 0\n"
                                  "thread\n"
                                  "thread apply all bt full\n";
  QFile gdbBacktraceCommandsFile;
  QString gdbBacktraceCommandsFilePath = QString("%1omeditbacktracecommands.txt").arg(Utilities::tempDirectory());
  gdbBacktraceCommandsFile.setFileName(gdbBacktraceCommandsFilePath);
  if (gdbBacktraceCommandsFile.open(QIODevice::WriteOnly)) {
    QTextStream out(&gdbBacktraceCommandsFile);
    out.setCodec(Helper::utf8.toStdString().data());
    out.setGenerateByteOrderMark(false);
    out << gdbBatchCommands;
    out.flush();
    gdbBacktraceCommandsFile.close();
    return gdbBacktraceCommandsFilePath;
  } else {
    *errorString = QString("Error: Could not create commands file %1.").arg(gdbBacktraceCommandsFilePath);
    return "";
  }
}
