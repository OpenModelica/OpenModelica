/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * @author John Tinnerholm
 */

#include "AutoLayout.h"
#include "MainWindow.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"

#include <QCoreApplication>
#include <QEventLoop>
#include <QFileInfo>
#include <QProcess>
#include <QProgressDialog>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>
#include <utility>

namespace {
const char *programKey = "autoLayout/program";
// The longest a layout may take; mocoal lays out the MSL 4.1.0 (2552 files) in about 1 s.
const int timeoutMs = 60000;
// True while mocoal runs: the event loop of the progress dialog must not start another change of a class.
bool running = false;

enum class WaitResult { Finished, Cancelled, TimedOut };

/*!
 * \brief waitForProcess
 * Waits for mocoal to end. After a second a dialog with Cancel shows; after timeoutMs it is stopped.
 */
WaitResult waitForProcess(QProcess *pProcess, const QString &className)
{
  pProcess->waitForFinished(1000);
  if (pProcess->state() == QProcess::NotRunning) {
    return WaitResult::Finished;
  }
  QProgressDialog progress(QCoreApplication::translate("AutoLayout", "Laying out %1 with mocoal ...").arg(className),
                           QCoreApplication::translate("AutoLayout", "Cancel"), 0, 0, MainWindow::instance());
  progress.setWindowModality(Qt::ApplicationModal);
  progress.setMinimumDuration(0);
  QEventLoop loop;
  QTimer timer;
  timer.setSingleShot(true);
  QObject::connect(pProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), &loop, &QEventLoop::quit);
  QObject::connect(&progress, &QProgressDialog::canceled, &loop, &QEventLoop::quit);
  QObject::connect(&timer, &QTimer::timeout, &loop, &QEventLoop::quit);
  timer.start(timeoutMs - 1000);
  progress.show();
  if (pProcess->state() != QProcess::NotRunning) {
    loop.exec();
  }
  if (pProcess->state() == QProcess::NotRunning) {
    return WaitResult::Finished;
  }
  return progress.wasCanceled() ? WaitResult::Cancelled : WaitResult::TimedOut;
}
}

/*!
 * \brief AutoLayout::isRunning
 * True while mocoal runs. Changes of classes (MCP tools, another layout, undo) are refused then: the progress dialog
 * runs an event loop.
 */
bool AutoLayout::isRunning()
{
  return running;
}

/*!
 * \brief AutoLayout::program
 * The program set by the user (remembered in the settings), else the one findProgram finds.
 */
QString AutoLayout::program()
{
  QString path = savedProgram();
  return path.isEmpty() ? findProgram() : path;
}

QString AutoLayout::savedProgram()
{
  return Utilities::getApplicationSettings()->value(programKey).toString();
}

void AutoLayout::setProgram(const QString &path)
{
  Utilities::getApplicationSettings()->setValue(programKey, path);
}

/*!
 * \brief AutoLayout::findProgram
 * The environment variable MOCOAL, or mocoal beside OMEdit (the build tree), in OPENMODELICAHOME/bin (an installed
 * OpenModelica), or on the PATH; empty when there is none.
 */
QString AutoLayout::findProgram()
{
#ifdef Q_OS_WIN
  const QString name = "mocoal.exe";
#else
  const QString name = "mocoal";
#endif
  const QStringList candidates = {qEnvironmentVariable("MOCOAL"), QString("%1/%2").arg(QCoreApplication::applicationDirPath(), name),
                                  QString("%1/bin/%2").arg(Helper::OpenModelicaHome, name)};
  for (const QString &candidate : candidates) {
    if (!candidate.isEmpty() && QFileInfo(candidate).isFile()) {
      return candidate;
    }
  }
  return QStandardPaths::findExecutable("mocoal");
}

/*!
 * \brief AutoLayout::arguments
 * The options as arguments of mocoal.
 */
QStringList AutoLayout::arguments(const Options &options)
{
  QStringList args;
  if (!options.className.isEmpty()) {
    args << "--class" << options.className;
  }
  args << "--layout" << options.layout << "--route" << options.route << "--direction" << options.direction;
  args << "--spacing" << QString("%1,%2").arg(options.dx, 0, 'g', 6).arg(options.dy, 0, 'g', 6);
  args << "--scale" << QString::number(options.scale, 'g', 6);
  args << "--graphics" << options.graphics;
  args << "--stack" << QString::number(options.stackMB);
  for (const QString &directory : options.libraries) {
    args << "--library" << directory;
  }
  if (options.keep) {
    args << "--keep";
  }
  if (!options.rotate) {
    args << "--no-rotate";
  }
  return args;
}

