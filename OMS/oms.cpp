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
 * \file otherdlg.h
 * \author Anders Fernström
 * \date 2005-11-10 (created)
 */


#ifdef WIN32
#include "windows.h"
#endif

//STD Headers
#include <iostream>

//QT Headers
#include <QtCore/QStringList>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QFileDialog>
#include <QtGui/QFrame>
#include <QtGui/QKeyEvent>
#include <QtGui/QMenu>
#include <QtGui/QMenuBar>
#include <QtGui/QMessageBox>
#include <QtGui/QTextBlock>
#include <QtGui/QToolBar>
#include <QtGui/QScrollBar>
#include <QtGui/QStatusBar>
#include <QtGui/QVBoxLayout>

//OMS Headers 
#include "oms.h"

//IAEX Headers
#include "omcinteractiveenvironment.h"
#include "otherdlg.h"


using namespace std;

MyTextEdit::MyTextEdit( QWidget* parent )
	: QTextEdit( parent )
{
	sameTab_ = false;
}

MyTextEdit::~MyTextEdit()
{
}

void MyTextEdit::sendKey( QKeyEvent *event )
{
	keyPressEvent( event );
}

void MyTextEdit::keyPressEvent(QKeyEvent *event)
{
	if( !insideCommandSign() )
	{
		switch( event->key() )
		{
		case Qt::Key_Backspace:
		case Qt::Key_Left:
			if( !startOfCommandSign() )
				QTextEdit::keyPressEvent( event );
			sameTab_ = false;
			break;
		case Qt::Key_Enter:
		case Qt::Key_Return:
			if( event->modifiers() == Qt::ShiftModifier )
				emit insertNewline();
			else
				emit returnPressed();
			sameTab_ = false;
			break;
		case Qt::Key_Up:
			emit prevCommand();
			sameTab_ = false;
			break;
		case Qt::Key_Down:
			emit nextCommand();
			sameTab_ = false;
			break;
		case Qt::Key_Home:
			if( event->modifiers() == Qt::ShiftModifier )
				emit goHome(true);
			else
				emit goHome(false);
			sameTab_ = false;
			break;
		case Qt::Key_Tab:
			emit codeCompletion( sameTab_ );
			sameTab_ = true;
			break;
		default:
			QTextEdit::keyPressEvent( event );
			sameTab_ = false;
			break;
		}		
	}
}

bool MyTextEdit::insideCommandSign()
{
	QTextBlock block = document()->findBlock( textCursor().position() );
	if( block.isValid() )
	{
		int signPos = block.text().indexOf( ">> ", 0, Qt::CaseInsensitive );
		int blockStartPos = block.position();
		int cursorPos = textCursor().position();
		if( blockStartPos <= cursorPos && cursorPos < (blockStartPos+3) && signPos == 0)
		{
			cerr << "Inside Command Sign" << endl;
			cerr << "BlockStart: " << blockStartPos << 
				", Cursor: " << cursorPos << endl << endl;

			return true;
		}
		else
			return false;
	}
	else
		cerr << "Not a valid QTextBlock (insideCommandSign)" << endl;

	return true;
}

bool MyTextEdit::startOfCommandSign()
{
	QTextBlock block = document()->findBlock( textCursor().position() );
	if( block.isValid() )
	{
		int signPos = block.text().indexOf( ">> ", 0, Qt::CaseInsensitive );
		int blockStartPos = block.position();
		int cursorPos = textCursor().position();
		if( cursorPos == (blockStartPos+3) && signPos == 0 )
			return true;
		else
			return false;
	}
	else
		cerr << "Not a valid QTextBlock (startOfCommandSign)" << endl;

	return true;
}

// ADDED 2006-01-30
// If the mimedata that should be insertet contain text,
// create a new mimedata object that only contains text, otherwise
// text format is insertet also - don't want that for inputcells.
void MyTextEdit::insertFromMimeData(const QMimeData *source)
{
	if( source->hasText() )
	{
		QMimeData *newSource = new QMimeData();
		newSource->setText( source->text() );
		QTextEdit::insertFromMimeData( newSource );
		delete newSource;
	}
	else
		QTextEdit::insertFromMimeData( source );
}




// ******************************************************


