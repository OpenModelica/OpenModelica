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
 * \file textcell.h
 * \author Ingemar Axelsson and Anders Fernström
 * \date 2005-02-08
 *
 * \brief Describes a textcell.
 */


//STD Headers
#include <iostream>
#include <exception>
#include <stdexcept>

//QT Headers
#include <QtCore/QString>
#include <QtGui/QAbstractTextDocumentLayout>
#include <QtGui/QBrush>
#include <QtGui/QApplication>
#include <QtGui/QStatusBar>
#include <QtGui/QFrame>
#include <QtGui/QTextDocumentFragment>
#include <QtGui/QTextFrame>
#include <QtGui/QResizeEvent>

//IAEX Headers
#include "textcell.h"
//#include "stylesheet.h"


namespace IAEX
{
	/*! 
	 * \class MyTextBrowser
	 * \author Ingemar Axelsson and Anders Fernström
	 *
	 * \brief extends QTextBrowser. Mostly so I can catch when a user
	 * clicks on a link without a change in textbrowsers content.
	 *
	 */
	MyTextBrowser::MyTextBrowser(QWidget *parent)
		: QTextBrowser(parent)
	{
	}

	MyTextBrowser::~MyTextBrowser()
	{
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernström
	 * date 2005-11-03
	 *
	 * 2005-11-03 AF, Updated the function to reflect the changes made
	 * in qt (from v3 to v4). The function now takes a QUrl as parameter
	 * insted of a QString (in qt3).
	 */
	void MyTextBrowser::setSource(const QUrl &name)
	{
		emit openLink( &name );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-01
	 *
	 * \brief Needed a signal to be emited when the user click on 
	 * the cell.
	 */
	void MyTextBrowser::mousePressEvent(QMouseEvent *event)
	{
		QTextBrowser::mousePressEvent(event);
		emit clickOnCell();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-28
	 *
	 * \brief Handles mouse wheel events, ignore them and send the up
	 * in the cell hierarchy
	 */
	void MyTextBrowser::wheelEvent(QWheelEvent * event)
	{
		// ignore event and send it up in the event hierarchy
		event->ignore();
		emit wheelMove( event );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-01-23
	 *
	 * \brief If the mimedata that should be insertet contain text,
	 * create a new mimedata object that only contains text, otherwise
	 * html is inserted - don't want that html code (inserting from
	 * microsoft words for example).
	 */
	void MyTextBrowser::insertFromMimeData(const QMimeData *source)
	{
		if( source->hasText() && !source->hasImage() )
		{
			QMimeData *newSource = new QMimeData();
			newSource->setText( source->text() );
			QTextBrowser::insertFromMimeData( newSource );
			delete newSource;
		}
		else
			QTextBrowser::insertFromMimeData( source );
	}

/*! 
	 * \author Anders Fernström
	 * \date 2006-01-30
	 *
	 * \brief Handles key event, added ignore to 'Alt+Enter'
	 */
	void MyTextBrowser::keyPressEvent(QKeyEvent *event )
	{
		// ALT+ENTER (ignore)
		if( event->modifiers() == Qt::AltModifier &&
			( event->key() == Qt::Key_Enter || event->key() == Qt::Key_Return ))
		{
			event->ignore();
		}
		else
		{
			QTextBrowser::keyPressEvent( event );
		}

	}




	/*! 
	 * \class TextCell
	 * \author Ingemar Axelsson and Anders Fernström
	 *
	 * \brief A concrete cellclass using QTextEdit as mainwidget.
	 *
	 * TextCell is a class that fulfills the Cell interface. It has the
	 * behavior of both QTextEdit and Cell. It is used to display texts
	 * in a cell. It supports simple undo, redo, cut, copy, paste. The
	 * text can be edited if the setReadOnly flag is set to
	 * false. Otherwise text is just selectable. The later is the
	 * default.
	 *
	 * \todo Add members to fulfill the QTextEdit interface. This is
	 * very nice when it is needed.(Ingemar Axelsson)
	 *
	 * \bug Set so tab focuses on next cell.
	 */

	/*! 
	 * \author Ingemar Axelsson (and Anders Fernström)
	 * \date 2005-10-31 (update)
	 *
	 * \brief The class constructor
	 */
	TextCell::TextCell(QWidget *parent)
		: Cell(parent)
	{
		setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed));
		setFocusPolicy(Qt::NoFocus);
		createTextWidget();
	}

	TextCell::TextCell(TextCell &t)
		: Cell(t)
	{
		setText(t.text());
		setStyle(t.style());
	}

	/*! 
	 * \author Ingemar Axelsson
	 *
	 * \brief The class destructor
	 */
	TextCell::~TextCell()
	{
		setMainWidget(0);
		delete text_;
	}

	/*! 
	 * \author Anders Fernström and Ingemar Axelsson
	 * \date 2005-10-28 (update)
	 *
	 * \brief Creates the QTextBrowser for the text inside the 
	 * cell
	 *
	 * Large part of this function was changes due to porting
	 * to QT4 (changes from Q3TextBrowser to QTextBrowser). /AF
	 */
	void TextCell::createTextWidget()
	{
		text_ = new MyTextBrowser(this);
		setMainWidget(text_);

		text_->setReadOnly( true );
		text_->setUndoRedoEnabled( true );
		text_->setFrameStyle( QFrame::NoFrame );
		text_->setAutoFormatting( QTextEdit::AutoNone );

		text_->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed));
		text_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
		text_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
		text_->setContextMenuPolicy( Qt::NoContextMenu );

