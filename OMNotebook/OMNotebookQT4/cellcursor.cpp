#define QT_NO_DEBUG_OUTPUT
/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet,
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

/*!
 * \file cellcursor.h
 * \author Ingemar Axelsson (and Anders Fenström)
 *
 * \brief Implementation of a marker made as an Cell.
 */

//STD Headers
#include <exception>
#include <stdexcept>

//Qt Headers
#include <QtGui/QApplication>
#include <QtGui/QLabel>
#include <QtGui/QPaintEvent>

//IAEX Headers
#include "cellcursor.h"
#include "visitor.h"


namespace IAEX
{

	/*!
	 * \class CellCursor
	 *
	 * \brief Implements a special type of cell that
	 * is used as a cursor within the document.
	 *
	 * The cellcursor class acts like a ordinary cell. It extends a
	 * cell with the functionality to move around in the celltree. See
	 * moveUp and moveDown members.
	 *
	 * This class should be inherited with a lot of precaution. It has
	 * a lot of responsibility and dependency within the
	 * application. So change it with caution.
	 *
	 * To change the cursors look reimplement the CursorWidget to have
	 * the desired look.
	 *
	 */


	/*!
	 * \author Ingemar Axelsson
	 *
	 * \brief The class constructor
	 */
	CellCursor::CellCursor(QWidget *parent)
		: Cell(parent),
		clickedOn_( false )
	{
		setHeight(3);
		QWidget *content = new CursorWidget(this);

		setMainWidget(content);
		hideTreeView(true);
		// PORT >> setBackgroundMode(Qt::PaletteBase);
		setBackgroundRole( QPalette::Base );
		setBackgroundColor(QColor(100,100,100));

		// 2006-04-27 AF, set cursor shape for cell cursor
		QCursor mousecursor = cursor();
		mousecursor.setShape( Qt::SizeHorCursor );
		setCursor( mousecursor );
	}

	/*!
	 * \author Ingemar Axelsson
	 *
	 * \brief The class destructor
	 */
	CellCursor::~CellCursor()
	{

	}

