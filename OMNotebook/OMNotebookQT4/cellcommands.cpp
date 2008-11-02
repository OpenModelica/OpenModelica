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
 * \file cellcommands.h
 * \author Ingemar Axelsson and Anders Fernström
 *
 * \brief Describes different cell commands
 */

// QT Headers
#include <QtGui/QTextCursor>
#include <QtGui/QTextDocumentFragment>

//STD Headers
#include <exception>
#include <stdexcept>
#include <typeinfo>

//IAEX Headers
#include "cellcommands.h"
#include "inputcell.h"
#include "textcell.h"
#include "cellgroup.h"


typedef vector<Rule *> rules_t;

namespace IAEX
{
   /*!
    * \class AddCellCommand
	* \author Ingemar Axelsson and Anders Fernström
    *
    * \brief Command for adding a new cell to the cellstructure.
    */
	void AddCellCommand::execute()
	{
		try
		{
			CellCursor *cursor = document()->getCursor();

			Factory *fac = document()->cellFactory();

			// 2005-10-28 AF, changed style from QString to CellStyle
			CellStyle style;

			if(cursor->currentCell()->hasChilds())
				style = *cursor->currentCell()->child()->style();
			else
				style = *cursor->currentCell()->style();


			//This does not work.
			if(cursor->currentCell()->isClosed())
			{
				if(cursor->currentCell()->hasChilds())
				{
					cursor->currentCell()->child()->setReadOnly(true);
					cursor->currentCell()->child()->setFocus(false);
				}
			}
			else
			{
				cursor->currentCell()->setReadOnly(true);
				cursor->currentCell()->setFocus(false);
			}

			// 2005-11-21 AF, Added check if the current cell is a
			// inputcell, set style to 'text' insted.
			// 2006-02-03 AF, added check if the current cell is a
			// groupcell
			if( style.name() == "input" || style.name() == "Input" || style.name() == "ModelicaInput" ||
				style.name() == "cellgroup" )
				cursor->addBefore(fac->createCell( "Text" ));
			else
				cursor->addBefore(fac->createCell(style.name()));

			if(cursor->currentCell()->isClosed())
			{
				if(cursor->currentCell()->hasChilds())
				{
					cursor->currentCell()->child()->setReadOnly(false);
					cursor->currentCell()->child()->setFocus(true);
				}
			}
			else
			{
				cursor->currentCell()->setReadOnly(false);
				cursor->currentCell()->setFocus(true);
			}

			//2006-01-18 AF, set docuement changed
			document()->setChanged( true );
		}
		catch(exception &e)
		{
			// 2006-01-30 AF, add exception
			string str = string("AddCellCommand(), Exception: \n") + e.what();
			throw runtime_error( str.c_str() );
		}
	}

   /*!
    * \class CreateNewCellCommand
	* \author Ingemar Axelsson
    *
    * \brief Command for creating a new cell.
    */
   void CreateNewCellCommand::execute()
   {
      try
      {
	 CellCursor *cursor = document()->getCursor();

	 Factory *fac = document()->cellFactory();

	 //This does not work.
	 if(cursor->currentCell()->isClosed())
	 {
	    if(cursor->currentCell()->hasChilds())
	    {
	       cursor->currentCell()->child()->setReadOnly(true);
	       cursor->currentCell()->child()->setFocus(false);
	    }
	 }
	 else
	 {
	    cursor->currentCell()->setReadOnly(true);
	    cursor->currentCell()->setFocus(false);
	 }

	 cursor->addBefore(fac->createCell(style_));

	 if(cursor->currentCell()->isClosed())
	 {
	    if(cursor->currentCell()->hasChilds())
	    {
	       cursor->currentCell()->child()->setReadOnly(false);
	       cursor->currentCell()->child()->setFocus(true);
	    }
	 }
	 else
	 {
	    cursor->currentCell()->setReadOnly(false);
	    cursor->currentCell()->setFocus(true);
	 }

		//2006-01-18 AF, set docuement changed
		document()->setChanged( true );
      }
      catch(exception &e)
      {
		  // 2006-01-30 AF, add exception
		  string str = string("CreateNewCommand(), Exception: \n") + e.what();
		  throw runtime_error( str.c_str() );
      }
   }


