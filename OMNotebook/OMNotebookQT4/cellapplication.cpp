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

#define RUN_DRMODELICA_CONVERTION		false

//QT Headers
#include <QtCore/QDir>
//#include <QtCore/QObject>
#include <QtGui/QImageWriter>
#include <QtGui/QMessageBox>

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
#include "highlighterthread.h"
#include "stylesheet.h"
#include "inputcell.h"
#include "notebookcommands.h"
#include "notebooksocket.h"

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
	CellApplication::CellApplication( int &argc, char *argv[] )
		: QObject()
	{
		app_ = new QApplication(argc, argv);
#ifdef HAVE_COIN
    mainWindow = SoQt::init(argc, argv, argv[0]);
#else
    mainWindow = new QMainWindow();
#endif
		QDir dir;

		// 2006-05-03 AF, Notebook socket...
		notebooksocket_ = new NotebookSocket( this );

		try
		{
			if( notebooksocket_->connectToNotebook() )
			{
				// found another OMNotebook process
				cout << "SOCKET: Connected" << endl;

				if( argc > 1 )
				{
					QString fileToOpen( argv[1] );
					if( dir.exists( fileToOpen ) && ( fileToOpen.endsWith( ".onb" ) || fileToOpen.endsWith( ".onbz" ) || fileToOpen.endsWith( ".nb" )))
					{
						if( notebooksocket_->sendFilename( fileToOpen ))
						{
							cout << "SOCKET: sent filename" << endl;
							exit( -1 );
						}
						else
							cout << "SOCKET: unable to send filename" << endl;
					}
					else
						cout << "SOCKET: Specified filename do not exist" << endl;


				}
				else
					cout << "SOCKET: No filename specified" << endl;
			}
			else
				cout << "SOCKET: Server" << endl;
		}
		catch( exception &e )
		{
      e.what();
//			string msg = string( "Unable to create socket, the application will not work as supposed:\nTry restarting OMNotebook." )+ e.what();
//			QMessageBox::warning( 0, "Socket Error", msg.c_str() );
		}



		// 2005-10-25 AF, added a check if omc is running, otherwise
		// try to start it
		// 2006-02-09 AF, Start of OMC have been moved to omcineractice-
		// environment
		try
		{
      OmcInteractiveEnvironment* zz = OmcInteractiveEnvironment::getInstance();
		}
		catch( exception &e )
		{
      e.what();
			if( !OmcInteractiveEnvironment::startOMC() )
			{
				QMessageBox::critical( 0, "OMC Error", "Was unable to start OMC, OMNotebook will therefore be unable to evaluate Modelica expressions." );
				//exit( -1 );
			}
		}

		// when last window closed, the applicaiton should quit also
		QObject::connect(app_, SIGNAL(lastWindowClosed()),
			app_, SLOT(quit()));

		//Create a commandCenter.
		cmdCenter_ = new CellCommandCenter(this);


		// 2006-04-10 AF, use environment variable to find xml files
		QString openmodelica( getenv( "OPENMODELICAHOME" ) );

//		if( openmodelica.isEmpty() )
		QDir d(openmodelica);
		if(!d.exists(openmodelica))
		{
			QMessageBox::critical( 0, "OpenModelica Error", "The environment variable OPENMODELICAHOME is missing or invalid" );

			//			open(QString::null);
//			return;
			exit(1);
		}

		// 2006-02-13 AF, create temp dir
		if( !dir.exists( "OMNoteboook_tempfiles" ) )
			dir.mkdir( "OMNoteboook_tempfiles" );

		// 2005-12-17 AF, Create instance (load styles) of stylesheet
		// 2006-04-10 AF, use environment variable to find stylesheet.xml
		Stylesheet *sheet;
		try
		{
			QString stylesheetfile;
			if( openmodelica.endsWith("/") || openmodelica.endsWith( "\\") )
				stylesheetfile = openmodelica + "share/omnotebook/stylesheet.xml";
			else
				stylesheetfile = openmodelica + "/share/omnotebook/stylesheet.xml";

			sheet = Stylesheet::instance( stylesheetfile );
		}
		catch( exception &e )
		{
			QMessageBox::warning( 0, "Error", e.what(), "OK" );
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
			QMessageBox::warning( 0, "Error", msg, "OK" );
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
			// 2006-01-09 AF, create a new highlight thread with the
			// 'openmodelicahighlighter' as the highlighter that should be
			// used.
			// 2006-04-10 AF, use environment variable to find modelicacolors.xml
			try
			{
				Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
				CellStyle style = sheet->getStyle( "Input" );
				style.textCharFormat()->setBackground( QBrush( QColor( 200, 200, 255 ) ));

				QString modelicacolorsfile;
				if( openmodelica.endsWith("/") || openmodelica.endsWith( "\\") )
					modelicacolorsfile = openmodelica + "share/omnotebook/modelicacolors.xml";
				else
					modelicacolorsfile = openmodelica + "/share/omnotebook/modelicacolors.xml";

				OpenModelicaHighlighter *highlighter = new OpenModelicaHighlighter( modelicacolorsfile, *style.textCharFormat() );
				HighlighterThread *thread = HighlighterThread::instance( highlighter );
				//thread->start( QThread::LowPriority );
			}
			catch( exception &e )
			{
				QString msg = e.what();
				msg += "\nCould not create highlighter thread, exiting OMNotebook";
				QMessageBox::warning( 0, "Error", msg, "OK" );
				std::exit(-1);
			}


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
				// 2006-02-27 AF, use environment variable to find DrModelica
				// 2006-03-24 AF, First try to find DrModelica.onb, then .nb
        QString drmodelica = getenv("DRMODELICAHOME"); // openmodelica;

		drmodelica.remove("\"");

				// ONB
				if( drmodelica.endsWith("/") || drmodelica.endsWith( "\\") )
					drmodelica += "DrModelica.onb";
				else
					drmodelica += "/DrModelica.onb";


				if( dir.exists( drmodelica ))
					open(drmodelica);
				else if( dir.exists( "DrModelica/DrModelica.onb" ))
					open( "DrModelica/DrModelica.onb" );
				else
				{
					cout << "Unable to find (1): " << drmodelica.toStdString() << endl;
					cout << "Unable to find (2): DrModelica/DrModelica.onb" << endl;

					// NB
					drmodelica = getenv( "DRMODELICAHOME" );
					if( drmodelica.endsWith("/") || drmodelica.endsWith( "\\") )
						drmodelica += "DrModelica.nb";
					else
						drmodelica += "/DrModelica.nb";

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
		// 2006-05-03 AF, delete notebook socket
		notebooksocket_->closeNotebookSocket();
		delete notebooksocket_;

		// 2005-12-19 AF, stop highlighter thread
		HighlighterThread *thread = HighlighterThread::instance();
		thread->exit();

		// 2006-02-09 AF, moved code for quiting omc to the notebook windos

		// 2006-01-16 AF, remove temporary files
		QDir dir;
		for( int i = 0; i < removeList_.size(); i++ )
		{
			if( !dir.remove( removeList_.at(i) ))
			{
				QString msg = "Could not remove temporary image " + removeList_.at(i) + " from harddrive.";
				QMessageBox::warning( 0, "Warning", msg, "OK" );
			}
		}

		// 2006-02-13 AF, remove temp dir
		dir.rmdir( "OMNoteboook_tempfiles" );
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
		/*
		// 2006-02-13 AF, DON'T KNOW IF I NEED TO COPY IMAGE

		// 2006-01-12 AF, copy any images in the cell
		QString html = c->textHtml();
		if( typeid(InputCell) == typeid( (*c) ))
		{
			InputCell *iCell = dynamic_cast<InputCell*>(c);
			html = iCell->textOutputHtml();
		}

		int pos(0);
		while( true )
		{
			int start = html.indexOf( "<img src=\"", pos, Qt::CaseInsensitive );
			if( start >= 0 )
			{
				// found start of imagename
				start += 10;
				int end = html.indexOf( "\"", start );
				if( end >= 0 )
				{
					//found end of imagename
					QString imagename = html.mid( start, end - start );
					imagename.remove( "file:///" );
					QImage image( imagename );
					QString newImagename = imagename.mid( 0, imagename.length() - 4 ) + "_omnotebook_pasteboardcopy.png";

					//cout << "PASTEBOARD:Imagename = " << imagename.toStdString() << endl;
					//cout << "PASTEBOARD:Imagename = " << newImagename.toStdString() << endl;

					if( !image.isNull() )
					{
						// 2006-02-13 AF, store images in temp dir
						QDir dir;
						dir.setPath( dir.absolutePath() + "/OMNoteboook_tempfiles" );

						QImageWriter writer( dir.absolutePath() + "/" + newImagename, "png" );
						writer.setDescription( "Temporary OMNotebook image" );
						writer.setQuality( 100 );
						writer.write( image );

						html.replace( imagename, newImagename );
						removeTempFiles( newImagename );
					}

					pos = start + newImagename.length() + 1;
				}
				else
					break;
			}
			else
				break;
		}

		//set html back
		if( typeid(InputCell) == typeid( (*c) ))
		{
			InputCell *iCell = dynamic_cast<InputCell*>(c);
			iCell->setTextOutputHtml( html );
			pasteboard_.push_back(iCell);
		}
		else
		{
			c->setTextHtml( html );
			pasteboard_.push_back(c);
		}
		*/
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
	 * \breif returns a vector with all content of the pasteboard.
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
	 * \brief Open an file, and display the content of hte file
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
			//2006-05-03 AF, during open, stop highlighter
			HighlighterThread *thread = HighlighterThread::instance();
			thread->setStop( true );

			//1. Create a new document.
			Document *d = new CellDocument( this, filename, readmode );
			add(d);

			//2. Create a new View.
			// 2005-09-22 AF: Added 'filename' in NotebookWindow() call
			DocumentView *v = new NotebookWindow(d, filename);
			add(v);

			// 2006-01-31 AF, Open window minimized insted of normal
			v->showMinimized();

			// 2005-10-11 AF, Porting, added resize so all cells get the
			// correct size. Ugly way!

//			v->resize( 810, 610 ); //not working with Qt 4.3

			// 2006-01-17 AF, when the document have been opened, set the
			// changed variable to false.
			v->document()->setChanged( false );

			// 2006-01-31 AF, show window again
			v->showNormal();

			v->resize( 801, 600 ); //fjass

			// 2005-11-30 AF, apply hide() and show() to closed groupcells
			// childs in the documentview
			UpdateGroupcellVisitor visitor;
			v->document()->runVisitor( visitor );


			// 2006-05-03 AF, done, start highlighter again
			thread->setStop( false );
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
	* be deleted when the applicaiton quits.
	*/
	void CellApplication::removeTempFiles(QString filename)
	{
		removeList_.append( filename );
	}

	/*!
	* \author Anders Fernström
	* \date 2006-01-27
	*
	* \brief returns list of all current doucment views
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
