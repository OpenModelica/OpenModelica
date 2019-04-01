/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */

#define RUN_DRMODELICA_CONVERTION    false

//IAEX Headers
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

namespace IAEX
{
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

    // ******************************************************

    class MyApp : public QApplication {
    private:
      CellApplication * ca = NULL;
      public:
        MyApp(int& argc, char**argv, CellApplication * c): QApplication(argc, argv)
        {ca = c;}
        bool event(QEvent *event) {
          switch(event->type())
          {
            case QEvent::FileOpen:
            {
              QFileOpenEvent * fileOpenEvent = static_cast<QFileOpenEvent *>(event);
              if(fileOpenEvent) {
                ca->FileOpenEventTriggered = true;
                ca->open(fileOpenEvent->file());

                return true;
              }
            }
            default:
              return QApplication::event(event);
          }
        }
    };

  CellApplication::CellApplication(int &argc, char *argv[], threadData_t *threadData)
    : QObject()
  {
    app_ = new MyApp(argc, argv, this);


    const char *omhome = getenv("OPENMODELICAHOME");
  #ifdef WIN32
    if (!omhome) {
      QMessageBox::critical(0, tr("Error"), tr("OPENMODELICAHOME not set"), "OK");
      app_->quit();
      exit(1);
    }
  #else /* unix */
    omhome = omhome ? omhome : CONFIG_DEFAULT_OPENMODELICAHOME;
  #endif
    QString translationDirectory = omhome + QString("/share/omnotebook/nls");
    // install Qt's default translations
  #ifdef Q_OS_WIN
    qtTranslator.load("qt_" + QLocale::system().name(), translationDirectory);
  #else
    qtTranslator.load("qt_" + QLocale::system().name(), QLibraryInfo::location(QLibraryInfo::TranslationsPath));
  #endif
    app_->installTranslator(&qtTranslator);
    // install application translations
    translator.load("OMNotebook_" + QLocale::system().name(), translationDirectory);
    app_->installTranslator(&translator);

    mainWindow = new QMainWindow();
    QDir dir;

    // when last window closed, the application should quit also
    QObject::connect(app_, SIGNAL(lastWindowClosed()), app_, SLOT(quit()));

    //Create a commandCenter.
    cmdCenter_ = new CellCommandCenter(this);

    /* Force C-style doubles */
    setlocale(LC_NUMERIC, "C");

    /* Don't move this line
     * Is importat for threadData initialization
     */
    OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance(threadData);

    // 2006-04-10 AF, use environment variable to find xml files
    QString openmodelica = OmcInteractiveEnvironment::OpenModelicaHome();

    if(!QDir().exists(openmodelica))
    {
      QMessageBox::critical( 0, "OpenModelica Error", tr("The environment variable OPENMODELICAHOME=%1 is not a valid directory").arg(openmodelica) );
      exit(1);
    }

    // Avoid cluttering the whole disk with omc temp-files
    env->evalExpression("setCommandLineOptions(\"+d=shortOutput\")");
    QString cmdLine = env->getResult();
    //cout << "Set shortOutput flag: " << cmdLine.toStdString() << std::endl;
    QString tmpDir = OmcInteractiveEnvironment::TmpPath();
    if (!QDir().exists(tmpDir)) QDir().mkdir(tmpDir);
    tmpDir = QDir(tmpDir).canonicalPath();
    //cout << "Temp.Dir " << tmpDir.toStdString() << std::endl;
    QString cdCmd = "cd(\"" + tmpDir + "\")";
    env->evalExpression(cdCmd);
    QString cdRes = env->getResult();
    cdRes.remove("\"");
    if (0 != tmpDir.compare(cdRes)) {
      QMessageBox::critical( 0, "OpenModelica Error", tr("Could not create or cd to temp-dir\nCommand:\n  %1\nReturned:\n  %2").arg(tmpDir).arg(cdRes));
      exit(1);
    }

    // 2005-12-17 AF, Create instance (load styles) of stylesheet
    // 2006-04-10 AF, use environment variable to find stylesheet.xml
    try
    {
      QString stylesheetfile;
      if( openmodelica.endsWith("/") || openmodelica.endsWith( "\\") )
        stylesheetfile = openmodelica + "share/omnotebook/stylesheet.xml";
      else
        stylesheetfile = openmodelica + "/share/omnotebook/stylesheet.xml";

      Stylesheet::instance( stylesheetfile );
    }
    catch( exception &e )
    {
      QMessageBox::warning( 0, tr("Error"), e.what(), "OK" );
      exit(-1);
    }

    // 2005-12-16 AF, Create instance of CommandCompletion.
    // 2006-04-10 AF, use environment variable to find commands.xml
    try
    {
      QString commandfile;
      if( openmodelica.endsWith("/") || openmodelica.endsWith( "\\") )
        commandfile = openmodelica + "share/omnotebook/commands.xml";
      else
        commandfile = openmodelica + "/share/omnotebook/commands.xml";

      CommandCompletion::instance( commandfile );
    }
    catch( exception &e )
    {
      QString msg = e.what();
      msg += "\nCould not create command completion class, exiting OMNotebook";
      QMessageBox::warning( 0, tr("Error"), msg, "OK" );
      std::exit(-1);
    }


    // 2006-03-21 AF, code for converting DrModelica from mathematica
    // fullform to OMNotebook (.onb)
    if( RUN_DRMODELICA_CONVERTION )
    {
      convertDrModelica();
    }
    else
    {
      // second arg is a file that should be opened.
      if( argc > 1 )
      {
        QString fileToOpen( argv[1] );
        if( dir.exists( fileToOpen ) && ( fileToOpen.endsWith( ".onb" ) ||  fileToOpen.endsWith( ".onbz" ) || fileToOpen.endsWith( ".nb" )))
        {
          open( fileToOpen );
        }
        else
        {
          cout << "File not found: " << fileToOpen.toStdString() << endl;
          open(QString::null);
        }
      }
      else
      {
        QIcon icon(":/Resources/OMNotebook_icon.svg");
        QSplashScreen splash(icon.pixmap(300,400));
        splash.show();
        app_->processEvents();
        splash.finish(mainWindow);
        if (FileOpenEventTriggered)
        {

        }
        else
        {
          // 2006-02-27 AF, use environment variable to find DrModelica
          // 2006-03-24 AF, First try to find DrModelica.onb, then .nb
          QString drmodelica = OmcInteractiveEnvironment::OpenModelicaHome() + "/share/omnotebook/drmodelica/DrModelica.onb";
          //QString drmodelica = OmcInteractiveEnvironment::OpenModelicaHome() + "/share/omnotebook/drmodelica/QuickTour/HelloWorld.onb";

          if( dir.exists( drmodelica ))
            open(drmodelica);
          else if( dir.exists( "DrModelica/DrModelica.onb" ))
            open( "DrModelica/DrModelica.onb" );
          else
          {
            cout << "Unable to find (1): " << drmodelica.toStdString() << endl;
            cout << "Unable to find (2): DrModelica/DrModelica.onb" << endl;

            // NB
            drmodelica = OmcInteractiveEnvironment::OpenModelicaHome() + "/share/omnotebook/drmodelica/DrModelica.onb";

            if( dir.exists( drmodelica ))
              open(drmodelica);
            else if( dir.exists( "DrModelica/DrModelica.nb" ))
              open( "DrModelica/DrModelica.nb" );
            else
            {
              cout << "Unable to find (3): " << drmodelica.toStdString() << endl;
              cout << "Unable to find (4): DrModelica/DrModelica.nb" << endl;
              open(QString::null);
            }
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
   */
  CellApplication::~CellApplication()
  {
    // 2006-02-09 AF, moved code for quiting omc to the notebook windos

    // 2006-01-16 AF, remove temporary files
    QDir dir;
    for( int i = 0; i < removeList_.size(); i++ )
    {
      if( !dir.remove( removeList_.at(i) ))
      {
        QMessageBox::warning( 0, tr("Warning"), tr("Could not remove temporary image %1 from harddrive.").arg(removeList_.at(i)), "OK" );
      }
    }
  }

  /*!
   * \author Ingemar Axelsson
   */
  CommandCenter *CellApplication::commandCenter()
  {
    return cmdCenter_;
  }

  /*!
   * \author Ingemar Axelsson
   */
  void CellApplication::setCommandCenter(CommandCenter *c)
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
  void CellApplication::addToPasteboard(Cell *c)
  {
    pasteboard_.push_back(c);
  }

  /*!
   * \author Ingemar Axelsson
   *
   * This is used to clear the pasteboard. This is an ugly solution.
   */
  void CellApplication::clearPasteboard()
  {
    pasteboard_.clear();
  }

  /*!
   * \author Ingemar Axelsson
   *
   * \brief returns a vector with all content of the pasteboard.
   */
  vector<Cell*> CellApplication::pasteboard()
  {
    return pasteboard_;
  }

  /*!
   * \author Ingemar Axelsson
   */
  int CellApplication::exec()
  {
    return app_->exec();
  }

  /*!
   * \author Ingemar Axelsson
   */
  void CellApplication::add(Document *d)
  {
    documents_.push_back(d);
  }

  /*!
   * \author Ingemar Axelsson
   */
  void CellApplication::add(DocumentView *d)
  {
    views_.push_back(d);
  }

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
  void CellApplication::open( const QString filename, int readmode )
  {
    // 2005-12-01 AF, Added try-catch
    try
    {
      //1. Create a new document.
      Document *d = new CellDocument( this, filename, readmode );
      add(d);

      //2. Create a new View.
      // 2005-09-22 AF: Added 'filename' in NotebookWindow() call
      DocumentView *v = new NotebookWindow(d, filename);
      add(v);

      // 2006-01-31 AF, Open window minimized instead of normal

      //v->showMinimized();

      // 2005-10-11 AF, Porting, added resize so all cells get the
      // correct size. Ugly way!

      //v->resize( 810, 610 ); //not working with Qt 4.3

      // 2006-01-17 AF, when the document have been opened, set the
      // changed variable to false.
      v->document()->setChanged( false );

      // 2006-01-31 AF, show window again
      v->show();
      v->raise();  // for MacOS
      v->activateWindow(); // for Windows

      vector<DocumentView *> windowViews = documentViewList();
      vector<DocumentView *>::iterator v_iter = windowViews.begin();
      while( v_iter != windowViews.end() )
      {
        ((NotebookWindow *)*v_iter)->updateWindowMenu();
        ++v_iter;
      }

      QDesktopWidget dw;
      v->move(0, 0);
      v->resize(dw.geometry().width(),dw.geometry().height());

      // 2005-11-30 AF, apply hide() and show() to closed groupcells
      // childs in the documentview
      UpdateGroupcellVisitor visitor;
      v->document()->runVisitor( visitor );
    }
    catch( exception &e )
    {
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
    removeList_.append( filename );
  }

  /*!
  * \author Anders Fernström
  * \date 2006-01-27
  *
  * \brief returns list of all current document views
  */
  vector<DocumentView *> CellApplication::documentViewList()
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
  void CellApplication::removeDocumentView( DocumentView *view )
  {
    vector<Document *>::iterator d_iter = documents_.begin();
    while( d_iter != documents_.end() )
    {
      if( (*d_iter) == view->document() )
      {
        documents_.erase( d_iter );
        break;
      }
      else
        ++d_iter;
    }

    vector<DocumentView *>::iterator dv_iter = views_.begin();
    while( dv_iter != views_.end() )
    {
      if( (*dv_iter) == view )
      {
        views_.erase( dv_iter );
        break;
      }
      else
        ++dv_iter;
    }
    dv_iter = views_.begin();
    while( dv_iter != views_.end() )
    {
      ((NotebookWindow *)*dv_iter)->updateWindowMenu();
      ++dv_iter;
    }
  }

  /*!
  * \author Anders Fernström
  * \date 2006-03-21
  *
  * \brief convert DrModelica documentation into OMNotebook format
  * (.onb).
  *
  * NO A WORKING FUNCTION
  * -Temporary function
  * -The function is not called anywhere.
  * -The function asume that DrModelia is located in 'C:\OpenModelica132\DrModelicaConv'
  * -Save documents to 'C:\OpenModelica132\DrModelicaConv'
  * -remove all .nb file
  */
  void CellApplication::convertDrModelica()
  {
    cout << "CONVERTING DRMODELICA" << endl;
    cout << "---------------------" << endl << endl;

    // load from
    QString path = "C:/OpenModelica132/DrModelicaConv";
    QDir dir( path );
    dir.setSorting( QDir::Name );

    if( dir.exists() )
    {
      // get dirs
      dir.setFilter( QDir::Dirs | QDir::NoDotAndDotDot);
      QStringList dirList = dir.entryList();
      dirList.prepend( "" );

      for( int i = 0; i < dirList.size(); ++i )
      {
        // get file names
        QDir fileDir( dir.absolutePath() + "/" + dirList.at(i) );
        fileDir.setSorting( QDir::Name );
        fileDir.setFilter( QDir::Files );
        //fileDir.setNameFilters( QStringList(".nb") );
        QStringList fileList = fileDir.entryList();

        // loop through all files
        for( int j = 0; j < fileList.size(); ++j )
        {
          cout << "Loading: " << fileDir.absolutePath().toStdString() +
            string( "/" ) + fileList.at(j).toStdString() << endl;

          Document *d = new CellDocument( this, fileDir.absolutePath() +
            QString( "/" ) + fileList.at(j), READMODE_CONVERTING_ONB );

          // save file
          QString filename = fileList.at(j);
          filename.replace( ".nb", ".onb" );

          cout << "Saving: " << dir.absolutePath().toStdString() +
            string( "/" ) + dirList.at(i).toStdString() + string( "/" ) +
            filename.toStdString() << endl;

          SaveDocumentCommand command( d, dir.absolutePath() +
            QString( "/" ) + dirList.at(i) + QString( "/" ) + filename );
          this->commandCenter()->executeCommand( &command );

          cout << "DONE!" << endl << endl;

          // delete file
          delete d;
          fileDir.remove( fileList.at(j) );
        }
      }
     }

    cout << "CONVERTION DONE !!!" << endl;
  }

}
