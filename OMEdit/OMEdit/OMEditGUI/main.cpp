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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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

/*!
 * \mainpage OMEdit - OpenModelica Connection Editor Documentation
 * Source code documentation. Provides brief information about the classes used.
 * \section contributors_section Contributors
 * - Adeel Asghar - <a href="mailto:adeel.asghar@liu.se">adeel.asghar@liu.se</a>
 * - Sonia Tariq
 * - Martin Sjölund - <a href="mailto:martin.sjolund@liu.se">martin.sjolund@liu.se</a>
 * - Alachew Shitahun - <a href="mailto:alachew.mengist@liu.se">alachew.mengist@liu.se</a>
 * - Jan Kokert - <a href="mailto:jan.kokert@imtek.uni-freiburg.de">jan.kokert@imtek.uni-freiburg.de</a>
 * - Dr. Henning Kiel - <a href="mailto:henning.kiel@w-hs.de">henning.kiel@w-hs.de</a>
 * - Haris Kapidzic
 * - Abhinn Kothari
 * - Lennart Ochel - <a href="mailto:lennart.ochel@liu.se">lennart.ochel@liu.se</a>
 * - Volker Waurich - <a href="mailto:volker.waurich@tu-dresden.de">volker.waurich@tu-dresden.de</a>
 * - Rüdiger Franke
 * - Martin Flehmig
 * - Robert Braun - <a href=\"mailto:robert.braun@liu.se\">robert.braun@liu.se</a>
 * - Per Östlund - <a href=\"mailto:per.ostlund@liu.se\">per.ostlund@liu.se</a>
 * - Dietmar Winkler
 * - Anatoly Severin
 * - Adrian Pop - <a href="mailto:adrian.pop@liu.se">adrian.pop@liu.se</a>
 */

#include "OMEditApplication.h"
#include "CrashReport/CrashReportDialog.h"
#define GC_THREADS

extern "C" {
#include "meta/meta_modelica.h"
}

#include <QMessageBox>

#ifdef QT_NO_DEBUG
#ifdef WIN32
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
    output_print(&ob,"Failed to init symbol context\n");
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
    for (int i = 4; i < addrlen; i++) {
      stackTrace.append(QString("%1\n").arg(symbollist[i]));
    }
    free(symbollist);
  }
  // show the CrashReportDialog
  CrashReportDialog *pCrashReportDialog = new CrashReportDialog(stackTrace);
  pCrashReportDialog->exec();
  exit(signalNumber);
}
#endif // #ifdef WIN32
#endif // #ifdef QT_NO_DEBUG

void printOMEditUsage()
{
  printf("Usage: OMEdit --Debug=true|false] [files]\n");
  printf("    --Debug=[true|false]        Enables the debugging features like QUndoView, diffModelicaFileListings view. Default is false.\n");
  printf("    files                       List of Modelica files(*.mo) to open.\n");
}

int main(int argc, char *argv[])
{
  MMC_INIT();
  MMC_TRY_TOP()
  /* Do not use the signal handler OR exception filter if user is building a debug version. Perhaps the user wants to use gdb. */
#ifdef QT_NO_DEBUG
#ifdef WIN32
  SetUnhandledExceptionFilter(exceptionFilter);
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
  // if user asks for --help
  for(int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--help") == 0) {
      printOMEditUsage();
      return 0;
    }
  }
  Q_INIT_RESOURCE(resource_omedit);
  OMEditApplication a(argc, argv, threadData);
  return a.exec();

  MMC_CATCH_TOP();
}