   /*!
    * \class CopySelectedCellsCommand
	* \author Ingemar Axelsson
	*
    * \brief copy a cell. Adds a copy of the cell on the pasteboard.
    *
	*
    * \todo Implement some kind of internal state or copy constructors
    * for all cells. This to make the copy process more general.(Ingemar Axelsson)
    *
    * \todo Implement release from cellgroup. It should be possible to
    * remove pointers to the cell structure without deleting the
    * object. That needs reparenting of all subcells.(Ingemar Axelsson)
    */
   void CopySelectedCellsCommand::execute()
   {
      CellCursor *c = document()->getCursor();
      vector<Cell *> cells = document()->getSelection();

      if(cells.empty())
      {
		  return;
		//Empty pasteboard.
		//application()->clearPasteboard();
		//application()->addToPasteboard(c->currentCell());
      }
      else
      {
		document()->clearSelection(); //Notice
		application()->clearPasteboard();

		vector<Cell *>::iterator i = cells.begin();
		for(;i != cells.end();++i)
		{
			application()->addToPasteboard((*i));
		}
      }
   }

   /*! What happens if a Groupcell is removed?
    */
   void DeleteCurrentCellCommand::execute()
   {
      try
      {
	 CellCursor *c = document()->getCursor();
	 vector<Cell *> cells = document()->getSelection();

	 if(cells.empty())
	 {
		 return;
	    //Empty pasteboard.
	    //application()->clearPasteboard();
	    //application()->addToPasteboard(c->currentCell());

	    //c->removeCurrentCell();
	 }
	 else
	 {

	    document()->clearSelection(); //Notice
	    application()->clearPasteboard();

	    vector<Cell *>::iterator i = cells.begin();
	    for(;i != cells.end();++i)
	    {
	       c->moveAfter((*i));

	       //1. Copy cell to pasteboard.
	       application()->addToPasteboard(c->currentCell());

	       //2. Delete Cell.
	       c->removeCurrentCell();
	    }
	 }

	 //2006-01-18 AF, set docuement changed
			document()->setChanged( true );
      }
      catch(exception &e)
      {
		  // 2006-01-30 AF, add message box
		  string str = string("DeleteCurrentCellsCommand(), Exception: \n") + e.what();
		throw runtime_error( str.c_str() );
      }
   }

   //Det borde vara möjligt att titta på stylen för att avgöra om en
   //cell är en grupp cell. Då borde det gå att kopiera in underceller
   //också.
   //
   // Kontrollera på stylen hur cellerna ska kopieras. Speciellt ska
   // gruppceller specialbehandlas så att deras subceller också
   // kopieras. Just nu funkar det att kopiera enstaka celler. Men
   // inte gruppceller.
	void PasteCellsCommand::execute()
	{
		try
		{
			vector<Cell *> cells = application()->pasteboard();

			// Insert new cells before this position.
			if(!cells.empty())
			{
				//Reverse iterator!!!!!
				//vector<Cell *>::reverse_iterator i = cells.rbegin();
				//for(;i != cells.rend();++i)
				// AF, Not reverse
				vector<Cell *>::iterator i = cells.begin();
				for(;i != cells.end();++i)
				{
					try
					{
						pasteCell( (*i) );
					}
					catch(exception &e)
					{
						throw e;
					}
				}
			}

			//2006-01-18 AF, set docuement changed
			document()->setChanged( true );
		}
		catch(exception &e)
		{
			// 2006-01-30 AF, add exception
			string str = string("PasteCellsCommand(), Exception: \n") + e.what();
			throw runtime_error( str.c_str() );
		}
	}

