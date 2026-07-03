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

#ifdef OMC_RUST_ABI
// Drive the Rust omc port (libOpenModelicaCompiler.so) in-process: a
// self-contained replacement for the MMC value/runtime ABI (no Boehm GC). See
// omc_rust_embedding.h; provides MMC_INIT/MMC_TRY_TOP/threadData.
#include "omc_rust_embedding.h"
#else
extern "C" {
#include "meta/meta_modelica_data.h"
}
#endif

#ifdef Q_OS_WIN
#include <windows.h>
#endif

#include <cstring>
#include <cstdlib>

#include "CrashReport/CrashReportDialog.h"
#include "Util/Utilities.h"
#include "Util/Helper.h"

#include <QApplication>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QTimer>

/*
 * Crash reporting design
 * ----------------------
 * A crash (SIGSEGV/SIGABRT/... or a Windows structured exception) must never run
 * Qt code directly: constructing widgets, spinning a nested event loop or driving
 * gdb through QProcess from the crashing thread deadlocks OMEdit instead of
 * terminating it (that was the #15965 hang). So the fatal handler only does
 * async-signal-safe work.
 *
 * For a developer-friendly report it still captures a rich, symbolised backtrace
 * (built with -g -O2): it fork()s a *separate* gdb process attached to the
 * crashed pid ("thread apply all bt full") with a bounded wait so gdb itself can
 * never hang us. If gdb is unavailable it falls back to backtrace_symbols_fd.
 *
 * The report is written to a file and a marker is dropped. It then tries to show
 * the dialog "if possible" by launching a *fresh* OMEdit process
 * (`--crash-report=<file>`); if that is not possible the marker survives and the
 * dialog is shown at the next normal startup, clearly worded as a report about an
 * earlier crash.
 */

/*!
 * \brief crashStackTraceFilePath
 * Path of the file the crash handler writes the backtrace to. It matches the
 * path CrashReportDialog uploads so the "attach backtrace" checkbox works.
 */
static QString crashStackTraceFilePath()
{
  return QString("%1openmodelica.stacktrace.%2").arg(Utilities::tempDirectory()).arg(Helper::OMCServerName);
}

/*!
 * \brief crashMarkerFilePath
 * Existence of this file means a crash is still waiting to be reported. It is
 * removed as soon as some process takes responsibility for showing the dialog.
 */
static QString crashMarkerFilePath()
{
  return QString("%1openmodelica.crash.%2").arg(Utilities::tempDirectory()).arg(Helper::OMCServerName);
}

/*!
 * \brief runCrashReporter
 * Entry point of the crash-reporter sub-process launched by the fatal handler.
 * Runs a minimal QApplication (no OMC, no MainWindow) and shows the dialog.
 */
static int runCrashReporter(int &argc, char **argv, const QString &stackFilePath)
{
  QApplication app(argc, argv);
  // CrashReportDialog needs the translated Helper strings.
  Helper::initHelperVariables();
  QString stackTrace;
  QFile file(stackFilePath);
  if (file.open(QIODevice::ReadOnly)) {
    stackTrace = QString::fromUtf8(file.readAll());
    file.close();
  }
  // We are handling this crash now, so a later normal launch must not show it again.
  QFile::remove(crashMarkerFilePath());
  CrashReportDialog dialog(stackTrace, CrashReportDialog::LiveCrash);
  dialog.exec();
  return 0;
}

/*!
 * \brief maybeShowPreviousCrash
 * At normal startup, if a crash marker is still present the live reporter never
 * got to run (or was killed), so show the dialog now as a "previous crash".
 */
static void maybeShowPreviousCrash()
{
  if (!QFile::exists(crashMarkerFilePath())) {
    return;
  }
  QString stackTrace;
  QFile file(crashStackTraceFilePath());
  if (file.open(QIODevice::ReadOnly)) {
    stackTrace = QString::fromUtf8(file.readAll());
    file.close();
  }
  // Take responsibility for this crash so it is only shown once.
  QFile::remove(crashMarkerFilePath());
  // Show it once the event loop is running and the main window is up.
  QTimer::singleShot(0, qApp, [stackTrace]() {
    CrashReportDialog *pCrashReportDialog = new CrashReportDialog(stackTrace, CrashReportDialog::PreviousCrash);
    pCrashReportDialog->exec();
  });
}

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

// Paths/command precomputed on the main thread so the fatal handler never has to
// touch Qt or the heap to build them.
#define OMEDIT_CRASH_PATH_MAX 4096
static char gCrashStackFile[OMEDIT_CRASH_PATH_MAX] = {0};
static char gCrashMarkerFile[OMEDIT_CRASH_PATH_MAX] = {0};
static char gCrashReporterExe[OMEDIT_CRASH_PATH_MAX] = {0};
static char gCrashReporterArg[OMEDIT_CRASH_PATH_MAX + 32] = {0};

