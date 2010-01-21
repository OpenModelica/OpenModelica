#define QT_NO_DEBUG_OUTPUT
/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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
#include <QtGui/QLabel>
#include <QtGui/QTextDocumentFragment>
#include <QtGui/QTextFrame>
#include <QtGui/QResizeEvent>
#include <QMessageBox>
#include <QVariant>

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


		if( event->modifiers() == Qt::ShiftModifier || textCursor().hasSelection() )
		{
			return; //fjass3
		}

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
		// PAGE UP (ignore)
		else if( event->key() == Qt::Key_PageUp )
		{
			event->ignore();
		}
		// PAGE DOWN (ignore)
		else if( event->key() == Qt::Key_PageDown )
		{
			event->ignore();
		}
		// CTRL+C
		else if( event->modifiers() == Qt::ControlModifier &&
			event->key() == Qt::Key_C )
		{
			event->ignore();
			emit forwardAction( 1 );
		}
		// CTRL+X
		else if( event->modifiers() == Qt::ControlModifier &&
			event->key() == Qt::Key_X )
		{
			event->ignore();
			emit forwardAction( 2 );
		}
		// CTRL+V
		else if( event->modifiers() == Qt::ControlModifier &&
			event->key() == Qt::Key_V )
		{
			event->ignore();
			emit forwardAction( 3 );
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
		: Cell(parent),
		oldHeight_( 0 )
	{
		setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed));
		setFocusPolicy(Qt::NoFocus);
		createTextWidget();
	}

	TextCell::TextCell(TextCell &t)
		: Cell(t)
	{
		setText(t.text());
		setStyle(*t.style());
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
	 * \date 2006-03-02 (update)
	 *
	 * \brief Creates the QTextBrowser for the text inside the
	 * cell
	 *
	 * Large part of this function was changes due to porting
	 * to QT4 (changes from Q3TextBrowser to QTextBrowser). /AF
	 *
	 * 2006-03-02 AF, Added call to createChapterCounter();
	 */
	void TextCell::createTextWidget()
	{
		text_ = new MyTextBrowser(this);
		setMainWidget(text_);

		// 2006-03-02 AF, Add a chapter counter
		createChapterCounter();

		text_->setReadOnly( true );
		text_->setUndoRedoEnabled( true );
		text_->setFrameStyle( QFrame::NoFrame );
		text_->setAutoFormatting( QTextEdit::AutoNone );


		text_->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed));
		text_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
		text_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
//		text_->setContextMenuPolicy( Qt::NoContextMenu ); //fjass



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
		// 2006-04-27 AF,
		connect( text_, SIGNAL( forwardAction(int) ),
			this, SIGNAL( forwardAction(int) ));


