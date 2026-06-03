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

#define RUN_DRMODELICA_CONVERTION    false

// IAEX Headers
#include "cellapplication.h"
#include "celldocument.h"
#include "commandcenter.h"
#include "cellcommandcenter.h"
#include "cursorcommands.h"
#include "notebook.h"
#include "omcinteractiveenvironment.h"
#include "updategroupcellvisitor.h"
#include "commandcompletion.h"
#include "stylesheet.h"
#include "inputcell.h"
#include "notebookcommands.h"
#include <QSplashScreen>

#include <cstdlib>

#include "../../../OMCompiler/Compiler/runtime/settingsimpl.h"

// ---------------------------------------------------------------------------
// Qt headers required for the new screen‑geometry code
// ---------------------------------------------------------------------------
#include <QGuiApplication>   // QGuiApplication::primaryScreen()
#include <QScreen>           // QScreen
#include <QApplication>
#include <QMessageBox>
#include <QLibraryInfo>
#include <QLocale>
#include <QMainWindow>
#include <QDir>

namespace IAEX
{
  //=====================================================================
  //  MyApp – a tiny subclass of QApplication that forwards
  //          QFileOpenEvent to CellApplication.
  //=====================================================================
  class MyApp : public QApplication {
  private:
      CellApplication *ca = nullptr;
  public:
      MyApp(int& argc, char** argv, CellApplication *c)
          : QApplication(argc, argv), ca(c) {}

      bool event(QEvent *event) override {
          if (event->type() == QEvent::FileOpen) {
              QFileOpenEvent *fileOpenEvent = static_cast<QFileOpenEvent*>(event);
              if (fileOpenEvent) {
                  ca->FileOpenEventTriggered = true;
                  ca->open(fileOpenEvent->file());
                  return true;
              }
          }
          return QApplication::event(event);
      }
  };