	// 2006-01-16 AF, move this code to a seperated function
	// 2006-09-04 AF, redid entire function, so groupcells are created, have there
	// children added and THEN add to the documnet
	void PasteCellsCommand::pasteCell( Cell *cell, CellGroup *groupcell )
	{
		// get cursor, factory and cell style
		CellCursor *cursor = document()->getCursor();
		Factory *factory = document()->cellFactory();
		CellStyle style = *cell->style();

		// set focus and readonly stuff (from old implementation, IA)
		if(cursor->currentCell()->isClosed())
		{
			if(cursor->currentCell()->hasChilds())
			{
				cursor->currentCell()->child()->setReadOnly(true);
				cursor->currentCell()->child()->setFocus(false);
			}
		}
		else
		{
			cursor->currentCell()->setReadOnly(true);
			cursor->currentCell()->setFocus(false);
		}

		// create the new cell, if there exists a groupcell add the new cell to
		// that groupcell.
		Cell* newCell = factory->createCell( style.name() );
//		if( groupcell )
//			groupcell->addChild( newCell );


		// set content of cell
		// *************************************************************************

		// COPY - EVERY CELL TYPE
		// ----------------------
		newCell->setCellTag( cell->cellTag() );

		// rules
		rules_t rules = cell->rules();
		rules_t::iterator current = rules.begin();
		while( current != rules.end() )
		{
			newCell->addRule( (*current) );
			++current;
		}

		// COPY - SPECIFIC FOR CELL TYPE
		// -----------------------------
		if( typeid(CellGroup) == typeid( *newCell ))
		{
			CellGroup *newCellGroup = dynamic_cast<CellGroup *>( newCell );
			newCellGroup->setClosed( cell->isClosed() );

			if( cell->hasChilds() )
			{
				Cell* child = cell->child();
				while( child )
				{
					pasteCell( child, newCellGroup );
					child = child->next();
				}
			}
		}
		else if( typeid(InputCell) == typeid( *newCell ))
		{
			InputCell *newInputCell = dynamic_cast<InputCell *>( newCell );
			InputCell *oldInputCell = dynamic_cast<InputCell *>( cell );

			newInputCell->setStyle( style );
			newInputCell->setText( oldInputCell->text() );

			if( oldInputCell->isEvaluated() )
			{
				newInputCell->setEvaluated( true );

				if( oldInputCell->isPlot() )
					newInputCell->setTextOutputHtml( oldInputCell->textOutputHtml() );
				else
					newInputCell->setTextOutput( oldInputCell->textOutput() );
			}
			else
				newInputCell->setEvaluated( false );

			newInputCell->setClosed( oldInputCell->isClosed() );
		}
		else if( typeid(TextCell) == typeid( *newCell ))
		{
			newCell->setStyle( style );
			newCell->setTextHtml( cell->textHtml() );
		}
		else
		{
			// Error
			throw runtime_error("pasteCell(): Unknown celltype.");
		}
		// *************************************************************************


		// Add cell to document
		if( !groupcell )
			cursor->addBefore( newCell );
		else //if there exists a groupcell add the new cell to that groupcell.
			groupcell->addChild( newCell );

		// set focus and readonly stuff (from old implementation, IA)
		if(cursor->currentCell()->isClosed())
		{
			if(cursor->currentCell()->hasChilds())
			{
				cursor->currentCell()->child()->setReadOnly(false);
				cursor->currentCell()->child()->setFocus(true);
			}
		}
		else
		{
			cursor->currentCell()->setReadOnly(false);
			cursor->currentCell()->setFocus(true);
		}
	}

