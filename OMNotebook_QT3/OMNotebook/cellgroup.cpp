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

//STD Headers
#include <iostream>
#include <exception>
#include <stdexcept>

//IAEX Headers
#include "cellgroup.h"


namespace IAEX{

   /*! \class CellGroup 
    * 
    *  \brief CellGroup implements the functionality to
    *  be a Cell and contain a lot of subcells.
    *
    *
    * \todo Reimplement as a composite instead. That is much much
    * cleaner. Also look at CellWorkspace and rename CellContainer to
    * CellDocument. CellWorkspace should dissappear.
    *
    * \todo Analyse class and find out what is different from the
    * Cell class. Is it possible that cell and cellgroup should be
    * integrated as one class? 
    * It should be easy to convert from a cell to a cellgroup. 
    */
   CellGroup::CellGroup(QWidget *parent, const char *name)
      : Cell(parent, name),
	closed_(false),
	newIndex_(0)
   {
      main_ = new QWidget(this);
      layout_ = new QGridLayout(main_, 1, 1);
      setMainWidget(main_);

      mainWidget()->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
      setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
   }

   CellGroup::~CellGroup()
   {
   }
   
   void CellGroup::adjustHeight()
   {
      setHeight(height());
   }

   /*! \brief calculates the height of the cellgroup.
    *
    * Calculates the height of the cellgroup. The calculated height
    * depends on the state of the group. Is the group closed then the
    * height is just the first cell otherwise the height is a sum of 
    * the height of all cells.
    *
    * \returns height of cellgroup.
    * 
    * \bug HeightVisitor does not return correct height value. I do
    * not know why, so I implemented another way to traverse subcells
    * and asking for heights.
    */
   int CellGroup::height()
   {
      int height = 0;
      
      if(closed_)  //Height of the first cell.
	 height = child()->height();
      else
      {
	 Cell *current = child();
 	 int h = 0;
 	 while(current != 0)
 	 {
 	    h += current->height();
 	    current = current->next();
 	 }

	 height = h;
      }
      
      return height;
    }

   /*! \todo Should this be moved to treeview? How does cell take care
    *  of this event?
    */
   void CellGroup::mouseDoubleClickEvent(QMouseEvent *event)
   {
      if(treeView()->hasMouse())
      {	
	 closed_ = !closed_;
	 setClosed(closed_); 
	 setSelected(false);
      }	
      else			
      {
	 //Do nothing.
      }
   }
   
   /*! \brief This function hides/shows the content of a groupcell. 
    *
    * This member hides/shows the content of a cellgroup. The height of
    * the cellgroup is calculated depending on wich case it is.
    *
    * \todo Add some signals when this happens. It can be possible that
    * someone will do some fun stuff when a cell is closing.
    * 
    * \bug This function could create a segmentation fault in some
    * special cases. Try to find them.
    *
    * \todo reimplement with removing and adding to the layout instead.
    *
    * \param closed tells if the cells should be visible or hidden.
    */
   void CellGroup::setClosed(const bool closed)
   {      
      if(hasChilds())
	 child()->hideTreeView(closed);
      
      treeView()->setClosed(closed);
      setHeight(height()); //Sends a signal
      
      closed_ = closed;
      
      emit cellOpened(this, closed_);
   }

   bool CellGroup::isClosed() const
   {
      return closed_;
   }

   void CellGroup::setFocus(const bool focus)
   {
      if(hasChilds())
	 child()->setFocus(focus);
   }

   /*! \brief Decides if a visitor is allowed to visit the object. 
    *
    * Traverses the structure in preorder.
    * 
    * \todo Could the traversing order be decided in the visitor instead
    * without to much dirt added to the code class? This is definitly not
    * important.
    *
    * \todo Implement an Iterator for the cell structure. This could be
    * nice.
    *
    */
   void CellGroup::accept(Visitor &v)
   {  
      v.visitCellGroupNodeBefore(this);

      if(hasChilds())
	 child()->accept(v);      

      v.visitCellGroupNodeAfter(this);
      
      if(hasNext())
	 next()->accept(v);
   }

   
   /*!
    * \todo Try to get rid of the dependency of the doc() member. One
      way should be to use the cursor when opening a document. Use the
      cursors add functionality. Then this could be removed. The
      dependency should only be in the cursor then.
    */
   void CellGroup::addChild(Cell *newCell)
   {      
      newCell->setParentCell(this);

      if(hasChilds())
      {
	 Cell *previous = last();
	 
	 newCell->setPrevious(previous);
	 newCell->setNext(0);
	 
	 previous->setNext(newCell);
	 setLast(newCell);
      }
      else
      { //First in line.
	 setChild(newCell);
	 setLast(newCell);
	 newCell->setNext(0);
	 newCell->setPrevious(0);
      }
      
      addCellWidget(newCell);
   }

   /*!
    * \brief Removes a cell from a cellgroup. But does not delete the cell!
    */
   void CellGroup::removeChild(Cell *aCell)
   {

      //remove all widgets from parents layout.
      Cell *par = aCell->parentCell();
      par->removeCellWidgets();
      
      Cell *prev = aCell->previous();
      Cell *next = aCell->next();

      if(aCell->parentCell()->child() == aCell)
 	 aCell->parentCell()->setChild(aCell->next());
      
      if(aCell->parentCell()->last() == aCell)
	 aCell->parentCell()->setLast(aCell->previous());
      
      if(next)
      {
	 if(prev)
	    next->setPrevious(prev);
      }

      if(prev)
      {
	 if(next)
	    prev->setNext(next);
      }
      //Insert all widgets again.
      par->addCellWidgets();
   }

   //Just add widget. Don´t forget to repaint.
   void CellGroup::addCellWidget(Cell *newCell)
   {
      newCell->reparent(mainWidget(), QPoint(0,0), true);
      connect(newCell, SIGNAL(heightChanged()),
	      this, SLOT(adjustHeight()));
      
      removeCellWidgets();
      addCellWidgets();   
   }

   void CellGroup::removeCellWidgets()
   {
      Cell *current = child(); 
      
      while(current != 0)
      {
	 layout_->remove(current);
	 current = current->next();
      }
   }

   void CellGroup::addCellWidgets()
   {  
      Cell *current = child();
      int i = 0;
      
      while(current != 0)
      {
	 if(current->parentWidget() != mainWidget())
	 {
	    current->reparent(mainWidget(), QPoint(0,0), true);
	    connect(current, SIGNAL(heightChanged()),
		    this, SLOT(adjustHeight()));
	 }
	 
	 layout_->addWidget(current,i,0);
	 ++i;
	 current = current->next();
      }
      
      adjustHeight();
   }

   //Delegate some properties.
   
   void CellGroup::setStyle(const QString &style)
   {
      if(closed_)
	 child()->setStyle(style);
   }

   void CellGroup::setStyle(const QString &name, const QString &val)
   {
      if(closed_)
	 child()->setStyle(name, val);
   }

	QString CellGroup::style()
	{
		if(closed_)
			return child()->style();
		else
			return QString::null;
	}
}