  //=====================================================================
  //  CellApplication implementation
  //=====================================================================
  CellApplication::CellApplication(int &argc, char *argv[], threadData_t *threadData)
      : QObject()
  {
      app_ = new MyApp(argc, argv, this);

      const char *installationDirectoryPath = SettingsImpl__getInstallationDirectoryPath();
      if (!installationDirectoryPath) {
          QMessageBox::critical(nullptr, tr("Error"),
                                tr("Could not find installation directory path. Please make sure OpenModelica is installed properly."));
          app_->quit();
          std::exit(1);
      }

      // -----------------------------------------------------------------
      //  Load translations (Qt and application specific)
      // -----------------------------------------------------------------
      QString locale = QLocale::system().name();

#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
      QString qtTranslationDirectory = QLibraryInfo::path(QLibraryInfo::TranslationsPath);
#else
      QString qtTranslationDirectory = QLibraryInfo::location(QLibraryInfo::TranslationsPath);
#endif

      if (qtTranslator.load("qt_" + locale, qtTranslationDirectory))
          app_->installTranslator(&qtTranslator);

      QString translationDirectory = QString::fromLatin1(installationDirectoryPath) +
                                      "/share/omnotebook/nls";

      if (translator.load("OMNotebook_" + locale, translationDirectory))
          app_->installTranslator(&translator);

      // -----------------------------------------------------------------
      //  Main window (purely a placeholder – real windows are opened later)
      // -----------------------------------------------------------------
      mainWindow = new QMainWindow();

      QObject::connect(app_, &QApplication::lastWindowClosed,
                       app_, &QApplication::quit);

      // -----------------------------------------------------------------
      //  Command centre
      // -----------------------------------------------------------------
      cmdCenter_ = new CellCommandCenter(this);

      // -----------------------------------------------------------------
      //  Misc. initialisation
      // -----------------------------------------------------------------
      setlocale(LC_NUMERIC, "C");               // force C‑style doubles

      // -----------------------------------------------------------------
      //  Initialise the OMC interactive environment
      // -----------------------------------------------------------------
      OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance(threadData);
      env->evalExpression("setCommandLineOptions(\"+d=shortOutput\")");
      QString tmpDir = OmcInteractiveEnvironment::TmpPath();

      if (!QDir().exists(tmpDir))
          QDir().mkdir(tmpDir);
      tmpDir = QDir(tmpDir).canonicalPath();
      env->evalExpression(QString("cd(\"%1\")").arg(tmpDir));
      QString cdRes = env->getResult();
      cdRes.remove('\"');
      if (tmpDir != cdRes) {
          QMessageBox::critical(nullptr, "OpenModelica Error",
                                tr("Could not create or cd to temp-dir\nCommand:\n  %1\nReturned:\n  %2")
                                    .arg(tmpDir).arg(cdRes));
          std::exit(1);
      }

      // -----------------------------------------------------------------
      //  Load stylesheet.xml
      // -----------------------------------------------------------------
      QString openmodelica = QString::fromLatin1(installationDirectoryPath);
      try {
          QString stylesheetfile = openmodelica;
          if (!stylesheetfile.endsWith('/') && !stylesheetfile.endsWith('\\'))
              stylesheetfile += '/';
          stylesheetfile += "share/omnotebook/stylesheet.xml";
          Stylesheet::instance(stylesheetfile);
      } catch (std::exception &e) {
          QMessageBox::warning(nullptr, tr("Error"), e.what());
          std::exit(-1);
      }

      // -----------------------------------------------------------------
      //  Load commands.xml (command completion)
      // -----------------------------------------------------------------
      try {
          QString commandfile = openmodelica;
          if (!commandfile.endsWith('/') && !commandfile.endsWith('\\'))
              commandfile += '/';
          commandfile += "share/omnotebook/commands.xml";
          CommandCompletion::instance(commandfile);
      } catch (std::exception &e) {
          QString msg = e.what();
          msg += "\nCould not create command completion class, exiting OMNotebook";
          QMessageBox::warning(nullptr, tr("Error"), msg);
          std::exit(-1);
      }

      // -----------------------------------------------------------------
      //  Either convert DrModelica (if the flag is on) or open the file(s)
      // -----------------------------------------------------------------
      if (RUN_DRMODELICA_CONVERTION) {
          convertDrModelica();
      } else {
          if (argc > 1) {
              QString fileToOpen(argv[1]);
              QDir dir;
              if (dir.exists(fileToOpen) &&
                  (fileToOpen.endsWith(".onb") || fileToOpen.endsWith(".onbz") ||
                   fileToOpen.endsWith(".nb"))) {
                  open(fileToOpen);
              } else {
                  std::cout << "File not found: " << fileToOpen.toStdString() << std::endl;
                  open(QString());
              }
          } else {
              // ---------------------------------------------------------
              //  No command line argument → show splash → open default file
              // ---------------------------------------------------------
              QIcon icon(":/Resources/OMNotebook_icon.svg");
              QSplashScreen splash(icon.pixmap(300, 400));
              splash.show();
              app_->processEvents();
              splash.finish(mainWindow);

              if (FileOpenEventTriggered) {
                  // nothing – the QFileOpenEvent handler already opened the file
              } else {
                  QDir dir;
                  QString drmodelica = OmcInteractiveEnvironment::OpenModelicaHome() +
                                      "/share/omnotebook/drmodelica/DrModelica.onb";

                  if (dir.exists(drmodelica))
                      open(drmodelica, READMODE_NORMAL, 1);
                  else if (dir.exists("DrModelica/DrModelica.onb"))
                      open("DrModelica/DrModelica.onb", READMODE_NORMAL, 1);
                  else {
                      std::cout << "Unable to find (1): " << drmodelica.toStdString() << std::endl;
                      std::cout << "Unable to find (2): DrModelica/DrModelica.onb" << std::endl;
                      open(QString());
                  }
              }
          }
      }
  }

  //=====================================================================
  //  Destructor – clean temporary files
  //=====================================================================
  CellApplication::~CellApplication()
  {
      QDir dir;
      for (const QString &file : std::as_const(removeList_)) {
          if (!dir.remove(file)) {
              QMessageBox::warning(nullptr, tr("Warning"),
                                   tr("Could not remove temporary image %1 from harddrive.").arg(file));
          }
      }
  }

  // -----------------------------------------------------------------
  //  Simple accessor / mutator helpers (unchanged)
  // -----------------------------------------------------------------
  CommandCenter *CellApplication::commandCenter()               { return cmdCenter_; }
  void           CellApplication::setCommandCenter(CommandCenter *c)
  {
      cmdCenter_ = c;
      cmdCenter_->setApplication(this);
  }

  void CellApplication::addToPasteboard(Cell *c) { pasteboard_.push_back(c); }
  void CellApplication::clearPasteboard()       { pasteboard_.clear(); }
  std::vector<Cell*> CellApplication::pasteboard() { return pasteboard_; }
  int CellApplication::exec()                  { return app_->exec(); }
  void CellApplication::add(Document *d)       { documents_.push_back(d); }
  void CellApplication::add(DocumentView *d)   { views_.push_back(d); }