OMS::OMS( QWidget* parent )
	: QMainWindow( parent )
{
	delegate_ = 0;

	mainFrame_ = new QFrame();
	mainFrame_->setFrameShadow( QFrame::Sunken );
	mainFrame_->setFrameShape( QFrame::Panel );
	mainFrame_->setSizePolicy( QSizePolicy(
		QSizePolicy::Expanding, QSizePolicy::Expanding ));
	setCentralWidget( mainFrame_ );

	// set frame backgroundcolor
	QPalette palette;
	palette.setColor( QPalette::Base, QColor(255,255,255) );
	mainFrame_->setPalette( palette );

	layout_ = new QVBoxLayout( mainFrame_ );
	layout_->setMargin( 0 );
	layout_->setSpacing( 5 );

	fontSize_ = 11;
	createMoshEdit();
	createMoshError();
	createAction();
	createMenu();
	createToolbar();

	// start server
	startServer();

	// windows stuff
	resize( 800, 600 );
	setWindowTitle( tr("OMS - OpenModelica Shell") );
	setWindowIcon( QIcon(":/Resources/OMS.bmp") );
	statusBar()->showMessage( tr("Ready") );

	connect( this, SIGNAL( emitQuit() ),
		qApp, SLOT( quit() ));

	// sett start message
	cursor_.insertText( "OpenModelica 1.3.2\n" );
	cursor_.insertText( "Copyright 2002-2006, PELAB, Linkoping University\n\n" );
	cursor_.insertText( "To get help on using OMS and OpenModelica, type \"help()\" and press enter.\n" );


	// add function names for code completion
	currentFunction_ = -1;
	currentFunctionName_ = "";
	functionList_ = new QStringList();
	functionList_->push_back( "cd()" );
	functionList_->push_back( "cd(dir)" );
	functionList_->push_back( "clear()" );
	functionList_->push_back( "clearVariables()" );
	functionList_->push_back( "help()" );
	functionList_->push_back( "instantiateModel(modelname)" );
	functionList_->push_back( "list()" );
	functionList_->push_back( "list(modelname)" );
	functionList_->push_back( "loadFile(strFile)" );
	functionList_->push_back( "loadModel(name)" );
	functionList_->push_back( "listVariables()" );
	functionList_->push_back( "plot(vars)" );
	functionList_->push_back( "readFile(str)" );
	functionList_->push_back( "readSimulationResultSize(strFile)" );
	functionList_->push_back( "readSimulationResult(strFile, variables, size)" );
	functionList_->push_back( "runScript(strFile)" );
	functionList_->push_back( "saveModel(strFile, modelname)" );
	functionList_->push_back( "simulate(modelname, startTime=0, stopTime=1)" );
	functionList_->push_back( "system(str)" );
	functionList_->push_back( "timing(expr)" );
	functionList_->push_back( "typeOf(variable)" );

	// command stuff
	commandSignFormat_.setFontFamily( "Arial" );
	commandSignFormat_.setFontWeight( QFont::Bold );
	commandSignFormat_.setFontPointSize( fontSize_ );

	commands_ = new QStringList();
	currentCommand_ = -1;
	addCommandLine();
}

OMS::~OMS()
{
	try 
	{
		if( delegate_ )
			delegate_->evalExpression( QString("quit()") );
	}
	catch(exception e) 
	{}


	delete mainFrame_;
	delete delegate_;
	delete commands_;
	delete functionList_;

	delete fileMenu_;
	delete editMenu_;
	delete viewMenu_;
	delete helpMenu_;
	delete loadModel_;
	delete loadModelicaLibrary_;
	delete exit_;
	delete cut_;
	delete copy_;
	delete paste_;
	delete font_;
	delete viewToolbar_;
	delete viewStatusbar_;
	delete aboutOMS_;
	delete print_;
	delete startServer_;
	delete stopServer_;
	delete clearWindow_;

	delete toolbar_;
}

