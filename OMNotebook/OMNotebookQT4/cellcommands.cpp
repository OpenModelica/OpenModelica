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


//STD Headers
#include <exception>

//IAEX Headers
#include "cellcommands.h"
#include "inputcell.h"
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
				style = cursor->currentCell()->child()->style();
			else
				style = cursor->currentCell()->style();

			
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
			throw exception( str.c_str() );
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
		  throw exception( str.c_str() );
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
	 //Empty pasteboard. 
	 application()->clearPasteboard();
	 application()->addToPasteboard(c->currentCell());
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
	    //Empty pasteboard. 
	    application()->clearPasteboard();
	    application()->addToPasteboard(c->currentCell());
	    
	    c->removeCurrentCell();
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
		throw exception( str.c_str() );
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
				vector<Cell *>::reverse_iterator i = cells.rbegin();
				for(;i != cells.rend();++i)
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
			throw exception( str.c_str() );
		}
	}
	
	// 2006-01-16 AF, move this code to a seperated function
	void PasteCellsCommand::pasteCell( Cell *cell, CellGroup *groupcell )
	{
		//Get current position.
		CellCursor *cursor = document()->getCursor();

		Factory *fac = document()->cellFactory();

		// 2005-10-28 AF, changed style from QString to CellStyle
		CellStyle style = cell->style();

		//Create a new cell.
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

		// 2006-01-16 AF, Added support so groupcell can be pasted.
		if( groupcell )
		{
			// add child and move cursor to correct position
			groupcell->addChild( fac->createCell( style.name() ));
			cursor->moveAfter( groupcell->child() );
		}
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


		//Copy its content.
		//This is a problem!
		// 2006-01-12/16 AF, Updated what is copied
		
		//copy (every cell type)
		cursor->currentCell()->setCellTag( cell->cellTag() );

		rules_t rules = cell->rules();
		rules_t::iterator current = rules.begin();
		while( current != rules.end() )
		{
			cursor->currentCell()->addRule( (*current) );
			++current;
		}

		// copy (specific for cell type)
		if( typeid(CellGroup) == typeid( *cursor->currentCell() ))
		{
			CellGroup *newCell = dynamic_cast<CellGroup *>(cursor->currentCell());
			
			if( cell->isClosed() )
				newCell->setClosed( true );
			else
				newCell->setClosed( false );

			if( cell->hasChilds() )
			{
				//add first child
				Cell *child = cell->child();
				pasteCell( child, newCell );

				
				// add rest of children
				child = child->next();
				while( child != 0 )
				{
					pasteCell( child );
					child = child->next();
				}
			}
		}
		else if( typeid(InputCell) == typeid( *cursor->currentCell() ))
		{
			InputCell *newCell = dynamic_cast<InputCell *>(cursor->currentCell());
			InputCell *oldCell = dynamic_cast<InputCell *>( cell );

			newCell->setStyle( style );
			newCell->setText( oldCell->text() );
			
			if( oldCell->isEvaluated() )
			{
				newCell->setEvaluated( true );

				if( oldCell->isPlot() )
					newCell->setTextOutputHtml( oldCell->textOutputHtml() );
				else
					newCell->setTextOutput( oldCell->textOutput() );
			}
			else
				newCell->setEvaluated( false );


			if( oldCell->isClosed() )
				newCell->setClosed( true );
			else
				newCell->setClosed( false );
		}
		else if( typeid(TextCell) == typeid( *cursor->currentCell() ))
		{
			cursor->currentCell()->setStyle( style );
			cursor->currentCell()->setTextHtml( cell->textHtml() );
		}
		else
		{
			// ERROR
			throw exception("Unknown cell");
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
		throw exception( str.c_str() );
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
			throw exception( str.c_str() );
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
		throw exception( str.c_str() );
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
		throw exception( str.c_str() );
		  
      }
   }
};
