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

#ifndef _APPLICATION_H
#define _APPLICATION_H

#include <vector>

#include <QtCore/QString>
#include <QtCore/QThread>

#include "commandcenter.h"
#include "cell.h"
#include "xmlnodename.h"


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
      virtual ~Application() = default;
      virtual CommandCenter *commandCenter() = 0;
      virtual void setCommandCenter(CommandCenter *) = 0;
      virtual void addToPasteboard(Cell *cell) = 0;
      virtual void clearPasteboard() = 0;
      virtual std::vector<Cell *> pasteboard() = 0;
      virtual void open(const QString filename, int readmode = READMODE_NORMAL, int isDrModelica = 0) = 0;
    virtual void removeTempFiles(QString filename) = 0;    // Added 2006-01-16 AF
    virtual std::vector<DocumentView *> documentViewList() = 0;  // Added 2006-01-27 AF
    virtual void removeDocumentView(DocumentView *view) = 0;  // Added 2006-01-27 AF
   };
}

#endif
