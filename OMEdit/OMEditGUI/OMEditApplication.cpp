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

#include "OMEditApplication.h"
#include "Util/Utilities.h"
#include "Util/Helper.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#ifndef WIN32
#include "omc_config.h"
#endif

#include <locale.h>
#include <QMessageBox>

/*!
 * \class OMEditApplication
 * \brief It is a subclass for QApplication so that we can handle QFileOpenEvent sent by OSX at startup.
 */
/*!
 * \brief OMEditApplication::OMEditApplication
 * \param argc
 * \param argv
 * \param threadData
 */
OMEditApplication::OMEditApplication(int &argc, char **argv, threadData_t* threadData)
  : QApplication(argc, argv)
{
  // set the stylesheet
  setStyleSheet("file:///:/Resources/css/stylesheet.qss");
#if !(QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
  QTextCodec::setCodecForTr(QTextCodec::codecForName(Helper::utf8.toLatin1().data()));
  QTextCodec::setCodecForCStrings(QTextCodec::codecForName(Helper::utf8.toLatin1().data()));
#endif
#ifndef WIN32
  QTextCodec::setCodecForLocale(QTextCodec::codecForName(Helper::utf8.toLatin1().data()));
#endif
  setAttribute(Qt::AA_DontShowIconsInMenus, false);
  // Localization
  //*a.severin/ add localization
  const char *omhome = getenv("OPENMODELICAHOME");
#ifdef WIN32
  if (!omhome) {
    QMessageBox::critical(0, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::OPENMODELICAHOME_NOT_FOUND), Helper::ok);
    quit();
    exit(1);
  }
#else /* unix */
  omhome = omhome ? omhome : CONFIG_DEFAULT_OPENMODELICAHOME;
#endif
  QSettings *pSettings = Utilities::getApplicationSettings();
  QLocale settingsLocale = QLocale(pSettings->value("language").toString());
  settingsLocale = settingsLocale.name() == "C" ? pSettings->value("language").toLocale() : settingsLocale;
  QString locale = settingsLocale.name().isEmpty() ? QLocale::system().name() : settingsLocale.name();
  /* Set the default locale of the application so that QSpinBox etc show values according to the locale.
   * Set OMEdit locale to C so that we get dot as decimal separator instead of comma.
   */
  QLocale::setDefault(QLocale::c());

  QString translationDirectory = omhome + QString("/share/omedit/nls");
  // install Qt's default translations
  QTranslator *pQtTranslator = new QTranslator(this);
#ifdef Q_OS_WIN
  pQtTranslator->load("qt_" + locale, translationDirectory);
#else
  pQtTranslator->load("qt_" + locale, QLibraryInfo::location(QLibraryInfo::TranslationsPath));
#endif
  installTranslator(pQtTranslator);
  // install application translations
  QTranslator *pTranslator = new QTranslator(this);
  pTranslator->load("OMEdit_" + locale, translationDirectory);
  installTranslator(pTranslator);
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
  if (arguments().size() > 1) {
    for (int i = 1; i < arguments().size(); i++) {
      if (strncmp(arguments().at(i).toStdString().c_str(), "--Debug=",8) == 0) {
        QString debugArg = arguments().at(i);
        debugArg.remove("--Debug=");
        if (0 == strcmp("true", debugArg.toStdString().c_str())) {
          debug = true;
        } else {
          debug = false;
        }
      } else {
        fileName = arguments().at(i);
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
  pMainwindow->setUpMainWindow(threadData);
  if (pMainwindow->getExitApplicationStatus()) {        // if there is some issue in running the application.
    quit();
    exit(1);
  }
  // open the files passed as command line arguments
  foreach (QString fileName, fileNames) {
    pMainwindow->getLibraryWidget()->openFile(fileName);
  }
  // open the files recieved by QFileOpenEvent
  foreach (QString fileToOpen, mFilesToOpenList) {
    pMainwindow->getLibraryWidget()->openFile(fileToOpen);
  }

  // finally show the main window
  pMainwindow->show();
  // hide the splash screen
  pSplashScreen->finish(pMainwindow);
}

/*!
 * \brief OMEditApplication::event
 * Handles the QFileOpenEvent. Since the event is sent at startup and we don't have MainWindow created.
 * So we put the file name information in mFilesToOpenList and
 * open it later in the OMEditApplication constructor when MainWindow is available.
 * When OMEdit is already running and this event is sent then it is handled in ModelWidgetContainer::eventFilter().
 * \param pEvent
 * \return
 * \sa ModelWidgetContainer::eventFilter()
 */
bool OMEditApplication::event(QEvent *pEvent)
{
  /* Ticket:4164
   * Open the file passed as an argument to OSX.
   * QFileOpenEvent is only available in OSX.
   */
  switch (pEvent->type()) {
    case QEvent::FileOpen: {
      QFileOpenEvent *pFileOpenEvent = static_cast<QFileOpenEvent*>(pEvent);
      if (pFileOpenEvent && !pFileOpenEvent->file().isEmpty()) {
        // if path is relative make it absolute
        QFileInfo fileInfo (pFileOpenEvent->file());
        QString fileName = pFileOpenEvent->file();
        if (fileInfo.isRelative()) {
          fileName = QString("%1/%2").arg(QDir::currentPath()).arg(fileName);
        }
        fileName = fileName.replace("\\", "/");
        mFilesToOpenList.append(fileName);
        return true;
      }
      break;
    }
    default:
      break;
  }
  return QApplication::event(pEvent);
}