void OMS::createMoshEdit()
{
	moshEdit_ = new MyTextEdit( mainFrame_ );
	layout_->addWidget( moshEdit_ );
	cursor_ = moshEdit_->textCursor();

	moshEdit_->setReadOnly( false );
	moshEdit_->setFrameShadow( QFrame::Plain );
	moshEdit_->setFrameShape( QFrame::Panel );
	moshEdit_->setAutoFormatting( QTextEdit::AutoNone );

	moshEdit_->setSizePolicy( QSizePolicy(
		QSizePolicy::Expanding, QSizePolicy::Expanding ));
	moshEdit_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
	moshEdit_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOn );
	moshEdit_->setContextMenuPolicy( Qt::NoContextMenu );

	// text settings
	moshEdit_->setFontFamily( "Courier New" );
	moshEdit_->setFontWeight( QFont::Normal );
	moshEdit_->setFontPointSize( fontSize_ );

	connect( moshEdit_, SIGNAL( returnPressed() ), 
		this, SLOT( returnPressed() ));
	connect( moshEdit_, SIGNAL( insertNewline() ), 
		this, SLOT( insertNewline() ));
	connect( moshEdit_, SIGNAL( prevCommand() ), 
		this, SLOT( prevCommand() ));
	connect( moshEdit_, SIGNAL( nextCommand() ), 
		this, SLOT( nextCommand() ));
	connect( moshEdit_, SIGNAL( goHome(bool) ), 
		this, SLOT( goHome(bool) ));
	connect( moshEdit_, SIGNAL( codeCompletion(bool) ),
		this, SLOT( codeCompletion(bool) ));
}

void OMS::createMoshError()
{
	moshError_ = new QTextEdit( mainFrame_ );
	layout_->addWidget( moshError_ );

	moshError_->setReadOnly( true );
	moshError_->setFrameShadow( QFrame::Plain );
	moshError_->setFrameShape( QFrame::Panel );
	moshError_->setAutoFormatting( QTextEdit::AutoNone );
	moshError_->setFixedHeight( 50 );

	moshError_->setSizePolicy( QSizePolicy(
		QSizePolicy::Expanding, QSizePolicy::Fixed ));
	moshError_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
	moshError_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOn );
	moshError_->setContextMenuPolicy( Qt::NoContextMenu );

	// set backgroundcolor
	QPalette palette;
	palette.setColor( QPalette::Base, QColor(200,200,200) );
	moshError_->setPalette( palette );

	// text settings
	moshError_->setFontFamily( "Courier New" );
	moshError_->setFontWeight( QFont::Normal );
	moshError_->setFontPointSize( fontSize_ );
}

void OMS::createAction()
{
	loadModel_ = new QAction( tr("&Load Model..."), this );
	loadModel_->setShortcut( tr("Ctrl+L") );
	loadModel_->setStatusTip( tr("Load mo-file") );
	connect( loadModel_, SIGNAL( triggered() ),
		this, SLOT( loadModel() ));

	loadModelicaLibrary_ = new QAction( tr("Load &Modelica Library"), this );
	loadModelicaLibrary_->setShortcut( tr("Ctrl+Shift+L") );
	loadModelicaLibrary_->setStatusTip( tr("Load the modelica standard llibrary") );
	connect( loadModelicaLibrary_, SIGNAL( triggered() ),
		this, SLOT( loadModelicaLibrary() ));

	exit_ = new QAction( tr("&Exit"), this );
	exit_->setShortcut( tr("Ctrl+D") );
	exit_->setStatusTip( tr("Quit the application") );
	connect( exit_, SIGNAL( triggered() ),
		this, SLOT( exit() ));

	cut_ = new QAction( QIcon(":/Resources/cut.bmp"), tr("Cu&t"), this );
	cut_->setShortcut( tr("Ctrl+X") );
	cut_->setStatusTip( tr("Cut the selection and put it on the Clipboard") );
	connect( cut_, SIGNAL( triggered() ),
		this, SLOT( cut() ));

	copy_ = new QAction( QIcon(":/Resources/copy.bmp"), tr("&Copy"), this );
	copy_->setShortcut( tr("Ctrl+C") );
	copy_->setStatusTip( tr("Copy the selection and put it on the Clipboard") );
	connect( copy_, SIGNAL( triggered() ),
		this, SLOT( copy() ));

	paste_ = new QAction( QIcon(":/Resources/paste.bmp"), tr("&Paste"), this );
	paste_->setShortcut( tr("Ctrl+V") );
	paste_->setStatusTip( tr("Insert Clipboard contents") );
	connect( paste_, SIGNAL( triggered() ),
		this, SLOT( paste() ));

	font_ = new QAction( tr("&FontSize"), this );
	font_->setStatusTip( "Select font size" );
	connect( font_, SIGNAL( triggered() ),
		this, SLOT( fontSize() ));

	viewToolbar_ = new QAction( tr("View &Toolbar"), this );
	viewToolbar_->setShortcut( tr("Ctrl+Shift+T") );
	viewToolbar_->setCheckable( true );
	viewToolbar_->setChecked( true );
	viewToolbar_->setStatusTip( tr("Show or hide the toolbar") );
	connect( viewToolbar_, SIGNAL( triggered() ),
		this, SLOT( viewToolbar() ));

	viewStatusbar_ = new QAction( tr("View &Statusbar"), this );
	viewStatusbar_->setShortcut( tr("Ctrl+Shift+S") );
	viewStatusbar_->setCheckable( true );
	viewStatusbar_->setChecked( true );
	viewStatusbar_->setStatusTip( tr("Show or hide the status bar") );
	connect( viewStatusbar_, SIGNAL( triggered() ),
		this, SLOT( viewStatusbar() ));

	aboutOMS_ = new QAction( QIcon(":/Resources/help.bmp"), tr("&About OMS"), this );
	aboutOMS_->setStatusTip( tr("Display program information, version number and copyright") );
	connect( aboutOMS_, SIGNAL( triggered() ),
		this, SLOT( aboutOMS() ));

	print_ = new QAction( QIcon(":/Resources/print.bmp"), tr("&Print"), this );
	print_->setShortcut( tr("Ctrl+P") );
	print_->setStatusTip( tr("Print the contents in the input window") );
	print_->setEnabled( false );
	connect( print_, SIGNAL( triggered() ),
		this, SLOT( print() ));

	startServer_ = new QAction( QIcon(":/Resources/start.bmp"), tr("&Start Server"), this );
	startServer_->setShortcut( tr("Alt+S") );
	startServer_->setStatusTip( tr("") );
	startServer_->setEnabled( false );
	connect( startServer_, SIGNAL( triggered() ),
		this, SLOT( startServer() ));

	stopServer_ = new QAction( QIcon(":/Resources/stop.bmp"), tr("S&top Server"), this );
	stopServer_->setShortcut( tr("Alt+Shift+S") );
	stopServer_->setStatusTip( tr("") );
	stopServer_->setEnabled( false );
	connect( stopServer_, SIGNAL( triggered() ),
		this, SLOT( stopServer() ));

	clearWindow_ = new QAction( QIcon(":/Resources/clear.bmp"), tr("Cl&ear"), this );
	clearWindow_->setShortcut( tr("Ctrl+Shift+C") );
	clearWindow_->setStatusTip( tr("Clear the input window") );
	connect( clearWindow_, SIGNAL( triggered() ),
		this, SLOT( clear() ));
}

