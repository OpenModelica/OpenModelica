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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

/*!
 * \mainpage OMEdit - OpenModelica Connection Editor Documentation
 * Source code documentation. Provides brief information about the classes used.
 */

#include "OMEditApplication.h"
#ifndef GC_THREADS
#define GC_THREADS
#endif

extern "C" {
#include "meta/meta_modelica_data.h"
}

#ifdef Q_OS_WIN
#include <windows.h>
#endif

#ifdef QT_NO_DEBUG
#include <QMutex>

static QMutex mutex;
void messageHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg)
{
  Q_UNUSED(ctx);
  QMutexLocker lock(&mutex);

  QString line;
  switch (type) {
    case QtDebugMsg:    line = QStringLiteral("[QtDebug]  ") + msg; break;
    case QtInfoMsg:     line = QStringLiteral("[QtInfo] ") + msg; break;
    case QtWarningMsg:  line = QStringLiteral("[QtWarning] ") + msg; break;
    case QtCriticalMsg: line = QStringLiteral("[QtCritical] ") + msg; break;
    case QtFatalMsg:    line = QStringLiteral("[QtFatal]") + msg; break;
  }

  FILE *out = (type == QtDebugMsg || type == QtInfoMsg) ? stdout : stderr;
  fprintf(out, "%s\n", qPrintable(line));
}

#include "CrashReport/CrashReportDialog.h"

#ifdef Q_OS_WIN
#include "CrashReport/backtrace.h"

static char *g_output = NULL;
LONG WINAPI exceptionFilter(LPEXCEPTION_POINTERS info)
{
  if (g_output == NULL) {
    g_output = (char*) malloc(BUFFER_MAX);
  }
  struct output_buffer ob;
  output_init(&ob, g_output, BUFFER_MAX);
  if (!SymInitialize(GetCurrentProcess(), 0, TRUE)) {
    output_print(&ob, "Failed to init symbol context\n");
  } else {
    bfd_init();
    struct bfd_set *set = (bfd_set*)calloc(1,sizeof(*set));
    _backtrace(&ob , set , 128 , info->ContextRecord);
    release_set(set);
    SymCleanup(GetCurrentProcess());
  }
  // show the CrashReportDialog
  CrashReportDialog *pCrashReportDialog = new CrashReportDialog(QString(g_output));
  pCrashReportDialog->exec();
  exit(1);
  return EXCEPTION_CONTINUE_SEARCH;
}

#else // Unix

#include <signal.h>
#include <execinfo.h>

void signalHandler(int signalNumber)
{
  // associate each signal with a signal name string.
  const char* signalName = NULL;
  switch (signalNumber) {
    case SIGABRT: signalName = "SIGABRT";  break;
    case SIGSEGV: signalName = "SIGSEGV";  break;
    case SIGILL:  signalName = "SIGILL";   break;
    case SIGFPE:  signalName = "SIGFPE";   break;
    default:  break;
  }
  QString stackTrace;
  if (signalName) {
    stackTrace.append(QString("Caught signal %1 (%2)\n").arg(QString::number(signalNumber)).arg(signalName));
  } else {
    stackTrace.append(QString("Caught signal %1\n").arg(QString::number(signalNumber)));
  }
  // storage array for stack trace address data
  unsigned int max_frames = 50;
  void* addrlist[max_frames+1];
  // retrieve current stack addresses
  int addrlen = backtrace(addrlist, sizeof(addrlist) / sizeof(void*));
  if (addrlen == 0) {
    stackTrace.append("Stack address length is empty.\n");
  } else {
    // create readable strings to each frame.
    char** symbollist = backtrace_symbols(addrlist, addrlen);
    // print the stack trace.
    for (int i = 0; i < addrlen; i++) {
      stackTrace.append(QString("%1\n").arg(symbollist[i]));

      char syscom[PATH_MAX];
      snprintf(syscom,PATH_MAX, "addr2line %p -e %s > addr2lineOutput.txt", addrlist[i], qApp->applicationFilePath().toStdString().c_str());
      system(syscom);
      QFile file(QString("addr2lineOutput.txt"));
      if (file.open(QIODevice::ReadOnly)) {
        stackTrace.append(QString(file.readAll()));
        file.close();
      } else {
        stackTrace.append(QString("Cannot read addr2lineOutput.txt file %1. addr2line has probably failed.").arg(file.errorString()));
      }
    }
    free(symbollist);
  }

  // show the CrashReportDialog
  CrashReportDialog *pCrashReportDialog = new CrashReportDialog(stackTrace);
  pCrashReportDialog->exec();
  exit(signalNumber);
}
#endif // #ifdef Q_OS_WIN

#endif // #ifdef QT_NO_DEBUG

void printOMEditUsage()
{
  fprintf(stderr, "Usage:\n");
  fprintf(stderr, "  OMEdit [options] [files]\n\n");

  fprintf(stderr, "Options:\n");
  fprintf(stderr, "  --Debug=[true|false]          Enable debugging features such as\n");
  fprintf(stderr, "                                QUndoView and diffModelicaFileListings.\n");
  fprintf(stderr, "                                Default: false.\n\n");

  fprintf(stderr, "  --NAPIProfiling=[true|false]  Enable profiling for the new JSON-based API.\n");
  fprintf(stderr, "                                Default: false.\n\n");

  fprintf(stderr, "  --StyleSheet=<file>           Load an additional Qt stylesheet after\n");
  fprintf(stderr, "                                OMEdit's default stylesheet.\n\n");

  fprintf(stderr, "  --paths                       Prints the Qt paths.\n\n");

  fprintf(stderr, "files                           List of Modelica files (*.mo) to open.\n");
}

static int execution_failed()
{
  fflush(NULL);
  fprintf(stderr, "Execution failed!\n");
  fflush(NULL);
  return 1;
}

int main(int argc, char *argv[])
{
#ifdef Q_OS_WIN
  /// Re-attach to the parent console (the cmd.exe that launched us)
  if (AttachConsole(ATTACH_PARENT_PROCESS)) {
    freopen("CONOUT$", "w", stdout);
    freopen("CONOUT$", "w", stderr);
  }
#endif // #ifdef Q_OS_WIN
#ifdef QT_NO_DEBUG
  // install the message handler before creating the application object so that we can catch all messages
  qInstallMessageHandler(messageHandler);
#endif // #ifdef QT_NO_DEBUG
  // if user asks for --help
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--help") == 0) {
      printOMEditUsage();
      return 0;
    }
  }
  MMC_INIT();
  MMC_TRY_TOP()
  Q_INIT_RESOURCE(resource_omedit);
#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0) && QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
  QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
  QApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
#endif
  OMEditApplication a(argc, argv, threadData);
// Do not use the signal handler OR exception filter if user is building a debug version.
// Perhaps the user wants to use gdb.
// moved the setting of the handler *after* OMEditApplication application definition
// as otherwise it did not work with msys2-ucrt64
#ifdef QT_NO_DEBUG
#if defined(_WIN32)
  LPTOP_LEVEL_EXCEPTION_FILTER top_filter = SetUnhandledExceptionFilter(exceptionFilter);
#else
  /* Abnormal termination (abort) */
  signal(SIGABRT, signalHandler);
  /* Segmentation violation */
  signal(SIGSEGV, signalHandler);
  /* Illegal instruction */
  signal(SIGILL, signalHandler);
  /* Floating point error */
  signal(SIGFPE, signalHandler);
#endif // #ifdef WIN32
#endif // #ifdef QT_NO_DEBUG

  return a.exec();

  MMC_CATCH_TOP(return execution_failed());
}