   /*!
    * \class DeleteSelectedCellsCommand
	* \author Ingemar Axelsson
    *
    * Deletes all selected cells. If no cell is selected the cell that
    * is before the cursor is deleted.
    *
    * What happens when all cells in a cellgroup is empty? Should the
    * cellgroup be deleted? Or what to do with it?
    *
    * Notice that the selection must be cleared.
    *
    *
    * \bug When all cells within a cellgroup is deleted. The cellgroup
    * should also be deleted then. What if all but one cell is deleted?
    */
   void DeleteSelectedCellsCommand::execute()
   {
      try
      {
	 vector<Cell *> cells = document()->getSelection();
	 if(cells.empty())
	 {
	    document()->getCursor()->deleteCurrentCell();
	 }
	 else
	 {
	    document()->clearSelection(); //Notice

	    vector<Cell *>::iterator i = cells.begin();
	    for(;i != cells.end();++i)
	    {
	       (document()->getCursor())->moveAfter((*i));
	       (document()->getCursor())->deleteCurrentCell();
	    }
	 }

	 //2006-01-18 AF, set docuement changed
			document()->setChanged( true );
      }
      catch(exception &e)
      {
		  // 2006-01-30 AF, add exception
		  string str = string("DeleteSelectedCellsCommand(), Exception: \n") + e.what();
		throw runtime_error( str.c_str() );
      }
   }



   	/*!
	 * \class ChangeStyleOnSelectedCellsCommand
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-10-28 (update)
	 *
	 * \brief Changes style on selected cells.
	 *
	 * This does not work on selected Cellgroups. This because I have
     * not defined what will happen if I change style on a
     * cellgroup. Probably all its children will get the same style.
	 *
	 * 2005-10-28, updated style_ from a QString object to a CellStyle
	 * object. Needed to do some major change of the class. /AF
	 *
	 */
	void ChangeStyleOnSelectedCellsCommand::execute()
	{
		try
		{
			vector<Cell *> cells = document()->getSelection();

			if(cells.empty())
			{
				document()->getCursor()->currentCell()->setStyle(style_);
			}
			else
			{;
				vector<Cell *>::iterator i = cells.begin();

				for(;i != cells.end() ;++i)
				{
					//This makes an segfault. Do not now why?
					(*i)->setStyle(style_);
				}

			}

			//2006-01-18 AF, set docuement changed
			document()->setChanged( true );
		}
		catch(exception &e)
		{
			// 2006-01-30 AF, add exception
			string str = string("ChangeStyleOnSelectedCellsCommand(), Exception: \n") + e.what();
			throw runtime_error( str.c_str() );
		}
	}


   void ChangeStyleOnCurrentCellCommand::execute()
   {
      try
      {
	 document()->getCursor()->currentCell()->setStyle(style_);

	 //2006-01-18 AF, set docuement changed
			document()->setChanged( true );
      }
      catch(exception &e)
      {
		  // 2006-01-30 AF, add exception
		  string str = string("ChangeStyleOnCurrentCellCommand(), Exception: \n") + e.what();
		throw runtime_error( str.c_str() );
      }
   }


   void MakeGroupCellCommand::execute()
   {
      try
      {
	 Factory *fac = document()->cellFactory();
	 CellCursor *cursor = document()->getCursor();

	 Cell *prev = cursor->currentCell();
	 cursor->currentCell()->parentCell()->removeChild(prev);

	 Cell *group = fac->createCell("cellgroup", cursor->parentCell());

	 group->addChild(prev);
	 cursor->addBefore(group);
	 cursor->moveToLastChild(group);

	 //2006-01-18 AF, set docuement changed
			document()->setChanged( true );
      }
      catch(exception &e)
      {
		  // 2006-01-30 AF, add exception
		  string str = string("MakeGroupCellCommand(), Exception: \n") + e.what();
		throw runtime_error( str.c_str() );

      }
   }