static void copyToBuffer(char *dst, size_t size, const QByteArray &src)
{
  size_t n = qMin((size_t) src.size(), size - 1);
  memcpy(dst, src.constData(), n);
  dst[n] = '\0';
}

static void fillCrashPathBuffers()
{
  copyToBuffer(gCrashStackFile, sizeof(gCrashStackFile), crashStackTraceFilePath().toUtf8());
  copyToBuffer(gCrashMarkerFile, sizeof(gCrashMarkerFile), crashMarkerFilePath().toUtf8());
  copyToBuffer(gCrashReporterExe, sizeof(gCrashReporterExe), qApp->applicationFilePath().toUtf8());
  copyToBuffer(gCrashReporterArg, sizeof(gCrashReporterArg),
               QByteArray("--crash-report=") + crashStackTraceFilePath().toUtf8());
}

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
  // Persist the backtrace and drop a marker. Do NOT show the dialog from inside
  // the exception filter (nested event loop => hang if the crash happened while
  // Qt held a lock); a fresh process shows it instead.
  if (gCrashStackFile[0]) {
    FILE *f = fopen(gCrashStackFile, "wb");
    if (f) {
      fwrite(g_output, 1, strlen(g_output), f);
      fclose(f);
    }
  }
  if (gCrashMarkerFile[0]) {
    FILE *m = fopen(gCrashMarkerFile, "wb");
    if (m) {
      fputs("crash\n", m);
      fclose(m);
    }
  }
  // If possible, show the crash dialog now via a fresh OMEdit process.
  if (gCrashReporterExe[0]) {
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));
    char cmdline[OMEDIT_CRASH_PATH_MAX * 2];
    // quote both so paths containing spaces survive CreateProcess' word splitting.
    snprintf(cmdline, sizeof(cmdline), "\"%s\" \"%s\"", gCrashReporterExe, gCrashReporterArg);
    if (CreateProcessA(NULL, cmdline, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
      CloseHandle(pi.hProcess);
      CloseHandle(pi.hThread);
    }
  }
  // Terminate the process; the reporter (if any) runs independently.
  return EXCEPTION_EXECUTE_HANDLER;
}

#else // Unix

#include <signal.h>
#include <execinfo.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <time.h>
#if defined(__linux__)
#include <sys/prctl.h>
#if defined(PR_SET_PTRACER) && !defined(PR_SET_PTRACER_ANY)
#define PR_SET_PTRACER_ANY ((unsigned long) -1)
#endif
#endif

// Full path to gdb and this process' pid as a string, both resolved at install
// time so the handler can exec gdb using only async-signal-safe calls.
static char gGdbPath[OMEDIT_CRASH_PATH_MAX] = {0};
static char gPidStr[24] = {0};

/*!
 * \brief uitoa
 * Async-signal-safe unsigned-to-string (no malloc). Writes into buf and returns
 * the length; buf must be large enough (<= 32 bytes covers 64-bit in base 10).
 */
static int uitoa(unsigned long value, char *buf, int base)
{
  static const char digits[] = "0123456789abcdef";
  char tmp[32];
  int n = 0;
  if (value == 0) {
    tmp[n++] = '0';
  }
  while (value) {
    tmp[n++] = digits[value % base];
    value /= base;
  }
  for (int i = 0; i < n; i++) {
    buf[i] = tmp[n - 1 - i];
  }
  return n;
}

/*!
 * \brief runGdbBacktrace
 * Forks gdb (a separate process) and attaches it to this crashed process to
 * append a rich "thread apply all bt full" to \p outPath. The crashing thread
 * blocks in a bounded wait so gdb can never itself hang OMEdit. Returns 1 if
 * gdb ran and exited cleanly.
 */
static int runGdbBacktrace()
{
  if (!gGdbPath[0]) {
    return 0;
  }
  pid_t child = fork();
  if (child < 0) {
    return 0;
  }
  if (child == 0) {
    // Child: send gdb's output to the crash file (appended after our header).
    int fd = open(gCrashStackFile, O_WRONLY | O_APPEND | O_CREAT, 0644);
    if (fd >= 0) {
      dup2(fd, STDOUT_FILENO);
      dup2(fd, STDERR_FILENO);
      if (fd > STDERR_FILENO) {
        close(fd);
      }
    }
    execl(gGdbPath, "gdb", "--batch", "--nx", "-q",
          "-ex", "set width 0", "-ex", "set height 0",
          "-ex", "thread apply all bt full",
          "-p", gPidStr, (char*) NULL);
    _exit(127); // exec failed
  }
  // Parent: bounded wait (~20s) so a wedged gdb never turns into a hang.
  int status = 0;
  for (int i = 0; i < 200; i++) {
    pid_t r = waitpid(child, &status, WNOHANG);
    if (r == child) {
      return WIFEXITED(status) && WEXITSTATUS(status) == 0;
    }
    if (r < 0) {
      return 0;
    }
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 100L * 1000 * 1000; // 100 ms
    nanosleep(&ts, NULL);
  }
  kill(child, SIGKILL);
  waitpid(child, &status, 0);
  return 0;
}