void OMS::createMenu()
{
	// create menus
	fileMenu_ = menuBar()->addMenu( tr("&File") );
	editMenu_ = menuBar()->addMenu( tr("&Edit") );
	viewMenu_ = menuBar()->addMenu( tr("&View") );
	helpMenu_ = menuBar()->addMenu( tr("&Help") );
	

	// add actions to menus
	fileMenu_->addAction( loadModel_ );
	fileMenu_->addAction( loadModelicaLibrary_ );
	fileMenu_->addSeparator();
	fileMenu_->addAction( exit_ );

	editMenu_->addAction( cut_ );
	editMenu_->addAction( copy_ );
	editMenu_->addAction( paste_ );
	editMenu_->addSeparator();
	editMenu_->addAction( font_ );

	viewMenu_->addAction( viewToolbar_ );
	viewMenu_->addAction( viewStatusbar_ );

	helpMenu_->addAction( aboutOMS_ );
}

void OMS::createToolbar()
{
	// create toolbars
	toolbar_ = addToolBar( tr("Toolbar") );
	toolbar_->setMovable( false );


	// add actions to toolbars
	toolbar_->addAction( cut_ );
	toolbar_->addAction( copy_ );
	toolbar_->addAction( paste_ );
	toolbar_->addSeparator();
	toolbar_->addAction( print_ );
	toolbar_->addSeparator();
	toolbar_->addAction( aboutOMS_ );
	toolbar_->addSeparator();
	//toolbar_->addAction( startServer_ );
	//toolbar_->addAction( stopServer_ );
	toolbar_->addAction( clearWindow_ );
	toolbar_->addSeparator();
}