/*!
 * \brief AutoLayout::layout
 * Lays out the classes `options.className` (and the classes in it) of the Modelica source `text`, which is the
 * content of `fileName`. The new source is put in `pResult`; the warnings, or the error, in `pMessage`.
 * mocoal runs as a child process and reads the text from its standard input: a crash or a hang of it ends only
 * that process, and the class stays as it was.
 */
bool AutoLayout::layout(const QString &text, const QString &fileName, const Options &options, QString *pResult, QString *pMessage)
{
  const QString path = program();
  if (path.isEmpty()) {
    *pMessage = QCoreApplication::translate("AutoLayout", "mocoal is not found. Set the environment variable MOCOAL to the program or choose it in the dialog.");
    return false;
  }
  // A class that is not saved yet has no file: the name shows only in messages.
  const QString name = fileName.isEmpty() ? QString("%1.mo").arg(options.className.isEmpty() ? "untitled" : options.className) : fileName;
  if (running) {
    *pMessage = QCoreApplication::translate("AutoLayout", "Another auto layout is running.");
    return false;
  }
  running = true;
  struct Done { ~Done() { running = false; } } done;
  QProcess process;
  process.start(path, arguments(options) << "--stdin" << name);
  if (!process.waitForStarted(10000)) {
    *pMessage = QCoreApplication::translate("AutoLayout", "Unable to start %1: %2").arg(path, process.errorString());
    return false;
  }
  process.write(text.toUtf8());
  process.closeWriteChannel();
  WaitResult waited = WaitResult::Finished;
  if (options.showProgress) {
    waited = waitForProcess(&process, options.className);
  } else if (!process.waitForFinished(timeoutMs) && process.state() != QProcess::NotRunning) {
    waited = WaitResult::TimedOut;
  }
  if (waited != WaitResult::Finished) {
    process.kill();
    process.waitForFinished(5000);
    *pMessage = waited == WaitResult::Cancelled
        ? QCoreApplication::translate("AutoLayout", "The layout was cancelled.")
        : QCoreApplication::translate("AutoLayout", "mocoal took more than %1 s and was stopped; the class is unchanged.").arg(timeoutMs / 1000);
    return false;
  }
  // The standard error has the warnings, or the error, after "mocoal: ", and a report per class.
  QStringList warnings, errors;
  for (const QString &line : QString::fromUtf8(process.readAllStandardError()).split('\n', Qt::SkipEmptyParts)) {
    if (line.startsWith("mocoal: warning: ")) {
      warnings << line.mid(17).trimmed();
    } else if (line.startsWith("mocoal: ")) {
      errors << line.mid(8).trimmed();
    }
  }
  if (process.exitStatus() == QProcess::CrashExit) {
    *pMessage = QCoreApplication::translate("AutoLayout", "mocoal crashed; the class is unchanged.");
    return false;
  }
  if (process.exitCode() != 0) {
    *pMessage = errors.isEmpty() ? QCoreApplication::translate("AutoLayout", "mocoal ended with exit code %1.").arg(process.exitCode())
                                 : errors.join('\n');
    return false;
  }
  *pResult = QString::fromUtf8(process.readAllStandardOutput());
  *pMessage = warnings.join('\n');
  return true;
}

/*!
 * \brief AutoLayout::layoutClass
 * Lays out the class `options.className` whose text is `classText`, in a file whose text before and after the
 * class is `before` and `after` (empty when the class has the file to itself). The layout changes only the class
 * (and the classes in it): the new text of the class is put in `pNewClassText`.
 */
bool AutoLayout::layoutClass(const QString &before, const QString &classText, const QString &after, const QString &fileName,
                             const Options &options, QString *pNewClassText, QString *pMessage)
{
  QString result;
  if (!layout(before + classText + after, fileName, options, &result, pMessage)) {
    return false;
  }
  if (!result.startsWith(before) || !result.endsWith(after) || result.size() < before.size() + after.size()) {
    *pMessage = QCoreApplication::translate("AutoLayout", "The layout changed more than the class.");
    return false;
  }
  *pNewClassText = result.mid(before.size(), result.size() - before.size() - after.size());
  return true;
}
