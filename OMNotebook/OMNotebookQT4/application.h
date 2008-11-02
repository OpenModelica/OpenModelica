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
