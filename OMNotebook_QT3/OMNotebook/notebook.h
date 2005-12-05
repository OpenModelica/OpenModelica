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

/*! \file notebook.h
 * \author Ingemar Axelsson
 * \date 2005-02-07
 */

#ifndef _NOTEBOOK_WINDOW_H
#define _NOTEBOOK_WINDOW_H

//STD Headers
#include <map>

//QT Headers
#include <qwidget.h>
#include <qmainwindow.h>
#include <qpopupmenu.h>
#include <qmenubar.h>
#include <qstatusbar.h>
#include <qaction.h>

//IAEX Headers
#include "application.h"
#include "document.h"
//#include "celldocument.h"

namespace IAEX{

   class NotebookWindow : public DocumentView
   {
      Q_OBJECT
   public:
      NotebookWindow(Document *subject, const QString& filename=0,
		     QWidget *parent=0, const char *name=0);
      virtual ~NotebookWindow();
      
      virtual void update();
      Application *application();
      
   public slots:
      void setSelectedStyle();
      void updateStyleMenu();

   protected:
      void keyPressEvent(QKeyEvent *event);
      void keyReleaseEvent(QKeyEvent *event);

   private slots:
      void newFile();
      void openFile(const QString &filename=0);
      void closeFile();
      void aboutQTNotebook();
      void saveas();
      void save();
      void changeStyle(QAction *action);
      void changeStyle();

      void createNewCell();
      void deleteCurrentCell();
      void cutCell();
      void copyCell();
      void pasteCell();
      void moveCursorUp();
      void moveCursorDown();
      void groupCellsAction();
      void inputCellsAction();

   private:
      void createMenu();
      void createAboutMenu();
      void createCellMenu();
      void createEditMenu();
      void createFormatMenu();

	  QString strippedFileName( const QString &fullFileName ); //AF
      
   private:
      void createSavingTimer();

      QPopupMenu *fileMenu;
      QPopupMenu *aboutMenu;
      QPopupMenu *cellMenu;
      QPopupMenu *formatMenu;
      QPopupMenu *editMenu;

      //Change to Document.
      Application *app_;
      Document *subject_;
      
      //list<Document *> opendocs_;
      QString filename_;

      QTimer *savingTimer_;
      map<QString, QAction*> styles_;      
   };
}
#endif