void OMS::addCommandLine()
{
	cursor_.movePosition( QTextCursor::End, QTextCursor::MoveAnchor );
	cursor_.insertBlock();
	cursor_.insertText( ">> " );
	cursor_.movePosition( QTextCursor::StartOfBlock, QTextCursor::MoveAnchor);
	cursor_.setPosition( cursor_.position()+2, QTextCursor::KeepAnchor );
	cursor_.mergeCharFormat( commandSignFormat_ );
	cursor_.clearSelection();
	cursor_.movePosition( QTextCursor::End, QTextCursor::MoveAnchor );
	moshEdit_->setTextCursor( cursor_ );

	// sett original text settings
	moshEdit_->setFontFamily( "Courier New" );
	textFormat_.setFontFamily( "Courier New" );
	moshEdit_->setFontWeight( QFont::Normal );
	textFormat_.setFontWeight( QFont::Normal );
	moshEdit_->setFontPointSize( fontSize_ );
	textFormat_.setFontPointSize( fontSize_ );

	// set correct scrollview
	moshEdit_->verticalScrollBar()->triggerAction(QAbstractSlider::SliderToMaximum);
}

void OMS::returnPressed()
{
	// find the last command sign 
	cursor_.movePosition( QTextCursor::End, QTextCursor::MoveAnchor );
	QTextBlock block = moshEdit_->document()->findBlock( cursor_.position() );
	QString commandText;
	while( true )
	{
		if( block.isValid() )
		{
			commandText = block.text() + commandText;

			if( block.text().indexOf( ">> ", 0, Qt::CaseInsensitive ) == 0 )
			{ // last command sign found, send command to OMC
				break;
			}
			else
			{ // no command sign, look in previous text block
				block = block.previous();
				commandText = "\n" + commandText;
			}
		}
		else
		{
			cerr << "Not a valid QTextBlock (returnPressed)" << endl;
			break;
		}
	}

	// strip command sign from commandText
	commandText.remove( 0, 3 );

	// save the last command
	commands_->append( commandText );
	currentCommand_ = -1;

	// remove any newline
	commandText.simplified();

	// if 'quit()' exit WinMosh
	if( commandText == "quit()" )
	{
		exit();
		return;
	}

	// send command to OMC
	if( delegate_ )
	{
		delegate_->evalExpression( commandText );
		QString res = delegate_->getResult();
			
		if( res.isEmpty() )
			cursor_.insertText( "\n" );
		else
			cursor_.insertText( "\n" + res + "\n" );

		// get Error text
		delegate_->evalExpression( QString("getErrorString()") );
		QString error = delegate_->getResult();
		if( error.size() > 2 )
		{
			QTextCursor errorCursor = moshError_->textCursor();
			errorCursor.insertText( error.mid( 1, error.size() - 3 ) + "\n" );
		}
	}
	else
	{
		QTextCursor cursor = moshError_->textCursor();
		cursor.insertText("[ERROR] No OMC serer started\n");
	}

	// add new command line
	addCommandLine();
}

void OMS::insertNewline()
{
	cursor_ = moshEdit_->textCursor();
	cursor_.insertBlock();
	moshEdit_->setTextCursor( cursor_ );
	moshEdit_->verticalScrollBar()->triggerAction(QAbstractSlider::SliderToMaximum);
}

void OMS::prevCommand()
{
	if( commands_->size() > 0 )
	{
		if( currentCommand_ < 0 )
			currentCommand_ = commands_->size() - 1;
		else
		{
			if( currentCommand_ >= 1 )
				currentCommand_--;
			else
				currentCommand_ = 0;
		}

		// select all text in the last commandline
		selectCommandLine();
		cursor_.removeSelectedText();
		cursor_.insertText( commands_->at( currentCommand_ ));
		cursor_.movePosition( QTextCursor::EndOfBlock, QTextCursor::MoveAnchor );
		moshEdit_->setTextCursor( cursor_ );
	}

	moshEdit_->verticalScrollBar()->triggerAction(QAbstractSlider::SliderToMaximum);
}

void OMS::nextCommand()
{
	if( currentCommand_ >= 0 )
	{
		if( currentCommand_ == commands_->size()-1 )
		{ // last command is currently displayed, clear the commandline
			currentCommand_ = -1;

			selectCommandLine();
			cursor_.removeSelectedText();
			cursor_.movePosition( QTextCursor::EndOfBlock, QTextCursor::MoveAnchor );
			moshEdit_->setTextCursor( cursor_ );
		}
		else
		{
			currentCommand_++;

			selectCommandLine();
			cursor_.removeSelectedText();
			cursor_.insertText( commands_->at( currentCommand_ ));
			cursor_.movePosition( QTextCursor::EndOfBlock, QTextCursor::MoveAnchor );
			moshEdit_->setTextCursor( cursor_ );
		}
	}
	else
	{
		// no erlier commands, clear the commandline..
		selectCommandLine();
		cursor_.removeSelectedText();
		cursor_.movePosition( QTextCursor::EndOfBlock, QTextCursor::MoveAnchor );
		moshEdit_->setTextCursor( cursor_ );
	}

	moshEdit_->verticalScrollBar()->triggerAction(QAbstractSlider::SliderToMaximum);
}

