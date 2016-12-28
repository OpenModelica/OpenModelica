/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
 * - Lennart Ochel - <a href="mailto:lennart.ochel@fh-bielefeld.de">lennart.ochel@fh-bielefeld.de</a>
 * - Volker Waurich - <a href="mailto:volker.waurich@tu-dresden.de">volker.waurich@tu-dresden.de</a>
 * - Rüdiger Franke
 * - Martin Flehmig
 * - Robert Braun - <a href=\"mailto:robert.braun@liu.se\">robert.braun@liu.se</a>
 * - Per Östlund - <a href=\"mailto:per.ostlund@liu.se\">per.ostlund@liu.se</a>
 * - Dietmar Winkler
 * - Anatoly Severin
 * - Adrian Pop - <a href="mailto:adrian.pop@liu.se">adrian.pop@liu.se</a>
 */

#include <locale.h>

#include "MainWindow.h"
#include "Util/Helper.h"
#include "CrashReport/GDBBacktrace.h"
#include "CrashReport/CrashReportDialog.h"
#include "Modeling/LibraryTreeWidget.h"
#include "meta/meta_modelica.h"

#ifndef WIN32
#include "omc_config.h"
#endif

#include <QApplication>
#include <QMessageBox>

#ifdef QT_NO_DEBUG
/*!
 * \brief writeGDBErrorFile
 * Writes the gdberror.log file if gdb based stack trace has failed.
 * \param output
 */
static inline void writeGDBErrorFile(QString output)
{
  QFile gdbErrorFile;
  gdbErrorFile.setFileName(QString("%1gdberror.log").arg(Utilities::tempDirectory()));
  if (gdbErrorFile.open(QIODevice::WriteOnly)) {
    QTextStream out(&gdbErrorFile);
    out.setCodec(Helper::utf8.toStdString().data());
    out.setGenerateByteOrderMark(false);
    out << output;
    out.flush();
    gdbErrorFile.close();
  }
}

#ifdef WIN32
#include "CrashReport/backtrace.h"
static char *g_output = NULL;
LONG WINAPI exceptionFilter(LPEXCEPTION_POINTERS /*info*/)
{
  GDBBacktrace *pGDBBacktrace = new GDBBacktrace;
  if (pGDBBacktrace->errorOccurred()) {
    /* gdb backtrace has failed fallback to normal one.
     * write a file gdberror.log to see why gdb backtrace has failed.
     */
    writeGDBErrorFile(pGDBBacktrace->output());
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
    // Dump a stack trace to a file.
    QFile stackTraceFile;
    stackTraceFile.setFileName(QString("%1/openmodelica.stacktrace.%2").arg(Utilities::tempDirectory()).arg(Helper::OMCServerName));
    if (stackTraceFile.open(QIODevice::WriteOnly)) {
      QTextStream out(&stackTraceFile);
      out.setCodec(Helper::utf8.toStdString().data());
      out.setGenerateByteOrderMark(false);
      out << g_output;
      out.flush();
      stackTraceFile.close();
    }
    CrashReportDialog *pCrashReportDialog = new CrashReportDialog;
    pCrashReportDialog->exec();
  }
  exit(1);
}
#else // Unix
#include <signal.h>
#include <execinfo.h>

static inline void printStackTrace(QFile *pFile, int signalNumber, const char* signalName, unsigned int max_frames = 50)
{
  QTextStream out(pFile);
  out.setCodec(Helper::utf8.toStdString().data());
  out.setGenerateByteOrderMark(false);
  if (signalName) {
    out << QString("Caught signal %1 (%2)\n").arg(QString::number(signalNumber)).arg(signalName);
  } else {
    out << QString("Caught signal %1\n").arg(QString::number(signalNumber));
  }
  out.flush();
  // storage array for stack trace address data
  void* addrlist[max_frames+1];
  // retrieve current stack addresses
  int addrlen = backtrace(addrlist, sizeof(addrlist) / sizeof(void*));
  if (addrlen == 0) {
    out << "Stack address length is empty.\n";
    return;
  }
  // create readable strings to each frame.
  backtrace_symbols_fd(addrlist, addrlen, pFile->handle());
  /* backtrace_symbols uses malloc. Its better to use backtrace_symbols_fd. */
  /*char** symbollist = backtrace_symbols(addrlist, addrlen);
  // print the stack trace.
  for (int i = 4; i < addrlen; i++)
  {
    out << QString("%1\n").arg(symbollist[i]);
  }
  free(symbollist);*/
}

