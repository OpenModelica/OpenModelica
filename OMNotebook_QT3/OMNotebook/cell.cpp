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
//af#include <iostream>
//at#include <exception>
//af#include <stdexcept>

//QT Headers
#include <qlabel.h>

//IAEX Headers
#include "cell.h"
//#include "notebookcommands.h"

using namespace IAEX;

namespace IAEX{

   /*! \class Cell
    * \author Ingemar Axelsson
    * \brief Cellinterface contains all functionality required to be a cell.
    *	
    * It implements the cells core functionality. Objects of this
    * class should never be created. Instead tailored objects from
    * subclasses such as TextCell, InputCell, CellGroup or ImageCell
    * should be used.
    *
    * To extend the Qt Notebook application with new type of cells
    * subclass this class. Then subclass or reimplement a CellFactory
    * so it creates the new type of cell. Examples of adding new cell
    * look at InputCell and ImageCell.
    *
    * Cells contains of two parts, a mainwidget containing the cells
    * data, and the treewidget containing the treeview at the right side
    * of the cell.
    *
    * \todo Implement a widgetstack for the treeview. This to make it
    * possible to implement other treeview structures.
    *
    */
   Cell::Cell(QWidget *parent, const char *name)
      : QWidget(parent, name), //Node(),
	selected_(false),
	treeviewVisible_(true),
	backgroundColor_(QColor(255,255,255)),
	parent_(0),
	next_(0),
	last_(0),
	previous_(0),
	child_(0),
	style_(""), //AF
	references_(0)      
   {
      setMouseTracking(TRUE);
      
      mainlayout_ = new QGridLayout(this,1,2);
      setLabel(new QLabel(this, ""));

      setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed));
      setBackgroundMode(Qt::PaletteBase);
      setPaletteBackgroundColor(backgroundColor());
      setTreeWidget(new TreeView(this));   
   }

   Cell::Cell(Cell &c) : QWidget()
   {
      setMouseTracking(TRUE);

      mainlayout_ = new QGridLayout(this,1,2);
      setLabel(new QLabel(this, ""));

      setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed));
      setBackgroundMode(Qt::PaletteBase);
      setPaletteBackgroundColor(c.backgroundColor());
      setTreeWidget(new TreeView(this));
   }

   Cell::~Cell()
   {
	   //Delete if there are no references to this cell.
	   if(references_ <= 0)
	   {
		   setMouseTracking(FALSE);

		   delete treeView_;
		   delete mainWidget_;
		   delete label_;
	   }
   }

   /*! \brief Set the cells mainwidget.
    *
    * \todo Delete old widget.
    *
    * \param newWidget A pointer to the cells new mainwidget.
    */
   void Cell::setMainWidget(QWidget *newWidget)
   {  
	   if(newWidget != 0)
	   {
		   mainWidget_ = newWidget;
		   mainlayout_->addWidget(newWidget,1,1);

		   mainWidget_->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, 
			   QSizePolicy::Expanding));

		   mainWidget_->setPaletteBackgroundColor(backgroundColor());
	   }
	   else
		   mainWidget_= 0;
   }

   /*!
    * \author Ingemar Axelsson 
    * \return A pointer to the mainwidget for the cell.
    */  
   QWidget *Cell::mainWidget()
   {
	   if(!mainWidget_)
		   throw logic_error("Cell::mainWidget(): No mainWidget set.");

	   return mainWidget_;
   }


   void Cell::setLabel(QLabel *label)
   {
	   label_ = label;
	   mainlayout_->addWidget(label,1,0);
	   label_->setPaletteBackgroundColor(backgroundColor());
	   label_->hide();
   }
   
   QLabel *Cell::label()
   {
      return label_;
   }

   /*!
    * \brief Add a treeview widget to the cell.
    */
   void Cell::setTreeWidget(TreeView *newTreeWidget)
   {
      treeView_ = newTreeWidget;
      treeView_->setFocusPolicy(QWidget::NoFocus);
      mainlayout_->addWidget(newTreeWidget,1,2, Qt::AlignTop);
      treeView_->setBackgroundColor(backgroundColor());
      treeView_->show();

      connect(this, SIGNAL(selected(const bool)),
	      treeView_, SLOT(setSelected(const bool)));
   }

   TreeView *Cell::treeView()
   {
      if(!treeView_)
	 throw logic_error("Cell::treeView(): No treeView set.");
  
      return treeView_;
   }

   /*!
    * \todo The treewidget should not only be hidden, the mainwidget
    * should be resized.
    *
    *\todo test if repaint is needed here.
    */    
   void Cell::hideTreeView(const bool hidden)
   {
      if(hidden)
      {
	 treeView_->hide();
      }
      else
      {
	 treeView_->show();
      }
      
      treeviewVisible_ = !hidden;
      repaint();
   }
   
   /*! \return TRUE if treeview is hidden. Otherwise FALSE.
    */
   const bool Cell::isTreeViewVisible() const
   {
      return treeviewVisible_;
   }   

   /*! \brief Sets the height of the cell.
    * \author Ingemar Axelsson
    *
    * \param height New height for cell. 
    */
   void Cell::setHeight(const int height)
   {
      int h = height;
      
      //! \bug Implement Cell::setHeight() in a correct way. Does not work for 
      //! widgets larger than 30000.
      if(height > 30000)
			h = 30000;
      
      setFixedHeight(h);
      
      if(!treeView_)
       throw logic_error("SetHeight(const int height): TreeView is not set.");
      
      treeView_->setFixedHeight(h);
      
      emit heightChanged();
   }

   
   /*! \brief Describes what will happen if a mousebutton is released
    *  when the mouse is over the treeview widget.
    * \author Ingemar Axelsson
    * 
    * \bug Should be done in the TreeView instead. Then a
    * signal could be emitted.
    */	
   void Cell::mouseReleaseEvent(QMouseEvent *event)
   { 
      if(treeView_->hasMouse())
      {
	 this->setSelected(!isSelected());
	 emit cellselected(this, event->state());
      }
      else
      {
	 //Do nothing.
      }
   }

   /*! \brief
    *  Mouse move event is triggered when the mouse is moved.
    *
    * This method must be implemented when adding support for drag and
    * drop. Also look at the QT manual for more information about drag
    * and drop. 
    *
    * \param event QMouseEvent sent from widgets parent.
    *
    * \todo Needs a cursor->moveBefore member. 
    */
   void Cell::mouseMoveEvent(QMouseEvent *event)
   {
//       cout << "Event (X:Y): (" << event->pos().x()
// 	   << ":" << event->pos().y() << ")" << endl;
      
      if(event->pos().x() < 0 || event->pos().x() > this->width())
      {
	 //Not inside widget. Do not care
      }
      else
      {
	 if(event->pos().y() < 0)
	 {
	    //if(hasPrevious())	       
//	    doc()->executeCommand(new CursorMoveAfterCommand(previous()))
//	    doc()->executeCommand(new CursorMoveAfterCommand(this));
	    // else
// 	    {
// 	       if(parentCell()->hasParentCell()) //Check for errors
// 		  doc()->executeCommand(new CursorMoveAfterCommand(parentCell()->previous()));
// 	       else
// 	       {
// 		  //Do nothing!
// 	       }
// 	    }
	 }

//  	 else // if(event->pos().y() < height())
//  	 {
//  	    doc()->executeCommand(new CursorMoveAfterCommand(this));
//  	 }

// 	 if((doc()->getCursor())->currentCell() != this)
//  	 {
//  	    doc()->executeCommand(new CursorMoveAfterCommand(this));
//  	 }
      }
   }   

   void Cell::resizeEvent(QResizeEvent *event)
   {
      setHeight(height());
      QWidget::resizeEvent(event);
   }
   
   /*! 
    * \return true if cell is selected, false otherwise.
    */
   const bool Cell::isSelected() const
   {
      return selected_;
   }

   /*! \brief Set the value for selectec_ to true if the cell is
    *  selected.
    * \author Ingemar Axelsson
    *
    * This slot is used to change the state of the cell.
    *
    * \todo Tell the treeview that the cell has changed state. Should the
    * cell be responsible to decide if it has been selected or should the
    * treeview decide? Probably better if the cell decides.
    *
    * \param selected true if cell should be selected, false otherwise
    */
   void Cell::setSelected(const bool sel)
   {
      selected_ = sel;
      emit selected(selected_);
   }
  
   /*! \brief Set the cells background color.
    * \author Ingemar Axelsson
    *
    * Sets cells backgroundcolor. Also propagates the background color to
    * the cells child widgets.
    *
    *  \param color new color.
    */
   void Cell::setBackgroundColor(const QColor color)
   {
      backgroundColor_ = color;
      setPaletteBackgroundColor(color);
   }
   
   /*!\brief get the current backgroundcolor.
    * \author Ingemar Axelsson
    *
    * \return current background color.
    */
   const QColor Cell::backgroundColor() const
   {
      return backgroundColor_;
   }

   void Cell::setStyle(const QString &style)
   {
      style_ = style;
   }
   
   void Cell::setStyle(const QString &name, const QString &val)
   {
      addRule(new Rule(name, val));
   }

	QString Cell::style() const
	{
		return style_;
	}

   void Cell::addRule(Rule *r)
   {
      rules_.push_back(r);
   }
   
   Cell::rules_t Cell::rules() const
   {
      return rules_;
   }
  
