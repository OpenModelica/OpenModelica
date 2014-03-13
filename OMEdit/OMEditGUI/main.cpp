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
 * 
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

/*!
  \mainpage OMEdit - OpenModelica Connection Editor Documentation
  Source code documentation. Provides brief information about the classes used.

  \section contributors_section Contributors
  \subsection year_2013_subsection 2013
  - Adeel Asghar - <a href="mailto:adeel.asghar@liu.se">adeel.asghar@liu.se</a>
  - Martin Sjölund - <a href="mailto:martin.sjolund@liu.se">martin.sjolund@liu.se</a>
  - Dr. Henning Kiel
  - Alachew Shitahun

  \subsection year_2012_subsection 2012
  - Adeel Asghar - <a href="mailto:adeel.asghar@liu.se">adeel.asghar@liu.se</a>
  - Martin Sjölund - <a href="mailto:martin.sjolund@liu.se">martin.sjolund@liu.se</a>
  - Dr. Henning Kiel

  \subsection year_2011_subsection 2011
  - Adeel Asghar - <a href="mailto:adeel.asghar@liu.se">adeel.asghar@liu.se</a>
  - Martin Sjölund - <a href="mailto:martin.sjolund@liu.se">martin.sjolund@liu.se</a>
  - Haris Kapidzic
  - Abhinn Kothari

  \subsection year_2010_subsection 2010
  - Adeel Asghar - <a href="mailto:adeel.asghar@liu.se">adeel.asghar@liu.se</a>
  - Sonia Tariq
  */

#include "MainWindow.h"
#include "Helper.h"
#include "../../Compiler/runtime/config.h"

#ifdef QT_NO_DEBUG
#ifndef WIN32
#include <signal.h>
#include <execinfo.h>
static inline void printStackTrace(QFile *pFile, int signalNumber, const char* signalName, unsigned int max_frames = 50)
{
  QTextStream out(pFile);
  if (signalName)
    out << QString("Caught signal %1 (%2)\n").arg(QString::number(signalNumber)).arg(signalName);
  else
    out << QString("Caught signal %1\n").arg(QString::number(signalNumber));
  out.flush();
  // storage array for stack trace address data
  void* addrlist[max_frames+1];
  // retrieve current stack addresses
  int addrlen = backtrace(addrlist, sizeof(addrlist) / sizeof(void*));
  if (addrlen == 0)
  {
    out << "Stack address length is empty.\n";
    return;
  }
  // create readable strings to each frame.
  backtrace_symbols_fd(addrlist, addrlen, pFile->handle());
  /*
     backtrace_symbols uses malloc. Its better to use backtrace_symbols_fd.
     */
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
  // associate each signal with a signal name string.
  const char* name = NULL;
  switch(signum)
  {
    case SIGABRT: name = "SIGABRT";  break;
    case SIGSEGV: name = "SIGSEGV";  break;
    case SIGILL:  name = "SIGILL";   break;
    case SIGFPE:  name = "SIGFPE";   break;
    default:  break;
  }
  // Dump a stack trace to a file.
  QFile stackTraceFile;
  char *user = getenv("USER");
  if (!user) { user = "nobody"; }
  QString tmpPath = QDir::tempPath() + "/OpenModelica_" + QString(user) + "/OMEdit/";
  stackTraceFile.setFileName(QString("%1openmodelica.%2.stacktrace.%3").arg(tmpPath).arg(QString(user)).arg(Helper::OMCServerName));
  if (stackTraceFile.open(QIODevice::WriteOnly | QIODevice::Text))
  {
    printStackTrace(&stackTraceFile, signum, name);
    stackTraceFile.close();
  }
  if (name)
    fprintf(stderr, "Caught signal %d", signum);
  else
    fprintf(stderr, "Caught signal %d (%s)", signum, name);
  NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::CrashReport, NotificationsDialog::CriticalIcon, 0);
  pNotificationsDialog->getNotificationCheckBox()->setHidden(true);
  pNotificationsDialog->exec();

  // If you caught one of the above signals, it is likely you just
  // want to quit your program right now.
  exit(signum);
}
#endif // #ifndef WIN32
#endif // #ifdef QT_NO_DEBUG