		connect( text_, SIGNAL( textChanged() ),
			this, SLOT( contentChanged() ));
		connect( text_, SIGNAL( openLink(const QUrl *) ),
			this, SLOT( openLinkInternal(const QUrl *) ));
		connect( text_, SIGNAL( clickOnCell() ),
			this, SLOT( clickEvent() ));
		connect( text_, SIGNAL( wheelMove(QWheelEvent*) ),
			this, SLOT( wheelEvent(QWheelEvent*) ));
		// 2006-01-17 AF, new...
		connect( text_, SIGNAL( currentCharFormatChanged(const QTextCharFormat &) ),
			this, SLOT( charFormatChanged(const QTextCharFormat &) ));
		connect( text_, SIGNAL( textChanged() ),
			this, SLOT( textChangedInternal() ));
		// 2006-02-10 AF, new...
		connect( text_, SIGNAL( highlighted(const QUrl &) ),
			this, SLOT( hoverOverLink(const QUrl &) ));
		
		contentChanged();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Returns the text (as plain text) from the mainarea.
	 *
	 * \returns The text inside the cell., as plain text
	 */
	QString TextCell::text()
	{
		return text_->toPlainText();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Return the text inside the cell as Html code
	 *
	 * \return Html code
	 */
	QString TextCell::textHtml()
	{
		return text_->toHtml();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Return the text cursor to the QTextBrowser that make up
	 * mainarea of the cell
	 *
	 * \return Text cursor to the cell
	 */
	QTextCursor TextCell::textCursor()
	{
		return text_->textCursor();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Return the text editor that make up the cell
	 *
	 * \return The text editor inside the cell
	 */
	QTextEdit* TextCell::textEdit()
	{
		return text_;
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-11-03 (update)
	 *
	 * \brief Sets the visible text.
	 *
	 * Sets the text that should be visible. Can change the 
	 * cellheight if the text is very long.
	 *
	 * 2005-11-02 AF, Ported the project to QT4, so I needed to add
	 * a check if the text is html code. If it's html code, just the
	 * correkt set function in QTextEdit.
	 * 2005-11-03 AF, Updated the html check
	 *
	 * \param text Text that should be visible inside the cell 
	 * mainarea.
	 */ 
	void TextCell::setText( QString text )
	{
		// check if the text contains html code, if so - set the 
		// text with correct function.
		QRegExp expression( "&nbsp;|<b>|<B>|</b>|</B>|<br>|<BR>|</a>|</A>|<sup>|<SUP>|</sup>|</SUP>|<sub>|<SUP>|</sub>|</SUB>|<span|<SPAN|</span>|</SPAN>" );
		QRegExp expressionTag( "<.*" );
		if( 0 <= text.indexOf( expression ))
		{
			// 2005-12-06 AF, ugly way to get the style, when inserting
			// text containg some html tags.
			text_->setPlainText( "TMP_OMNOTEBOOK" );
			setStyle( style() );
			QString html = text_->toHtml();
			int pos = html.indexOf( "TMP_OMNOTEBOOK", 0, Qt::CaseInsensitive );
			html.replace( pos, 14, text );
			text_->setHtml( html );
			text_->setAlignment( (Qt::AlignmentFlag)style_.alignment() );
			text_->document()->rootFrame()->setFrameFormat( (*style().textFrameFormat()) );
			
			//setTextHtml( text );
		}
		else if( 0 <= text.indexOf( expressionTag ))
		{
			qDebug( "Possible HTML tag in text:" );
			qDebug( text.toStdString().c_str() );

			text_->setPlainText( text );
			setStyle( style() );

			contentChanged();
		}
		else
		{
			text_->setPlainText( text );
			setStyle( style() );

			contentChanged();
		}

		text_->setUndoRedoEnabled( true );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Sets the visible text, given an specific text format.
	 *
	 * Sets the text that should be visible and uses the text format 
	 * that's sent to the function. Can change the cellheight if the 
	 * text is very long.
	 *
	 * \param text Text that should be visible inside the cell mainarea.
	 * \param format Text format that should be used on the text
	 */ 
	void TextCell::setText( QString text, QTextCharFormat format )
	{
		text_->setCurrentCharFormat( format );
		text_->setPlainText( text );    
		contentChanged();
		text_->setUndoRedoEnabled( true );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Sets the visible text using html code.
	 *
	 * Sets the text that should be visible using html code. Can change 
	 * the cellheight if the text is very long.
	 *
	 * \param html Html code that should be visible as normal text inside the cell mainarea.
	 */ 
	void TextCell::setTextHtml(QString html)
	{
		text_->setHtml( html );
		text_->document()->rootFrame()->setFrameFormat( (*style().textFrameFormat()) );

		contentChanged();
		text_->setUndoRedoEnabled( true );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Set cell style
	 *
	 * \param stylename The style name of the style that is to be applyed to the cell
	 */
	void TextCell::setStyle(const QString &stylename)
	{
		Cell::setStyle( stylename );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-28
	 * \date 2006-01-17 (update)
	 *
	 * \brief Set cell style
	 *
	 * \param style The cell style that is to be applyed to the cell
	 *
	 * 2005-11-03 AF, updated so the text is selected when the style
	 * is changed, after the text is unselected.
	 * 2005-11-15 AF, added trick to make sure that links are displayed
	 * correctly
	 * 2006-01-17 AF, removed trick to make sure the links are displaed
	 * correctly
	 *
	 * \todo right now all the text inside the cell is changed, when
	 * changing style. Text that have been changed from the cells 
	 * style (for example words made bold) should be uneffected by
	 * the change in cellstyle. Right now this function is used when
	 * the user sets text to change the hole text to the cellstyle. /AF
	 */
	void TextCell::setStyle(CellStyle style)
	{
		Cell::setStyle( style );

		// select all the text,
		// don't do it if the text contains an image, qt krasches if a 
		// cell contains starts with a image and the entier cell is 
		// selected.
		if( text_->toHtml().indexOf( "file:///", 0) < 0 )
			text_->selectAll();

		// set the new style settings
		text_->setAlignment( (Qt::AlignmentFlag)style_.alignment() );
		text_->mergeCurrentCharFormat( (*style_.textCharFormat()) );
		text_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );
		
		// unselect the text, reset cursor position
		QTextCursor cursor(	text_->textCursor() );
		cursor.clearSelection();
		text_->setTextCursor( cursor );

		// clear the undo/redo
		text_->setUndoRedoEnabled( false );
		text_->setUndoRedoEnabled( true );

		// ugly trick to make the sure that the links haven't change color
		//if( !text_->toPlainText().isEmpty() )
		//	text_->setHtml( text_->toHtml() );

	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-11-01 (update)
	 *
	 * \breif Set readonly value on the texteditor
	 *
	 * 2005-10-31 AF, removed the change in framstyle, looks better now
	 * 2005-11-01 AF, clear text selection when text edit is set to readonly
	 *
	 * \param readonly The boolean value of readonly property
	 */
	void TextCell::setReadOnly(const bool readonly)
	{
		if( readonly )
		{
			QTextCursor cursor = text_->textCursor();
			cursor.clearSelection();
			text_->setTextCursor( cursor );
		}

		text_->setReadOnly(readonly);

		/* Removed /AF
		if(readonly)
			text_->setFrameStyle(QFrame::NoFrame);
		else
			text_->setFrameStyle(QFrame::Panel|QFrame::Sunken);	 
		*/
	}

	/*!
	 * \author Ingemar Axelsson
	 */
	void TextCell::setFocus(const bool focus)
	{
		if(focus)
			text_->setFocus();
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernström
	 *
	 * \breif send a clicked signal if the user clicks on the cell
	 */
	void TextCell::clickEvent()
	{
		//if( text_->isReadOnly() )
			emit clicked(this);
	}

	/*!
	 * \author Anders Fernström and Ingemar Axelsson
	 * \date 2005-10-31 (update)
	 *
	 * \breif Recalculates height. 
	 *
	 * Large part of this function was changes due to porting
	 * to QT4 (changes from Q3TextBrowser to QTextBrowser). /AF
	 */
	void TextCell::contentChanged()
	{
		int height = text_->document()->documentLayout()->documentSize().toSize().height();

		//cout << "Height: " << height << endl;

		if( height < 0 )
			height = 30;

		text_->setMinimumHeight( height );
		
		// add a little extra, just in case /AF
		setHeight( height + 5 );		
		emit textChanged();
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-02-10
	 */
	void TextCell::hoverOverLink(const QUrl &link)
	{
		if( oldHoverLink_ != (link.path() + link.fragment()) )
		{
			oldHoverLink_ = link.path() + link.fragment();
			emit hoverOverUrl( link );
		}
	}

	/*! 
	 * \author Ingemar Axelsson
	 *
	 * \bug The link is removed if the sourcefile does not
	 * exists. This is strange.
	 */
	void TextCell::openLinkInternal(const QUrl *url)
	{
		emit openLink(url);
	}

	/*! 
	 * \author Anders Fernström
	 */
	void TextCell::textChangedInternal()
	{
		emit textChanged( true );
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-01-17
	 *
	 * \breif set the correct style if the charFormat is changed and the
	 * cell is empty. This is done because otherwise the style is lost if
	 * all text is removed inside a cell.
	 */
	void TextCell::charFormatChanged(const QTextCharFormat &)
	{
		if( text_->toPlainText().isEmpty() )
		{
			text_->blockSignals( true );
			text_->setAlignment( (Qt::AlignmentFlag)style().alignment() );
			text_->mergeCurrentCharFormat( (*style().textCharFormat()) );
			text_->document()->rootFrame()->setFrameFormat( (*style().textFrameFormat()) );
			text_->blockSignals( false );
			contentChanged();
		}
	}


	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Function for telling if the user is allowed to change 
	 * the text settings for the text inside the cell. User is
	 * allowed to change the text settings for textcell so this 
	 * function always return true.
	 *
	 * \return True
	 */
	bool TextCell::isEditable()
	{
		return true;
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-11-01 (update)
	 *
	 * \breif toggle between showing the html code in the cell and 
	 * normal plain text.
	 *
	 * 2005-11-01 AF, Remade the function to reflect the new
	 * QTextEdit
	 */
	void TextCell::viewExpression(const bool expr)
	{
		if( expr != isViewExpression() )
		{
			text_->blockSignals( true );

			if( expr )
			{
				viewexpression_ = true;
				text_->setCurrentCharFormat( *style().textCharFormat() );
				text_->setPlainText( text_->toHtml() );

				QPalette palette;
				palette.setColor( text_->backgroundRole(), 
					QColor( 180, 180, 180 ) );
				text_->setPalette(palette);
			}
			else
			{
				viewexpression_ = false;
				text_->setHtml( text_->toPlainText() );
				text_->document()->rootFrame()->setFrameFormat( (*style().textFrameFormat()) );

				QPalette palette;
				palette.setColor( text_->backgroundRole(), 
					backgroundColor() );
				text_->setPalette(palette);
			}

			text_->blockSignals( false );
			contentChanged();
		}
	}


	// ***************************************************************


    



	

	void TextCell::accept(Visitor &v)
	{
		v.visitTextCellNodeBefore(this);

		if(hasChilds())
		{
			child()->accept(v);
		}
		v.visitTextCellNodeAfter(this);    

		//Move along.
		if(hasNext())
			next()->accept(v);    
	}

	/*!
	* Resize textcell when the mainwindow is resized. This because the
	* cellcontent should always be visible.
	*/
	void TextCell::resizeEvent(QResizeEvent *event)
	{
		contentChanged(); 
		Cell::resizeEvent(event);
	}

	void TextCell::clear()
	{
		text_->clear();
	}






}