  //=====================================================================
  //  Open a document – *the only place that used QDesktopWidget*
  //=====================================================================
  void CellApplication::open(const QString filename, int readmode, int isDrModelica)
  {
      try {
          // 1. Create the document
          Document *d = new CellDocument(this, filename, readmode);
          add(d);

          // 2. Create the view (NotebookWindow)
          DocumentView *v = new NotebookWindow(d, filename, isDrModelica);
          add(v);

          // 3. Initialise the view – size, position, etc.
          v->document()->setChanged(false);
          v->show();
          v->raise();               // macOS
          v->activateWindow();      // Windows

          // Update the Window‑menu for all open notebooks
          for (DocumentView *dv : documentViewList())
              static_cast<NotebookWindow*>(dv)->updateWindowMenu();

          // -----------------------------------------------------------------
          //  Position the window at the top‑left corner and resize it to the
          //  full screen size – using Qt‑6‑compatible API.
          // -----------------------------------------------------------------
          v->move(0, 0);

          // Qt 5 and Qt 6 both provide a QScreen via QGuiApplication.
          // The code works for any Qt version ≥ 5.0 (QGuiApplication existed
          // already) and therefore also for Qt 6.
          QScreen *screen = QGuiApplication::primaryScreen();
          if (screen) {
              // Use *availableGeometry* so the window does not overlap the task‑bar / dock.
              QRect geom = screen->availableGeometry();
              v->resize(geom.width(), geom.height());
          } else {
              // Fallback – extremely unlikely, but keeps the old behaviour.
              v->resize(800, 600);
          }

          // Apply the "show‑/hide‑closed‑groupcells" visitor.
          UpdateGroupcellVisitor visitor;
          v->document()->runVisitor(visitor);
      } catch (std::exception &e) {
          throw e;
      }
  }

  // -----------------------------------------------------------------
  //  Remaining helper functions (unchanged)
  // -----------------------------------------------------------------
  void CellApplication::removeTempFiles(QString filename)
  {
      removeList_.append(filename);
  }

  std::vector<DocumentView *> CellApplication::documentViewList()
  {
      return views_;
  }

  void CellApplication::removeDocumentView(DocumentView *view)
  {
      // erase from document list
      auto dit = std::remove_if(documents_.begin(), documents_.end(),
                                [&](Document *d){ return d == view->document(); });
      documents_.erase(dit, documents_.end());

      // erase from view list
      auto vit = std::remove_if(views_.begin(), views_.end(),
                                [&](DocumentView *v){ return v == view; });
      views_.erase(vit, views_.end());

      // refresh all window menus
      for (DocumentView *dv : documentViewList())
          static_cast<NotebookWindow*>(dv)->updateWindowMenu();
  }

  //=====================================================================
  //  DrModelica conversion (unchanged – never called)
  //=====================================================================
  void CellApplication::convertDrModelica()
  {
      std::cout << "CONVERTING DRMODELICA\n---------------------\n\n";

      QString path = "C:/OpenModelica132/DrModelicaConv";
      QDir dir(path);
      dir.setSorting(QDir::Name);

      if (!dir.exists())
          return;

      dir.setFilter(QDir::Dirs | QDir::NoDotAndDotDot);
      QStringList dirList = dir.entryList();
      dirList.prepend(QString()); // add empty entry for root

      for (int i = 0; i < dirList.size(); ++i) {
          QDir fileDir(dir.absolutePath() + "/" + dirList.at(i));
          fileDir.setSorting(QDir::Name);
          fileDir.setFilter(QDir::Files);
          QStringList fileList = fileDir.entryList();

          for (int j = 0; j < fileList.size(); ++j) {
              std::cout << "Loading: "
                        << (fileDir.absolutePath() + "/" + fileList.at(j)).toStdString()
                        << std::endl;

              Document *d = new CellDocument(this,
                         fileDir.absolutePath() + "/" + fileList.at(j),
                         READMODE_CONVERTING_ONB);

              // Save file
              QString filename = fileList.at(j);
              filename.replace(".nb", ".onb");
              std::cout << "Saving: "
                        << (dir.absolutePath() + "/" + dirList.at(i) + "/" + filename).toStdString()
                        << std::endl;

              SaveDocumentCommand command(d,
                     dir.absolutePath() + "/" + dirList.at(i) + "/" + filename);
              commandCenter()->executeCommand(&command);

              std::cout << "DONE!\n\n";

              delete d;
              fileDir.remove(fileList.at(j));
          }
      }

      std::cout << "CONVERTION DONE !!!\n";
  }

} // namespace IAEX
