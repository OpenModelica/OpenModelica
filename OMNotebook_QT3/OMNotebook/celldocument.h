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

/*! \file celldocument.h
 * \author Ingemar Axelsson
 * \brief Describes the mainwidget used in other applications.
 */

#ifndef CELLDOCUMENT_H
#define CELLDOCUMENT_H

//STD Headers
#include <vector>

//QT Headers
#include <qscrollview.h>
#include <qlayout.h>
#include <qframe.h>
#include <qdom.h>
#include <qobject.h>

//IAEX Headers
#include "application.h"
#include "cell.h"
#include "visitor.h"
#include "factory.h"
#include "document.h"
#include "command.h"
#include "documentview.h"
//#include "cursor.h"
#include "cellcursor.h"


namespace IAEX{

   class CellDocument : public Document//, public QObject
   {
      Q_OBJECT
   public:
      //typedef unsigned int cellpos;
      typedef vector<DocumentView*> observers_t;
   public:
      CellDocument(Application *a, const QString filename);
      virtual ~CellDocument();

      void setApplication(Application *app){app_ = app;}
      Application *application(){ return app_;}

      //Document implementations
      virtual void open(const QString &filename);
      virtual void close();
      virtual QString getFilename();
	  virtual void setFilename( QString filename ); //AF
	  virtual void setSaved( bool saved ); //AF

      virtual void attach(DocumentView *d);
      virtual void detach(DocumentView *d);
      virtual void notify();

	  //Cursor methods
      virtual void cursorStepUp();
      virtual void cursorStepDown();
      virtual void cursorAddCell();
      virtual void cursorDeleteCell();
      virtual void cursorCutCell();
      virtual void cursorCopyCell();
      virtual void cursorPasteCell();
      virtual void cursorChangeStyle(const QString &style);
      
      //State operations
      virtual bool hasChanged() const;
      bool isOpen() const;
	  bool isSaved() const;
      
      //Cursor operations
      CellCursor *getCursor();
      Factory *cellFactory();
      vector<Cell*> getSelection();

      //Command
      void executeCommand(Command *cmd);
      
      //Traversals.
      void runVisitor(Visitor &v);

      //observer
      QFrame *getState();

   public slots:
      void toggleMainTreeView();
      void setEditable(bool editable);
      void cursorChangedPosition();
      void selectedACell(Cell *selected, Qt::ButtonState);
      void clearSelection();
      void mouseClickedOnCell(Cell *clickedCell);
      void linkClicked(QUrl *url);
      virtual void cursorMoveAfter(Cell *aCell, const bool open);
      void showHTML(bool b);
   signals:
      /*! \brief Signals when the celldocument width has changed.
       */
      void widthChanged(const int);
      void cursorChanged();
      void viewExpression(const bool);

   protected:
      void setWorkspace(Cell *newWorkspace);
      bool eventFilter(QObject *o, QEvent *e);

   private:
      bool open_;
	  bool saved_;

      Application *app_;
      QString filename_;

      Cell *workspace_; //This should alwas be a cellgroup. 
      QFrame *mainFrame_;
      QScrollView *vp_;
      QGridLayout *mainLayout_;

      CellCursor *current_;
      Factory *factory_;
      
      vector<Cell*> selectedCells_;
      
      observers_t observers_;
   };
}

#endif
