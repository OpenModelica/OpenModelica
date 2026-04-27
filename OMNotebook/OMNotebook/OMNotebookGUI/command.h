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
      virtual ~Command() = default;
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
   std::vector<Command*>::iterator i = commands_.begin();
   for(;i != commands_.end(); ++i)
   {
      (*i)->execute();
   }
      }

   private:
      std::vector<Command*> commands_;
   };
};
#endif