//		connect(text_, SIGNAL(anchorClicked(const QUrl&)), this, SLOT(openLinkIternal(const QUrl&)));
		contentChanged();
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-03-02
	 *
	 * \brief Creates the chapter counter
	 */
	void TextCell::createChapterCounter()
	{
		chaptercounter_ = new MyTextBrowser(this);
		chaptercounter_->setFrameStyle( QFrame::NoFrame );
		chaptercounter_->setSizePolicy(QSizePolicy(QSizePolicy::Fixed, QSizePolicy::Expanding));
		chaptercounter_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
		chaptercounter_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
		chaptercounter_->setContextMenuPolicy( Qt::NoContextMenu );

		chaptercounter_->setFixedWidth(50);
		chaptercounter_->setReadOnly( true );

		connect( chaptercounter_, SIGNAL( clickOnCell() ),
			this, SLOT( clickEvent() ));

		addChapterCounter( chaptercounter_ );
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
			setStyle( *style() );
			QString html = text_->toHtml();
			int pos = html.indexOf( "TMP_OMNOTEBOOK", 0, Qt::CaseInsensitive );
			html.replace( pos, 14, text );
			text_->setHtml( html );
			text_->setAlignment( (Qt::AlignmentFlag)style_.alignment() );
			text_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );

			//setTextHtml( text );
		}
		else if( 0 <= text.indexOf( expressionTag ))
		{
			qDebug( "Possible HTML tag in text:" );
			qDebug( text.toStdString().c_str() );

			text_->setPlainText( text );
			setStyle( style_ );

			contentChanged();
		}
		else
		{
			text_->setPlainText( text );
			setStyle( style_ );

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
		text_->setAlignment( (Qt::AlignmentFlag)style_.alignment() );
		text_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );

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
	 * \date 2006-03-02 (update)
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
	 * 2006-03-02 AF, set chapter style
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
		// ignore this in version 4.1. of QT
		//if( text_->toHtml().indexOf( "file:///", 0) < 0 )


		text_->selectAll();

		// set the new style settings
		text_->mergeCurrentCharFormat( (*style_.textCharFormat()) );
		text_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );
		text_->setAlignment( (Qt::AlignmentFlag)style_.alignment() );

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

		// 2006-03-02 AF, set chapter counter style

		if(chaptercounter_->document()->isEmpty())
			chaptercounter_->document()->setPlainText(" "); //070606 This seems to eliminate the style bug..


		chaptercounter_->selectAll();
		chaptercounter_->mergeCurrentCharFormat( (*style_.textCharFormat()) );



		QTextFrameFormat format = chaptercounter_->document()->rootFrame()->frameFormat();

		format.setMargin( style_.textFrameFormat()->margin() +
			style_.textFrameFormat()->border() +
			style_.textFrameFormat()->padding()	);
		chaptercounter_->document()->rootFrame()->setFrameFormat( format );


		chaptercounter_->setAlignment( (Qt::AlignmentFlag)Qt::AlignRight );


		cursor = chaptercounter_->textCursor();

		cursor.clearSelection();
		chaptercounter_->setTextCursor( cursor );



	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-03-02
	 *
	 * \brief set the chapter counter
	 */
	void TextCell::setChapterCounter( QString number )
	{
		chaptercounter_->selectAll();
		chaptercounter_->setPlainText( number );
		chaptercounter_->setAlignment( (Qt::AlignmentFlag)Qt::AlignRight );
		QTextFrameFormat format = chaptercounter_->document()->rootFrame()->frameFormat();
		format.setMargin( style_.textFrameFormat()->margin() +
			style_.textFrameFormat()->border() +
			style_.textFrameFormat()->padding()	);
		chaptercounter_->document()->rootFrame()->setFrameFormat( format );
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-03-02
	 *
	 * \brief return the value of the chapter counter, as plain text.
	 * Returns null if the counter is empty
	 */
	QString TextCell::ChapterCounter()
	{
		if( chaptercounter_->toPlainText().isEmpty() )
			return QString::null;

		return chaptercounter_->toPlainText();
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-03-03
	 *
	 * \brief return the value of the chapter counter, as html code.
	 * Returns null if the counter is empty
	 */
	QString TextCell::ChapterCounterHtml()
	{
		if( chaptercounter_->toPlainText().isEmpty() )
			return QString::null;

		return chaptercounter_->toHtml();
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2006-03-02 (update)
	 *
	 * \breif Set readonly value on the texteditor
	 *
	 * 2005-10-31 AF, removed the change in framstyle, looks better now
	 * 2005-11-01 AF, clear text selection when text edit is set to readonly
	 * 2006-03-02 AF, clear text selection in chapter counter
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

			// 2006-03-02 AF, clear selection in chapter counter
			cursor = chaptercounter_->textCursor();
			cursor.clearSelection();
			chaptercounter_->setTextCursor( cursor );
		}

		text_->setReadOnly(readonly);
		text_->setTextInteractionFlags(text_->textInteractionFlags() | 	Qt::LinksAccessibleByMouse | Qt::LinksAccessibleByKeyboard);
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
//	QTextCursor c = textCursor();

//	if(textCursor().charFormat().isAnchor())
//		openLinkInternal(QUrl(textCursor().charFormat().anchorHref())); //fjass
//	else

		emit clicked(this);
//	{
//		QUrl u(c.charFormat().anchorHref());

//		setReadOnly(true);

//		if
//	}

	}

	/*!
	 * \author Anders Fernström and Ingemar Axelsson
	 * \date 2006-04-10 (update)
	 *
	 * \breif Recalculates height.
	 *
	 * 2005-10-31 AF, Large part of this function was changes due to
	 * porting to QT4 (changes from Q3TextBrowser to QTextBrowser).
	 * 2006-04-10 AF, emits heightChanged if the height changes
	 */
	void TextCell::contentChanged()
	{
		int height = text_->document()->documentLayout()->documentSize().toSize().height();

		//cout << "Height: " << height << endl;

		if( height < 0 )
			height = 30;

		text_->setMinimumHeight( height );

		// add a little extra, just in case, emit 'heightChanged()' if height
		// have chagned /AF
		setHeight( height + 5 );
		emit textChanged();

		if( oldHeight_ != (height + 5) )
			emit heightChanged();

		oldHeight_ = height + 5;
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

	void TextCell::openLinkInternal(const QUrl &url)
	{
		emit openLink(&url);
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
			text_->setAlignment( (Qt::AlignmentFlag)style_.alignment() );
			text_->mergeCurrentCharFormat( (*style_.textCharFormat()) );
			text_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );
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
				text_->setCurrentCharFormat( *style_.textCharFormat() );
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
				text_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );

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
