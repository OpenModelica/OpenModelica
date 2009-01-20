/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */

/*!
 * \file cellgroup.h
 * \author Ingemar Axelsson and Anders Fernström
 *
 */


//STD Headers
#include <iostream>
#include <exception>
#include <stdexcept>

//QT Headers
#include <QtGui/QTextEdit>

//IAEX Headers
#include "cellgroup.h"


namespace IAEX{

	/*!
	 * \class CellGroup
	 * \author Ingemar Axelsson and Anders Fernström
	 *
	 *  \brief CellGroup implements the functionality to
	 *  be a Cell and contain a lot of subcells.
	 *
	 *
	 * \todo Reimplement as a composite instead. That is much much
	 * cleaner. Also look at CellWorkspace and rename CellContainer to
	 * CellDocument. CellWorkspace should dissappear.(Ingemar Axelsson)
	 *
	 * \todo Analyse class and find out what is different from the
	 * Cell class. Is it possible that cell and cellgroup should be
	 * integrated as one class?
	 * It should be easy to convert from a cell to a cellgroup. (Ingemar Axelsson)
	 */


	/*!
	 * \author Ingemar Axelsson
	 *
	 * \brief The class constructor
	 */
	CellGroup::CellGroup(QWidget *parent)
		: Cell(parent),
		closed_(false),
		newIndex_(0)
	{
		main_ = new QWidget(this);

		layout_ = new QGridLayout(main_);
		layout_->setMargin(0);
		layout_->setSpacing(0);

		setMainWidget(main_);

		mainWidget()->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
		setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);

