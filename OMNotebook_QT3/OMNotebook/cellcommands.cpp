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

#include <exception>

#include "cellcommands.h"

namespace IAEX
{
   /*! \class AddCellCommand
    *
    * \brief Command for adding a new cell to the cellstructure.
    */
	void AddCellCommand::execute()
	{
		try
		{
			CellCursor *cursor = document()->getCursor();

			Factory *fac = document()->cellFactory();

			QString style;

			if(cursor->currentCell()->hasChilds())
				style = cursor->currentCell()->child()->style();
			else
				style = cursor->currentCell()->style();

			//qDebug( "Add style:" );
			//qDebug( style );

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

			cursor->addBefore(fac->createCell(style));
	
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
		catch(exception &e)
		{
			cerr << "AddCellCommand(), Exception: " << e.what() << endl;
		}
	}
   
   /*! \class CreateNewCellCommand
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
      }
      catch(exception &e)
      {
	 cerr << "CreateNewCommand(), Exception: " << e.what() << endl;
      }
   }


   /*! class CopySelectedCellsCommand 
    * \brief copy a cell. Adds a copy of the cell on the pasteboard. 
    *
    * \todo Implement some kind of internal state or copy constructors
    * for all cells. This to make the copy process more general.
    *
    * \todo Implement release from cellgroup. It should be possible to
    * remove pointers to the cell structure without deleting the
    * object. That needs reparenting of all subcells.
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
	
      }
      catch(exception &e)
      {
	 cerr << "DeleteCurrentCellsCommand(), Exception: " << e.what() << endl;
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

	 //1. Get current position.
	 CellCursor *cursor = document()->getCursor();

	 //2. Insert new cells before this position.
	 if(!cells.empty())
	 {
	    //Reverse iterator!!!!!
	    vector<Cell *>::reverse_iterator i = cells.rbegin();
	    for(;i != cells.rend();++i)
	    {
	       cout << "PASTEBOARD: " << (*i)->style() << endl;
	       Factory *fac = document()->cellFactory();
			   
	       QString style = (*i)->style();
				  
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
			   
	       cursor->addBefore(fac->createCell(style));
			   
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
	       if(style == "cellgroup")
	       {
		  //Copy content of cellgroup.
		  //add all subcells. 
	       }
	       else if(style == "imagecell")
	       {
		  //This should be treated in some way.
	       }
	       else
	       {
		  cursor->currentCell()->setText((*i)->text());
	       }
	    }
	 }
      }
      catch(exception &e)
      {
	 cerr << " PasteCellsCommand(), Exception: " << e.what() << endl;
      }
   }
   
   /*! \class DeleteSelectedCellsCommand 
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
      }
      catch(exception &e)
      {
	 cerr << "DeleteSelectedCellsCommand(), Exception: " << e.what() << endl;
      }
   }

   /*! \class ChangeStyleOnSelectedCellsCommand
    *
    * \brief Changes style on selected cells. 
    *
    * This does not work on selected Cellgroups. This because I have
    * not defined what will happen if I change style on a
    * cellgroup. Probably all its children will get the same style.
    *
    *\todo implement setStyle for cellgroups.
    */
   void ChangeStyleOnSelectedCellsCommand::execute()
   {
      try
      {
	 //qDebug("entered ChangeStyleOnSelectedCellsCommand");
	 vector<Cell *> cells = document()->getSelection();
	 
	 if(cells.empty())
	 {
	    //qDebug("No selection");
	    document()->getCursor()->currentCell()->setStyle(style_);
	 }
	 else
	 {
	    //qDebug("For all cells");
	    vector<Cell *>::iterator i = cells.begin();
	    
	    for(;i != cells.end() ;++i)
	    {
	       //qDebug("setting style");
	       (*i)->setStyle(style_);//This makes an segfault. Do not now why?
	    }
	    
	 }
	 //qDebug("Leaving");
      }
      catch(exception &e)
      {
	 cerr << "ChangeStyleOnSelectedCellsCommand(), Exception: " << e.what() << endl;
      }
   }

   void ChangeStyleOnCurrentCellCommand::execute()
   {
      try
      {
	 document()->getCursor()->currentCell()->setStyle(style_);
      }
      catch(exception &e)
      {
	 cerr << "ChangeStyleOnCurrentCellCommand(), Exception: " << e.what() << endl;
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
      }
      catch(exception &e)
      {
	 cerr << "MakeGroupCellCommand(), Exception: " << e.what() << endl;
      }
   }
};
