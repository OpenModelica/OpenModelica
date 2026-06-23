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

// Qt headers required for the new screen‑geometry code
#include <QGuiApplication>   // QGuiApplication::primaryScreen()
#include <QScreen>
#include <QApplication>
#include <QMessageBox>
#include <QLibraryInfo>
#include <QLocale>
#include <QMainWindow>
#include <QDir>

namespace IAEX
{
  /*!
   * \class MyApp
   *
   * \brief Subclass of QApplication that forwards QFileOpenEvent to CellApplication.
   */
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

  /*!
   * \class CellApplication
   * \author Ingemar Axelsson and Anders Fernström
   * \date 2006-04-10 (update)
   *
   * \brief Implements the application interface. This class is the
   * main controller of the program.
   *
   * This class has the responsibility to open new windows, open new
   * documents and handle commands. Commands are sent to a
   * commandCenter object where they are executed and stored (they
   * should be stored).
   *
   * 2005-10-25 AF, Added a check to see if OMC is running, if not -
   * try to start OMC.
   * 2005-12-16 AF, Added code that create an instance of
   * CommandCompletion, so all commands are loaded from the beginning.
   * 2005-12-17 AF, Added code that create instance of stylesheet, so
   * the styles are loaded from the beginning.
   * 2006-01-09 AF, added a new highlight thread with the
   * 'openmodelicahighlighter' as the highlighter that should be used.
   * 2006-02-09 AF, code for starting omc have been moved to the
   * omc interactive environment.
   * 2006-02-13 AF, create temp dir
   * 2006-02-27 AF, use environment variable to find DrModelica
   * 2006-03-24 AF, first look for DrModelica.onb, and then for
   * DrModelica.nb
   * 2006-04-10 AF, use environment variable to find xml files
   * 2006-04-10 AF, Open file that is sent to main
   */
  CellApplication::CellApplication(int &argc, char *argv[], threadData_t *threadData)
      : QObject()
  {
      app_ = new MyApp(argc, argv, this);

#ifndef __EMSCRIPTEN__
      const char *installationDirectoryPath = SettingsImpl__getInstallationDirectoryPath();
      if (!installationDirectoryPath) {
          QMessageBox::critical(nullptr, tr("Error"),
                                tr("Could not find installation directory path. Please make sure OpenModelica is installed properly."));
          app_->quit();
          std::exit(1);
      }

      //  Load translations (Qt and application specific)
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
#endif

      //  Main window (purely a placeholder – real windows are opened later)
      mainWindow = new QMainWindow();

      // when last window closed, the application should quit also
      QObject::connect(app_, &QApplication::lastWindowClosed,
                       app_, &QApplication::quit);

      // Create a commandCenter
      cmdCenter_ = new CellCommandCenter(this);

      setlocale(LC_NUMERIC, "C");               // force C‑style doubles

      //  Initialise the OMC interactive environment
      /* Don't move this line
       * Is important for threadData initialization
       */
      OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance(threadData);
#ifdef __EMSCRIPTEN__
      // The browser omc starts with no library; queue the MSL install (and the
      // startup option) as fire-and-forget worker commands. They must not run a
      // nested event loop here, before QApplication::exec(), as that crashes the
      // not-yet-realized wasm screen. The window comes up while they run.
      env->startBackgroundCommand("setCommandLineOptions(\"+d=shortOutput\")");
      env->startBackgroundCommand("installPackage(Modelica)");
#else
      // Avoid cluttering the whole disk with omc temp-files
      env->evalExpression("setCommandLineOptions(\"+d=shortOutput\")");
#endif
#ifndef __EMSCRIPTEN__
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
#endif

      //  Load stylesheet.xml and commands.xml from the bundled resources, so they
      //  work regardless of the installation layout and on the web build.
      try {
          Stylesheet::instance(":/stylesheet.xml");
      } catch (std::exception &e) {
          QMessageBox::warning(nullptr, tr("Error"), e.what());
          std::exit(-1);
      }

      //  Load commands.xml (command completion)
      try {
          CommandCompletion::instance(":/commands.xml");
      } catch (std::exception &e) {
          QString msg = e.what();
          msg += "\nCould not create command completion class, exiting OMNotebook";
          QMessageBox::warning(nullptr, tr("Error"), msg);
          std::exit(-1);
      }

      //  Either convert DrModelica (if the flag is on) or open the file(s)
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
              //  No command line argument → show splash → open default file
              // use environment variable to find DrModelica
              // First try to find DrModelica.onb, then .nb
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

  /*!
   * \author Anders Fernström and Ingemar Axelsson
   * \date 2006-05-03 (update)
   *
   * \brief Class destructor
   *
   * 2005-11-24 AF, Added code that quited OMC, if it was still running.
   * 2005-12-19 AF, Added code that stopped the highlighter thread,
   * if it is running
   * 2006-01-16 AF, Go Through remove list and remove all temporary
   * files.
   * 2006-02-09 AF, moved code for quiting omc to notebook windows
   * closeEvent handler
   * 2006-02-13 AF, remove temp dir
   * 2006-05-03 AF, delete notebook socket
   */  CellApplication::~CellApplication()
  {
      // 2006-02-09 AF, moved code for quiting omc to the notebook windows

      // 2006-01-16 AF, remove temporary files
      QDir dir;
      for (const QString &file : std::as_const(removeList_)) {
          if (!dir.remove(file)) {
              QMessageBox::warning(nullptr, tr("Warning"),
                                   tr("Could not remove temporary image %1 from harddrive.").arg(file));
          }
      }
  }


  //  Simple accessor / mutator helpers

  CommandCenter *CellApplication::commandCenter()               { return cmdCenter_; }

  void           CellApplication::setCommandCenter(CommandCenter *c)
  {
      cmdCenter_ = c;
      cmdCenter_->setApplication(this);
  }

  /*!
   * \author Anders Fernström and Ingemar Axelsson
   * \date 2006-01-12 (update)
   *
   * 2006-01-12 AF, added so any images in the cell are copied.
   * 2006-02-13 AF, removed code for copy image
   *
   * \todo Create a pasteboard class as a Singleton that should be
   * used instead of having a singleton inside the application class.
   * Other things to do is to use the systemwide pasteboard instead.
   * (Ingemar Axelsson)
   */
  void CellApplication::addToPasteboard(Cell *c) { pasteboard_.push_back(c); }

  /*!
   * \author Ingemar Axelsson
   *
   * This is used to clear the pasteboard. This is an ugly solution.
   */
  void CellApplication::clearPasteboard()       { pasteboard_.clear(); }

  /*!
   * \author Ingemar Axelsson
   *
   * \brief returns a std::vector with all content of the pasteboard.
   */
  std::vector<Cell*> CellApplication::pasteboard() { return pasteboard_; }
  int CellApplication::exec()                  { return app_->exec(); }
  void CellApplication::add(Document *d)       { documents_.push_back(d); }
  void CellApplication::add(DocumentView *d)   { views_.push_back(d); }

  /*!
   * \author Ingemar Axelsson and Anders Fernström
   * \date 2006-05-03 (update)
   *
   * \brief Open an file, and display the content of the file
   *
   * 2005-09-22 AF, added the filename to the NotebookWindow() call
   * 2005-10-11 AF, Porting, added resize call, so all cells get the
   * correct size. Ugly way!
   * 2005-11-30 AF, added code to launch the visitor that applies
   * hide() and show() to groupcells.
   * 2005-12-01 AF, added a try-catch statment around the function
   * 2006-01-17 AF, added code that set the change variable in a
   * document to false.
   * 2006-01-31 AF, open windows minimized, then show normal when
   * all operations are done on the window.
   * 2006-05-03 AF, during open, stop highlighter
   */
  void CellApplication::open(const QString filename, int readmode, int isDrModelica)
  {
      try {
          // 1. Create the document
          Document *d = new CellDocument(this, filename, readmode);
          add(d);

          // 2. Create the view (NotebookWindow)
          DocumentView *v = new NotebookWindow(d, filename, isDrModelica);
          add(v);

      // 2006-01-31 AF, Open window minimized instead of normal

      //v->showMinimized();

      // 2005-10-11 AF, Porting, added resize so all cells get the
      // correct size. Ugly way!

      //v->resize( 810, 610 ); //not working with Qt 4.3

      // 2006-01-17 AF, when the document have been opened, set the
      // changed variable to false.
          // 3. Initialise the view – size, position, etc.
          v->document()->setChanged(false);

      // 2006-01-31 AF, show window again
          v->show();
          v->raise();               // macOS
          v->activateWindow();      // Windows

          // Update the Window‑menu for all open notebooks
          for (DocumentView *dv : documentViewList())
              static_cast<NotebookWindow*>(dv)->updateWindowMenu();

          //  Position the window at the top‑left corner and resize it to the
          //  full screen size – using Qt‑6‑compatible API.
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

  /*!
  * \author Anders Fernström
  * \date 2006-01-16
  *
  * \brief Add filename to a list of temporary files that should
  * be deleted when the application quits.
  */
  void CellApplication::removeTempFiles(QString filename)
  {
      removeList_.append(filename);
  }

  /*!
  * \author Anders Fernström
  * \date 2006-01-27
  *
  * \brief returns list of all current document views
  */
  std::vector<DocumentView *> CellApplication::documentViewList()
  {
      return views_;
  }

  /*!
  * \author Anders Fernström
  * \date 2006-01-27
  *
  * \brief remove document view from internal list, also remove
  * document
  */
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
        dv->updateWindowMenu();
  }

  //  DrModelica conversion (unchanged – never called)
  /*!
  * \author Anders Fernström
  * \date 2006-03-21
  *
  * \brief convert DrModelica documentation into OMNotebook format
  * (.onb).
  *
  * NOT A WORKING FUNCTION
  * -Temporary function
  * -The function is not called anywhere.
  * -The function asume that DrModelia is located in 'C:\OpenModelica132\DrModelicaConv'
  * -Save documents to 'C:\OpenModelica132\DrModelicaConv'
  * -remove all .nb file
  */
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
          //fileDir.setNameFilters( QStringList(".nb") );
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
