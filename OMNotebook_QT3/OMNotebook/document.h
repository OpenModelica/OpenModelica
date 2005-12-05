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

/*! \file document.h
 * \author Ingemar Axelsson
 * \brief Describes a celldocument.
 */

#ifndef DOCUMENT_H
#define DOCUMENT_H

#include <vector>

#include <qframe.h>

#include <qobject.h>

#include "visitor.h"

#include "documentview.h"

using namespace std;

namespace IAEX
{
   
   //Forward declaration
   class Command;
   class CellCursor;
   class Factory;
   class DocumentView;
   class Application;


   /*! \interface Document
    *
    * \brief Describes all operations that is needed by a document.
    *
    * The Document interface describes all methods that must be
    * implemented by a concrete document class. 
    */
   class Document : public QObject 
   {
      Q_OBJECT
   public: 
      //Application
      virtual Application *application() = 0;
      //State
      virtual bool hasChanged() const = 0;
      virtual bool isOpen() const = 0;
	  virtual bool isSaved() const = 0; // AF
      
      //File operations
      virtual void open(const QString &filename) = 0;
      virtual void close() = 0;
      //virtual void save() = 0;
      virtual QString getFilename() = 0;
	  virtual void setFilename( QString filename ) = 0; //AF
	  virtual void setSaved( bool saved ) = 0; //AF

      //Cursor operations
      virtual CellCursor *getCursor() = 0;
      virtual void cursorStepUp() = 0;
      virtual void cursorStepDown() = 0;
      virtual void cursorMoveAfter(Cell *aCell, const bool open) = 0;
      virtual void cursorAddCell() = 0;
      virtual void cursorDeleteCell() = 0;
      virtual void cursorCutCell() = 0;
      virtual void cursorCopyCell() = 0;
      virtual void cursorPasteCell() = 0;
      
      virtual void cursorChangeStyle(const QString &style) = 0;

      //Utility operations
      virtual Factory *cellFactory() = 0;
      virtual vector<Cell *> getSelection() = 0;
      virtual void clearSelection() = 0;
      
      //command operations
      virtual void executeCommand(Command *cmd) = 0;

      //Observer interface
      virtual void attach(DocumentView *d) = 0;
      virtual void detach(DocumentView *d) = 0;
      virtual void notify() = 0;
      virtual QFrame *getState() = 0;

      //Visitor Initializations
      virtual void runVisitor(Visitor &v) = 0;
   };
}
#endif
