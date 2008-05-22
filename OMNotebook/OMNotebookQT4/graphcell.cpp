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
 * \file GraphCell.cpp
 * \author Ingemar Axelsson and Anders Fernström
 * \date 2005-10-27 (update)
 *
 * \brief Describes a GraphCell.
 */

//STD Headers
#include <exception>
#include <stdexcept>
#include <sstream>
#include <cmath>

//QT Headers
#include <QtCore/QDir>
#include <QtCore/QEvent>
#include <QtCore/QThread>
#include <QtGui/QAbstractTextDocumentLayout>
#include <QtGui/QApplication>
#include <QtGui/QMouseEvent>
#include <QtGui/QGridLayout>
#include <QtGui/QKeyEvent>
#include <QtGui/QLabel>
#include <QtGui/QMessageBox>
#include <QtGui/QResizeEvent>
#include <QtGui/QFrame>
#include <QtGui/QTextFrame>
#include <QAction>
#include <QActionGroup>
#include <QTextDocumentFragment>
#include <QTextStream>
#include <QRegExp>
#include <QPushButton>

//IAEX Headers
#include "graphcell.h"
#include "treeview.h"
#include "stylesheet.h"
#include "commandcompletion.h"
#include "highlighterthread.h"
#include "omcinteractiveenvironment.h"
#include "../Pltpkg2/graphWidget.h"
#include "../Pltpkg2/compoundWidget.h"
#include "indent.h"

#include "evalthread.h"

namespace IAEX
{
	/*! 
	 * \class SleeperThread
	 * \author Anders Ferström
	 *
	 * \brief Extends QThread. A small trick to get access to protected
	 * function in QThread.
	 */
	class SleeperThread : public QThread
	{
	public:
		static void msleep(unsigned long msecs)
		{
			QThread::msleep(msecs);
		}
	};



	/*! 
	 * \class MyTextEdit2
	 * \author Anders Ferström
	 * \date 2005-11-01
	 *
	 * \brief Extends QTextEdit. Mostly so I can catch when a user
	 * clicks on the editor
	 */
	MyTextEdit2::MyTextEdit2(QWidget *parent)
		: QTextBrowser(parent),
		inCommand(false),
		stopHighlighter(false), autoIndent(true)
	{

	}

	MyTextEdit2::~MyTextEdit2()
	{
		for(QMap<int, IndentationState*>::iterator i = indentationStates.begin(); i != indentationStates.end(); ++i)
		{
			delete i.value();
		}
	}