/*!
 * \brief signalHandler
 * Async-signal-safe fatal signal handler. It writes a crash report (a rich gdb
 * backtrace when possible, otherwise a brief one), launches the reporter as a
 * fresh process, then re-raises so the process dies cleanly (and can dump core).
 */
void signalHandler(int signalNumber, siginfo_t *si, void *ucontext)
{
  (void) ucontext;
  // Guard against a fault while we are already handling one: just die.
  static volatile sig_atomic_t handling = 0;
  if (handling) {
    _exit(128 + signalNumber);
  }
  handling = 1;

  const char *signalName;
  switch (signalNumber) {
    case SIGABRT: signalName = "SIGABRT"; break;
    case SIGSEGV: signalName = "SIGSEGV"; break;
    case SIGILL:  signalName = "SIGILL";  break;
    case SIGFPE:  signalName = "SIGFPE";  break;
    case SIGBUS:  signalName = "SIGBUS";  break;
    default:      signalName = "signal";  break;
  }
  // Describe the fault so developers see the crash type at a glance.
  const char *codeDesc = "";
  if (signalNumber == SIGSEGV && si) {
    if (si->si_code == SEGV_MAPERR)      codeDesc = " (address not mapped)";
    else if (si->si_code == SEGV_ACCERR) codeDesc = " (invalid permissions)";
  }
  static const char nl[] = "\n";
  char hdr[256];
  int h = 0;
  const char *p = "Caught ";
  memcpy(hdr + h, p, strlen(p)); h += strlen(p);
  memcpy(hdr + h, signalName, strlen(signalName)); h += strlen(signalName);
  memcpy(hdr + h, codeDesc, strlen(codeDesc)); h += strlen(codeDesc);
  if (si && (signalNumber == SIGSEGV || signalNumber == SIGBUS || signalNumber == SIGILL || signalNumber == SIGFPE)) {
    const char *at = " at address 0x";
    memcpy(hdr + h, at, strlen(at)); h += strlen(at);
    h += uitoa((unsigned long) si->si_addr, hdr + h, 16);
  }
  hdr[h++] = '\n';

  // 1) brief message + header to the console (write() is async-signal-safe).
  static const char msg1[] = "\nOMEdit crashed. Writing crash report to:\n  ";
  (void)!write(STDERR_FILENO, msg1, sizeof(msg1) - 1);
  (void)!write(STDERR_FILENO, gCrashStackFile, strlen(gCrashStackFile));
  (void)!write(STDERR_FILENO, nl, sizeof(nl) - 1);
  (void)!write(STDERR_FILENO, hdr, h);

  // 2) start the crash file with the header (truncating any stale content).
  int fd = open(gCrashStackFile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (fd >= 0) {
    (void)!write(fd, hdr, h);
    close(fd);
  }

  // 3) rich gdb backtrace if possible; otherwise a brief in-process backtrace.
  if (!runGdbBacktrace()) {
    // Tell developers why the rich trace is missing (usually a locked-down
    // ptrace on default systems we cannot override, or gdb not installed).
    static const char note[] =
      "\n[No gdb backtrace: gdb not found, or ptrace attach was blocked "
      "(yama /proc/sys/kernel/yama/ptrace_scope >= 2, seccomp, or missing "
      "CAP_SYS_PTRACE). Falling back to a brief backtrace:]\n";
    void *addrlist[64];
    int addrlen = backtrace(addrlist, sizeof(addrlist) / sizeof(void*));
    (void)!write(STDERR_FILENO, note, sizeof(note) - 1);
    if (addrlen > 0) {
      backtrace_symbols_fd(addrlist, addrlen, STDERR_FILENO);
    }
    int afd = open(gCrashStackFile, O_WRONLY | O_APPEND | O_CREAT, 0644);
    if (afd >= 0) {
      (void)!write(afd, note, sizeof(note) - 1);
      if (addrlen > 0) {
        backtrace_symbols_fd(addrlist, addrlen, afd);
      }
      close(afd);
    }
  }

  // 4) drop the marker so the crash gets reported (now or at next startup).
  int mfd = open(gCrashMarkerFile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (mfd >= 0) {
    (void)!write(mfd, signalName, strlen(signalName));
    (void)!write(mfd, nl, sizeof(nl) - 1);
    close(mfd);
  }

  // 5) if possible, show the crash dialog now via a fresh OMEdit process.
  if (gCrashReporterExe[0]) {
    pid_t pid = fork();
    if (pid == 0) {
      execl(gCrashReporterExe, gCrashReporterExe, gCrashReporterArg, (char*) NULL);
      _exit(127); // exec failed
    }
    // parent: do not wait; the reporter runs independently.
  }

  // 6) restore the default action and re-raise so we terminate (and dump core).
  signal(signalNumber, SIG_DFL);
  raise(signalNumber);
}
#endif // #ifdef Q_OS_WIN

/*!
 * \brief installCrashHandlers
 * Precomputes the crash paths and installs the fatal handler / exception filter.
 */
static void installCrashHandlers()
{
  fillCrashPathBuffers();
#if defined(_WIN32)
  SetUnhandledExceptionFilter(exceptionFilter);
#else
  // Resolve gdb to an absolute path now (execlp is not async-signal-safe) and
  // remember our pid so the handler can attach gdb with only safe calls.
  QString gdb = Utilities::getGDBPath();
  if (!QDir::isAbsolutePath(gdb)) {
    QString resolved = QStandardPaths::findExecutable(gdb);
    if (!resolved.isEmpty()) {
      gdb = resolved;
    }
  }
  copyToBuffer(gGdbPath, sizeof(gGdbPath), gdb.toUtf8());
  char pidbuf[24];
  int pn = uitoa((unsigned long) getpid(), pidbuf, 10);
  pidbuf[pn] = '\0';
  copyToBuffer(gPidStr, sizeof(gPidStr), QByteArray(pidbuf));
#if defined(__linux__) && defined(PR_SET_PTRACER)
  // Allow the gdb we fork to ptrace us even when yama ptrace_scope is restricted.
  prctl(PR_SET_PTRACER, PR_SET_PTRACER_ANY, 0, 0, 0);
#endif
  // Warm up backtrace() so its first-call lazy dlopen does not happen in signal context.
  void *warmup[1];
  backtrace(warmup, 1);
  // Alternate signal stack so the handler can run even on a stack overflow
  // (the current stack is exhausted); plain signal() could not do this.
  size_t stackSize = SIGSTKSZ;
  if (stackSize < 32768) {
    stackSize = 32768;
  }
  stack_t ss;
  ss.ss_sp = malloc(stackSize);
  ss.ss_size = stackSize;
  ss.ss_flags = 0;
  if (ss.ss_sp) {
    sigaltstack(&ss, NULL);
  }
  struct sigaction sa;
  memset(&sa, 0, sizeof(sa));
  sa.sa_sigaction = signalHandler;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_ONSTACK | SA_SIGINFO;
  sigaction(SIGABRT, &sa, NULL); /* Abnormal termination (abort) */
  sigaction(SIGSEGV, &sa, NULL); /* Segmentation violation */
  sigaction(SIGILL,  &sa, NULL); /* Illegal instruction */
  sigaction(SIGFPE,  &sa, NULL); /* Floating point error */
  sigaction(SIGBUS,  &sa, NULL); /* Bus error (bad memory access) */
#endif // #ifdef WIN32
}

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
  // if we were launched as a crash reporter, just show the dialog and exit.
  for (int i = 1; i < argc; i++) {
    if (strncmp(argv[i], "--crash-report=", 15) == 0) {
      return runCrashReporter(argc, argv, QString::fromUtf8(argv[i] + 15));
    }
  }
  MMC_INIT();
  MMC_TRY_TOP()
  Q_INIT_RESOURCE(resource_omedit);
#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0) && QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
  QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
  QApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
#endif
#ifdef Q_OS_WIN
  // Set this before creating QApplication. Avoids web engine switch to Direct3DSurface. See issue #15822.
  qputenv("QSG_RHI_BACKEND", "opengl");
#endif // #ifdef Q_OS_WIN
#ifdef Q_OS_LINUX
  qputenv("EGL_LOG_LEVEL", "fatal");
#endif // #ifdef Q_OS_LINUX
  OMEditApplication a(argc, argv, threadData);
// Do not use the signal handler OR exception filter if user is building a debug version.
// Perhaps the user wants to use gdb.
// moved the setting of the handler *after* OMEditApplication application definition
// as otherwise it did not work with msys2-ucrt64
#ifdef QT_NO_DEBUG
  installCrashHandlers();
#endif // #ifdef QT_NO_DEBUG
  // if an earlier session crashed and the live reporter never handled it, show it now.
  maybeShowPreviousCrash();

  return a.exec();

  MMC_CATCH_TOP(return execution_failed());
}
