/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet,
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

/*! 
 * \file notebookcommands.h
 * \author Ingemar Axelsson and Anders Fernström
 */

#ifndef _NOTEBOOK_COMMANDS_H
#define _NOTEBOOK_COMMANDS_H

//STD Headers
#include <iostream>
#include <stdexcept>
#include <exception>

//QT Headers
#include <QtCore/QFile>
#include <QtCore/QTextStream>
#include <QtGui/QTextDocument>
#include <QtXml/qdom.h>

//IAEX Headers
#include "command.h"
#include "celldocument.h"
#include "application.h"
#include "serializingvisitor.h"
#include "puretextvisitor.h"
#include "updatelinkvisitor.h"
#include "printervisitor.h"
#include "chaptercountervisitor.h"
#include "xmlparser.h"
#include "inputcell.h"
#include "cellgroup.h"
#include "highlighterthread.h"
#include <QDataStream>

using namespace std;

namespace IAEX
{
	/*! 
	 * \class SleeperThread
	 * \author Anders Ferström
	 *
	 * \brief Extends QThread. A small trick to get access to protected
	 * function in QThread.
	 */
	class SleeperThread : public QThread
	{
	public:
		static void msleep(unsigned long msecs)
		{
			QThread::msleep(msecs);
		}
	};

	/*! 
	 * \class SaveDocumentCommand
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-12-05 (update)
	 *
	 * \brief Saves the document.
	 *
	 * 2005-09-28 AF, made a small change to get swedish letters to work
	 * 2005-10-07 AF, mada a change due to porting
	 * 2005-11-30 AF, smaller update due to changes in the xml format
	 * that notebooks are saved in and changes in 'SerializingVisitor'.
	 * 2005-12-05 AF, added visitor for updating links when saving (and
	 * the folder changes.
	 */
	class SaveDocumentCommand : public Command
	{
	public:
		SaveDocumentCommand(Document *doc) : doc_(doc)
		{
			filename_ = doc_->getFilename();
		}
		SaveDocumentCommand(Document *doc, const QString &filename)
			:filename_(filename), doc_(doc){}
			virtual ~SaveDocumentCommand(){}
			void execute()
			{
				try
				{
					// 2005-11-30 AF, Changed DomDocument name from 
					// 'qtNotebook' to 'OMNotebook'.
					QDomDocument doc( "OMNotebook" );

					QFile file( filename_ );
					if(file.open(QIODevice::WriteOnly))
					{
						// 2005-12-05 AF, update links
						try
						{
							QString oldFilepath = doc_->getFilename();
							QString newFilepath = QFileInfo( filename_ ).absolutePath();

							// if no oldFilepath, use current work dir
							if( oldFilepath.isNull() || oldFilepath.isEmpty() )
							{
								QDir dir;
								oldFilepath  = dir.absolutePath();
							}
							else
								oldFilepath = QFileInfo(oldFilepath).absolutePath();
							
							// use visitor if the new path is different from the old
							if( oldFilepath != newFilepath )
							{
								UpdateLinkVisitor visitor( oldFilepath, newFilepath );
								doc_->runVisitor( visitor );
							}
						}
						catch( exception &e )
						{
							throw e;
						}

						// save the document
						SerializingVisitor visitor(doc, doc_);
						doc_->runVisitor( visitor );

						// 2005-09-28 AF, Hade to change from 'doc.toString()' 
						// to 'doc.toCString()', so the xml file was saved in
						// UTF-8, otherwise swedish letters didn't work.
						// 2005-10-07 AF, Porting, changed from 'toCString()'
						// to 'toByteArray()'
//						QTextStream filestream(&file);
//						QDataStream filestream(&file);

						if(filename_.endsWith("onbz", Qt::CaseInsensitive)) 
//							filestream << qCompress(doc.toByteArray());
							file.write(qCompress(doc.toByteArray(), 9));
						else
							//filestream << doc.toByteArray();
							file.write(doc.toByteArray());

						file.close();

						// AF, Added this
						doc_->setFilename( filename_ );
						doc_->setSaved( true );
						doc_->setChanged( false );
					}
					else
					{
						string msg = "Could not save documet to file: " + filename_.toStdString();
						throw runtime_error( msg.c_str() );
					}
				}
				catch(exception &e)
				{
					// 2006-01-30 AF, add exception
					string str = string("SaveDocumentCommand(), Exception: ") + e.what();
					throw runtime_error( str.c_str() );
				}
			}
	private:
		QString filename_;
		Document *doc_;
	};


	/*! 
	 * \class OpenFileCommand
	 * \author Ingemar Axelsson
	 * 
	 * Opens the specified filename.
	 */
	class OpenFileCommand : public Command
	{
	public:
		OpenFileCommand(const QString &filename) : filename_(filename){}
		virtual ~OpenFileCommand(){}
		void execute()
		{
			try
			{
				application()->open( filename_, READMODE_NORMAL );
			}
			catch(exception &e)
			{
				string msg = string("OpenFileCommand(), Exception:\r\n") + e.what();
				throw runtime_error( msg.c_str() );				
			}
		}
	private:
		QString filename_;
	};


	/*! 
	 * \class OpenOldFileCommand
	 * \author Anders Fernström
	 * \date 2005-12-01
	 * 
	 * \breif Opens an old file, using the specified filename.
	 *
	 * \param filename The file that should be open
	 * \param readmode The mode that the xmlpaser should use
	 */
	class OpenOldFileCommand : public Command
	{
	public:
		OpenOldFileCommand( const QString &filename, int readmode ) 
			: filename_( filename ), readmode_( readmode ){}
		virtual ~OpenOldFileCommand(){}
		void execute()
		{
			try
			{
				application()->open( filename_, readmode_ );
			}
			catch(exception &e)
			{
				string msg = string("OpenOldFileCommand(), Exception:\r\n") + e.what();
				throw runtime_error( msg.c_str() );				
			}
		}
	private:
		QString filename_;
		int readmode_;
	};


