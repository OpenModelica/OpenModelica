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

#ifndef _APPLICATION_H
#define _APPLICATION_H

#include <vector>

#include <QtCore/QString>
#include <QtCore/QThread>

#include "commandcenter.h"
#include "cell.h"
#include "xmlnodename.h"

using namespace std;

namespace IAEX
{
   //class CommandCenter;

   /*!\interface Application
    * \brief Describes the core application.
    *
    * See qtapp.cpp for more information about how to use this class.
    *
    */
   class Application
   {
   public:
      virtual CommandCenter *commandCenter() = 0;
      virtual void setCommandCenter(CommandCenter *) = 0;
      virtual void addToPasteboard(Cell *cell) = 0;
      virtual void clearPasteboard() = 0;
      virtual vector<Cell *> pasteboard() = 0;
      virtual void open(const QString filename, int readmode = READMODE_NORMAL) = 0;
	  virtual void removeTempFiles(QString filename) = 0;		// Added 2006-01-16 AF
	  virtual vector<DocumentView *> documentViewList() = 0;	// Added 2006-01-27 AF
	  virtual void removeDocumentView(DocumentView *view) = 0;	// Added 2006-01-27 AF
   };
};

#endif