		style_.setName( "cellgroup" );


	}

	/*!
	 * \author Ingemar Axelsson
	 *
	 * \brief The class destructor
	 */
	CellGroup::~CellGroup()
	{
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-10-28 (update)
	 *
	 * \brief Set the cells style. If the cell is closed, set style
	 * on the first child (the cell thats displayed).
	 *
	 * 2005-10-28, changes style from QString to CellStyle /AF
	 *
	 * \param style The cell style that is to be applyed to the cell
	 */
	void CellGroup::setStyle(CellStyle style)
	{
		if(closed_)
			child()->setStyle(style);
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-10-28 (update)
	 *
	 * \brief Return the cells style. If the cell is closed, style
	 * is returned from the first child (the cell thats displayed).
	 * If the cell is opened this function returns a new CellStyle
	 * with the name 'cellgroup';
	 *
	 * 2005-10-28, changes style from QString to CellStyle /AF
	 *
	 * \return The cells style
	 */
	CellStyle *CellGroup::style()
	{
		if(closed_)
			return child()->style();
		else
		{
			return &style_;
		}
	}

	/*!
	 * \author Anders Fernström
	 * \date 2005-11-30
	 *
	 * \brief hide() or show() the child cells of the groupcell,
	 * depending on the state of the groupcell (opened or closed).
	 * This must be done because otherwise qt layout will compress
	 * all child and display them in the smaller height set went the
	 * groupcell is closed.
	 */
	void CellGroup::closeChildCells()
	{
		if( closed_ )
		{
			Cell *current = child();
			if( current != 0 )
			{
				current = current->next();
				while(current != 0)
				{
					current->hide();
					current = current->next();
				}
			}
		}
		else
		{
			Cell *current = child();
			if( current != 0 )
			{
				current = current->next();
				while(current != 0)
				{
					current->show();
					current = current->next();
				}
			}
		}
	}

	/*!
	 * \author Ingemar Axelsson
	 */
	bool CellGroup::isClosed() const
	{
		return closed_;
	}

	/*!
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Function for telling if the user is allowed to change
	 * the text settings for the text inside the cell. User isn't
	 * allowed to change the text settings for cellgroups so this
	 * function always return false.
	 *
	 * \return False
	 */
	bool CellGroup::isEditable()
	{
		return false;
	}

	/*!
	 * \author Anders Fernström
	 * \date 2005-08-24
	 *
	 * \brief Returns the first childs text editor, if the cell is closed. If
	 * the cell isn't closed, return 0.
	 *
	 * \return False
	 */
	QTextEdit* CellGroup::textEdit()
	{
		if( isClosed() && hasChilds() )
			return child()->textEdit();
		else
			return 0;
	}

	/*!
	 * \author Ingemar Axelsson
	 *
	 * \brief This function hides/shows the content of a groupcell.
	 *
	 * This member hides/shows the content of a cellgroup. The height of
	 * the cellgroup is calculated depending on wich case it is.
	 *
	 * \param closed tells if the cells should be visible or hidden.
	 *
	 *
	 * \todo Add some signals when this happens. It can be possible that
	 * someone will do some fun stuff when a cell is closing.(Ingemar Axelsson)
	 *
	 * \todo reimplement with removing and adding to the layout instead.(Ingemar Axelsson)
	 *
	 *
	 * \bug This function could create a segmentation fault in some
	 * special cases. Try to find them.
	 */
	void CellGroup::setClosed(const bool closed, bool update)
	{
		closed_ = closed;

		if( hasChilds() )
			child()->hideTreeView( closed );

		treeView()->setClosed( closed );
		setHeight( height() ); //Sends a signal



		if( update )
			emit cellOpened(this, closed_);
	}

	/*!
	 * \author Ingemar Axelsson
	 *
	 * \brief calculates the height of the cellgroup.
	 *
	 * Calculates the height of the cellgroup. The calculated height
	 * depends on the state of the group. Is the group closed then the
	 * height is just the first cell otherwise the height is a sum of
	 * the height of all cells.
	 *
	 * \returns height of cellgroup.
	 *
	 *
	 * \bug HeightVisitor does not return correct height value. I do
	 * not know why, so I implemented another way to traverse subcells
	 * and asking for heights.
	 */
	int CellGroup::height()
	{
		int height = 0;

		if( closed_ )
		{
			//Height of the first cell.
			height = child()->height();
		}
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

	/*!
	 * \author Ingemar Axelsson (and Anders Fernström)
	 * \date 2005-11-30 (update)
	 *
	 * \brief open and close the groupcell when double click on the
	 * treeview
	 *
	 * 2005-11-30 AF, added the call to 'closeChildCells()'
	 *
	 * \todo Should this be moved to treeview?(Ingemar Axelsson)
	 */
	void CellGroup::mouseDoubleClickEvent(QMouseEvent *event)
	{
		// PORT >>if(treeView()->hasMouse())
		if( treeView()->testAttribute(Qt::WA_UnderMouse) )
		{
			closed_ = !closed_;
			setClosed(closed_);
			setSelected(false);
			closeChildCells();
		}
		else
		{
			//Do nothing.
		}
	}

	/*!
	 * \author Ingemar Axelsson
	 */
	void CellGroup::adjustHeight()
	{
		setHeight( height() );
	}

	// ***************************************************************

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
	* important.(Ingemar Axelsson)
	*
	* \todo Implement an Iterator for the cell structure. This could be
	* nice.(Ingemar Axelsson)
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
	dependency should only be in the cursor then.(Ingemar Axelsson)
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
		// PORT >> newCell->reparent(mainWidget(), QPoint(0,0), true);
		newCell->setParent( mainWidget() );
		newCell->move( QPoint(0,0) );
		newCell->show();

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
			// PORT >> layout_->remove(current);
			layout_->removeWidget(current);

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
				// PORT >> current->reparent(mainWidget(), QPoint(0,0), true);
				current->setParent( mainWidget() );
				current->move( QPoint(0,0) );
				current->show();

				connect(current, SIGNAL(heightChanged()),
					this, SLOT(adjustHeight()));
			}

			layout_->addWidget(current,i,0);
			++i;
			current = current->next();
		}

		adjustHeight();
	}


}