	/*! 
	 * \class PrintDocumentCommand
	 * \author Anders Fernström
	 * \date 2005-12-19
	 * 
	 * \breif print a document
	 *
	 * \param filename The file that should be open
	 * \param readmode The mode that the xmlpaser should use
	 */
	class PrintDocumentCommand : public Command
	{
	public:
		PrintDocumentCommand( Document *doc, QPrinter *printer ) 
			: doc_( doc ), printer_( printer ){}
		virtual ~PrintDocumentCommand(){}
		void execute()
		{
			try
			{
				QTextDocument* printDocument = new QTextDocument();
				PrinterVisitor visitor( printDocument );
				doc_->runVisitor( visitor );
				printDocument->print( printer_ );

				// 2006-03-16 AF
				delete printDocument;
			}
			catch(exception &e)
			{
				string msg = string("PrintDocumentCommand(), Exception:\r\n") + e.what();
				throw runtime_error( msg.c_str() );				
			}
		}
	private:
		Document *doc_;
		QPrinter *printer_;
	};


	/*! 
	 * \class CloseFileCommand
	 * \author Ingemar Axelsson
	 *
	 * Closes the current document. 
	 */
	class CloseFileCommand : public Command
	{
	public:
		CloseFileCommand(){}
		virtual ~CloseFileCommand(){}
		void execute()
		{
			try
			{

				document()->close();
			}
			catch(exception &e)
			{
				// 2006-01-30 AF, add exception
				string str = string("CloseFileCommand(), Exception: ") + e.what();
				throw runtime_error( str.c_str() );
			}
		}
	};


	/*! 
	 * \class NewFileCommand
	 * \author Ingemar Axelsson
	 *
	 * Create a new document in a notebook window
	 */
	class NewFileCommand : public Command
	{
	public:
		NewFileCommand(){}
		virtual ~NewFileCommand(){}
		void execute()
		{
			try
			{
				/*
				Document *doc = document();
				doc = new CellDocument( application(), QString::null );
				*/
			}
			catch(exception &e)
			{
				// 2006-01-30 AF, add exception
				string str = string("NewFileCommand(), Exception: ") + e.what();
				throw runtime_error( str.c_str() );
			}
		}
	};


	/*! 
	 * \class ExportToPureText
	 * \author Anders Fernström
	 *
	 * Export the documents content to a file as pure text, all structure
	 * is removed
	 */
	class ExportToPureText : public Command
	{
	public:
		ExportToPureText(Document *doc, const QString &filename)
			:filename_(filename), doc_(doc){}
		virtual ~ExportToPureText(){}
		void execute()
		{
			try
			{
				QFile file( filename_ );
				if( file.open( QIODevice::WriteOnly ))
				{
					PureTextVisitor visitor( &file );
					doc_->runVisitor( visitor );
				}
				else
				{
					string msg = "Could not export text to file: " + filename_.toStdString();
					throw runtime_error( msg.c_str() );
				}

				file.close();
			}
			catch(exception &e)
			{
				// 2006-01-30 AF, add exception
				string str = string("ExportToPureText(), Exception: ") + e.what();
				throw runtime_error( str.c_str() );
			}			
		}

	private:
		QString filename_;
		Document *doc_;
	};


	/*! 
	 * \class EvalSelectedCells
	 * \author Anders Fernström
	 * \date 2006-02-14
	 *
	 * Eval all inputcells in the vector of selected cells
	 */
	class EvalSelectedCells : public Command
	{
	public:
		EvalSelectedCells( Document *doc )
			:doc_(doc){}
		virtual ~EvalSelectedCells(){}
		void execute()
		{
			try
			{
				vector<Cell *> cells = doc_->getSelection();
			
				vector<Cell *>::iterator c_iter = cells.begin();
				while( c_iter != cells.end() )
				{
					evalCell( (*c_iter) );
					++c_iter;
				}

				doc_->setChanged( true );
			}
			catch(exception &e)
			{
				string str = string("EvalSelectedCells(), Exception: ") + e.what();
				throw runtime_error( str.c_str() );
			}			
		}

	private:
		void evalCell( Cell *cell )
		{
			if( typeid( InputCell ) == typeid( *cell ) )
			{
				InputCell *inputcell = dynamic_cast<InputCell *>(cell);
				inputcell->eval();
			}
			else if( typeid( CellGroup ) == typeid( *cell ) )
			{
				if( cell->hasChilds() )
				{
					Cell *child = cell->child();
					while( child != 0 )
					{
						evalCell( child );
						child = child->next();
					}
				}
			}
		}

		Document *doc_;
	};

	/*! 
	 * \class UpdateChapterCounters
	 * \author Anders Fernström
	 * \date 2006-03-02
	 *
	 * Updates all chapter counter in a documetn
	 */
	class UpdateChapterCounters : public Command
	{
	public:
		UpdateChapterCounters( Document *doc )
			:doc_(doc){}
		virtual ~UpdateChapterCounters(){}
		void execute()
		{
			try
			{
				ChapterCounterVisitor visitor;
				doc_->runVisitor( visitor );
			}
			catch(exception &e)
			{
				string str = string("UpdateChapterCounters(), Exception: ") + e.what();
				throw runtime_error( str.c_str() );
			}			
		}

	private:
		Document *doc_;
	};

};

#endif