   /*!
    * \class UngroupCellCommand
    * \author Anders Fernström
    * \date 2006-04-26
    *
    * \brief Ungroup the cell
    */
	void UngroupCellCommand::execute()
	{
		try
		{
			vector<Cell *> cells = document()->getSelection();

			if( !cells.empty() )
			{
				// clear selection before changing cell strucure
				document()->clearSelection();

				vector<Cell *>::iterator c_iter = cells.begin();
				for(; c_iter != cells.end() ; ++c_iter )
				{
					//check if groupcell
					if( typeid( *(*c_iter) ) == typeid( CellGroup ))
					{
						if( !(*c_iter)->hasChilds() )
							throw runtime_error( "No children" );

						// get child
						Cell* child = (*c_iter)->child();
						Cell* deletedCellsParent = (*c_iter)->parentCell();
						Cell* deletedCellsPrevious = (*c_iter)->previous();
						Cell* deletedCellsNext = (*c_iter)->next();

						// if previous is 0 = first in cell
						child->setPrevious( deletedCellsPrevious );
						if( !child->hasPrevious() )
							deletedCellsParent->setChild( child );
						else
							deletedCellsPrevious->setNext( child );

						// add all children
						while( child != 0 )
						{
							//child->setParent( (*c_iter)->parent() );
							child->setParentCell( deletedCellsParent );

							if( child->hasNext() )
                                child = child->next();
							else
							{
								child->setNext( deletedCellsNext );
								if( !child->hasNext() )
								{
									// update last value on all cells
									Cell* current = child;
									while( current != 0 )
									{
										current->setLast( child );
										current = current->previous();
									}
								}
								else
									deletedCellsNext->setPrevious( child );

								break;
							}
						}

						(*c_iter)->setChild( 0 );
						(*c_iter)->hide();

						// must update groupcells parents layout
						deletedCellsParent->removeCellWidgets();
						deletedCellsParent->addCellWidgets();

						// delete groupcell
						//(document()->getCursor())->moveAfter( (*c_iter) );
						//(document()->getCursor())->deleteCurrentCell();
						delete (*c_iter);

						// update document
						document()->setChanged( true );
					}
				}
			}
		}
		catch( exception &e )
		{
			string str = string("UngroupCellCommand(), Exception: ") + e.what();
			throw runtime_error( str.c_str() );
		}
	}

 /*!
    * \class SplitCellCommand
    * \author Anders Fernström
    * \date 2006-04-26
    *
    * \brief Split the cell
    */
	void SplitCellCommand::execute()
	{
		try
		{
			if( document()->getCursor()->currentCell() )
			{
				if( typeid( *document()->getCursor()->currentCell() ) == typeid( TextCell ) ||
					typeid( *document()->getCursor()->currentCell() ) == typeid( InputCell ) )
				{
					// extraxt text
					QTextEdit* editor = document()->getCursor()->currentCell()->textEdit();
					if( editor )
					{
						QTextCursor cursor = editor->textCursor();
						cursor.movePosition( QTextCursor::End, QTextCursor::KeepAnchor );
						QTextDocumentFragment text = cursor.selection();
						cursor.removeSelectedText();

						// add new cell
						if( typeid( *document()->getCursor()->currentCell() ) == typeid( TextCell ) )
						{
							AddCellCommand addcellCommand;
							addcellCommand.setApplication( application() );
							addcellCommand.setDocument( document() );
							addcellCommand.execute();
						}
						else
						{
							// inputcell
							CreateNewCellCommand newcellCommand( "Input" );
							newcellCommand.setApplication( application() );
							newcellCommand.setDocument( document() );
							newcellCommand.execute();
						}

						// add text to new cell
						QTextEdit* newEditor = document()->getCursor()->currentCell()->textEdit();
						QTextCursor newCursor = newEditor->textCursor();
						newCursor.insertFragment( text );
						newCursor.movePosition( QTextCursor::Start );
						newEditor->setTextCursor( newCursor );

						// update document
						document()->setChanged( true );
					}
				}
			}
		}
		catch( exception &e )
		{
			string str = string("SplitCellCommand(), Exception: ") + e.what();
			throw runtime_error( str.c_str() );
		}
	}

};
