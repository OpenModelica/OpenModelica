/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

/*
 * RCS: $Id$
 */

#include <QtGui/QApplication>
#include <QSplashScreen>

#include "SplashScreen.h"
#include "mainwindow.h"
#include "../../Compiler/runtime/config.h"

void printUsage()
{
  printf("Usage: OMEdit [--OMCLogger=true|false] [files]\n");
  printf("    --OMCLogger=[true|false]        Allows sending OMC commands from OMCLogger. Default is false.\n");
  printf("    files                           List of Modelica files(*.mo) to open.\n");
}

int main(int argc, char *argv[])
{
  Q_INIT_RESOURCE(resource_omedit);
  // read the second argument if specified by user.
  QString fileName = QString();
  // adding style sheet
  argc++;
  argv[(argc - 1)] = "-stylesheet=:/Resources/css/stylesheet.qss";

  QApplication a(argc, argv);
  QTextCodec::setCodecForTr(QTextCodec::codecForName("UTF-8"));
  QTextCodec::setCodecForCStrings(QTextCodec::codecForName("UTF-8"));
  QTextCodec::setCodecForLocale(QTextCodec::codecForName("UTF-8"));
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
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omedit");
  QString language = settings.value("language").toString();
  QString dir = omhome + QString("/share/omedit/nls");
  QString locale = QString("OMEdit_") + (language.isEmpty() ? QLocale::system().name() : language);
  QTranslator translator;
  translator.load(locale, dir);
  a.installTranslator(&translator);
  // Splash Screen
  QPixmap pixmap(":/Resources/icons/omeditor_splash.png");
  SplashScreen splashScreen(pixmap);
  splashScreen.setMessage();
  splashScreen.show();
  Helper::initHelperVariables();
  // MainWindow Initialization
  MainWindow mainwindow(&splashScreen);
  if (mainwindow.mExitApplication) {        // if there is some issue in running the application.
    a.quit();
    exit(1);
  }
  bool OMCLogger = false;
  // if user has requested to open the file by passing it in argument then,
  if (a.arguments().size() > 1)
  {
    for (int i = 1; i < a.arguments().size(); i++)
    {
      if (strncmp(a.arguments().at(i).toStdString().c_str(), "--OMCLogger=",12) == 0) {
        QString omcLoggerArg = a.arguments().at(i);
        omcLoggerArg.remove("--OMCLogger=");
        if (0 == strcmp("true", omcLoggerArg.toStdString().c_str()))
          OMCLogger = true;
        else if (0 == strcmp("false", omcLoggerArg.toStdString().c_str()))
          OMCLogger = false;
      }
      fileName = a.arguments().at(i);
      if (!fileName.isEmpty())
      {
        // if path is relative make it absolute
        QFileInfo file (fileName);
        if (file.isRelative())
        {
          fileName.prepend(QString(QDir::currentPath()).append("/"));
        }
        mainwindow.mpProjectTabs->openFile(fileName);
      }
    }
  }
  // hide OMCLogger send custom expression feature if OMCLogger is false
  mainwindow.mpOMCProxy->enableCustomExpression(OMCLogger);
  // finally show the main window
  mainwindow.show();
  // hide the splash screen
  splashScreen.finish(&mainwindow);
  return a.exec();
}