	/*!
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Function for telling if the user is allowed to change
	 * the text settings for the text inside the cell. User isn't
	 * allowed to change the text settings for cellcursor so this
	 * function always return false.
	 *
	 * \return False
	 */
	bool CellCursor::isEditable()
	{
		return false;
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-04-27
	 *
	 * \brief Return state of the clickedOn_ property.
	 */
	bool CellCursor::isClickedOn()
	{
		return clickedOn_;
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-04-27
	 *
	 * \brief Reimplemenation of the mousePressEvent function
	 */
	void CellCursor::mousePressEvent(QMouseEvent *event)
	{
		clickedOn_ = true;
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-04-27
	 *
	 * \brief Function that should be called everytime the cursor
	 * is about to be moved.
	 */
	void CellCursor::cursorIsMoved()
	{
		clickedOn_ = false;
	}


	// ***************************************************************



	/*!
	* \bug This does not work correctly.
	*/
	void CellCursor::accept(Visitor &v)
	{
		//Does not have any childs!
		v.visitCellCursorNodeBefore(this);
		v.visitCellCursorNodeAfter(this);

		if(hasNext())
			next()->accept(v);
	}


	void CellCursor::addBefore(Cell *newCell)
	{
		// 2006-04-27 AF,
		cursorIsMoved();

		if(parentCell()->child() == this)
		{ //first in line.
			newCell->setParentCell(parentCell());
			newCell->setNext(this);
			newCell->setPrevious(0);
			parentCell()->setChild(newCell);
			setPrevious(newCell);
		}
		else
		{
			newCell->setParentCell(parentCell());
			newCell->setPrevious(previous());
			previous()->setNext(newCell);
			setPrevious(newCell);
			newCell->setNext(this);
		}

		parentCell()->addCellWidget(newCell);

		// TMP EMIT
		emit changedPosition();
	}

	/*! \brief Replaces current cell with a new cell.
	*
	* \todo create a cellcopy operation.
	* \todo test!
	*
	*/
	void CellCursor::replaceCurrentWith(Cell *newCell)
	{
		//       newCell->setParent(currentCell()->parentCell());
		//       newCell->setChild(currentCell()->child());
		//       newCell->setLast(currentCell()->last());
		//       newCell->setPrevious(currentCell()->previous());
		//       newCell->setNext(currentCell()->next());
		qDebug("replaceWithCurrent");

		newCell->setText(currentCell()->text());

		//Replace cell.
		deleteCurrentCell();
		addBefore(newCell);
		qDebug("End replaceWithCurrent");
	}

	void CellCursor::removeFromCurrentPosition()
	{
		//remove all widgets from parents layout.
		Cell *par = parentCell();
		par->removeCellWidgets();

		if(parentCell()->child() == this)
			parentCell()->setChild(next());

		if(parentCell()->last() == this)
			parentCell()->setLast(previous());

		if(hasNext())
			next()->setPrevious(previous());

		if(hasPrevious())
			previous()->setNext(next());

		//Insert all widgets again.
		par->addCellWidgets();
	}

	/*!
	* Removes a cell and all its subcells from the tree.
	*
	* This should work for all cells. But it will leave an empty
	* cellgroup if last cell is deleted in cellgroup.
	*
	* This does not delete the cell, it just removes the cell from the
	* celltree.
	*/
	void CellCursor::removeCurrentCell()
	{
		if(hasPrevious()) //If cursor has previous
		{
			// 2006-04-27 AF,
			cursorIsMoved();

			Cell *current = previous();

			removeFromCurrentPosition();

			if(current->hasPrevious())
				current->previous()->setNext(this);
			else
				parentCell()->setChild(this);

			setPrevious(current->previous());

			current->setParentCell(0);
			current->setPrevious(0);
			current->setNext(0);
			current->setChild(0);
			current->setLast(0);

			current->hide();
			parentCell()->addCellWidgets();
		}
	}

	/*! \bug Segfault in cellgroups. Probably a parent, child or last.
	* \bug Deletion of last cell in cellgroup should be taken care of.
	*/
	void CellCursor::deleteCurrentCell()
	{
		if(hasPrevious()) //If cursor has previous
		{
			// 2006-04-27 AF,
			cursorIsMoved();

			//removeCurrentCell();

			//OLD CODE
			//Remove currentCell.
			Cell *current = previous(); //Save a pointer to the cell being deleted.

			removeCurrentCell();
			// removeFromCurrentPosition();

			// 	 if(current->hasPrevious())
			// 	    current->previous()->setNext(this);
			// 	 else
			// 	    parentCell()->setChild(this);

			// 	 setPrevious(current->previous());

			// 	 current->setParentCell(0);
			// 	 current->setPrevious(0);
			// 	 current->setNext(0);
			// 	 current->setChild(0);
			// 	 current->setLast(0);

			//Segfault on delete.
			delete current;

			//parentCell()->addCellWidgets();
		}
		// TMP EMIT
		emit changedPosition();
	}

	/*! Returns current cell.
	*/
	Cell *CellCursor::currentCell()
	{
		if(!hasPrevious()) //First in group.
			return parentCell(); //Will always work.
		else
			return previous();
	}

	// 2006-08-24 AF, changed so the function returns a boolean value, true if
	// the cursor is moved.
	bool CellCursor::moveUp()
	{
		// 2006-08-24 AF,
        bool moved( false );

		// 2006-04-27 AF,
		cursorIsMoved();

		if( !hasPrevious() )
		{
			if( parentCell()->hasParentCell() )
			{
				moveBefore( parentCell() );
				moved = true;
			}
		}
		else
		{
			//previous() exists.
			if(previous()->hasChilds())
			{
				if(!previous()->isClosed())
				{
					moveToLastChild(previous());
					moved = true;
				}
				else
				{
					moveBefore(previous());
					moved = true;
				}
			}
			else
			{
				moveBefore(previous());
				moved = true;
			}
		}
		emit positionChanged(x(), y(), 5,5);

		// TMP EMIT
		emit changedPosition();
		return moved;
	}

	/*!
	* \bug Segmentationfault when last cell.
	*
	* \todo It is better that Commands take care of how to change
	* state of cells.(Ingemar Axelsson)
	*
	* 2006-08-24 AF, changed so the function returns a boolean value, true if
	* the cursor is moved.
	*/
	bool CellCursor::moveDown()
	{
		// 2006-08-24 AF,
        bool moved( false );

		// 2006-04-27 AF,
		cursorIsMoved();

		if( !hasNext() )
		{
			if( parentCell()->hasParentCell() )
			{
				moveAfter( parentCell() );
				moved = true;
			}
		}
		else //Has next.
		{
			if(next()->hasChilds())
			{
				if(!next()->isClosed())
				{
					moveToFirstChild(next());
					moved = true;
				}
				else
				{
					moveAfter(next());
					moved = true;
				}
			}
			else
			{
				moveAfter(next());
				moved = true;
			}
		}
		// TMP EMIT
		emit changedPosition();
		emit positionChanged(x(), y(), 5,5);
		return moved;
	}

	/*! Insert this cell as first child of parent.
	*
	* \bug This does not seem to work correctly.
	*/
	void CellCursor::moveToFirstChild(Cell *parent)
	{
		// 2006-04-27 AF,
		cursorIsMoved();

		if(parent->hasChilds())
		{
			parent->removeCellWidgets();
			moveBefore(parent->child());
			parent->addCellWidgets();
		}
		else //No child.
		{
			//Become first child.
			parent->removeCellWidgets();
			parent->setChild(this);
			parent->setLast(this);
			parent->addCellWidgets();
		}

		// TMP EMIT
		emit changedPosition();
	}

	/*!
	* \bug This does not seem to work correctly.
	*/
	void CellCursor::moveToLastChild(Cell *parent)
	{
		// 2006-04-27 AF,
		cursorIsMoved();

		if(parent->hasChilds())
		{
			parent->removeCellWidgets();
			moveAfter(parent->last());
			parent->addCellWidgets();
		}
		else
		{
			throw runtime_error("LAST CHILD: Tried to move to a child that did not exist.");
		}

		// TMP EMIT
		emit changedPosition();
	}

	/*!
	* \bug Fel vid flytt så cursor hamnar som sista barn.
	*/
	void CellCursor::moveAfter(Cell *current)
	{
		// 2006-04-27 AF,
		cursorIsMoved();

		removeFromCurrentPosition();

		//if(!current->hasParentCell())
		//  throw runtime_error("Could not insert after root");

		if(current->hasParentCell())
		{
			current->parentCell()->removeCellWidgets();

			if(current->hasNext() == 0)
			{
				current->parentCell()->setLast(this);
			}
			else
				current->next()->setPrevious(this);

			setParentCell(current->parentCell());
			setNext(current->next());
			current->setNext(this);
			setPrevious(current);

			//insert widgets to parents layout.
			parentCell()->addCellWidgets();
		}
		else
		{
			//If current does not have a parent. That is current is not
			//in the celltree at all or that current is the root of the
			//tree. It should not be possible to move after the root of
			//the tree. Do nothing!
		}

		// TMP EMIT
		emit changedPosition();
		//      emit positionChanged(x(), y(), 5,5);
	}


	/*
	* \bug fel  om vi flyttas till att vara första barn..
	*/
	void CellCursor::moveBefore(Cell *current)
	{
		// 2006-04-27 AF,
		cursorIsMoved();

		removeFromCurrentPosition();

		//Remove all widgets from currents parent.
		current->parentCell()->removeCellWidgets();

		//Move to new position.
		if(current->hasParentCell())
		{
			setParentCell(current->parentCell());
			if(!current->hasPrevious())
				current->parentCell()->setChild(this);
			else
				current->previous()->setNext(this);

		}
		else
			throw runtime_error("Could not insert before root");

		setPrevious(current->previous());
		current->setPrevious(this);
		setNext(current);

		//Insert widgets to parents layout.
		parentCell()->addCellWidgets();

		// TMP EMIT
		emit changedPosition();
		//      emit positionChanged(x(), y(), 5, 5);
	}


	/*! \class CursorWidget
	*
	* \brief CursorWidget describes how the cursor should be painted.
	*/
	void CursorWidget::paintEvent(QPaintEvent *event)
	{
		QPainter painter(this);

		QPalette palette;
		palette.setColor(this->backgroundRole(), QColor(0,0,0));
		this->setPalette(palette);

		// changed from 1 to 3, don\t know way, but something must have
		// changed between qt 4 and qt 4.1
		painter.setPen(QPen(black,3, SolidLine));



		painter.drawRect(0, 0, width(), height());
		QWidget::paintEvent(event);
	}
}
