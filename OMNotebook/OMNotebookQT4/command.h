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

/*! \file command.h
 * \author Ingemar Axelsson
 * \brief Interface for creating cellcommands.
 */

#ifndef COMMAND_H
#define COMMAND_H

#include "document.h"

namespace IAEX
{

   /*!\inteface Command
    * \brief Interface for creating cell commands.
    *
    * Every command will have access to a cursor when executed. This
    * cursor is set by the executing environment.
    *
    * it should probably have access to the document instead. This
    * would give the commands much more usable.
    *
    * \todo Define some atomic commands that could be used to build up
    * more advanced commands. For example move up down. Select cell at
    * cursor position. Add/delete cell and so on. Just so there is a
    * base to work with. Then this could be really powerful. (Ingemar Axelsson)
    *
    * \todo Add a composite command. With composite command and a
    * ifcommand a quite powerful macro environment.(Ingemar Axelsson)
    *
    */
   class Command
   {
   public:
      virtual void execute() = 0;

      virtual QString commandName(){ return QString("NoCommandNameSet");}

      void setDocument(Document *document){document_ = document;}
      void setApplication(CellApplication *app){application_ = app;}

   protected:
      Document *document(){ return document_;}
      CellApplication *application(){return application_;}

   private:
      Document *document_;
      CellApplication *application_;
   };


   /*! \class CompositeCommand
    *
    * \brief Allows composite commands to be created.
    *
    * This is not fully implemented. It is just a template for the
    * composite command.
    *
    * One command could execute a lot of things. Notice that commands
    * are executed in the order that they are added (or see STL
    * vector). This command could be used to make some kind of macro
    * of other commands. It seems to be very powerful.
    *
    * Use this class with caution.
    */
   class CompositeCommand : public Command
   {
   public:
      CompositeCommand(){}
      virtual ~CompositeCommand(){}
      void add(Command *c){commands_.push_back(c);}

      virtual void execute()
      {
	 vector<Command*>::iterator i = commands_.begin();
	 for(;i != commands_.end(); ++i)
	 {
	    (*i)->execute();
	 }
      }

   private:
      vector<Command*> commands_;
   };
};
#endif
