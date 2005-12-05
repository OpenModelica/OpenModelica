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

#ifndef _CURSORCOMMANDS_H
#define _CURSORCOMMANDS_H

#include "command.h"
#include "factory.h"
#include "document.h"
#include "cellcursor.h"
#include "serializingvisitor.h"

using namespace std;

namespace IAEX
{
   /*! \class CursorMoveUpCommand
    *
    * \brief Moves the cursor up one step.
    */
   class CursorMoveUpCommand : public Command
   {
   public:
      CursorMoveUpCommand(){}
      virtual ~CursorMoveUpCommand(){}
      void execute()
      {
	 try
	 {
	    CellCursor *cursor = document()->getCursor();
	    
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

	    cursor->moveUp();
	    
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
	    cerr << "CursorMoveUpCommand(), Exception: " << e.what() << endl;
	 }
      }
   }; 

   /*! \class CursorMoveDownCommand
    *
    * \brief Moves the cursor down one step.
    */
   class CursorMoveDownCommand : public Command
   {
   public:
      CursorMoveDownCommand(){}
      virtual ~CursorMoveDownCommand(){}
      void execute()
      {
	 try
	 {
	    CellCursor *cursor = document()->getCursor();
	    
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

	    cursor->moveDown();	    

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
	    cerr << "CursorMoveDownCommand(), Exception: " << e.what() << endl;
	 }
      }
   }; 

   /*! \class CursorMoveAfterCommand
    *
    * \brief Moves the cursor after a specific cell.
    */
   class CursorMoveAfterCommand : public Command
   {
   public:
      CursorMoveAfterCommand(Cell *cell):cell_(cell){}
      virtual ~CursorMoveAfterCommand(){}
      void execute()
      {
	 try
	 {
	    CellCursor *cursor = document()->getCursor();

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

	    cursor->moveAfter(cell_);
	    
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
	    cerr << "CursorMoveAfterCommand(), Exception: " << e.what() << endl;
	 }
      }
   private:
      Cell *cell_;
   }; 
};
#endif