void OMS::goHome( bool shift )
{
	QTextBlock block = moshEdit_->document()->findBlock( cursor_.position() );
	if( block.isValid() )
	{
		cursor_ = moshEdit_->textCursor();

		if( shift )
			cursor_.setPosition( block.position() + 3, QTextCursor::KeepAnchor );
		else
			cursor_.setPosition( block.position() + 3, QTextCursor::MoveAnchor );

		moshEdit_->setTextCursor( cursor_ );
	}
	else
		cout << "Not a valid QTextBlock (selectCommandLine)" << endl;
}

void OMS::codeCompletion( bool same )
{
	cursor_ = moshEdit_->textCursor();

	if( !same )
	{
		//find last word
		cursor_.movePosition( QTextCursor::PreviousWord, QTextCursor::KeepAnchor );
		currentFunctionName_ = cursor_.selectedText();
		currentFunction_ = 0;
	}

		
	QStringList list = getFunctionNames( currentFunctionName_ );
	if( list.isEmpty() )
	{
		if( currentFunctionName_ == "> " )
			list = *functionList_;
	}

	if( !list.isEmpty() )
	{
		if( same )
		{
			if( currentFunction_ == list.size() - 1 )
				currentFunction_ = 0;
			else
				currentFunction_++;
		}

		selectCommandLine();
		cursor_.insertText( list.at( currentFunction_ ));
		moshEdit_->setTextCursor( cursor_ );
	}

	
}

QStringList OMS::getFunctionNames(QString func)
{
	QStringList list;

	for( int i = 0; i < functionList_->size(); ++i )
	{
		if( functionList_->at(i).indexOf( func, 0, Qt::CaseSensitive ) == 0 )
			list.push_back( functionList_->at(i) );
	}

	return list;
}

void OMS::selectCommandLine()
{
	cursor_.movePosition( QTextCursor::End, QTextCursor::MoveAnchor );
	QTextBlock block = moshEdit_->document()->findBlock( cursor_.position() );
	while( true )
	{
		if( block.isValid() )
		{
			if( block.text().indexOf( ">> ", 0, Qt::CaseInsensitive ) == 0 )
			{ // last command sign found, move cursor there
				cursor_.setPosition( block.position()+3, QTextCursor::KeepAnchor );
				break;
			}
			else
			{ // no command sign, look in previous text block
				block = block.previous();
			}
		}
		else
		{
			cout << "Not a valid QTextBlock (selectCommandLine)" << endl;
			break;
		}
	}

	moshEdit_->ensureCursorVisible();
}


// MENU SLOTS
// *************************************************************
void OMS::loadModel()
{
	QString filename = QFileDialog::getOpenFileName(
		this,
		"WinMosh - Load Model",
		QString::null,
		"Modelica files (*.mo)" );

	if( !filename.isNull() )
	{
		selectCommandLine();
		cursor_.removeSelectedText();
		cursor_.movePosition( QTextCursor::EndOfBlock, QTextCursor::MoveAnchor );

		cursor_.insertText( QString("loadFile(\"") + filename + QString("\")") );
		moshEdit_->update();
		returnPressed();
	}
}

void OMS::loadModelicaLibrary()
{
	selectCommandLine();
	cursor_.removeSelectedText();
	cursor_.movePosition( QTextCursor::EndOfBlock, QTextCursor::MoveAnchor );

	cursor_.insertText( "loadModel(Modelica)" );
	moshEdit_->update();
	returnPressed();
}

void OMS::exit()
{
	emit emitQuit();
}

void OMS::cut()
{
	QKeyEvent* key = new QKeyEvent( QEvent::KeyPress, Qt::Key_X, Qt::ControlModifier, "x" );
	((MyTextEdit*)moshEdit_)->sendKey( key );
}

void OMS::copy()
{
	QKeyEvent* key = new QKeyEvent( QEvent::KeyPress, Qt::Key_C, Qt::ControlModifier, "c" );
	((MyTextEdit*)moshEdit_)->sendKey( key );
}

