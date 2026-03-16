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
//! @todo Remove this once new frontend is used as default and old frontend is removed.
#include "Options/OptionsDialog.h"
#include "Simulation/TranslationFlagsWidget.h"

#include <locale.h>
#include <QMessageBox>
#include <QTextCodec>

#include "../../OMCompiler/Compiler/runtime/settingsimpl.h"

#ifdef Q_OS_WIN
/*!
 * \brief getWindowsUIFont
 * Retrieves the Windows UI font as a QFont.
 * This function uses the SystemParametersInfo API to get the non-client metrics,
 * specifically the message font, and converts it to a QFont.
 * \return
 */
QFont getWindowsUIFont()
{
  NONCLIENTMETRICS ncm;
  ncm.cbSize = sizeof(NONCLIENTMETRICS);
  SystemParametersInfo(SPI_GETNONCLIENTMETRICS, sizeof(NONCLIENTMETRICS), &ncm, 0);

  LOGFONT lf = ncm.lfMessageFont;

  // Get DPI of primary monitor
  HDC screenDC = GetDC(nullptr);
  int dpi = GetDeviceCaps(screenDC, LOGPIXELSY);
  ReleaseDC(nullptr, screenDC);

  // Convert lfHeight to point size
  int pixelHeight = (lf.lfHeight < 0) ? -lf.lfHeight : lf.lfHeight;
  double pointSize = 0.0;
  pointSize = pixelHeight * 72.0 / dpi;

  QFont font(QString::fromWCharArray(lf.lfFaceName));
  font.setPointSizeF(pointSize); // floating-point for exact scaling

  return font;
}
#endif

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
OMEditApplication::OMEditApplication(int &argc, char **argv, threadData_t* threadData, bool testsuiteRunning)
  : QApplication(argc, argv)
{
  // set the stylesheet
  setStyleSheet("file:///:/Resources/css/stylesheet.qss");
#ifndef WIN32
  QTextCodec::setCodecForLocale(QTextCodec::codecForName(Helper::utf8.toUtf8().constData()));
#endif
  setAttribute(Qt::AA_DontShowIconsInMenus, false);
#ifdef Q_OS_WIN
  /*! @todo Qt by default uses "MS Shell Dlg 2" on Windows which doesn't scale good.
   *  Use the Windows default font instead of Qt default.
   *  Remove this workaround once we move to Qt6.
   *  Qt6 automatically uses the Windows UI font.
   */
  setFont(getWindowsUIFont());
#endif
  // Localization
  //*a.severin/ add localization
  const char *installationDirectoryPath = SettingsImpl__getInstallationDirectoryPath();
  if (!installationDirectoryPath) {
    QMessageBox::critical(0, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::INSTALLATIONDIRECTORY_NOT_FOUND), QMessageBox::Ok);
    quit();
    exit(1);
  }
  QSettings *pSettings = Utilities::getApplicationSettings();
  QLocale settingsLocale = QLocale(pSettings->value("language").toString());
  QString locale = settingsLocale.name() == "C" ? QLocale::system().name() : settingsLocale.name();
  // Set OMEdit locale to C so that we get dot as decimal separator instead of comma.
  QLocale::setDefault(QLocale::c());

  QString qtTranslatorLoadError, translatorLoadError;
  QMap<QString, QLocale> languagesMap = Utilities::supportedLanguages();
  for (auto i = languagesMap.cbegin(), end = languagesMap.cend(); i != end; ++i) {
    if (i.value() == settingsLocale) {
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
      QString qtTranslationsLocation = QLibraryInfo::path(QLibraryInfo::TranslationsPath);
#else
      QString qtTranslationsLocation = QLibraryInfo::location(QLibraryInfo::TranslationsPath);
#endif
      // install Qt's default translations
      if (mQtTranslator.load("qt_" + locale, qtTranslationsLocation)) {
        installTranslator(&mQtTranslator);
      } else {
        qtTranslatorLoadError = QString("Failed to load Qt translation file %1 from location %2").arg("qt_" + locale, qtTranslationsLocation);
      }
      // install application translations
      QString translationsLocation = installationDirectoryPath + QString("/share/omedit/nls");
      // skip loading OMEdit translation file if locale language is QLocale::English. We don't have any OMEdit_en*.qm file.
      if (settingsLocale.language() != QLocale::English) {
        if (mTranslator.load("OMEdit_" + locale, translationsLocation)) {
          installTranslator(&mTranslator);
        } else {
          translatorLoadError = QString("Failed to load translation file %1 from location %2").arg("OMEdit_" + locale, translationsLocation);
        }
      }
      break;
    }
  }
  // Splash Screen
  QPixmap pixmap(":/Resources/icons/omedit_splashscreen.png");
  SplashScreen *pSplashScreen = SplashScreen::instance();
  pSplashScreen->setPixmap(pixmap);
  if (!testsuiteRunning) {
    pSplashScreen->show();
  }
  Helper::initHelperVariables();
  /* Force C-style doubles */
  setlocale(LC_NUMERIC, "C");
  // if user has requested to open the file by passing it in argument then,
  bool debug = false;
  bool newApiProfiling = false;
  QString fileName = "";
  QStringList fileNames, invalidFlags;
  if (arguments().size() > 1 && !testsuiteRunning) {
    for (int i = 1; i < arguments().size(); i++) {
      if (strncmp(arguments().at(i).toUtf8().constData(), "--Debug=",8) == 0) {
        QString debugArg = arguments().at(i);
        debugArg.remove("--Debug=");
        if (0 == strcmp("true", debugArg.toUtf8().constData())) {
          debug = true;
        }
      } else if (strncmp(arguments().at(i).toUtf8().constData(), "--NAPIProfiling=",16) == 0) {
        QString napiProfilingArg = arguments().at(i);
        napiProfilingArg.remove("--NAPIProfiling=");
        if (0 == strcmp("true", napiProfilingArg.toUtf8().constData())) {
          newApiProfiling = true;
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
            invalidFlags.append(fileName);
          }
        }
      }
    }
  }
  // MainWindow Initialization
  MainWindow *pMainwindow = MainWindow::instance();
  pMainwindow->setDebug(debug);
  pMainwindow->setNewApiProfiling(newApiProfiling);
  pMainwindow->setTestsuiteRunning(testsuiteRunning);
  pMainwindow->setUpMainWindow(threadData);
  if (pMainwindow->getExitApplicationStatus()) {        // if there is some issue in running the application.
    quit();
    exit(1);
  }
  // show error of invalid flags
  if (!invalidFlags.isEmpty()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, QString("Invalid command line argument(s): %1").arg(invalidFlags.join(", ")),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
  // show qt translator load error
  if (!qtTranslatorLoadError.isEmpty()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, qtTranslatorLoadError, Helper::scriptingKind, Helper::warningLevel));
  }
  // show translator load error
  if (!translatorLoadError.isEmpty()) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, translatorLoadError, Helper::scriptingKind, Helper::warningLevel));
  }
  // open the files passed as command line arguments
  foreach (QString fileName, fileNames) {
    pMainwindow->getLibraryWidget()->openFile(fileName);
  }
  // open the files recieved by QFileOpenEvent
  if (!testsuiteRunning) {
    foreach (QString fileToOpen, mFilesToOpenList) {
      pMainwindow->getLibraryWidget()->openFile(fileToOpen);
    }
  }

  if (!testsuiteRunning) {
    // finally show the main window
    pMainwindow->show();
    // hide the splash screen
    SplashScreen::instance()->finish(pMainwindow);
    //! @todo Remove this once new frontend is used as default and old frontend is removed.
    //! Fixes issue #7456
    if (OptionsDialog::instance()->getSimulationPage()->getTranslationFlagsWidget()->getOldInstantiationCheckBox()->isChecked()) {
      QMessageBox *pMessageBox = new QMessageBox;
      pMessageBox->setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::question));
      pMessageBox->setIcon(QMessageBox::Question);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(tr("You have enabled old frontend for code generation which is not recommended. Do you want to switch to new frontend?"));
      pMessageBox->addButton(tr("Switch to new frontend"), QMessageBox::AcceptRole);
      pMessageBox->addButton(tr("Keep using old frontend"), QMessageBox::RejectRole);
      int answer = pMessageBox->exec();
      switch (answer) {
        case QMessageBox::AcceptRole:
          OptionsDialog::instance()->getSimulationPage()->getTranslationFlagsWidget()->getOldInstantiationCheckBox()->setChecked(false);
          OptionsDialog::instance()->saveSimulationSettings();
          break;
        case QMessageBox::RejectRole:
        default:
          break;
      }
    }
  }
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
