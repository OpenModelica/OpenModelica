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

/*! \file inputcell.h
 * \author Ingemar Axelsson
 *
 * \brief Describes a inputcell.
 */

#ifndef _INPUTCELL_H_
#define _INPUTCELL_H_

//QT Headers
#include <qstylesheet.h>
#include <qwidget.h>
#include <qtextedit.h>
#include <qsyntaxhighlighter.h>

//IAEX Headers
#include "cell.h"
#include "inputcelldelegate.h"
//#include "document.h"
#include "syntaxhighlighter.h"


namespace IAEX
{   
   class InputCell : public Cell
   {
      Q_OBJECT
   public:
      InputCell(QWidget *parent=0, const char *name=0);
      virtual ~InputCell();

      void setStyleSheet(QStyleSheet *);
      void setText(QString text);
      QString text();
      virtual void viewExpression(const bool){} 
	  
      virtual void addCellWidgets();
      virtual void removeCellWidgets();
	  
      void setDelegate(InputCellDelegate *d);
      void setSyntaxHighlighter(SyntaxHighlighter *h);
      virtual void accept(Visitor &v);
      //QSize sizeHint() const; 
	  
      //virtual Cell clone(){}

   signals:
      void textChanged();

   public slots:
      void eval();
      void contentChanged();
      void setClosed(const bool closed);
      virtual void setFocus(const bool focus);
      void clickEvent(int, int);
      virtual void setStyle(const QString &style);
      virtual void setStyle(const QString &name, const QString &val);

   protected:
	   void resizeEvent(QResizeEvent *event);	//AF
      void mouseDoubleClickEvent(QMouseEvent *);
      void clear();
      bool eventFilter(QObject *o, QEvent *e);

      bool hasDelegate();
      InputCellDelegate *delegate();

   private:
      void createInputCell();
      void createOutputCell();
      //void createHighlighter();
      
      bool evaluated_;
      bool closed_;
      static int numEvals_;

      QTextEdit *input_;
      QTextEdit *output_;
      InputCellDelegate *delegate_;

      QGridLayout *layout_;
      
      //QSyntaxHighlighter *syntaxHighlighter_;
      SyntaxHighlighter *syntaxHighlighter_;
   };
}
#endif
