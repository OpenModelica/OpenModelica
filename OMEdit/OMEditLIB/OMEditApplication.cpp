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

#include "MCP/MCPServer.h"
#include "LSP/LSPClient.h"
#include "LSP/LSPSetupDialog.h"
#include "OMEditApplication.h"
#include "Util/Utilities.h"
#include "Util/Helper.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
//! @todo Remove this once new frontend is used as default and old frontend is removed.
#include "Options/OptionsDialog.h"
#include "Simulation/TranslationFlagsWidget.h"

#include <locale.h>
#include <QDir>
#include <QMessageBox>
#include <QStandardPaths>
#include <QUrl>
#include <QTextCodec>
#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
#include <QStyleHints>
#endif // #if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)

#include "../../OMCompiler/Compiler/runtime/settingsimpl.h"

#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
#define QT_LIBRRY_INFO_PATH_OR_LOCATION QLibraryInfo::path
#define QT_LIBRRY_INFO_QMLIP QLibraryInfo::QmlImportsPath
#else
#define QT_LIBRRY_INFO_PATH_OR_LOCATION QLibraryInfo::location
#define QT_LIBRRY_INFO_QMLIP QLibraryInfo::ImportsPath
#endif

void dumpQtPaths()
{
  fprintf(stdout, "Qt location/paths:\n");
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::PrefixPath) = \n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::PrefixPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::DocumentationPath) = \n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::DocumentationPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::HeadersPath) = \n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::HeadersPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::LibrariesPath) = \n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::LibrariesPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::LibraryExecutablesPath) =\n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::LibraryExecutablesPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::BinariesPath) =\n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::BinariesPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::PluginsPath) =\n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::PluginsPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::QmlImportsPath) =\n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QT_LIBRRY_INFO_QMLIP)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::ArchDataPath) =\n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::ArchDataPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::DataPath) =\n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::DataPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::TranslationsPath) =\n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::TranslationsPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::ExamplesPath) =\n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::ExamplesPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::TestsPath) =\n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::TestsPath)));
  fprintf(stdout, "QLibraryInfo::location|path(QLibraryInfo::SettingsPath) =\n\t%s\n",
    qPrintable(QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::SettingsPath)));
  fflush(NULL);
}

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
  const char *installationDirectoryPath = SettingsImpl__getInstallationDirectoryPath();
  if (!installationDirectoryPath) {
    QMessageBox::critical(0, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::INSTALLATIONDIRECTORY_NOT_FOUND), QMessageBox::Ok);
    quit();
    exit(1);
  }
#ifdef Q_OS_WIN
  // currently the sandbox does not work with qt6-webengine
  qputenv("QTWEBENGINE_CHROMIUM_FLAGS", qgetenv("QTWEBENGINE_CHROMIUM_FLAGS") + " --no-sandbox");
  // make QtWebEngineProcess find the Qt dlls!
  // Qt6Core.dll lives in <install>/bin, so Qt computes its prefix as <install>/ and
  // looks for QtWebEngine resources/locales under <install>/...
  // We install those under <install>/bin/... instead, so override the
  // search paths here before any QtWebEngine subprocess is launched.
  qputenv("QTWEBENGINE_RESOURCES_PATH",  QByteArray(installationDirectoryPath) + "/bin/resources");
  QString localesPath = QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::TranslationsPath) + "/qtwebengine_locales";
  qputenv("QTWEBENGINE_LOCALES_PATH", localesPath.toUtf8());
#endif // #ifdef Q_OS_WIN

/* We need a better handling of ligth and dark themes.
 * For now just force light theme for Qt 6.8
 * The default color scheme is based on the system theme, so Qt will automatically use light or dark theme based on the user's system settings.
 */
#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
  styleHints()->setColorScheme(Qt::ColorScheme::Light);  // must be before setStyleSheet
#endif // #if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
  // set the stylesheet
  setStyleSheet("file:///:/Resources/css/stylesheet.qss");
#ifndef WIN32
  QTextCodec::setCodecForLocale(QTextCodec::codecForName(Helper::utf8.toUtf8().constData()));
#endif // #ifndef WIN32
  setAttribute(Qt::AA_DontShowIconsInMenus, false);
  // Localization
  //*a.severin/ add localization
  QSettings *pSettings = Utilities::getApplicationSettings();
  QLocale settingsLocale = QLocale(pSettings->value("language").toString());
  QString locale = settingsLocale.name() == "C" ? QLocale::system().name() : settingsLocale.name();
  // Set OMEdit locale to C so that we get dot as decimal separator instead of comma.
  QLocale::setDefault(QLocale::c());

  QString qtTranslatorLoadError, translatorLoadError;
  QMap<QString, QLocale> languagesMap = Utilities::supportedLanguages();
  for (auto i = languagesMap.cbegin(), end = languagesMap.cend(); i != end; ++i) {
    if (i.value().name() == locale) {
      QString qtTranslationsLocation = QT_LIBRRY_INFO_PATH_OR_LOCATION(QLibraryInfo::TranslationsPath);
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
  bool newApiNoJson = false;
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
      } else if (strncmp(arguments().at(i).toUtf8().constData(), "--NAPINoJson=",13) == 0) {
        QString napiNoJsonArg = arguments().at(i);
        napiNoJsonArg.remove("--NAPINoJson=");
        if (0 == strcmp("true", napiNoJsonArg.toUtf8().constData())) {
          newApiNoJson = true;
        }
      } else if (strncmp(arguments().at(i).toUtf8().constData(), "--paths",7) == 0) {
        dumpQtPaths();
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
  pMainwindow->setNewApiNoJson(newApiNoJson);
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

  if (pSettings->contains("modelContextProtocol/enabled") && pSettings->value("modelContextProtocol/enabled").toBool()) {
    int port = 3000;
    bool enableAdminTools = false;
    if (pSettings->contains("modelContextProtocol/port")) {
      port = pSettings->value("modelContextProtocol/port").toInt();
    }
    if (pSettings->contains("modelContextProtocol/enableAdminTools")) {
      enableAdminTools = pSettings->value("modelContextProtocol/enableAdminTools").toBool();
    }
    new MCPServer(pMainwindow->getOMCProxy(), port, enableAdminTools, pMainwindow);
  }

  if (pSettings->contains("languageServer/enabled") && pSettings->value("languageServer/enabled").toBool()) {
    // Resolve the server executable: user setting → bundled server.js → PATH
    QString executable = pSettings->value("languageServer/executable").toString().trimmed();
    if (executable.isEmpty()) {
      executable = LSPClient::findBundledServer();
    }
    if (executable.isEmpty()) {
      executable = QStandardPaths::findExecutable(QStringLiteral("modelica-language-server"));
    }

    bool canStart = !executable.isEmpty();
    if (canStart && executable.endsWith(QStringLiteral(".js"))
        && LSPClient::findNodeExecutable().isEmpty()) {
      // Node.js is missing — prompt the user
      LSPSetupDialog setupDialog(pMainwindow);
      setupDialog.exec();
      if (setupDialog.result() == QDialog::Rejected) {
        // User chose to disable LSP; persist the choice
        pSettings->setValue(QStringLiteral("languageServer/enabled"), false);
      }
      canStart = setupDialog.wasNodeFound();
    }

    if (canStart) {
      LSPClient *pLSPClient = new LSPClient(pMainwindow);
      QString rootUri = QUrl::fromLocalFile(QDir::homePath()).toString();
      pLSPClient->start(executable, rootUri);
      pMainwindow->setLSPClient(pLSPClient);
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
