/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */

//STD Headers
#include <fstream>
#include <iostream>

//QT Headers
#include <QtGui/QMessageBox>

//IAEX Headers
#include "cellcommandcenter.h"

using namespace std;

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
		catch( exception &e )
		{
			QString msg = e.what();

			if( 0 <= msg.indexOf( "OpenFileCommand()", 0, Qt::CaseInsensitive ))
			{
				msg += QString("\r\n\r\nIf you are trying to open an old ") +
					QString("OMNotebook file, use menu 'File->Import->") +
					QString("Old OMNotebook file' instead.");
			}

			// display message box
			QMessageBox::warning( 0, "Warning", msg, "OK" );
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
      ofstream diskstorage("lastcommands.txt");

      vector<Command *>::iterator i = storage_.begin();

      for(;i!= storage_.end();++i)
      {
		  diskstorage << (*i)->commandName().toStdString() << endl;
      }
   }
}