	bool MyTextEdit2::isStopingHighlighter()
	{
		return stopHighlighter;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-01
	 * \date 2005-12-15 (update)
	 *
	 * Needed a signal to be emited when the user click on the cell.
	 *
	 * 2005-12-15 AF, set inCommand to false when clicking on the cell,
	 * otherwise the commandcompletion class want be reseted when 
	 * changing GraphCells by clicking.
	 */
	void MyTextEdit2::mousePressEvent(QMouseEvent *event)
	{
		stopHighlighter = false;
		inCommand = false;
		QTextBrowser::mousePressEvent(event);

		if( event->modifiers() == Qt::ShiftModifier ||
			textCursor().hasSelection() )
		{
			return;
		}

		emit clickOnCell();
		updatePosition();
		if(state != ERROR)
			emit setState(MODIFIED);


	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-28
	 *
	 * \brief Handles mouse wheel events, ignore them and send the up
	 * in the cell hierarchy
	 */
	void MyTextEdit2::wheelEvent(QWheelEvent * event)
	{
		// ignore event and send it up in the event hierarchy
		event->ignore();
		emit wheelMove( event );
	}

	void MyTextEdit2::focusInEvent(QFocusEvent* event)
	{
		emit undoAvailable(document()->isUndoAvailable());
		emit redoAvailable(document()->isRedoAvailable());
		setModified();
		QTextBrowser::focusInEvent(event);
	}
	/*! 
	 * \author Anders Fernström
	 * \date 2005-12-15
	 * \date 2006-01-30 (update)
	 *
	 * \brief Handles key event, check if command completion or eval, 
	 * otherwise send them to the textbrowser
	 *
	 * 2006-01-30 AF, added ignore to 'Alt+Enter'
	 */
	void MyTextEdit2::keyPressEvent(QKeyEvent *event )
	{
		emit showVariableButton(false);
		// EVAL, key: SHIFT + RETURN || SHIFT + ENTER
		if( event->modifiers() == Qt::ShiftModifier && 
			(event->key() == Qt::Key_Return || event->key() == Qt::Key_Enter) )
		{
			inCommand = false;
			stopHighlighter = false;

			event->accept();
			emit eval();
		}
		// COMMAND COMPLETION, key: SHIFT + TAB (= BACKTAB) || CTRL + SPACE
		else if( (event->modifiers() == Qt::ShiftModifier && event->key() == Qt::Key_Backtab ) || 
			(event->modifiers() == Qt::ControlModifier && event->key() == Qt::Key_Space) )
		{
			stopHighlighter = false;

			event->accept();
			if( inCommand )
			{
				emit nextCommand();
			}
			else
			{
				inCommand = true;
				emit command();
			}
		}
		// COMMAND COMPLETION- NEXT FIELD, key: CTRL + TAB
		else if( event->modifiers() == Qt::ControlModifier &&
			event->key() == Qt::Key_Tab )
		{
			stopHighlighter = false;

			event->accept();
			inCommand = false;
			emit nextField();
		}
		// BACKSPACE, DELETE
		else if( event->key() == Qt::Key_Backspace ||
			event->key() == Qt::Key_Delete )
		{
			inCommand = false;
			stopHighlighter = true;
			
			QTextBrowser::keyPressEvent( event );
		}
		// ALT+ENTER (ignore)
		else if( event->modifiers() == Qt::AltModifier &&
			( event->key() == Qt::Key_Enter || event->key() == Qt::Key_Return ))
		{
			inCommand = false;
			stopHighlighter = false;

			event->ignore();
		}
		// PAGE UP (ignore)
		else if( event->key() == Qt::Key_PageUp )
		{
			inCommand = false;
			stopHighlighter = false;

			event->ignore();
		}
		// PAGE DOWN (ignore)
		else if( event->key() == Qt::Key_PageDown )
		{
			inCommand = false;
			stopHighlighter = false;

			event->ignore();
		}
		// CTRL+C
		else if( event->modifiers() == Qt::ControlModifier &&
			event->key() == Qt::Key_C )
		{
			inCommand = false;
			stopHighlighter = false;

			event->ignore();
			emit forwardAction( 1 );
		}
		// CTRL+X
		else if( event->modifiers() == Qt::ControlModifier &&
			event->key() == Qt::Key_X )
		{
			inCommand = false;
			stopHighlighter = false;

			event->ignore();
			emit forwardAction( 2 );
		}
		// CTRL+V
		else if( event->modifiers() == Qt::ControlModifier &&
			event->key() == Qt::Key_V )
		{
			inCommand = false;
			stopHighlighter = false;

			event->ignore();
			emit forwardAction( 3 );
		}
		else if(event->modifiers() == Qt::ControlModifier && event->key() == Qt::Key_W)
		{
			inCommand = false;
			stopHighlighter = false;
			indentText();
			event->ignore();
//			QTextBrowser::keyPressEvent( event );
			//			update();
			
		}

		else if(event->modifiers() == Qt::ControlModifier && event->key() == Qt::Key_E)
		{
			inCommand = false;
			stopHighlighter = false;
//			QMessageBox::information(0, "uu6", QVariant(textCursor().block().userState()).toString());
//			Indent a(toPlainText());
//			setText(a.indentedText(&indentationStates));
//
//			int i = 1;
//			for(QTextBlock b =this->document()->begin(); b != this->document()->end(); b = b.next())
//			{
//				b.setUserState(++i);
////				if(i > 5)
////					QMessageBox::information(0,  "uu5", QVariant(b.previous().userState()).toString());
//				//				QMessageBox::information(0, "uu5", b.text());
//			}

						indentText();
//			event->ignore();
//			QTextBrowser::keyPressEvent( event );
			//			update();
			
		}

		else if(event->modifiers() == Qt::ControlModifier && event->key() == Qt::Key_K)
		{
			inCommand = false;
			stopHighlighter = true;
			QTextCursor tc(textCursor());
			int i = toPlainText().indexOf(QRegExp("\\n|$"), tc.position());

			if(i -tc.position() > 0)
			  tc.setPosition(i, QTextCursor::KeepAnchor);
			else
			  tc.setPosition(i +1, QTextCursor::KeepAnchor);

			tc.insertText("");
//			int i = toPlainText().indexOf("\n", tc.position());


//			event->ignore();
			QTextBrowser::keyPressEvent( event );
//						update();
		}
		// TAB
		else if( event->key() == Qt::Key_Tab )
		{
			inCommand = false;
			stopHighlighter = false;

            textCursor().insertText( "  " );
		}
		else if( event->key() == Qt::Key_Enter || event->key() == Qt::Key_Return )
		{

			if(autoIndent)
			{
				/*
				QString prevLine, currentLine=toPlainText().left(textCursor().position());
				int i = currentLine.lastIndexOf("\n");
				int i2 = currentLine.lastIndexOf("\n", i-1);
				prevLine = currentLine.mid(i2+1, i-i2-1);
				currentLine = currentLine.right(currentLine.size() - i -1); 

				int currentLevel = currentLine.indexOf(QRegExp("\\S|$"));
				int prevLevel = prevLine.indexOf(QRegExp("\\S|$"));
				int ilevel = 2*indentationLevel(currentLine, true);

				if(currentLevel > prevLevel && ilevel < 0)
				{
				QTextCursor t(textCursor());
				t.clearSelection();
				t.setPosition(i+1);
				t.setPosition(i+1 +currentLevel-prevLevel-2 -ilevel, QTextCursor::MoveMode::KeepAnchor);
				if(t.selection().toPlainText().indexOf(QRegExp("\\S"))< 0)
				t.insertText("");
				//				currentLevel += ilevel;
				currentLevel -= (currentLevel -prevLevel -2 + -ilevel);
				}
				else if(currentLevel == prevLevel && ilevel <0)
				{
				QTextCursor t(textCursor());
				t.clearSelection();
				t.setPosition(i+1);
				t.setPosition(i+1 -ilevel, QTextCursor::MoveMode::KeepAnchor);
				if(t.selection().toPlainText().indexOf(QRegExp("\\S"))< 0)
				t.insertText("");
				currentLevel += ilevel;
				}
				else if(ilevel > 0)
				{
				currentLevel += ilevel;
				}

				if(currentLevel > 1 && lessIndented(currentLine))
				{
				QTextCursor t(textCursor());
				t.clearSelection();
				t.setPosition(i+1);
				t.setPosition(i+1 +currentLevel-prevLevel +2, QTextCursor::MoveMode::KeepAnchor);
				if(t.selection().toPlainText().indexOf(QRegExp("\\S"))< 0)
				t.insertText("");

				currentLevel = prevLevel;
				}
				//			textCursor().insertText(QString(currentLevel +2*indentationLevel(currentLine, false), ' '));
				QTextBrowser::keyPressEvent(event);
				textCursor().insertText(QString(currentLevel, ' '));
				}
				else
				QTextBrowser::keyPressEvent(event);
				*/

				//			QMessageBox::information(0, "uu", textCursor().block().text());
				QTextCursor t(textCursor());
				QString tmp, tmp2;
//				tmp = t.block().text();
				int k2 = t.blockNumber();
				QTextBlock b = t.block();
				int k = b.userState();
				int prevLevel = b.text().indexOf(QRegExp("\\S"));//tmp.indexOf(QRegExp("\\S")) ;

				while(k2 >= 0 && !indentationStates.contains(k))
				{
					tmp = b.text() + "\n" + tmp;
					b = b.previous();
					--k2;
					k = b.userState();
//					QMessageBox::information(0, "uu", QVariant(k).toString());
				}
//				QMessageBox::information(0, "uu", QVariant(k).toString());
//				QMessageBox::information(0, "uu2", tmp);
				//				Indent i(toPlainText().left(t.position()));
				Indent i(tmp);
				if(indentationStates.contains(k))
				{
					IndentationState* s = indentationStates[k];
					i.ism.level = s->level;
					i.ism.equation = s->equation;
					i.ism.equationSection = s->equationSection;
					i.ism.lMod = s->lMod;
					i.ism.loopBlock = s->loopBlock;
					i.ism.nextMod = s->nextMod;
					i.ism.skipNext = s->skipNext;
					i.ism.state = s->state;
					i.current = s->current;
//					QMessageBox::information(0, "uu3", s->current);
					i.next = s->next;

				}




			//}
				//			tmp = tmp.right(tmp.size() - tmp.lastIndexOf("\n"));

				i.indentedText();

//				QMessageBox::information(0, "uu1", QString("%1, %2").arg(prevLevel).arg(2*i.level()));
//				if(prevLevel >= 0 && 2*(i.level()) != prevLevel )
				if(prevLevel > 2*i.level())
				{
					int j = t.position();
/*
					t.setPosition(t.block().position());
					QMessageBox::information(0, "uu3", t.block().text());
					t.setPosition(t.block().position() + max(0,t.block().text().indexOf(QRegExp("\\S"))), QTextCursor::KeepAnchor);
					t.insertText(QString(2*i.level(), '_'));
					QMessageBox::information(0, "uu", t.selection().toPlainText());
					//					t.setPosition(t.block().position() + t.block().text().size());

					t.setPosition(t.block().position() + t.block().text().size()+1);
*/
					
					t.setPosition(t.block().position());
					t.setPosition(t.block().position() + prevLevel-2*(i.level()),QTextCursor::KeepAnchor);
					if(!t.selection().toPlainText().trimmed().size())
						t.insertText("");
					//			t.setPosition(t.block().position() + t.block().length());
					t.setPosition(t.block().position() + t.block().length() -1);
					
				}

				QTextBrowser::keyPressEvent(event);
				t.insertText(QString(2*i.level(), ' '));

			}		
			else
                QTextBrowser::keyPressEvent(event);

		}
		else
		{
			inCommand = false;
			stopHighlighter = false;

			QTextBrowser::keyPressEvent( event );
		}


		updatePosition();

	}

	void MyTextEdit2::setAutoIndent(bool b)
	{
		autoIndent = b;
	}

	void MyTextEdit2::setModified()
	{
		emit setState(MODIFIED);
	}

	void MyTextEdit2::updatePosition()
	{

		int pos = textCursor().position();
		int row = toPlainText().left(pos).count("\n") +1;
		int col = pos - toPlainText().left(pos).lastIndexOf("\n");

		emit updatePos(row, col);
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-01-23
	 *
	 * \brief If the mimedata that should be insertet contain text,
	 * create a new mimedata object that only contains text, otherwise
	 * text format is insertet also - don't want that for GraphCells.
	 */
	void MyTextEdit2::insertFromMimeData(const QMimeData *source)
	{
		if( source->hasText() )
		{
			QMimeData *newSource = new QMimeData();
			newSource->setText( source->text() );
			QTextBrowser::insertFromMimeData( newSource );
			delete newSource;
		}
		else
			QTextBrowser::insertFromMimeData( source );

		updatePosition();
		if(state != ERROR)
			emit setState(MODIFIED);

	}

	void MyTextEdit2::goToPos(const QUrl& u)
	{
		QRegExp e("\\-|:");
		int r=u.toString().section(e, 0,0).toInt();
		int c=u.toString().section(e, 1,1).toInt();
		int r2=u.toString().section(e, 2,2).toInt();
		int c2=u.toString().section(e, 3,3).toInt();

		
		int p = 0;
		for(int i = 1; i < r; ++i)
			p = toPlainText().indexOf("\n", p)+1;
		p += (c-1);

		QTextCursor tc(textCursor());
		tc.setPosition(p);

		int p2 = 0;
		if(r2 > 0)
		{
			for(int i = 1; i < r2; ++i)
				p2 = toPlainText().indexOf("\n", p2)+1;
			p2 += (c2-1);
		tc.setPosition(p2, QTextCursor::KeepAnchor);
		}
		
		setTextCursor(tc);

		updatePos(r, c);

		setFocus(Qt::MouseFocusReason);
	}

	void MyAction::triggered2()
	{
		emit urlClicked(QUrl(text()));
	}

	MyAction::MyAction(const QString& text, QObject* parent): QAction(text, parent) {}

//	};

	/*! 
	* \class GraphCell
	* \author Ingemar Axelsson and Anders Fernström
	*
	* \brief Describes how an GraphCell works.
	*
	* Input cells is places where the user can do input. To evaluate
	* the content of an GraphCell just press shift+enter. It will
	* throw an exception if it cant find OMC. Start OMC with
	* following commandline: 
	*
	* # omc +d=interactiveCorba
	*
	*
	* \todo Make it possible to add and change syntax coloring of code.(Ingemar Axelsson)
	*/

	int GraphCell::numEvals_ = 1;

	/*! 
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-11-23 (update)
	 *
	 * \brief The class constructor
	 *
	 * 2005-10-27 AF, updated the method due to porting from Q3Support 
	 * to pure QT4 classes.
	 * 2005-11-23 AF, added document to the constructor, because need 
	 * the document to insert images to the output part if ploting.
	 */
	GraphCell::GraphCell(Document *doc, QWidget *parent)
		: Cell(parent), 
		evaluated_(false), 
		closed_(true), 
		delegate_(0),
		oldHeight_( 0 ),
		document_(doc),
		compoundwidget(0)
	{
		QWidget *main = new QWidget(this);
		setMainWidget(main);
		
		layout_ = new QGridLayout(mainWidget());
		layout_->setMargin(0);
		layout_->setSpacing(0);

		setTreeWidget(new InputTreeView(this));
		setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed));

		//2005-10-07 AF, Porting, change from 'QWidget::' to 'Qt::'
		setFocusPolicy(Qt::NoFocus);

		createGraphCell();
		createOutputCell();
		createCompoundWidget();		

		connect(compoundwidget->gwMain, SIGNAL(showVariableButton(bool)), this, SLOT(showVariableButton(bool)));
		connect(input_, SIGNAL(showVariableButton(bool)), this, SLOT(showVariableButton(bool)));
		connect(variableButton, SIGNAL(clicked()), compoundwidget->gwMain, SLOT(showVariables()));
 
		connect(compoundwidget->gwMain, SIGNAL(newExpr(QString)), this, SLOT(setExpr(QString)));
		connect(this, SIGNAL(newExpr(QString)), compoundwidget->gwMain, SLOT(setExpr(QString)));
		connect(compoundwidget->gwMain, SIGNAL(showGraphics()), this, SLOT(showGraphics()));
		
		connect(output_, SIGNAL(anchorClicked(const QUrl&)), input_, SLOT(goToPos(const QUrl&)));

		showGraph = false;

		imageFile=0;
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernström
	 *
	 * \brief The class destructor
	 */
	GraphCell::~GraphCell()
	{
		//2006-01-05 AF, check if input texteditor is in the highlighter,
		//if it is - wait for 60 ms and check again.
		HighlighterThread *thread = HighlighterThread::instance();
		int sleepTime = 0;
		bool firstTime = true;
		while( thread->haveEditor( input_ ) )
		{
			if( firstTime )
			{
				thread->removeEditor( input_ );
				firstTime = false;
			}

			SleeperThread::msleep( 60 );
			sleepTime++;

			if( sleepTime > 100 )
				break;
		}
		
		delete compoundwidget;

		delete input_;
		delete output_;
		if(imageFile)
			delete imageFile;
		//delete syntaxHighlighter_;
	}

	/*! 
	 * \author Anders Fernström and Ingemar Axelsson
	 * \date 2006-03-02 (update)
	 *
	 * \brief Creates the QTextEdit for the input part of the 
	 * GraphCell
	 *
	 * 2005-10-27 AF, Large part of this function was changes due to 
	 * porting to QT4 (changes from Q3TextEdit to QTextEdit).
	 * 2005-12-15 AF, Added more connections to the editor, mostly for
	 * commandcompletion, but also for eval. invoking eval have moved
	 * from the eventfilter on this cell to the reimplemented key event
	 * handler in the editor
	 * 2006-03-02 AF, Added call to createChapterCounter();
	 */
	void GraphCell::createGraphCell()
	{
		input_ = new MyTextEdit2( mainWidget() );
		variableButton = new QPushButton("D",input_);
		variableButton->setToolTip("New simulation data available");

//		QHBoxLayout *lo = new QHBoxLayout();
//		lo->addItem(new QSpacerItem(1, 1), 1, 1);
		
//		lo->addWidget(l, 1, Qt::AlignRight);
//		input_->setLayout(lo);
		//		l->setFrameShape(QFrame::Box);
		variableButton->setMaximumWidth(25);
		//l->setFrameStyle(QFrame::Sunken | QFrame::Box);
		layout_->addWidget( input_, 1, 1 );
		layout_->addWidget(variableButton, 1, 2);
		variableButton->hide();
		// 2006-03-02 AF, Add a chapter counter
		createChapterCounter();

		//input_->setReadOnly( false );
		input_->setReadOnly( true );
		input_->setUndoRedoEnabled( true );
		//input_->setFrameStyle( QFrame::NoFrame );
		input_->setFrameShape( QFrame::Box );
		input_->setAutoFormatting( QTextEdit::AutoNone );

		input_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
		input_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
//		input_->setContextMenuPolicy( Qt::NoContextMenu );

		QPalette palette;
		palette.setColor(input_->backgroundRole(), QColor(200,200,255));
//		palette.setColor(input_->backgroundRole(), QColor(Qt::green));
		input_->setPalette(palette);

		variableButton->setPalette(palette);
		// is this needed, don't know /AF
		input_->installEventFilter(this);
		

		connect( input_, SIGNAL( textChanged() ),
			this, SLOT( contentChanged() ));
		connect( input_, SIGNAL( clickOnCell() ),
			this, SLOT( clickEvent() ));
		connect( input_, SIGNAL( wheelMove(QWheelEvent*) ),
			this, SLOT( wheelEvent(QWheelEvent*) ));
		// 2005-12-15 AF, new connections
		connect( input_, SIGNAL( eval() ),
			this, SLOT( eval() ));
		connect( input_, SIGNAL( command() ),
			this, SLOT( command() ));
		connect( input_, SIGNAL( nextCommand() ),
			this, SLOT( nextCommand() ));
		connect( input_, SIGNAL( nextField() ),
			this, SLOT( nextField() ));
		//2005-12-29 AF
		connect( input_, SIGNAL( textChanged() ),
			this, SLOT( addToHighlighter() ));
		// 2006-01-17 AF, new...
		connect( input_, SIGNAL( currentCharFormatChanged(const QTextCharFormat &) ),
			this, SLOT( charFormatChanged(const QTextCharFormat &) ));
		// 2006-04-27 AF,
		connect( input_, SIGNAL( forwardAction(int) ),
			this, SIGNAL( forwardAction(int) ));

		connect( input_, SIGNAL(updatePos(int, int)), this, SIGNAL(updatePos(int, int)));
		contentChanged();

		connect(input_, SIGNAL(setState(int)), this, SLOT(setState(int)));
		connect(input_, SIGNAL(textChanged()), input_, SLOT(setModified()));

	}


	void GraphCell::showVariableButton(bool b)
	{
		if(b)
			variableButton->show();
		else
			variableButton->hide();
	}

	/*! 
	 * \author Anders Fernström and Ingemar Axelsson
	 * \date 2005-10-28 (update)
	 *
	 * \brief Creates the QTextEdit for the output part of the 
	 * GraphCell
	 *
	 * Large part of this function was changes due to porting
	 * to QT4 (changes from Q3TextEdit to QTextEdit).
	 */
	void GraphCell::createOutputCell()
	{
		output_ = new MyTextEdit2( mainWidget() );
		layout_->addWidget( output_, 2, 1 );

		output_->setReadOnly( true );

		output_->setOpenLinks(false);

		//output_->setFrameShape( QFrame::Panel );
		output_->setFrameShape( QFrame::Box );
		output_->setAutoFormatting( QTextEdit::AutoNone );

		output_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
		output_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
//		output_->setContextMenuPolicy( Qt::NoContextMenu ); 

		connect( output_, SIGNAL( textChanged() ),
			this, SLOT(contentChanged()));
		connect( output_, SIGNAL( clickOnCell() ),
			this, SLOT( clickEventOutput() ));
		connect( output_, SIGNAL( wheelMove(QWheelEvent*) ),
			this, SLOT( wheelEvent(QWheelEvent*) ));

		connect(output_, SIGNAL(forwardAction(int)), this, SIGNAL(forwardAction(int)));

		setOutputStyle();
		
		output_->setTextInteractionFlags(Qt::TextSelectableByMouse|Qt::TextSelectableByKeyboard|Qt::LinksAccessibleByMouse|Qt::LinksAccessibleByKeyboard);
//		QPalette palette;
//		palette.setColor(input_->backgroundRole(), QColor(Qt::gray));
//		output_->setPalette(palette);
		output_->hide();
	}

	void GraphCell::createCompoundWidget()
	{

		compoundwidget = new CompoundWidget(mainWidget());
		compoundwidget->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);

		layout_->addWidget( compoundwidget, 3, 1 );

		compoundwidget->gwMain->setServerState(false);
		compoundwidget->hide();


//		connect( compoundwidget, SIGNAL( wheelMove(QWheelEvent*) ),
//			this, SLOT( wheelEvent(QWheelEvent*) ));




	}

	bool MyTextEdit2::lessIndented(QString s)
	{
		QRegExp l("\\b(equation|algorithm|public|protected|else|elseif)\\b");

		return s.indexOf(l) >= 0;
	}
	int MyTextEdit2::indentationLevel(QString s, bool includeNegative)
	{
		QRegExp e1("\\b(model|class|type|connector|block|record|function|record|for|when|package|if)\\b");
		QRegExp e1b("end\\s+(model|class|type|connector|block|record|function|record|for|when|package|if)\\b");
		QRegExp e2("\\b(end|then)\\b");

		QRegExp newLineEnd("^end\\b");

//		return s.count(e1) - includeNegative?(s.count(e2) + s.count(e1b)):0;
		if(includeNegative)
			return s.count(e1) - s.count(e2) - s.count(e1b);// - s.count(lessIndented);
		else
			return s.count(e1) - s.count(e1b);//- s.count(lessIndented);
	}

	void MyTextEdit2::indentText()
	{

		
			Indent a(toPlainText());
			setText(a.indentedText(&indentationStates));

			int i = 1;
			for(QTextBlock b =this->document()->begin(); b != this->document()->end(); b = b.next())
			{
				b.setUserState(++i);
//				if(i > 5)
//					QMessageBox::information(0,  "uu5", QVariant(b.previous().userState()).toString());
				//				QMessageBox::information(0, "uu5", b.text());
			}
		
		
		
		
		
		
		
		//		stopHighlighter = true;
	
//		int level = 0;
//		QString s =  toPlainText();
//
//		QTextStream ts(&s);
//		QRegExp e1("\\b(model|class|type|connector|block|record|function|record|for|when|package|if)\\b");
//		QRegExp e1b("end\\s+(model|class|type|connector|block|record|function|record|for|when|package|if)\\b");
//		QRegExp e1c("\\b(else\\s+if|else\\s+[\\S]+[\\s]*;|then\\s+[\\S]+[\\s]*;)\\b");
//		QRegExp e1c2("\\b(else\\b[\\S]+[\\s]*;)\\b");
//		QRegExp e1c3("b\\s+else");
//		//QRegExp e1c3("\\b(else\\bif|else\\b[\\S]+[\\s]*;|then\\b[\\S]+[\\s]*;)\\b");
//
//		e1c.setMinimal(true);
//		QRegExp e2("\\bend\\b");
//		QRegExp lessIndented("\\b(equation|algorithm|public|protected|else|elseif)\\b");
//		QRegExp newLineEnd("^end\\b");
//		QString tmp, res;
//		int levelMod = 0;
//		QMessageBox::information(0, "uu", QVariant(QString("a b else ; ").indexOf(e1c3)).toString());
//		while(!ts.atEnd())
//		{
//			level=max(0, level);
//			levelMod = 0;
//			tmp = ts.readLine();
//
//
//			if(tmp.trimmed().left(2) == QString("//"))
//			{
////				tmp = QString( 2*(level + levelMod), ' ') + tmp + "\n";
//				res = res +tmp +"\n";
//				continue;
//			}
//			tmp = tmp.trimmed();
//
//			if(tmp.indexOf(lessIndented) >= 0)
//				--levelMod;
//
////			if(tmp.left(2) != QString("//"))
//
////			level -= tmp.count(newLineEnd);
//			if(tmp.indexOf(newLineEnd) >= 0)
//				--levelMod;
//
//			/*
//			if(tmp.indexOf(newLineEnd) >= 0)
//				levelMod = -1;
//			else
//				levelMod = 0;
//*/
////			QMessageBox::information(0, tmp, QVariant(level+levelMod).toString());
//			//			QMessageBox::information(0, "uu",QString("_") + tmp + "_");
//			tmp = QString( 2*(level + levelMod), ' ') + tmp + "\n";
////			QMessageBox::information(0, "uu",QString("_") + tmp + "_");
//
////			if(tmp.left(2) != QString("//"))
//				level = level + tmp.count(e1) - tmp.count(e2) - tmp.count(e1b) -tmp.count(e1c);
////				if(tmp.indexOf(newLineEnd) >= 0)
////					++level ; 
//
//			res += tmp;
//		}
//		
//		QTextCursor t(textCursor());
////		t.setPosition(0);
////		t.select(QTextCursor::SelectionType::Document);
//		
//		setText(res.trimmed());
//		

//		t.insertText(res);
		emit textChanged();
	//		setText(res.trimmed());

//		stopHighlighter = false;

	}
	/*! 
	 * \author Anders Fernström
	 * \date 2006-04-21
	 *
	 * \brief Set the output style
	 */
	void GraphCell::setOutputStyle()
	{
		// Set the correct style for the QTextEdit output_
		output_->selectAll();

		Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
		CellStyle style = sheet->getStyle( "Output" );

		if( style.name() != "null" )
		{
			output_->setAlignment( (Qt::AlignmentFlag)style.alignment() );
			output_->mergeCurrentCharFormat( (*style.textCharFormat()) );
			output_->document()->rootFrame()->setFrameFormat( (*style.textFrameFormat()) );
		}
		else
		{
			// 2006-01-30 AF, add message box
			QString msg = "No Output style defened, please define a Output style in stylesheet.xml";
			QMessageBox::warning( 0, "Warning", msg, "OK" );
		}

		QTextCursor cursor = output_->textCursor();
		cursor.clearSelection();
		output_->setTextCursor( cursor );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-03-02
	 *
	 * \brief Creates the chapter counter
	 */
	void GraphCell::createChapterCounter()
	{
		chaptercounter_ = new MyTextEdit2(this);
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
	 * \date 2005-10-27
	 *
	 * \brief Returns the text (as plain text) fromthe cell
	 *
	 * \return The text, as plain text
	 */
	QString GraphCell::text()
	{
		return input_->toPlainText();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-27
	 *
	 * \brief Return the text inside the cell as Html code
	 *
	 * \return Html code
	 */
	QString GraphCell::textHtml()
	{
		return input_->toHtml();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-23
	 *
	 * \brief Return the text inside the output part of the cell
	 * as plain text
	 *
	 * \return output text
	 */
	QString GraphCell::textOutput()
	{
		return output_->toPlainText();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-23
	 *
	 * \brief Return the text inside the output part of the cell
	 * as html code
	 *
	 * \return html code
	 */
	QString GraphCell::textOutputHtml()
	{
		return output_->toHtml();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-27
	 *
	 * \brief Return the text cursor to the QTextEdit that make up
	 * the inputpart of the GraphCell
	 *
	 * \return Text cursor to the cell
	 */
	QTextCursor GraphCell::textCursor()
	{
		return input_->textCursor();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-01-05
	 *
	 * \brief Return the input texteditor
	 *
	 * \return Texteditor for the inputpart of the GraphCell
	 */
	QTextEdit *GraphCell::textEdit()
	{
		return input_;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-02-03
	 *
	 * \brief Return the output texteditor
	 *
	 * \return Texteditor for the output part of the GraphCell
	 */
	QTextEdit* GraphCell::textEditOutput()
	{
		return output_;
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2005-12-16 (update)
	 *
	 * \brief Set text to the cell
	 *
	 * \param text The text that should be placed inside the cell
	 *
	 * 2005-10-04 AF, added some code for removing/replacing some text
	 * 2005-10-27 AF, updated the function due to porting from qt3 to qt4
	 * 2005-12-08 AF, added code that removed any <span style tags added 
	 * in the parser.
	 * 2005-12-16 AF, block signlas so syntax highligher isn't done more 
	 * than once.
	 */
	void GraphCell::setText(QString text)
	{
		// 2005-12-16 AF, block signals
		input_->document()->blockSignals(true);
	
		// 2005-10-04 AF, added some code to replace/remove
		QString tmp = text.replace("<br>", "\n");
		tmp.replace( "&nbsp;&nbsp;&nbsp;&nbsp;", "  " );

		// 2005-12-08 AF, remove any <span style tag
		QRegExp spanEnd( "</span>" );
		tmp.remove( spanEnd );
		int pos = 0;
		while( true )
		{
			int startpos = tmp.indexOf( "<span", pos, Qt::CaseInsensitive );
			if( startpos >= 0 )
			{
				int endpos = tmp.indexOf( "\">", startpos );
				if( endpos >= 0 )
				{
					endpos += 2;
					tmp.remove( startpos, endpos - startpos );
				}
				else
					break;
			}
			else
				break;
			
			pos = startpos;
		}

		// set the text
		input_->setPlainText( tmp );


		// 2005-12-16 AF, unblock signals and tell highlighter to highlight
		input_->document()->blockSignals(false);

//		input_->document()->setHtml( input_->toHtml() ); //uu
//		input_->document()->setPlainText(tmp);

		bool b = input_->document()->isEmpty();
/*
		input_->document()->setPlainText(text);

		//		input_->document()->setPlainText( input_->toPlainText() );

		input_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );
*/
		contentChanged();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-01
	 *
	 * \brief Sets the visible text using html code.
	 *
	 * Sets the text that should be visible using html code. Can change 
	 * the cellheight if the text is very long.
	 *
	 * \param html Html code that should be visible as normal text inside the cell mainarea.
	 */ 
	void GraphCell::setTextHtml(QString html)
	{
		input_->setHtml( html );
		setStyle( style_ );

		contentChanged();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-23
	 *
	 * \brief Set text to the output part of the cell
	 *
	 * \param text The text that should be placed inside the output part
	 */
	void GraphCell::setTextOutput(QString text)
	{
		if( !text.isNull() && !text.isEmpty() )
		{
			output_->setPlainText( text );
			evaluated_ = true;
			//setClosed( false );

			contentChanged();
		}
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-23
	 *
	 * \brief Sets the output text using html code.
	 *
	 * Sets the text that should be visible in the output part of the
	 * cell using html code. Can change the cellheight if the text is 
	 * very long.
	 *
	 * \param html Html code that should be visible as normal text inside the cell mainarea.
	 */ 
	void GraphCell::setTextOutputHtml(QString html)
	{
		if( !html.isNull() && !html.isEmpty() )
		{
			output_->setHtml( html );
			evaluated_ = true;
			//setClosed( false );
			contentChanged();
		}
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-28
	 *
	 * \brief Set cell style
	 *
	 * IMPORTANT: User shouldn't be able to change style on GraphCells 
	 * so this function always use "Input" as style.
	 *
	 * \param stylename The style name of the style that is to be applyed to the cell
	 */
	void GraphCell::setStyle(const QString &)
	{
		Cell::setStyle( "Graph" );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-27
	 * \date 2006-03-02 (update)
	 *
	 * \brief Set cell style
	 *
	 * IMPORTANT: User shouldn't be able to change style on GraphCells 
	 * so this function always use "Input" as style.
	 *
	 * 2005-11-03 AF, updated so the text is selected when the style
	 * is changed, after the text is unselected.
	 * 2006-03-02 AF, set chapter style
	 *
	 * \param style The cell style that is to be applyed to the cell
	 */
	void GraphCell::setStyle(CellStyle style)
	{

		if( style.name() == "Graph" )
		{
			Cell::setStyle( style );

			// select all the text
			input_->selectAll();
		
			// set the new style settings
			input_->setAlignment( (Qt::AlignmentFlag)style_.alignment() );
			input_->mergeCurrentCharFormat( (*style_.textCharFormat()) );
			input_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );

			// unselect the text
			QTextCursor cursor(	input_->textCursor() );
			cursor.clearSelection();
			input_->setTextCursor( cursor );

			// 2006-03-02 AF, set chapter counter style
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
		else
		{
			setStyle( "Graph" );
		}
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-03-02
	 *
	 * \brief set the chapter counter
	 */
	void GraphCell::setChapterCounter( QString number )
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
	QString GraphCell::ChapterCounter()
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
	QString GraphCell::ChapterCounterHtml()
	{
		if( chaptercounter_->toPlainText().isEmpty() )
			return QString::null;

		return chaptercounter_->toHtml();
	}

	/*!
	 * \author Anders Fernström
	 * \date 2005-11-01
	 * \date 2006-03-02 (update)
	 *
	 * \breif Set readonly value on the texteditor
	 *
	 * \param readonly The boolean value of readonly property
	 *
	 * 2006-03-02 AF, clear text selection in chapter counter
	 */
	void GraphCell::setReadOnly(const bool readonly)
	{
		try
		{
			if( readonly )
			{
				QTextCursor cursor = input_->textCursor();
				cursor.clearSelection();
				input_->setTextCursor( cursor );

				cursor = output_->textCursor();
				cursor.clearSelection();
				output_->setTextCursor( cursor );

				// 2006-03-02 AF, clear selection in chapter counter
				cursor = chaptercounter_->textCursor();
				cursor.clearSelection();
				chaptercounter_->setTextCursor( cursor );
			}

			input_->setReadOnly(readonly);
		}
		catch(...)
		{
			qDebug() << "setReadOnly: crash" << endl;
		}
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-01-16
	 *
	 * \breif Set evaluated value on the texteditor
	 *
	 * \param evaluated The boolean value of evaluated property
	 */
	void GraphCell::setEvaluated(const bool evaluated)
	{
		evaluated_ = evaluated;
	}

	/*!
	 * \author Ingemar Axelsson (and Anders Fernström)
	 * \date 2005-11-01 (update)
	 *
	 * \breif Set if the output part of the cell shoud be 
	 * closed(hidden) or not.
	 *
	 * 2005-11-01 AF, Made some small changes to how the function 
	 * calculate the new height, to reflect the changes made when 
	 * porting from Q3TextEdit to QTextEdit. 
	 */
	void GraphCell::setClosed(const bool closed, bool update)
	{
		if( closed )
		{
			output_->hide();
			compoundwidget->hide();
		
		}
		else
		{
			if( evaluated_ )
			{
				output_->show();
				if(showGraph)
					compoundwidget->show();
			}
		}

		closed_ = closed;
		contentChanged();
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernström
	 */
	void GraphCell::setFocus(const bool focus)
	{
		if(focus)
			input_->setFocus();
	}
	
	/*!
	 * \author Anders Fernström
	 */
	void GraphCell::setFocusOutput(const bool focus)
	{
		if(focus)
			output_->setFocus();
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernström
	 */
	void GraphCell::clickEvent()
	{
		//if( input_->isReadOnly() )
			emit clicked(this);
	}

	/*!
	 * \author Anders Fernström
	 */
	void GraphCell::clickEventOutput()
	{
		emit clickedOutput(this);
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
	void GraphCell::contentChanged()
	{
		int height = input_->document()->documentLayout()->documentSize().toSize().height();

		if( height < 0 )
			height = 30;

		// add a little extra, just in case /AF
		input_->setMinimumHeight( height + 3 );

		if( evaluated_ && !closed_ )
		{	
			int outHeight = output_->document()->documentLayout()->documentSize().toSize().height();

			if( outHeight < 0 )
				outHeight = 30;

			output_->setMinimumHeight( outHeight );
			height += outHeight;
		}

		// add a little extra, just in case, emit 'heightChanged()' if height
		// have chagned /AF
		if(compoundwidget && compoundwidget->isVisible())
		{

			compoundwidget->setMinimumHeight(250);
			compoundwidget->gvBottom->show();
			compoundwidget->gvLeft->show();
			height += 250;

		}


		setHeight( height + 3 );
		emit textChanged();

		if( oldHeight_ != (height + 3 ) )
			emit heightChanged();

		oldHeight_ = height + 3;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-01-17
	 *
	 * \brief Returns true if GraphCell is closed, otherwise the method
	 * returns false.
	 *
	 * \return State of GraphCell (closed or not)
	 */
	bool GraphCell::isClosed()
	{
		return closed_;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-10-27
	 *
	 * \brief Function for telling if the user is allowed to change 
	 * the text settings for the text inside the cell. User isn't
	 * allowed to change the text settings for GraphCell so this 
	 * function always return false.
	 *
	 * \return False
	 */
	bool GraphCell::isEditable()
	{
		return false;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-23
	 *
	 * \brief Returns true if GraphCell is evaluated, returns false if
	 * GraphCell haven't been evaluated.
	 *
	 * \return State of GraphCell (evaluated or not)
	 */
	bool GraphCell::isEvaluated()
	{
		return evaluated_;	
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-11-23
	 *
	 * \brief Returns true if the expression in the text is a plot 
	 * command, returns false otherwise. If no text is sent to the 
	 * method it will test the text in the input part of the cell.
	 *
	 * \param text The text that should be tested, if no text the 
	 * inputpart of the cell will be tested.
	 * \return If plot command or not
	 */
	bool GraphCell::isPlot(QString text)
	{
//		QRegExp exp( "plot\\((.*)|plotParametric\\((.*)|simulate" );
		QRegExp exp( "plot\\((.*)|plotParametric\\((.*)" );
		if( text.isNull() )
		{
			if( 0 <= input_->toPlainText().indexOf( exp, 0 ) )
				return true;
			else
				return false;
		}
		else
		{
			if( 0 <= text.indexOf( exp, 0 ) )
				return true;
			else
				return false;
		
		}
	}

	void GraphCell::showGraphics()
	{
		compoundwidget->show();
		showGraph = true;


		if(!compoundwidget->isVisible())
		{
			setHeight(height() +200);
			compoundwidget->show();
			compoundwidget->setMinimumHeight(200);
		}
		contentChanged();
	}
	bool GraphCell::isPlot2(QString text)
	{
		QRegExp exp("plot2\\(.*\\)|plotParametric2\\(.*\\)|simulate|plotAll" );

		if( text.isNull() )
		{
			if( 0 <= input_->toPlainText().indexOf( exp, 0 ) )
				return true;
			else
				return false;
		}
		else
		{
			if( 0 <= text.indexOf( exp, 0 ) )
				return true;
			else
				return false;
		
		}
	}

	void GraphCell::setExpr(QString expr)
	{
		input_->setPlainText(expr);
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2006-04-18 (update)
	 *
	 *\brief Sends the content of the GraphCell to the evaluator. 
	 * Displays the result in a outputcell. 
	 *
	 * 2005-11-01 AF, updated so the text that is sent to be evaled isn't
	 * in html code.
	 * 2005-11-17 AF, added a check if the result if empty, if so add
	 * some default text
	 * 2005-11-23 AF, added support for inserting image to output
	 * 2006-04-18 AF, uses environment variable to find the plot
	 *
	 * Removes whitespaces and tags from the content string. Then sends
	 * the content to the delegate object for evaluation. The result is
	 * printed in a output cell. No indentation and syntax
	 * highlightning is used in the output cell.
	 * 
	 */
	void GraphCell::eval()
	{
		input_->blockSignals(true);
		output_->blockSignals(true);

		
		setState(EVAL);
		

		if( hasDelegate() )
		{

			// Only the text, no html tags. /AF
			QString expr = input_->toPlainText();
			//expr = expr.simplified();

			emit newExpr(expr);

			QString openmodelica( getenv( "OPENMODELICAHOME" ) );
			if( openmodelica.isEmpty() )
				QMessageBox::critical( 0, "OpenModelica Error", "Could not find environment variable OPENMODELICAHOME; OMNotebook will therefore not work correctly" );

			if( openmodelica.endsWith("/") || openmodelica.endsWith( "\\") )
				openmodelica += "tmp/";
			else
				openmodelica += "/tmp/";

			QString imagename = "omc_tmp_plot.png";

			QDir dir1 = QDir::current();
			QString filename1 = dir1.absolutePath();

			QDir dir2 = QDir::current(); dir2.setPath( openmodelica );
			QString filename2 = dir2.absolutePath();
			if( !filename1.endsWith( "/" ) ) filename1 += "/";
			filename1 += imagename;
			if( !filename2.endsWith( "/" ) ) filename2 += "/";
			filename2 += imagename;


			// 2006-02-17 AF, 
			evaluated_ = true;
			setClosed(false);

			// 2006-02-17 AF, set text '{evaluation expression}" during
			// evaluation of expressiuon
			output_->selectAll();
			output_->textCursor().insertText( "{evaluating expression}" );
			setOutputStyle();
			//output_->setPlainText( "{evaluating expression}" );
			output_->update();
			QCoreApplication::processEvents();


			// remove plot.png if it already exist, don't want any
			// old plot.
			bool oldPlot = isPlot(input_->toPlainText());
			bool newPlot = isPlot2(input_->toPlainText());

			if( oldPlot )
			{
				setClosed(false);

				if( dir1.exists( imagename ))
					dir1.remove( imagename );
				if( dir2.exists( imagename ))
					dir2.remove( imagename );

				compoundwidget->hide();

			}
			else if(newPlot)
			{
				setClosed(false);

//				showGraphics();
//		if(!compoundwidget->gwMain->getServerState())
			compoundwidget->gwMain->setServerState(true);

/*
				if(!compoundwidget->gwMain->getServerState())
					compoundwidget->gwMain->setServerState(true);
				if(!compoundwidget->isVisible())
				{
					setHeight(height() +200);
					compoundwidget->show();
					compoundwidget->setMinimumHeight(200);
				}
*/
			}

			// 2006-02-02 AF, Added try-catch
			QString res, error;

			// 2005-11-24 AF, added check to see if the user wants to quit
			if( 0 == expr.indexOf( "quit()", 0, Qt::CaseSensitive ))
			{
				qApp->closeAllWindows();
				input_->blockSignals(false);
				output_->blockSignals(false);
				return;
			}

//			if(!newPlot)
			if(oldPlot)
			{
				try
				{
					delegate()->evalExpression( expr );
				}
				catch( exception &e )
				{
					exceptionInEval(e);
					input_->blockSignals(false);
					output_->blockSignals(false);
					return;
				}

				res = delegate()->getResult();


				try
				{
					error = delegate()->getError();
				}
				catch( exception &e )
				{
					exceptionInEval(e);
					input_->blockSignals(false);
					output_->blockSignals(false);
					return;
				}


			}
			else
			{
				try
				{
					EvalThread* et = new EvalThread(delegate(), expr);
					connect(et, SIGNAL(finished()), this, SLOT(delegateFinished()));
					et->start();
					//				delegate()->evalExpression( expr );
				}
				catch( exception &e )
				{
					exceptionInEval(e);
					input_->blockSignals(false);
					output_->blockSignals(false);
					return;
				}
			}

			//////////
			if(oldPlot)
			{
				if(error.isEmpty() )
				{	

					output_->selectAll();
					output_->textCursor().insertText( "{creating plot}" );
					//output_->setPlainText( "{creating plot}" );
					output_->update();
					QCoreApplication::processEvents();

					int sleepTime = 1;
					bool firstTry = true;
					while( true )
					{
				                QString filename = "";
						bool foundIt = false;
						/* Search BOTH $OPENMODELICA/tmp and the current directory! */
						if( dir1.exists( imagename )) { filename = filename1; foundIt = true; }
						else if( dir2.exists( imagename )) { filename = filename2; foundIt = true; }

						if (foundIt)
						{
							QImage *image = new QImage( filename );
							if( !image->isNull() )
							{
								QString newname = document_->addImage( image );
								QTextCharFormat format = output_->currentCharFormat();

								QTextImageFormat imageformat;
								imageformat.merge( format );
								imageformat.setHeight( image->height() );
								imageformat.setWidth( image->width() );
								imageformat.setName( newname );

								output_->selectAll();
								//output_->textCursor().insertText( "{Plot - Generated by PtPlot}" );
								//output_->setPlainText("{Plot}\n");
								QTextCursor outCursor = output_->textCursor();
								//outCursor.movePosition( QTextCursor::End );
								outCursor.insertImage( imageformat );
								break;
							}
							else
							{
								if( firstTry )
								{
									firstTry = false;
									delete image;
								}
								else
								{
									output_->selectAll();
									output_->textCursor().insertText( "[Error] Unable to read plot image \"" + 
													  filename1 + "or " + filename2 + "\". Please retry." );
									setState(ERROR);
									break;
								}
							}
						}

						if( sleepTime > 25 )
						{
							output_->selectAll();
							output_->textCursor().insertText( "[Error] Unable to find plot image \"" + 
											  filename1 + " or " + filename2  + "\"" );
							setState(ERROR);
							break;
						}

						SleeperThread::msleep( 1000 );
						sleepTime++;
					}

				}
				else
				{
					// check if resualt is empty
					if( res.isEmpty() && error.isEmpty() )
					{
						setState(FINISHED);					
						res = "[done]";
					}
					if( !error.isEmpty() )
					{
						res += QString("\n") + error;
				//		palette.setColor(input_->backgroundRole(), QColor(200,00,00));
						setState(ERROR);
					}
					else
						setState(FINISHED);
//						palette.setColor(input_->backgroundRole(), QColor(200,200,255));					

//		QPalette palette;

//		palette.setColor(input_->backgroundRole(), QColor(Qt::green));
//		input_->setPalette(palette);

					output_->selectAll();
					output_->textCursor().insertText( res );
					//output_->setPlainText( res );
				}

				++numEvals_;
				/* remove the image */
				if( dir1.exists( imagename ))
				  dir1.remove( imagename );
				if( dir2.exists( imagename ))
				  dir2.remove( imagename );

				contentChanged();

				//Emit that the text have changed
				emit textChanged(true);


			}

			}
		else //!hasDelegate
		{
			cout << "Not delegate on GraphCell" << endl;
			setState(ERROR);
		}
			input_->blockSignals(false);
			output_->blockSignals(false);
		
}

/*
			// get the result
			QString res = delegate()->getResult();
			QString error;
			
			// 2006-02-02 AF, Added try-catch
			try
			{
				error = delegate()->getError();
			}
			catch( exception &e )
			{
				exceptionInEval(e);
				input_->blockSignals(false);
				output_->blockSignals(false);
				return;
			}
*/
			// if the expression is a plot command and the is no errors
			// in the result, find the image and insert it into the 
			// output part of the cell.

			
			/*
			if( isPlot() && error.isEmpty() )
			{	
				output_->selectAll();
				output_->textCursor().insertText( "{creating plot}" );
				//output_->setPlainText( "{creating plot}" );
				output_->update();
				QCoreApplication::processEvents();

				int sleepTime = 1;
				bool firstTry = true;
				while( true )
				{
					if( dir.exists( imagename ))
					{
						QImage *image = new QImage( filename );
						if( !image->isNull() )
						{
							QString newname = document_->addImage( image );
							QTextCharFormat format = output_->currentCharFormat();
																				
							QTextImageFormat imageformat;
							imageformat.merge( format );
							imageformat.setHeight( image->height() );
							imageformat.setWidth( image->width() );
							imageformat.setName( newname );

							output_->selectAll();
							//output_->textCursor().insertText( "{Plot - Generated by PtPlot}" );
							//output_->setPlainText("{Plot}\n");
							QTextCursor outCursor = output_->textCursor();
							//outCursor.movePosition( QTextCursor::End );
							outCursor.insertImage( imageformat );
							break;
						}
						else
						{
							if( firstTry )
							{
								firstTry = false;
								delete image;
							}
							else
							{
								output_->selectAll();
								output_->textCursor().insertText( "[Error] Unable to read plot image \"" + filename + "\". Please retry." );
								//output_->setPlainText( "[Error] Unable to read plot image \"" + imagename + "\". Please retry." );
								break;
							}
						}
					}

					if( sleepTime > 25 )
					{
						output_->selectAll();
						output_->textCursor().insertText( "[Error] Unable to find plot image \"" + filename + "\"" );
//						output_->setPlainText( "[Error] Unable to found plot image \"" + imagename + "\"" );
						break;
					}
					
					SleeperThread::msleep( 1000 );
					sleepTime++;
				}

			}
			else
			{
*/			
			// check if resualt is empty
/*
			if( res.isEmpty() && error.isEmpty() )
					res = "[done]";

				if( !error.isEmpty() )
					res += QString("\n") + error;
			
				output_->selectAll();
				output_->textCursor().insertText( res );
				//output_->setPlainText( res );
//			}

			++numEvals_;
			dir.remove( imagename );


			contentChanged();

			//Emit that the text have changed
			emit textChanged(true);
		}
		else
			cout << "Not delegate on GraphCell" << endl;

		input_->blockSignals(false);
		output_->blockSignals(false);
*/
/*
		}


		else
			cout << "Not delegate on GraphCell" << endl;

			input_->blockSignals(false);
			output_->blockSignals(false);



	}
*/


	void GraphCell::delegateFinished()
	{

		delete sender();

		QString res = delegate()->getResult();
		QString error;

		// 2006-02-02 AF, Added try-catch
		try
		{
			error = delegate()->getError();
		}
		catch( exception &e )
		{
			exceptionInEval(e);
			input_->blockSignals(false);
			output_->blockSignals(false);

			setState(ERROR);
			return;
		}
/*
		//////////////////
			QString openmodelica( getenv( "OPENMODELICAHOME" ) );
			if( openmodelica.isEmpty() )
				QMessageBox::critical( 0, "OpenModelica Error", "Could not find environment variable OPENMODELICAHOME; OMNotebook will therefore not work correctly" );
	
			if( openmodelica.endsWith("/") || openmodelica.endsWith( "\\") )
				openmodelica += "bin/";
			else
				openmodelica += "/bin/";

			QDir dir;
			dir.setPath( openmodelica );
			QString imagename = "omc_tmp_plot.png";

			QString filename = dir.absolutePath();
			if( !filename.endsWith( "/" ) )
				filename += "/";
			filename += imagename;

		if( isPlot() && error.isEmpty() )
			{	
				output_->selectAll();
				output_->textCursor().insertText( "{creating plot}" );
				//output_->setPlainText( "{creating plot}" );
				output_->update();
				QCoreApplication::processEvents();

				
				int sleepTime = 1;
				bool firstTry = true;
				while( true )
				{
					if( dir.exists( imagename ))
					{
						QImage *image = new QImage( filename );
						if( !image->isNull() )
						{
							QString newname = document_->addImage( image );
							QTextCharFormat format = output_->currentCharFormat();
																				
							QTextImageFormat imageformat;
							imageformat.merge( format );
							imageformat.setHeight( image->height() );
							imageformat.setWidth( image->width() );
							imageformat.setName( newname );

							output_->selectAll();
							//output_->textCursor().insertText( "{Plot - Generated by PtPlot}" );
							//output_->setPlainText("{Plot}\n");
							QTextCursor outCursor = output_->textCursor();
							//outCursor.movePosition( QTextCursor::End );
							outCursor.insertImage( imageformat );
							break;
						}
						else
						{
							if( firstTry )
							{
								firstTry = false;
								delete image;
							}
							else
							{
								output_->selectAll();
								output_->textCursor().insertText( "[Error] Unable to read plot image \"" + filename + "\". Please retry." );
								//output_->setPlainText( "[Error] Unable to read plot image \"" + imagename + "\". Please retry." );
								break;
							}
						}
					}

					if( sleepTime > 25 )
					{
						output_->selectAll();
						output_->textCursor().insertText( "[Error] Unable to find plot image \"" + filename + "\"" );
//						output_->setPlainText( "[Error] Unable to found plot image \"" + imagename + "\"" );
						break;
					}
					
					SleeperThread::msleep( 1000 );
					sleepTime++;
				}

			}
			else
			{
///////////////
*/

		if( res.isEmpty() && error.isEmpty() )
		{
			res = "[done]";
			setState(FINISHED);
		}

		if( !error.isEmpty() )
		{
			setState(ERROR);
			res += QString("\n") + error;
		}
		else
			setState(FINISHED);
		


		QRegExp e("([\\d]+:[\\d]+-[\\d]+:[\\d]+)|([\\d]+:[\\d]+)");		

		bool b;
		int p=0;


			output_->selectAll();
			output_->textCursor().insertText( res );

		QList<QAction*> actions;
		while((p=res.indexOf(e, p)) > 0)
		{

			QTextCharFormat f;
			f.setAnchor(true);




			if(e.cap(1).size() > e.cap(2).size())
			{
				f.setAnchorHref(e.cap(1));
				QTextCursor c(output_->textCursor());
				c.setPosition(p);
				c.setPosition(p+=e.cap(1).size(), QTextCursor::KeepAnchor);


				f.setAnchor(true);
				f.setFontUnderline(true);
				c.mergeCharFormat(f);
				c.setPosition(output_->toPlainText().size());
				output_->setTextCursor(c);

				
				MyAction* a = new MyAction(e.cap(1), 0);
				connect(a, SIGNAL(triggered()), a, SLOT(triggered2()));
				connect(a, SIGNAL(urlClicked(const QUrl&)), output_, SIGNAL(anchorClicked(const QUrl&)));
				actions.push_back(a);
			}
			else
			{
				f.setAnchorHref(e.cap(2));
				QTextCursor c(output_->textCursor());
				c.setPosition(p);
				c.setPosition(p+=e.cap(2).size(), QTextCursor::KeepAnchor);


				f.setAnchor(true);
				f.setFontUnderline(true);
				c.mergeCharFormat(f);
				c.setPosition(output_->toPlainText().size());
				output_->setTextCursor(c);

				MyAction* a = new MyAction(e.cap(2), 0);
				connect(a, SIGNAL(triggered()), a, SLOT(triggered2()));
				connect(a, SIGNAL(urlClicked(const QUrl&)), output_, SIGNAL(anchorClicked(const QUrl&)));
				actions.push_back(a);				

/*


				f.setAnchorName(e.cap(2));
				output_->textCursor().setPosition(p);
				output_->textCursor().setPosition(p+e.cap(2).size(), QTextCursor::KeepAnchor);
//				output_->textCursor().mergeBlockCharFormat(f);
		output_->textCursor().charFormat().setAnchor(true);
//				output_->textCursor().mergeCharFormat(f);
*/

			}

	
//		output_->setCurrentCharFormat(f);
//			output_->textCursor().setBlockCharFormat(f);



		}
			emit setStatusMenu(actions);
		/*
		else
		{
			output_->selectAll();
			output_->textCursor().insertText( res );

		}
*/
		//		QMessageBox::information(0, QVariant(res.indexOf(e2)).toString(), QVariant(res.indexOf(e)).toString());
		//output_->setPlainText( res );
		//			}

		++numEvals_;
//		dir.remove( imagename );
			//} ////fjass

		contentChanged();

		//Emit that the text have changed
		emit textChanged(true);
	}
	/*! 
	 * \author Anders Fernström
	 * \date 2006-02-02
	 * \date 2006-02-09 (update)
	 *
	 *\brief Method for handleing exceptions in eval()
	 */

	void GraphCell::setState(int state_)
	{
		input_->state = state_;
		switch(state_)
		{
		case MODIFIED:
			emit newState("Ready");
			break;
		case EVAL:
			emit newState("Evaluating...");
			break;
		case FINISHED:
			emit newState("Done");
			break;
		case ERROR:
			emit newState("Error");
			break;

		}


	}


	void GraphCell::exceptionInEval(exception &e)
	{
		// 2006-0-09 AF, try to reconnect to OMC first.
		try
		{
			delegate_->closeConnection();
			delegate_->reconnect();
			eval();
		}
		catch( exception &e )
		{
			// unable to reconnect, ask if user want to restart omc.
			QString msg = QString( e.what() ) + "\n\nUnable to reconnect with OMC. Do you want to restart OMC?";
			int result = QMessageBox::critical( 0, tr("Communication Error with OMC"),
				msg, 
				QMessageBox::Yes | QMessageBox::Default,
				QMessageBox::No );

			if( result == QMessageBox::Yes )
			{
				delegate_->closeConnection();
				if( delegate_->startDelegate() )
				{
					// 2006-03-14 AF, wait before trying to reconnect, 
					// give OMC time to start up
					SleeperThread::msleep( 1000 );
 
					//delegate_->closeConnection();
					try
					{
						delegate_->reconnect();
						eval();
					}
					catch( exception &e )
					{
						QMessageBox::critical( 0, tr("Communication Error"),
							tr("<B>Unable to communication correctlly with OMC.</B>") );
					}
				}
			}
		}
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-12-15
	 *
	 *\brief Get/Insert the command that match the last word in the 
	 * input editor.
	 */
	void GraphCell::command()
	{
		CommandCompletion *commandcompletion = CommandCompletion::instance( "commands.xml" );
		QTextCursor cursor = input_->textCursor();
		
		if( commandcompletion->insertCommand( cursor ))
			input_->setTextCursor( cursor );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-12-15
	 *
	 *\brief Get/Insert the next command that match the last word in 
	 * the input editor.
	 */
	void GraphCell::nextCommand()
	{
		qDebug("Next Command");
		CommandCompletion *commandcompletion = CommandCompletion::instance( "commands.xml" );
		QTextCursor cursor = input_->textCursor();
		
		if( commandcompletion->nextCommand( cursor ))
			input_->setTextCursor( cursor );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-12-15
	 *
	 *\brief Select the next field in the command, if any exists
	 */
	void GraphCell::nextField()
	{
		qDebug("Next Field");
		CommandCompletion *commandcompletion = CommandCompletion::instance( "commands.xml" );
		QTextCursor cursor = input_->textCursor();
		
		if( commandcompletion->nextField( cursor ))
			input_->setTextCursor( cursor );
	}

	/*!
	 * \author Anders Fernström
	 * \date 2005-12-29
	 * \date 2006-01-16 (update)
	 *
	 * \breif adds the input text editor to the highlighter thread
	 * when text have changed.
	 *
	 * 2006-01-16 AF, don't add text editor if MyTextEdit2 says NO
	 */
	void GraphCell::addToHighlighter()
	{
//		QMessageBox::information(0, "uu3", "addToHighlighter");
		emit textChanged(true);
		if( input_->toPlainText().isEmpty() )
			return;

		// 2006-01-16 AF, Don't add the text editor if MyTextEdit2 
		// don't allow it. MyTextEdit2 says no if the user removes
		// text (backspace or delete).
		if( dynamic_cast<MyTextEdit2 *>(input_)->isStopingHighlighter() )
			return;

//		QMessageBox::information(0,"uu3", "add2");
		
		HighlighterThread *thread = HighlighterThread::instance();
		thread->addEditor( input_ );
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-01-17
	 *
	 * \breif set the correct style if the charFormat is changed and the
	 * cell is empty. This is done because otherwise the style is lost if
	 * all text is removed inside a cell.
	 */
	void GraphCell::charFormatChanged(const QTextCharFormat &)
	{
		//if( input_->toPlainText().isEmpty() )
		//{
			input_->blockSignals( true );
			input_->setAlignment( (Qt::AlignmentFlag)style_.alignment() );
			input_->mergeCurrentCharFormat( (*style_.textCharFormat()) );
			input_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );
			input_->blockSignals( false );
			contentChanged();
		//}
	}




	// ***************************************************************


	/*! \brief Sets the evaulator delegate.
	*/
	void GraphCell::setDelegate(InputCellDelegate *d)
	{
		delegate_ = d;
	}

	InputCellDelegate *GraphCell::delegate()
	{
		if(!hasDelegate())
			throw runtime_error("No delegate.");

		return delegate_;
	}



	bool GraphCell::hasDelegate()
	{
		return delegate_ != 0;
	}








	

	/*! \brief Do not use this member.
	*
	* This is an ugly part of the cell structure.
	*/
	void GraphCell::addCellWidgets()
	{
		layout_->addWidget(input_,0,0);	 

		if(evaluated_)
			layout_->addWidget(output_,1,0);
	}

	void GraphCell::removeCellWidgets()
	{
		/*
		// PORT >> layout_->remove(input_);
		if(evaluated_)
			layout_->remove(output_);
			*/

		layout_->removeWidget(input_);
		if(evaluated_)
			layout_->removeWidget(output_);
	}

	/*! \brief resets the input cell. Removes all output data and
	*  restores the initial state.
	*/
	void GraphCell::clear()
	{
		if(evaluated_)
		{
			output_->clear();
			evaluated_ = false;
			// PORT >> layout_->remove(output_);
			layout_->removeWidget(output_);
		}

		//input_->setReadOnly(false);
		input_->setReadOnly(true);
		input_->clear();
		treeView()->setClosed(false); //Notis this
		setClosed(true);
	}

	/*!
	* Resize textcell when the mainwindow is resized. This because the
	* cellcontent should always be visible.
	*
	* Added by AF, copied from textcell.cpp
	*/
	void GraphCell::resizeEvent(QResizeEvent *event)
	{
		contentChanged(); 
		Cell::resizeEvent(event);
	}




	


	void GraphCell::mouseDoubleClickEvent(QMouseEvent *)
	{
		// PORT >>if(treeView()->hasMouse())
		if(treeView()->testAttribute(Qt::WA_UnderMouse))
		{
			setClosed(!closed_);
		}
	}

	void GraphCell::accept(Visitor &v)
	{
		v.visitGraphCellNodeBefore(this);

		if(hasChilds())
			child()->accept(v);

		v.visitGraphCellNodeAfter(this);

		if(hasNext())
			next()->accept(v);
	}

}
