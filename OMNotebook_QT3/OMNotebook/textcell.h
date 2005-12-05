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

/*! \file textcell.h
 * \author Ingemar Axelsson
 * \date 2005-02-08
 */
#ifndef TEXTCELL_H
#define TEXTCELL_H

//QT Headers
#include <qwidget.h>
#include <qtextbrowser.h>
#include <qframe.h>
#include <qurl.h>

//IAEX Headers
#include "cell.h"
#include "visitor.h"
#include "stylesheet.h"

namespace IAEX
{      
   class TextCell : public Cell
   {
      Q_OBJECT
   public:
      TextCell(QWidget *parent = 0, const char *name = 0);
      TextCell(TextCell &t);
      
      virtual ~TextCell();
      
      virtual QString text();
      void clear();      
      virtual void accept(Visitor &v);

//<<<<<<< .mine
      //virtual Cell clone(); //Create a copy of itself.
//=======
      //virtual Cell &clone(); //Create a copy of itself.
//>>>>>>> .r179
   
   signals:
      void textChanged();

   public slots:
      void clickEvent(int para, int pos); //Should not be public!
      void setReadOnly(const bool readonly);
      void setText(QString text);
      virtual void setStyle(const QString &style);
      virtual void setStyle(const QString &name, const QString &val);
      virtual void setFocus(const bool focus);
      virtual void viewExpression(const bool expr); 

   protected slots:
      void contentChanged();
      void openLinkInternal(QUrl *url);
      void textChangedInternal();

   protected:
      void resizeEvent(QResizeEvent *event);

   private:
      void setStyleSheet(QStyleSheet *sheet);
      void createTextWidget();
      QTextBrowser *text_;
   };

///////////////////////////////////////////////
   class MyTextBrowser : public QTextBrowser
   {
      Q_OBJECT
   public:
      MyTextBrowser(QWidget *parent=0, const char *name=0);
      virtual ~MyTextBrowser();
      
   signals:
      void openLink(QUrl *);
	 
   public slots:
      void setSource(const QString &name);

   protected:
      //void mousePressEvent(QMouseEvent *event);
   };

}
#endif
