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

#include <iostream>
#include "treeview.h"

namespace IAEX
{
   
   /*! \brief Construct a TreeView object and initialize it.
    * \author Ingemar Axelsson
    *
    * For parameter information, see the Qt manual.
    */
   TreeView::TreeView(QWidget *parent, const char *name)
      :QWidget(parent, name), 
       selected_(false), 
       closed_(false),
       selectedColor_(QColor(0,0,255))
   {
      setFixedWidth(10);
      setSizePolicy(QSizePolicy(QSizePolicy::Fixed, QSizePolicy::Expanding));
      setBackgroundMode(Qt::PaletteBase);
   }
   
   /*! \brief Set the background color of the treeview.
    * \author Ingemar Axelsson
    *
    * Sets the backgroundcolor of this view. This should never be set to
    * black due to the color of the treething.
    *
    * \todo Add functionality to change the treecolor. Also add
    * functionality to retrieve the current colors.
    *
    * \param col background color for the treeview.
    */
   void TreeView::setBackgroundColor(const QColor col)
   {
      backgroundColor_ = col;
   }
   
   void TreeView::setSelected(const bool sel)
   {
      selected_ = sel;
      repaint();
   }
   
   /*! 
    * \deprecated
    */
   const bool TreeView::selected() const
   {
      return selected_;
   }
      
   void TreeView::setClosed(const bool closed)
   {
      closed_ = closed;
      repaint();
   }

   const bool TreeView::isClosed() const
   {
      return closed_;
   }
   
   QColor TreeView::selectedColor() const
   {
      return selectedColor_;
   }

   QColor TreeView::backgroundColor() const
   {
      return backgroundColor_;
   }

   /*! \brief Describes what a TreeView widget will look like.
    *
    * \bug Some cells are closed even if they cant be closed. This must
    * be fixed in some way.
    */	
   void TreeView::paintEvent(QPaintEvent *event)
   {      
      QPainter painter(this);

      if(selected_)
      {
	 this->setPaletteBackgroundColor(selectedColor());
	 painter.setPen(QPen(yellow, 1, SolidLine));
      }
      else
      {
	 this->setPaletteBackgroundColor(backgroundColor());
	 painter.setPen(QPen(black,1, SolidLine));
      }
      
      QWidget::paintEvent(event);
      
      QPointArray points(4);
      
      if(closed_)
      {
	 points[0] = QPoint(1,2);
	 points[1] = QPoint(5,2);
	 points[2] = QPoint(5, height()-2);
	 points[3] = QPoint(1, height()-8);
      }
      else
      {    
	 points[0] = QPoint(1,2);
	 points[1] = QPoint(5,2);
	 points[2] = QPoint(5,height()-2);
	 points[3] = QPoint(1,height()-2);
      }
      
      painter.drawPolyline(points);
   }

//////////////////////////////////////////////////////////////////////

   /*! \class InputTreeView
    *
    * \brief A treeview for inputcells. This view acts a little
    * different than other treeviews. Mostly different paintEvent.
    */
   InputTreeView::InputTreeView(QWidget *parent, const char *name)
      : TreeView(parent, name)
   {}
   
   void InputTreeView::paintEvent(QPaintEvent *event)
   {
      QPainter painter(this);

      //Selected or not selected
      if(selected())
      {
	 setPaletteBackgroundColor(selectedColor());
	 painter.setPen(QPen(yellow, 1, SolidLine));
      }
      else
      {
	 setPaletteBackgroundColor(backgroundColor());
	 painter.setPen(QPen(black,1, SolidLine));
      }
      
      if(isVisible())
      {
	 QWidget::paintEvent(event);
	 
	 QPointArray points(4);
	 
	 points[0] = QPoint(1,2);
	 points[1] = QPoint(5,2);
	 points[2] = QPoint(5,height()-2);
	 points[3] = QPoint(1,height()-2);
	 
	 painter.drawPolyline(points);
      }
   }
}
