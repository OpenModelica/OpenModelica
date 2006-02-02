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

/*! \file treeview.h 
 *  \author Ingemar Axelsson
 */
#ifndef TREEVIEW_H
#define TREEVIEW_H

#include <QtGui/QWidget>
#include <QtGui/QPainter>
#include <QtCore/QPoint>
//Added by qt3to4:
#include <QtGui/QPaintEvent>

namespace IAEX
{

   /*! \class TreeView
    * \brief Class describing how the treeview should be drawn.
    * \author Ingemar Axelsson
    * 
    * TreeView is responsible for drawing the treestructure for each
    * cell.
    *
    * \todo Find a way to easily extend a cell with multiple
    * treeviews. It should be easy to change the treeview to a more
    * goodlooking view if someone wants to do that.(Ingemar Axelsson)
    */
   class TreeView : public QWidget
   {
      Q_OBJECT
   public:
      TreeView(QWidget *parent=0);
      
      void TreeView::setBackgroundColor(const QColor col);
      
      const bool selected() const;
      const bool isClosed() const;
   public slots:	
      void setClosed(const bool closed);
      void setSelected(const bool sel);


   protected:
      void paintEvent(QPaintEvent *event);
      //void mousePressedEvent(QMouseEvent *event);
      //void mouseReleaseEvent(QMouseEvent *event);
      QColor selectedColor() const;
      QColor backgroundColor() const;
      
   signals:
      void becomeSelected(bool); //Deprecated
      
   private:
      bool selected_;
      bool closed_; //This is not a good way, but it works for now!
      QColor selectedColor_;
      QColor backgroundColor_;
   };
   
   class InputTreeView : public TreeView
   {
   public:
      InputTreeView(QWidget *parent=0);
   protected:
      void paintEvent(QPaintEvent *event);
   };
}
#endif
