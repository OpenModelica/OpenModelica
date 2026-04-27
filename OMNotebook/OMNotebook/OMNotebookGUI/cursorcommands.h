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

#ifndef _CURSORCOMMANDS_H
#define _CURSORCOMMANDS_H

#include <exception>
#include <stdexcept>

#include "command.h"
#include "factory.h"
#include "document.h"
#include "cellcursor.h"
#include "serializingvisitor.h"


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
      catch(std::exception &e)
      {
        // 2006-01-30 AF, add exception
        std::string str = std::string("CursorMoveUpCommand(), Exception: ") + e.what();
        throw std::runtime_error( str.c_str() );
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
      catch(std::exception &e)
      {
        // 2006-01-30 AF, add exception
        std::string str = std::string("CursorMoveDownCommand(), Exception: ") + e.what();
        throw std::runtime_error( str.c_str() );
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
      catch(std::exception &e)
      {
        // 2006-01-30 AF, add exception
        std::string str = std::string("CursorMoveAfterCommand(), Exception: ") + e.what();
        throw std::runtime_error( str.c_str() );
      }
    }
  private:
    Cell *cell_;
  };
};
#endif
