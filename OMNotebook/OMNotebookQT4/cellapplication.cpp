/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

* Neither the name of Linköpings universitet nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
*/
#ifdef WIN32
#include "windows.h"
#endif

//QT Headers
#include <QtCore/QDir>
#include <QtCore/QObject>
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


namespace IAEX
{
	/*! 
	 * \class CellApplication
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2006-01-09 (update)
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
	 */
	CellApplication::CellApplication(int &argc, char **argv)
		: QObject()
	{  
		app_ = new QApplication(argc, argv);

		// 2005-10-25 AF, added a check if omc is running, otherwise
		// try to start it
		try
		{
			new OmcInteractiveEnvironment();
		}
		catch( exception &e )
		{
#ifdef WIN32
			try
			{
				STARTUPINFO startinfo;
				PROCESS_INFORMATION procinfo;
				memset(&startinfo, 0, sizeof(startinfo));
				memset(&procinfo, 0, sizeof(procinfo));
				startinfo.cb = sizeof(STARTUPINFO);
				startinfo.wShowWindow = SW_MINIMIZE;
				startinfo.dwFlags = STARTF_USESHOWWINDOW;

				string parameter = "\"omc.exe\" +d=interactiveCorba";
				char *pParameter = new char[parameter.size() + 1];
				const char *cpParameter = parameter.c_str();
				strcpy(pParameter, cpParameter);

				bool flag = CreateProcess(NULL,pParameter,NULL,NULL,FALSE,CREATE_NEW_CONSOLE,NULL,NULL,&startinfo,&procinfo);

				Sleep(2000);

				if( !flag )
					throw std::exception("Unable to start OMC");
			}
			catch( exception &e )
			{
				QString msg = e.what();
				msg += "\nWas unable to start OMC! Closeing OMNotebook!";
				QMessageBox::critical( 0, "Error", msg, "OK" );
				std::exit(-1);
			}
#else
			QString msg = e.what();
			msg += "\nOMC not started! Closeing OMNotebook!";
			QMessageBox::critical( 0, "Error", msg, "OK" );
			std::exit(-1);
#endif
		}

		// when last window closed, the applicaiton should quit also
		QObject::connect(app_, SIGNAL(lastWindowClosed()),
			app_, SLOT(quit()));

		//Create a commandCenter.
		cmdCenter_ = new CellCommandCenter(this);

		// 2005-12-17 AF, Create instance (load styles) of stylesheet
		Stylesheet *sheet;
		try
		{
			sheet = Stylesheet::instance("stylesheet.xml");
		}
		catch( exception &e )
		{
			QMessageBox::warning( 0, "Error", e.what(), "OK" );
			exit(-1);
		}

		// 2005-12-16 AF, Create instance of CommandCompletion.
		try
		{
			CommandCompletion::instance( "commands.xml" );
		}
		catch( exception &e )
		{
			QString msg = e.what();
			msg += "\nCould not create command completion class, exiting OMNotebook";
			QMessageBox::warning( 0, "Error", msg, "OK" );
			std::exit(-1);
		}

		// 2006-01-09 AF, create a new highlight thread with the
		// 'openmodelicahighlighter' as the highlighter that should be
		// used.
		try
		{
			Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
			CellStyle style = sheet->getStyle( "Input" );
			style.textCharFormat()->setBackground( QBrush( QColor( 200, 200, 255 ) ));

			OpenModelicaHighlighter *highlighter = 
				new OpenModelicaHighlighter( "modelicacolors.xml", *style.textCharFormat() );
			HighlighterThread *thread = HighlighterThread::instance( highlighter );
			thread->start( QThread::LowPriority );
		}
		catch( exception &e )
		{
			QString msg = e.what();
			msg += "\nCould not create highlighter thread, exiting OMNotebook";
			QMessageBox::warning( 0, "Error", msg, "OK" );
			std::exit(-1);
		}
 
		//open(QString("WelcomeToOMNotebook.onb"));
		// 2006-02-02 AF, open DrModelica from the begining - release stuff
		QDir dir;
		if( dir.exists( "DrModelica/DrModelica.nb" ))
			open(QString("DrModelica/DrModelica.nb")); 
		else
			open(QString::null);
	}

	/*! 
	 * \author Anders Fernström and Ingemar Axelsson
	 * \date 2006-01-16 (update)
	 *
	 * \brief Class destructor
	 *
	 * 2005-11-24 AF, Added code that quited OMC, if it was still running.
	 * 2005-12-19 AF, Added code that stopped the highlighter thread,
	 * if it is running
	 * 2006-01-16 AF, Go Through remove list and remove all temporary 
	 * files.
	 */
	CellApplication::~CellApplication()
	{
		// 2005-12-19 AF, stop highlighter thread
		HighlighterThread *thread = HighlighterThread::instance();
		thread->exit();

		// 2005-11-24 AF,
		// check if omc server is still runing, if its runing -> send quit() command
		try
		{
			OmcInteractiveEnvironment *omc = new OmcInteractiveEnvironment();
			omc->evalExpression( QString("quit()") );
			//omc->getResult();
			//delete omc;
		}
		catch( exception &e )
		{ 
		}

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
	 *
	 * \todo Create a pasteboard class as a Singleton that should be
	 * used instead of having a singleton inside the application class.
	 * Other things to do is to use the systemwide pasteboard instead.
	 * (Ingemar Axelsson)
	 */
	void CellApplication::addToPasteboard(Cell *c)
	{
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
						QImageWriter writer( newImagename, "png" );
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
	 * \date 2006-01-30 (update)
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

			// 2006-01-31 AF, Open window minimized insted of normal
			v->showMinimized();

			// 2005-10-11 AF, Porting, added resize so all cells get the 
			// correct size. Ugly way!
			v->resize( 810, 610 );

			// 2006-01-17 AF, when the document have been opened, set the
			// changed variable to false.
			v->document()->setChanged( false );

			// 2006-01-31 AF, show window again
			v->showNormal();

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


}