void OMS::paste()
{
	QKeyEvent* key = new QKeyEvent( QEvent::KeyPress, Qt::Key_V, Qt::ControlModifier, "v" );
	((MyTextEdit*)moshEdit_)->sendKey( key );
}

void OMS::fontSize()
{
	IAEX::OtherDlg dlg(this, 8, 120);
	dlg.exec();

	if( dlg.value() > 0 )
	{
		fontSize_ = dlg.value();

		moshEdit_->selectAll();
		moshEdit_->setFontPointSize( fontSize_ );
		textFormat_.setFontPointSize( fontSize_ );

		//cursor_ = moshEdit_->textCursor();
		cursor_.clearSelection();
		moshEdit_->setTextCursor(cursor_);
	}
	else
	{
		QTextCursor cursor = moshError_->textCursor();
		cursor.insertText( "[ERROR] Selected fontsize not between 8 and 120.\n" );
	}
}

void OMS::viewToolbar()
{
	if( viewToolbar_->isChecked() )
		toolbar_->show();
	else
		toolbar_->hide();
}

void OMS::viewStatusbar()
{
	if( viewStatusbar_->isChecked() )
		statusBar()->show();
	else
		statusBar()->hide();
}

void OMS::aboutOMS()
{
	QMessageBox::about(this, "About OMS",
		QString("OMS v1.0 (for OpenModelica v1.3.2)\n") + 
		QString("Copyright PELAB (c) 2006") );
}

void OMS::print()
{
	// TODO: Implement print
}

void OMS::startServer()
{
	if( delegate_ == 0 )
	{

		bool omcNowStarted = false;
		try
		{
			delegate_ = new IAEX::OmcInteractiveEnvironment();
		}
		catch( exception &e )
		{

	#ifdef WIN32

			try
			{
				STARTUPINFO startinfo;
				PROCESS_INFORMATION procinfo;
				memset(&startinfo, 0, sizeof(startinfo));
				memset(&procinfo, 0, sizeof(procinfo));
				startinfo.cb = sizeof(STARTUPINFO);
				startinfo.wShowWindow = SW_MINIMIZE;
				startinfo.dwFlags = STARTF_USESHOWWINDOW;
				
				string parameter = "\"omc.exe\" +d=interactiveCorba";
				char *pParameter = new char[parameter.size() + 1];
				const char *cpParameter = parameter.c_str();
				strcpy(pParameter, cpParameter);

				bool flag = CreateProcess(NULL,pParameter,NULL,NULL,FALSE,CREATE_NEW_CONSOLE,NULL,NULL,&startinfo,&procinfo);

				Sleep(2000);

				if( !flag )
					throw std::exception("Unable to start OMC");
				else
					omcNowStarted = true;
			}
			catch( exception &e )
			{
				QString msg = e.what();
				msg += "\nWas unable to start OMC! Closeing OMS!";
				QMessageBox::warning( 0, "Error", msg, "OK" );
				std::exit(-1);
			}

	#else

			QString msg = e.what();
			msg += "\nOMC not started! Closeing OMS!";
			QMessageBox::warning( 0, "Error", msg, "OK" );
			std::exit(-1);

	#endif

		}

		if( omcNowStarted )
			delegate_ = new IAEX::OmcInteractiveEnvironment();
	}
}

void OMS::stopServer()
{
	// TODO: Implement stop server
}

void OMS::clear()
{
	moshEdit_->clear();

	// sett original text settings
	moshEdit_->setFontFamily( "Courier New" );
	moshEdit_->setFontWeight( QFont::Normal );
	moshEdit_->setFontPointSize( fontSize_ );

	cursor_ = moshEdit_->textCursor();
	cursor_.insertText( "Open Source Modelica 1.3.1\n" );
	cursor_.insertText( "Copyright 2002, PELAB, Linkoping University\n\n" );
	cursor_.insertText( "To get help on using Mosh and OpenModelica, type \"help()\" and press enter.\n" );

	addCommandLine();


	moshError_->clear();
	
	// set backgroundcolor
	QPalette palette;
	palette.setColor( QPalette::Base, QColor(200,200,200) );
	moshError_->setPalette( palette );

	// text settings
	moshError_->setFontFamily( "Courier New" );
	moshError_->setFontWeight( QFont::Normal );
	moshError_->setFontPointSize( fontSize_ );
}