/////VIRTUALS ////////////////////////////////   


   /*! \brief Implements visitor acceptability.
    *
    */
   void Cell::accept(Visitor &v)
   {
      v.visitCellNodeBefore(this);

      if(hasChilds())
	 child()->accept(v);

      v.visitCellNodeAfter(this);

      //Move along.
      if(hasNext())
	 next()->accept(v);
   }

   void Cell::addCellWidget(Cell *newCell)
   {
      cerr << "AddCellWidget" << endl;
      parentCell()->addCellWidget(newCell);
   }

////// DATASTRUCTURE IMPLEMENTATION ///////////////////////////

   void Cell::setNext(Cell *nxt)
   {
      next_ = nxt;
   }
   
   Cell *Cell::next()
   {
      return next_;
   }
   
   bool Cell::hasNext()
   {
      return next_ != 0;
   }

   void Cell::setLast(Cell *last)
   {
      last_ = last;
   }
   
   Cell *Cell::last()
   {
      return last_;
   }
   
   bool Cell::hasLast()
   {
      return hasChilds();
   }
   
   void Cell::setPrevious(Cell *prev)
   {
      previous_ = prev;
   }
   
   Cell *Cell::previous()
   {
      return previous_;
   }
   
   bool Cell::hasPrevious()
   {
      return previous_ != 0;
   }
   
   Cell *Cell::parentCell()
   {
      return parent_;
   }
   
   void Cell::setParentCell(Cell *parent)
   {
      parent_ = parent;
   }
   
   bool Cell::hasParentCell()
   {
      return parent_ != 0;
   }

   void Cell::setChild(Cell *child)
   {
      child_ = child;
   }
   
   Cell *Cell::child()
   {
      return child_;
   }
   
   bool Cell::hasChilds()
   {
      return child_ != 0;
   }

   void Cell::printCell(Cell *current)
   {
      cout << "This: " << current << endl
	   << "Parent: " << current->parentCell() << endl
	   << "Child: " << current->child() << endl
	   << "Last: " << current->last() << endl
	   << "Next: " << current->next() << endl
	   << "Prev: " << current->previous() << endl;
   }

   void Cell::printSurrounding(Cell *current)
   {
      cout << "CURRENT CELL:" << endl;
      printCell(current);
      
      //Print surroundings
      if(current->hasNext())
      {
	 cout << "Next: " << endl;
	 printCell(current->next());
	 cout << endl;
      }
      
      if(current->hasPrevious())
      {
	 cout << "Previous: " << endl;
	 printCell(current->previous());
	 cout << endl;
      }
      
      if(current->hasParentCell())
      {
	 cout << "Parent: " << endl;
	 printCell(current->parentCell());
	 cout << endl;
      }
      
      if(current->hasChilds())
      {
	 cout << "Child: " << endl;
	 printCell(current->child());
	 cout << endl;
      }
   }

//    void Cell::retain()
//    {
//       references_ += 1;
//    }
   
//    void Cell::release()
//    {
//       references_ -= 1;
//    }
} 
