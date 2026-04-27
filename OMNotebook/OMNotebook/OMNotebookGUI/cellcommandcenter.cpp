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

//STD Headers
#include <fstream>
#include <iostream>

//QT Headers
#include <QtGlobal>
#include <QObject>
#include <QtWidgets>

//IAEX Headers
#include "cellcommandcenter.h"


namespace IAEX
{
   /*! \class CellCommandCenter
    *
    * \brief Executes and store commands.
    *
    * This class has the responsibility of storing and executing
    * commands. Support for undo is not implemented yet.
    *
    * \todo implement undo/redo functionality. This needs some changes
    * in the command classes.(Ingemar Axelsson)
    */
   CellCommandCenter::CellCommandCenter(CellApplication *a) : app_(a)
   {
   }

   CellCommandCenter::~CellCommandCenter()
   {
      storeCommands();
   }

  void CellCommandCenter::executeCommand(Command *cmd)
  {
    cmd->setApplication(application());

    //Save for undo redo, or atleast for printing.
    storage_.push_back(cmd);

    // 2005-12-01 AF, Added try-catch and messagebox
    try
    {
      cmd->execute();
    }
    catch( std::exception &e )
    {
      QString msg = e.what();

      if( 0 <= msg.indexOf( "OpenFileCommand()", 0, Qt::CaseInsensitive ))
      {
        msg += QString("\r\n\r\n")+QObject::tr("If you are trying to open an old OMNotebook file, use menu 'File->Import->Old OMNotebook file' instead.");
      }

      // display message box
      QMessageBox::warning(nullptr, QObject::tr("Warning"), msg);
    }
  }

   CellApplication *CellCommandCenter::application()
   {
      return app_;
   }

   void CellCommandCenter::setApplication(CellApplication *app)
   {
      app_ = app;
   }

   void CellCommandCenter::storeCommands()
   {
      std::ofstream diskstorage("lastcommands.txt");

      std::vector<Command *>::iterator i = storage_.begin();

      for(;i!= storage_.end();++i)
      {
      diskstorage << (*i)->commandName().toStdString() << std::endl;
      }
   }
}
