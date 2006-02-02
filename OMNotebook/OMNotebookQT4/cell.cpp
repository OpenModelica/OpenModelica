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

//QT Headers
#include <QtGui/QGridLayout>
#include <QtGui/QLabel>
#include <QtGui/QMessageBox>
#include <QtGui/QMouseEvent>
#include <QtGui/QResizeEvent>
#include <QtGui/QTextCursor>

//IAEX Headers
#include "cell.h"
#include "stylesheet.h"


using namespace IAEX;
using namespace std;

namespace IAEX
{

	/*! 
	 * \class Cell
	 * \author Ingemar Axelsson and Anders Ferström
	 *
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
	 *
	 * \todo Implement a widgetstack for the treeview. This to make it
	 * possible to implement other treeview structures. (Ingemar Axelsson)
	 */


	/*! 
	 * \author Ingemar Axelsson
	 *
	 * \brief The class constructor
	 */
	Cell::Cell(QWidget *parent)
		: QWidget(parent),
		selected_(false),
		treeviewVisible_(true),
		viewexpression_(false),
		backgroundColor_(QColor(255,255,255)),
		parent_(0),
		next_(0),
		last_(0),
		previous_(0),
		child_(0),
		references_(0)      
	{
		setMouseTracking(true);
		setEnabled(true);

		mainlayout_ = new QGridLayout(this);
		mainlayout_->setMargin(0);
		mainlayout_->setSpacing(0);

		setLayout( mainlayout_ );//AF
		setLabel(new QLabel(this));

		setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed));
		// PORT >> setBackgroundMode(Qt::PaletteBase);
		setBackgroundRole( QPalette::Base );
		setTreeWidget(new TreeView(this));

		QPalette palette;
		palette.setColor(backgroundRole(), backgroundColor());
		setPalette(palette);
	}

	Cell::Cell(Cell &c) : QWidget()
	{
		setMouseTracking(true);

		mainlayout_ = new QGridLayout(this);
		mainlayout_->setMargin(0);
		mainlayout_->setSpacing(0);

		setLabel(new QLabel(this));

		setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed));
		// PORT >> setBackgroundMode(Qt::PaletteBase);
		setBackgroundRole( QPalette::Base );
		setTreeWidget(new TreeView(this));
		setStyle( c.style() ); // Added 2005-10-27 AF


		QPalette palette;
		palette.setColor(c.backgroundRole(), c.backgroundColor());
		setPalette(palette);
	}

	/*! 
	 * \author Ingemar Axelsson
	 *
	 * \brief The class destructor
	 */
	Cell::~Cell()
	{
		//Delete if there are no references to this cell.
		if(references_ <= 0)
		{
			setMouseTracking(false);

			delete treeView_;
			delete mainWidget_;
			delete label_;
		}
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Set cell style
	 *
	 * \param stylename The style name of the style that is to be applyed to the cell
	 */
	void Cell::setStyle(const QString &stylename)
	{
		Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
		CellStyle style = sheet->getStyle( stylename );

		if( style.name() != "null" )
			setStyle( style );
		else
		{
			QString msg = "Cant set style, style name is not valid";
			QMessageBox::warning( 0, "Warning", msg, "OK" );
		}
	}

	/*!
	* \author Anders Fernström
	* \date 2005-10-27
	*
	* \brief Set the current cell style.
	*
	* \param style The cell style that is to be applyed to the cell
	*/
	void Cell::setStyle(CellStyle style)
	{
		style_ = style;
		applyRulesToStyle();
	}

	/*!
	* \author Anders Fernström
	* \date 2005-10-27
	*
	* \brief Get the current cell style.
	*
	* \return current cell style
	*/
	CellStyle Cell::style()
	{
		return style_;
	}

	/*!
	* \author Anders Fernström
	* \date 2006-01-16
	*
	* \brief Set cells tag name
	*/
	void Cell::setCellTag(QString tagname)
	{
		celltag_ = tagname;
	}

	/*!
	* \author Anders Fernström
	* \date 2006-01-16
	*
	* \brief Get the cell tag name
	*
	* \return cell tag name
	*/
	QString Cell::cellTag()
	{
		return celltag_;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-02
	 *
	 * \brief Function for telling if the function viewExpression is 
	 * activated or not. 
	 *
	 * \return boolean, that tells if the cell is set to view expression
	 */
	const bool Cell::isViewExpression() const
	{
		return viewexpression_;
	}

	/*! 
	 * \author Ingemar Axelsson
	 *
	 * \brief Adds a rule to the cell 
	 *
	 * \param r The rule that will be added
	 *
	 *
	 * \todo Implement functionality for 'InitializationCell':
	 * inputcells should be evaled from the start if the value is true.
	 * (Anders Fernström)
	 */
	void Cell::addRule(Rule *r)
	{
		// TODO: DEBUG code: Remove when doing release,
		// just a check to find new rules
		/*
		QRegExp expression( "InitializationCell|CellTags|FontSlant|TextAlignment|TextJustification|FontSize|FontWeight|FontFamily|PageWidth" );
		if( 0 > r->attribute().indexOf( expression ))
		{
			cout << "[NEW] Rule <" << r->attribute().toStdString() << "> <" << r->value().toStdString() << ">" << endl;
		}
		else
		{	
			if( r->attribute() == "FontSlant" )
			{
				QRegExp fontslant( "Italic" );
				if( 0 > r->value().indexOf( fontslant ))
					cout << "[NEW] Rule Value <FontSlant>, VALUE: " << r->value().toStdString() << endl;
			}
			else if( r->attribute() == "TextAlignment" )
			{
				QRegExp textalignment( "Right|Left|Center" );
				if( 0 > r->value().indexOf( textalignment ))
					cout << "[NEW] Rule Value <TextAlignment>, VALUE: " << r->value().toStdString() << endl;
			}
			else if( r->attribute() == "TextJustification" )
			{
				QRegExp textjustification( "1|0" );
				if( 0 > r->value().indexOf( textjustification ))
					cout << "[NEW] Rule Value <TextJustification>, VALUE: " << r->value().toStdString() << endl;
			}
			else if( r->attribute() == "FontWeight" )
			{
				QRegExp fontweight( "Bold|Plain" );
				if( 0 > r->value().indexOf( fontweight ))
					cout << "[NEW] Rule Value <FontWeight>, VALUE: " << r->value().toStdString() << endl;
			}
		}
		*/



		// *** THE REAL FUNCTION ***
		rules_.push_back(r);
	}


	/*!
	 * \author Anders Fernström
	 * \date 2005-10-27
	 *
	 * \brief Apply any rules to the current cellstyle
	 *
	 * \todo Implement functionality for 'TextJustification'.
	 */
	void Cell::applyRulesToStyle()
	{
		rules_t::iterator current = rules_.begin();
		while( current != rules_.end() )
		{
			if( (*current)->attribute() == "FontSlant" )
			{
				if( (*current)->value() == "Italic" )
					style_.textCharFormat()->setFontItalic( true );
			}
			else if( (*current)->attribute() == "TextAlignment" )
			{
				if( (*current)->value() == "Left" )
					style_.setAlignment( Qt::AlignLeft );
				else if( (*current)->value() == "Right" )
					style_.setAlignment( Qt::AlignRight );
				else if( (*current)->value() == "Center" )
					style_.setAlignment( Qt::AlignCenter );
			}
			else if( (*current)->attribute() == "TextJustification" )
			{
				//values: 1,0
			}
			else if( (*current)->attribute() == "FontSize" )
			{
				bool ok;
				int size = (*current)->value().toInt(&ok);
					
				if(ok)
				{
					if( size > 0 )
						style_.textCharFormat()->setFontPointSize( size );
				}
			}
			else if( (*current)->attribute() == "FontWeight" )
			{
				if( (*current)->value() == "Bold" )
					style_.textCharFormat()->setFontWeight( QFont::Bold );
				if( (*current)->value() == "Plain" )
					style_.textCharFormat()->setFontWeight( QFont::Normal );
			}
			else if( (*current)->attribute() == "FontFamily" )
			{
				style_.textCharFormat()->setFontFamily( (*current)->value() );
			}
			else if( (*current)->attribute() == "InitializationCell" )
			{}
			else if( (*current)->attribute() == "CellTags" )
			{
				celltag_ = (*current)->value();
			}

			++current;
		}
	}

	/*!
	 * \author Anders Fernström
	 * \date 2005-10-27
	 *
	 * \brief return the cells text cursor. if the cell don't have
	 * a cursor that have been created by the default constructor and
	 * is a null cursor.
	 *
	 * \return The cells text cursor
	 */
	QTextCursor Cell::textCursor()
	{
		QTextCursor cursor;
		return cursor;
	}
	
	void Cell::wheelEvent(QWheelEvent * event)
	{
		// ignore event and send it up in the event hierarchy
		event->ignore();

		if( parentCell() )
		{
			parentCell()->wheelEvent( event );
		}
		else
		{
			// if no parent cell -> top cell
			parent()->event( event );
		}
	}












	// ***************************************************************






	/*! \brief Set the cells mainwidget.
	*
	* \todo Delete old widget. (Ingemar Axelsson)
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
			
			QPalette palette;
			palette.setColor(mainWidget_->backgroundRole(), backgroundColor());
			mainWidget_->setPalette(palette);
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

		QPalette palette;
		palette.setColor(label_->backgroundRole(), backgroundColor());
		label_->setPalette(palette);

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
		treeView_->setFocusPolicy(Qt::NoFocus);
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
	* should be resized.(Ingemar Axelsson)
	*
	*\todo test if repaint is needed here. (Ingemar Axelsson)
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
		//! widgets larger than 32767. (qt limitation)
		/*if(height > 32000)
		{
			h = 32000;
		}*/

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
		// PORT >> if(treeView_->hasMouse())
		if(treeView_->testAttribute(Qt::WA_UnderMouse))
		{
			this->setSelected(!isSelected());
			emit cellselected(this, event->modifiers());
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
	* \todo Needs a cursor->moveBefore member. (Ingemar Axelsson)
	*/
	void Cell::mouseMoveEvent(QMouseEvent *event)
	{
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
	* treeview decide? Probably better if the cell decides. (Ingemar Axelsson)
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

		QPalette palette;
		palette.setColor(backgroundRole(), color);
		setPalette(palette);
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
		//setParent( parent );
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
		printCell(current);

		//Print surroundings
		if(current->hasNext())
		{
			printCell(current->next());
		}

		if(current->hasPrevious())
		{
			printCell(current->previous());
		}

		if(current->hasParentCell())
		{
			printCell(current->parentCell());
		}

		if(current->hasChilds())
		{
			printCell(current->child());
		}
	}

	//    void Cell::retain(s)
	//    {
	//       references_ += 1;
	//    }

	//    void Cell::release()
	//    {
	//       references_ -= 1;
	//    }
} 