void signalHandler(int signum)
{
  GDBBacktrace *pGDBBacktrace = new GDBBacktrace;
  if (pGDBBacktrace->errorOccurred()) {
    /* gdb backtrace has failed fallback to normal one.
     * write a file gdberror.log to see why gdb backtrace has failed.
     */
    writeGDBErrorFile(pGDBBacktrace->output());
    // associate each signal with a signal name string.
    const char* name = NULL;
    switch(signum) {
      case SIGABRT: name = "SIGABRT";  break;
      case SIGSEGV: name = "SIGSEGV";  break;
      case SIGILL:  name = "SIGILL";   break;
      case SIGFPE:  name = "SIGFPE";   break;
      default:  break;
    }
    // Dump a stack trace to a file.
    QFile stackTraceFile;
    stackTraceFile.setFileName(QString("%1openmodelica.stacktrace.%2").arg(Utilities::tempDirectory()).arg(Helper::OMCServerName));
    if (stackTraceFile.open(QIODevice::WriteOnly)) {
      printStackTrace(&stackTraceFile, signum, name);
      stackTraceFile.close();
    }
    if (name) {
      fprintf(stderr, "Caught signal %d", signum);
    } else {
      fprintf(stderr, "Caught signal %d (%s)", signum, name);
    }
    CrashReportDialog *pCrashReportDialog = new CrashReportDialog;
    pCrashReportDialog->exec();
  }
  exit(signum);
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
  /* Do not use the signal handler OR exception filter if user is building a debug version. Perhaps the user wants to use gdb. */
  MMC_INIT();

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
  QApplication a(argc, argv);
  // set the stylesheet
  a.setStyleSheet("file:///:/Resources/css/stylesheet.qss");
#if !(QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
  QTextCodec::setCodecForTr(QTextCodec::codecForName(Helper::utf8.toLatin1().data()));
  QTextCodec::setCodecForCStrings(QTextCodec::codecForName(Helper::utf8.toLatin1().data()));
#endif
#ifndef WIN32
  QTextCodec::setCodecForLocale(QTextCodec::codecForName(Helper::utf8.toLatin1().data()));
#endif
  a.setAttribute(Qt::AA_DontShowIconsInMenus, false);
  // Localization
  //*a.severin/ add localization
  const char *omhome = getenv("OPENMODELICAHOME");
#ifdef WIN32
  if (!omhome) {
    QMessageBox::critical(0, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::OPENMODELICAHOME_NOT_FOUND), Helper::ok);
    a.quit();
    exit(1);
  }
#else /* unix */
  omhome = omhome ? omhome : CONFIG_DEFAULT_OPENMODELICAHOME;
#endif
  QSettings *pSettings = Utilities::getApplicationSettings();
  QLocale settingsLocale = QLocale(pSettings->value("language").toString());
  settingsLocale = settingsLocale.name() == "C" ? pSettings->value("language").toLocale() : settingsLocale;
  QString locale = settingsLocale.name().isEmpty() ? QLocale::system().name() : settingsLocale.name();
  /* set the default locale of the application so that QSpinBox etc show values according to the locale. */
  QLocale::setDefault(settingsLocale);

  QString translationDirectory = omhome + QString("/share/omedit/nls");
  // install Qt's default translations
  QTranslator qtTranslator;
#ifdef Q_OS_WIN
  qtTranslator.load("qt_" + locale, translationDirectory);
#else
  qtTranslator.load("qt_" + locale, QLibraryInfo::location(QLibraryInfo::TranslationsPath));
#endif
  a.installTranslator(&qtTranslator);
  // install application translations
  QTranslator translator;
  translator.load("OMEdit_" + locale, translationDirectory);
  a.installTranslator(&translator);
  // Splash Screen
  QPixmap pixmap(":/Resources/icons/omedit_splashscreen.png");
  SplashScreen *pSplashScreen = SplashScreen::instance();
  pSplashScreen->setPixmap(pixmap);
  pSplashScreen->show();
  Helper::initHelperVariables();
  /* Force C-style doubles */
  setlocale(LC_NUMERIC, "C");
  // if user has requested to open the file by passing it in argument then,
  bool debug = false;
  QString fileName = "";
  QStringList fileNames;
  if (a.arguments().size() > 1) {
    for (int i = 1; i < a.arguments().size(); i++) {
      if (strncmp(a.arguments().at(i).toStdString().c_str(), "--Debug=",8) == 0) {
        QString debugArg = a.arguments().at(i);
        debugArg.remove("--Debug=");
        if (0 == strcmp("true", debugArg.toStdString().c_str())) {
          debug = true;
        } else {
          debug = false;
        }
      } else {
        fileName = a.arguments().at(i);
        if (!fileName.isEmpty()) {
          // if path is relative make it absolute
          QFileInfo file (fileName);
          QString absoluteFileName = fileName;
          if (file.isRelative()) {
            absoluteFileName = QString("%1/%2").arg(QDir::currentPath()).arg(fileName);
          }
          absoluteFileName = absoluteFileName.replace("\\", "/");
          if (QFile::exists(absoluteFileName)) {
            fileNames << absoluteFileName;
          } else {
            printf("Invalid command line argument: %s %s\n", fileName.toStdString().c_str(), absoluteFileName.toStdString().c_str());
          }
        }
      }
    }
  }
  // MainWindow Initialization
  MainWindow *pMainwindow = MainWindow::instance(debug);
  pMainwindow->setUpMainWindow();
  if (pMainwindow->getExitApplicationStatus()) {        // if there is some issue in running the application.
    a.quit();
    exit(1);
  }
  // open the files passed as command line arguments
  foreach (QString fileName, fileNames) {
    pMainwindow->getLibraryWidget()->openFile(fileName);
  }
  // finally show the main window
  pMainwindow->show();
  // hide the splash screen
  pSplashScreen->finish(pMainwindow);
  return a.exec();
}