#ifdef QT_NO_DEBUG
#ifdef WIN32
#include "backtrace.h"
static char *g_output = NULL;
LONG WINAPI exceptionFilter(LPEXCEPTION_POINTERS info)
{
  if (g_output == NULL)
  {
    g_output = (char*) malloc(BUFFER_MAX);
  }
  struct output_buffer ob;
  output_init(&ob, g_output, BUFFER_MAX);
  if (!SymInitialize(GetCurrentProcess(), 0, TRUE))
  {
    output_print(&ob,"Failed to init symbol context\n");
  }
  else
  {
    bfd_init();
    struct bfd_set *set = (bfd_set*)calloc(1,sizeof(*set));
    _backtrace(&ob , set , 128 , info->ContextRecord);
    release_set(set);
    SymCleanup(GetCurrentProcess());
  }
  // Dump a stack trace to a file.
  QFile stackTraceFile;
  stackTraceFile.setFileName(QString("%1/OpenModelica/OMEdit/openmodelica.stacktrace.%2").arg(QDir::tempPath()).arg(Helper::OMCServerName));
  if (stackTraceFile.open(QIODevice::WriteOnly | QIODevice::Text))
  {
    QTextStream out(&stackTraceFile);
    out << g_output;
    out.flush();
    stackTraceFile.close();
  }
  NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::CrashReport, NotificationsDialog::CriticalIcon, 0);
  pNotificationsDialog->getNotificationCheckBox()->setHidden(true);
  pNotificationsDialog->exec();
  exit(1);
}
#endif // #ifdef WIN32
#endif // #ifdef QT_NO_DEBUG

void printOMEditUsage()
{
  printf("Usage: OMEdit [--OMCLogger=true|false] [files]\n");
  printf("    --OMCLogger=[true|false]    Allows sending OMC commands from OMCLogger. Default is false.\n");
  printf("    --debug=[true|false]        Prints the debug information related to the GUI. Default is false.\n");
  printf("    files                       List of Modelica files(*.mo) to open.\n");
}

int main(int argc, char *argv[])
{
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
  for(int i = 1; i < argc; i++)
  {
    if (strcmp(argv[i], "--help") == 0)
    {
      printOMEditUsage();
      return 0;
    }
  }
  Q_INIT_RESOURCE(resource_omedit);
  // read the second argument if specified by user.
  QString fileName = QString();
  // adding style sheet
  argc++;
  argv[(argc - 1)] = (char*)"-stylesheet=:/Resources/css/stylesheet.qss";

  QApplication a(argc, argv);
  QTextCodec::setCodecForTr(QTextCodec::codecForName(Helper::utf8.toLatin1().data()));
  QTextCodec::setCodecForCStrings(QTextCodec::codecForName(Helper::utf8.toLatin1().data()));
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
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  QLocale settingsLocale = QLocale(settings.value("language").toString());
  settingsLocale = settingsLocale.name() == "C" ? settings.value("language").toLocale() : settingsLocale;
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
  QSplashScreen splashScreen(pixmap);
  //splashScreen.setMessage();
  splashScreen.show();
  Helper::initHelperVariables();
  // MainWindow Initialization
  MainWindow mainwindow(&splashScreen);
  if (mainwindow.getExitApplicationStatus()) {        // if there is some issue in running the application.
    a.quit();
    exit(1);
  }
  // if user has requested to open the file by passing it in argument then,
  bool OMCLogger = false;
  if (a.arguments().size() > 1)
  {
    for (int i = 1; i < a.arguments().size(); i++)
    {
      if (strncmp(a.arguments().at(i).toStdString().c_str(), "--OMCLogger=",12) == 0)
      {
        QString omcLoggerArg = a.arguments().at(i);
        omcLoggerArg.remove("--OMCLogger=");
        if (0 == strcmp("true", omcLoggerArg.toStdString().c_str()))
          OMCLogger = true;
        else
          OMCLogger = false;
      }
      else if (strncmp(a.arguments().at(i).toStdString().c_str(), "--debug=",8) == 0)
      {
        QString debugArg = a.arguments().at(i);
        debugArg.remove("--debug=");
        if (0 == strcmp("true", debugArg.toStdString().c_str()))
          mainwindow.setDebugApplication(true);
        else
          mainwindow.setDebugApplication(false);
      }
      else
      {
        fileName = a.arguments().at(i);
        if (!fileName.isEmpty())
        {
          // if path is relative make it absolute
          QFileInfo file (fileName);
          if (file.isRelative())
          {
            fileName.prepend(QString(QDir::currentPath()).append("/"));
          }
          fileName = fileName.replace("\\", "/");
          mainwindow.getLibraryTreeWidget()->openFile(fileName);
        }
      }
    }
  }
  // hide OMCLogger send custom expression feature if OMCLogger is false
  mainwindow.getOMCProxy()->enableCustomExpression(OMCLogger);
  // finally show the main window
  mainwindow.show();
  // hide the splash screen
  splashScreen.finish(&mainwindow);
  /* Show release information notification */
  bool releaseInformation = true;
  if (settings.contains("notifications/releaseInformation"))
  {
    releaseInformation = settings.value("notifications/releaseInformation").toBool();
  }
  if (releaseInformation)
  {
    NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::ReleaseInformation,
                                                                        NotificationsDialog::InformationIcon, &mainwindow);
    pNotificationsDialog->getNotificationCheckBox()->setHidden(true);
    pNotificationsDialog->exec();
  }
  return a.exec();
}
