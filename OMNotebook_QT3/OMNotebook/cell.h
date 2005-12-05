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

/*! \file cell.h
 * \author Ingemar Axelsson
 *  \brief Definition of the cellinterface.
 *
 *  This file contains the definition of the cellinterface.
 */
#ifndef CELL_H
#define CELL_H

//STD Headers
//af#include <iostream>
#include <vector>

//QT Headers
#include <qwidget.h>
#include <qlabel.h>
#include <qlayout.h>
#include <qurl.h>
#include <qsizepolicy.h>

//IAEX Headers
//#include "document.h"
#include "visitor.h"
#include "treeview.h"
#include "rule.h"
#include "inputcelldelegate.h"
#include "syntaxhighlighter.h"

using namespace IAEX;

namespace IAEX{

//    class CellInterface
//    {
//    public:
//       virtual void accept(Visitor &v) = 0;
      
//       //Interface from cellgroup
//       virtual void addChild(CellInterface *child) = 0;
//       virtual void height() = 0;
//       virtual void setClosed(const bool closed) = 0; //public slot
//       virtual void adjustHeight() = 0; //public slot
      
//       //Interface from textedit
//       virtual void setText(QString text) = 0;
//       virtual QString text() = 0;
//       virtual void clear() = 0;
      
//       virtual void clickEvent(int para, int pos);
//       virtual void setReadOnly(const bool readonly);
//       virtual void setFocused(const bool focused);
//       virtual void openLink(QUrl *link);
//       virtual void setStyle(const QString &style);
//       virtual void setStyle(const QString &name, const QString &val);
      
//       //Interface from inputcell
//    };

   class Cell : public QWidget //, public Node
   { 
      Q_OBJECT
   public:
      typedef vector<Rule *> rules_t;
   public:
      Cell(QWidget *parent=0, const char *name=0);
      Cell(Cell &c);
      virtual ~Cell();

      //Datastructure interface.
      void setNext(Cell *nxt);
      Cell *next();
      bool hasNext();

      void setLast(Cell *last);
      Cell *last();
      bool hasLast();

      void setPrevious(Cell *prev);
      Cell *previous();
      bool hasPrevious();
      
      Cell *parentCell();
      void setParentCell(Cell *parent);
      bool hasParentCell();
      
      void setChild(Cell *child);
      Cell *child();
      bool hasChilds();

      void printCell(Cell *current);
      void printSurrounding(Cell *current);

      //Document *doc() const;

      //TextCell interface.
      virtual QString text() = 0;//{return QString::null;}
      virtual void viewExpression(const bool){}; 

      //Cellgroup interface.
      virtual void addChild(Cell *){}
      virtual void removeChild(Cell *){}
      virtual bool isClosed() const{ return false;}
      virtual void setClosed(const bool){}
      
      virtual void addCellWidget(Cell *newCell); //Protected?
      
      //Rename to insertCellWidgets() instead.
      virtual void addCellWidgets(){parentCell()->addCellWidgets();}
      virtual void removeCellWidgets(){parentCell()->removeCellWidgets();}
      
      //Traversal methods
      virtual void accept(Visitor &v);
            
      //Flags
      const bool isSelected() const;
      const bool isTreeViewVisible() const;      

      //Properties
      const QColor backgroundColor() const;       
      virtual QString style() const;
      virtual rules_t rules() const;
      QWidget *mainWidget();
      TreeView *treeView();
      QLabel *label();      

   public slots:
      virtual void addRule(Rule *r);
      virtual void setStyle(const QString &style);
      virtual void setStyle(const QString &name, const QString &val);
      virtual void setText(QString text){}
      
      virtual void setReadOnly(const bool){}
      
      virtual void setBackgroundColor(const QColor color);
      virtual void setSelected(const bool selected);
      virtual void setFocus(const bool focus) = 0;
      virtual void setHeight(const int height);
      void hideTreeView(const bool hidden);
      
   protected slots:
      void setLabel(QLabel *label);
      void setTreeWidget(TreeView *newTreeWidget);
      void setMainWidget(QWidget *newWidget);

   signals:
      void clicked(Cell*);
      void doubleClicked(int);
      void changedWidth(const int);
      void selected(const bool);
      void cellselected(Cell *, Qt::ButtonState);
      void heightChanged();
      void openLink(QUrl *link);
      void cellOpened(Cell *, const bool);

   protected:      
      //Events
      void resizeEvent(QResizeEvent *event);
      void mouseReleaseEvent(QMouseEvent *event);
      void mouseMoveEvent(QMouseEvent *event);

   private:
      QGridLayout *mainlayout_;
      TreeView *treeView_;
      QWidget *mainWidget_;
      QLabel *label_;
      QString style_;

      //Document *doc_;
      bool selected_;
      bool treeviewVisible_;
      QColor backgroundColor_;

      rules_t rules_;

      Cell *parent_;
      Cell *next_;
      Cell *last_;
      Cell *previous_;
      Cell *child_;

      int references_;
   };
}
#endif
