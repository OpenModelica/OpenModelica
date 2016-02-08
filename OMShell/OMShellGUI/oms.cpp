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
 * \file otherdlg.h
 * \author Anders FernstrÃ¶m
 * \date 2005-11-10 (created)
 */

// 2006-04-25 AF, removed error editor


#ifdef WIN32
#include "windows.h"
#endif

// STD Headers
#include <iostream>

//OMS Headers
#include "oms.h"

//IAEX Headers
#include "omcinteractiveenvironment.h"
#include "otherdlg.h"


using namespace std;

static QString omc_version_;
static QString omhome;
static IAEX::InputCellDelegate* delegate_;

//A small trick to get access to protected function in QThread.
class SleeperThread : public QThread
{
public:
  static void msleep(unsigned long msecs)
  {
    QThread::msleep(msecs);
  }
};

// ******************************************************

MyTextEdit::MyTextEdit( QWidget* parent )
  : QPlainTextEdit( parent )
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
        QPlainTextEdit::keyPressEvent( event );
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
      {
        if( event->modifiers() == Qt::ControlModifier )
        {
          emit codeNextField();
          sameTab_ = false;
        }
        else
        {
          emit codeCompletion( sameTab_ );
          sameTab_ = true;
        }
      }
      break;
    default:
      QPlainTextEdit::keyPressEvent( event );
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
    QPlainTextEdit::insertFromMimeData( newSource );
    delete newSource;
  }
  else
    QPlainTextEdit::insertFromMimeData( source );
}




// ******************************************************


OMS::OMS( QWidget* parent )
  : QMainWindow( parent ), mpSettings(getApplicationSettings())
{
  delegate_ = 0;
  omc_version_ = "(version)";
  statusBar();

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

  mpSettings->sync();
  if (mpSettings->contains("FontSize"))
    fontSize_ = mpSettings->value("FontSize").toInt();
  else
    fontSize_ = 11;
  createMoshEdit();
  //createMoshError();
  createAction();
  createMenu();

//  connect( this, SIGNAL( emitQuit() ),
//    qApp, SLOT( quit() ));

  // start server
  startServer();

  // windows stuff
  resize( 800, 600 );
  setWindowTitle( tr("OMShell - OpenModelica Shell") );
  setWindowIcon( QIcon(":/Resources/omshell-large.svg") );

  // set start message
  const char* dateStr = __DATE__; // "Mmm dd yyyy", so dateStr+7 = "yyyy"
  copyright_info_ = QString("OMShell 1.1 Copyright Open Source Modelica Consortium (OSMC) 2002-") + (dateStr+7) + "\nDistributed under OMSC-PL and GPL, see www.openmodelica.org\n\nConnected to " + omc_version_;
  cursor_.insertText( copyright_info_, textFormat_ );
  cursor_.insertText( tr("\nTo get help on using OMShell and OpenModelica, type \"help()\" and press enter.\n"), textFormat_ );


  // create command compleation instance
  QString openmodelica( omhome );
  if( openmodelica.isEmpty() )
    QMessageBox::critical( 0, "OMShell Error", "Could not find environment variable OPENMODELICAHOME, command completion will not work" );

  try
  {
    QString commandfile;
    if( openmodelica.endsWith("/") || openmodelica.endsWith( "\\") )
      commandfile = openmodelica + "share/omshell/commands.xml";
    else
      commandfile = openmodelica + "/share/omshell/commands.xml";

    commandcompletion_ = IAEX::CommandCompletion::instance( commandfile );
  }
  catch( exception &e )
  {
    QString msg = e.what();
    msg += "\nCould not create command completion class!";
    QMessageBox::warning( 0, "Error", msg, "OK" );
  }

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
  delete mainFrame_;
  delete delegate_;
  delete commandcompletion_;

  delete fileMenu_;
  delete editMenu_;
  delete helpMenu_;
  delete loadModel_;
  delete loadModelicaLibrary_;
  delete exit_;
  delete font_;
  delete aboutOMS_;
  delete aboutQT_;
  delete clearWindow_;
}

void OMS::createMoshEdit()
{
  moshEdit_ = new MyTextEdit( mainFrame_ );
  layout_->addWidget( moshEdit_ );
  cursor_ = moshEdit_->textCursor();

  moshEdit_->setReadOnly( false );
  moshEdit_->setFrameShadow( QFrame::Plain );
  moshEdit_->setFrameShape( QFrame::Panel );

  moshEdit_->setSizePolicy( QSizePolicy(
    QSizePolicy::Expanding, QSizePolicy::Expanding ));
  moshEdit_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
  moshEdit_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOn );
  moshEdit_->setContextMenuPolicy( Qt::NoContextMenu );

  // text settings
  moshEdit_->document()->setDefaultFont(QFont("Courier New", fontSize_, QFont::Normal));

  textFormat_ = moshEdit_->currentCharFormat();

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
  connect( moshEdit_, SIGNAL( codeNextField() ),
    this, SLOT( codeNextField() ));
}

void OMS::createAction()
{
  loadModel_ = new QAction( tr("&Open"), this );
  loadModel_->setShortcut(QKeySequence("Ctrl+O"));
  loadModel_->setStatusTip( tr("Open mo-file") );
  connect( loadModel_, SIGNAL( triggered() ),
    this, SLOT( loadModel() ));

  loadModelicaLibrary_ = new QAction( tr("Load &Modelica Library"), this );
  loadModelicaLibrary_->setShortcut(QKeySequence("Ctrl+L"));
  loadModelicaLibrary_->setStatusTip( tr("Load the Modelica Standard Library") );
  connect( loadModelicaLibrary_, SIGNAL( triggered() ),
    this, SLOT( loadModelicaLibrary() ));

  exit_ = new QAction( tr("&Exit"), this );
  exit_->setShortcut(QKeySequence("Ctrl+D"));
  exit_->setStatusTip( tr("Quit the application") );
  connect( exit_, SIGNAL( triggered() ),
    this, SLOT( close() ));

  cut_ = new QAction( tr("Cu&t"), this );
  cut_->setShortcut(QKeySequence("Ctrl+X"));
  cut_->setStatusTip( tr("Cut the selection") );
  connect( cut_, SIGNAL( triggered() ),
    this, SLOT( cut() ));

  copy_ = new QAction( tr("&Copy"), this );
  copy_->setShortcut(QKeySequence("Ctrl+C"));
  copy_->setStatusTip( tr("Copy the selection") );
  connect( copy_, SIGNAL( triggered() ),
    this, SLOT( copy() ));

  paste_ = new QAction( tr("&Paste"), this );
  paste_->setShortcut(QKeySequence("Ctrl+V"));
  paste_->setStatusTip( tr("Insert from clipboard") );
  connect( paste_, SIGNAL( triggered() ),
    this, SLOT( paste() ));


  font_ = new QAction( tr("&FontSize"), this );
  font_->setStatusTip( "Select font size" );
  connect( font_, SIGNAL( triggered() ),
    this, SLOT( fontSize() ));

  aboutOMS_ = new QAction( tr("&About OMShell"), this );
  aboutOMS_->setStatusTip( tr("About this application") );
  connect( aboutOMS_, SIGNAL( triggered() ),
    this, SLOT( aboutOMS() ));

  // Added 2006-02-21 AF
  aboutQT_ = new QAction( tr("About &Qt"), this );
  aboutQT_->setStatusTip( tr("About Qt") );
  connect( aboutQT_, SIGNAL( triggered() ),
    this, SLOT( aboutQT() ));

  clearWindow_ = new QAction( tr("Cl&ear"), this );
  clearWindow_->setShortcut(QKeySequence("Ctrl+Shift+C"));
  clearWindow_->setStatusTip( tr("Clear the input window") );
  connect( clearWindow_, SIGNAL( triggered() ),
    this, SLOT( clear() ));
}

void OMS::createMenu()
{
  // create menus
  fileMenu_ = menuBar()->addMenu( tr("&File") );
  editMenu_ = menuBar()->addMenu( tr("&Edit") );
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
  editMenu_->addAction( clearWindow_ );
  editMenu_->addSeparator();
  editMenu_->addAction( font_ );

  helpMenu_->addAction( aboutOMS_ );
  helpMenu_->addAction( aboutQT_ );
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

  // set original text settings
  moshEdit_->document()->setDefaultFont(QFont("Courier New", fontSize_, QFont::Normal));
  textFormat_.setFontFamily( "Courier New" );
  textFormat_.setFontWeight( QFont::Normal );
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
    close();
    return;
  }

  // send command to OMC
  if( delegate_ )
  {
eval:
    // 2006-02-02 AF, Added try-catch
    try
    {
      delegate_->evalExpression( commandText );
    }
    catch( exception &e )
    {
      exceptionInEval(e);
      return;
    }

    // get result
    QString res = delegate_->getResult();

    if( res.isEmpty() )
      cursor_.insertText( "\n", textFormat_ );
    else
      cursor_.insertText( "\n" + res + "\n", textFormat_ );

    // get Error text
    try
    {
      QString getErrorString = "getErrorString()";
      delegate_->evalExpression(getErrorString);
    }
    catch( exception &e )
    {
      exceptionInEval(e);
      return;
    }
    QString error = delegate_->getResult();
    if( error.size() > 2 )
    {
      cursor_.insertText( error.mid( 1, error.size() - 2 ) );
    }
  }
  else
  {
    if( startServer() )
    {
      cursor_.insertText("[ERROR] No OMC serer started - restarted OMC\n" );
      goto eval;
    }
    else
      cursor_.insertText("[ERROR] No OMC serer started - unable to restart OMC\n" );
  }

  // add new command line
  addCommandLine();
}

void OMS::exceptionInEval(exception &e)
{
  // 2006-0-09 AF, try to reconnect to OMC first.
  try
  {
    delegate_->closeConnection();
    delegate_->reconnect();
    returnPressed();
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
          returnPressed();
        }
        catch( exception &e )
        {
          QMessageBox::critical( 0, tr("Communication Error"),
            tr("<B>Unable to communication correctlly with OMC. OMShell will therefore close.</B>") );
          close();
        }
      }
    }
  }
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
    commandcompletion_->insertCommand( cursor_ );
    moshEdit_->setTextCursor( cursor_ );
  }
  else
  {
    commandcompletion_->nextCommand( cursor_ );
    moshEdit_->setTextCursor( cursor_ );
  }

}

void OMS::codeNextField()
{
  cursor_ = moshEdit_->textCursor();
  commandcompletion_->nextField( cursor_ );
  moshEdit_->setTextCursor( cursor_ );
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

bool OMS::exit()
{
  // check if omc is running, if so: ask if it is ok that omc also closes.
  try
  {
    if( delegate_ )
    {
      delegate_->closeConnection();
      delegate_->reconnect();

      QMessageBox *msgBox = new QMessageBox(0);
      msgBox->setWindowTitle(tr("Close OMC"));
      msgBox->setIcon(QMessageBox::Question);
      msgBox->setText(tr("OK to quit running OpenModelica Compiler process at exit?\n(Answer No if other OMShell/OMNotebook/Graphic editor is still running)"));
      msgBox->setStandardButtons(QMessageBox::Ok | QMessageBox::No | QMessageBox::Cancel);
      msgBox->setDefaultButton(QMessageBox::Ok);

      int result = msgBox->exec();

      if( result == QMessageBox::Ok )
      {
        stopServer();
        return true;
      }
      else if (result == QMessageBox::No)
      {
          return true;
      }
      else if (result == QMessageBox::Cancel)
      {
          return false;
      }
    }
  }
  catch(exception e)
  {}
}

void OMS::fontSize()
{
  IAEX::OtherDlg dlg(this, 8, 120);
  dlg.exec();

  if( dlg.value() > 0 )
  {
    fontSize_ = dlg.value();

    moshEdit_->selectAll();
    QFont font = moshEdit_->document()->defaultFont();
    font.setPointSize(fontSize_);
    moshEdit_->document()->setDefaultFont(font);
    textFormat_.setFontPointSize( fontSize_ );
    commandSignFormat_.setFontPointSize( fontSize_ );

    //cursor_ = moshEdit_->textCursor();
    cursor_.clearSelection();
    moshEdit_->setTextCursor(cursor_);

    mpSettings->setValue("FontSize", fontSize_);
    mpSettings->sync();
  }
  else
  {
    cursor_.movePosition( QTextCursor::End );
    cursor_.insertText( tr("[ERROR] Selected fontsize not between 8 and 120.\n") );
  }
}

void OMS::aboutOMS()
{
  QMessageBox::about(this, "About OMShell", copyright_info_ );
}

void OMS::aboutQT()
{
  QMessageBox::aboutQt( this );
}

void OMS::print()
{
  // TODO: Implement print
}

bool OMS::startServer()
{
  bool omcNowStarted = false;
  QString getVersionStr = "getVersion()";
  QString getOMHomeStr = "getInstallationDirectoryPath()";

  if( delegate_ == 0 )
  {
    try
    {
      delegate_ = new IAEX::OmcInteractiveEnvironment();
      omcNowStarted = true;

      // get version no
      delegate_->evalExpression( getVersionStr );
      omc_version_ = delegate_->getResult();
      omc_version_.remove( "\"" );
      // get omhome
      delegate_->evalExpression( getOMHomeStr );
      omhome = delegate_->getResult();
      omhome.remove( "\"" );
    }
    catch( exception &e )
    {
      if( !IAEX::OmcInteractiveEnvironment::startOMC() )
      {
        QMessageBox::critical( 0, "OMC Error", "Was unable to start OMC, therefore OMShell will not work correctly." );
      }
      else
      {
        // 2006-03-14 AF, wait before trying to reconnect,
        // give OMC time to start up
        SleeperThread::msleep( 3000 );

        delegate_ = new IAEX::OmcInteractiveEnvironment();
        omcNowStarted = true;

        // get version no
        QString getTempStr = "getTempDirectoryPath()";
        delegate_->evalExpression( getTempStr );
        QString tmpDir = delegate_->getResult()+"/OpenModelica/";
        tmpDir.remove("\"");
        if (!QDir().exists(tmpDir)) QDir().mkdir(tmpDir);
        tmpDir = "cd(\"" + tmpDir + "\")";
        cout << "Temp.Dir " << tmpDir.toStdString() << std::endl;
        delegate_->evalExpression(tmpDir);
        cout << "cdToTempDir: " << delegate_->getResult().toStdString() << std::endl;

        QString getVersionStr = "getVersion()";
        delegate_->evalExpression( getVersionStr );
        omc_version_ = delegate_->getResult();
        omc_version_.remove( "\"" );
        cout << "OMC version " << omc_version_.toStdString() << std::endl;

        // get omhome
        delegate_->evalExpression( getOMHomeStr );
        omhome = delegate_->getResult();
        omhome.remove( "\"" );
        cout << "OPENMODELICAHOME: " << omhome.toStdString() << std::endl;
      }
    }
  }

  return omcNowStarted;
}

void OMS::stopServer()
{
  if( delegate_ )
  {
    QString quit = "quit()";
    delegate_->evalExpression( quit );
  }
}

void OMS::clear()
{
  moshEdit_->clear();

  // set original text settings
  moshEdit_->document()->setDefaultFont(QFont("Courier New", fontSize_, QFont::Normal));

  addCommandLine();
}

void OMS::closeEvent( QCloseEvent *event )
{
  if (exit())
      event->accept();
  else
      event->ignore();
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

QString OMS::organization = "openmodelica";  /* case-sensitive string. Don't change it. Used by ini settings file. */
QString OMS::application = "omshell"; /* case-sensitive string. Don't change it. Used by ini settings file. */
QString OMS::utf8 = "UTF-8";

QSettings* OMS::getApplicationSettings()
{
  static int init = 0;
  static QSettings *pSettings;
  if (!init) {
    init = 1;
    pSettings = new QSettings(QSettings::IniFormat, QSettings::UserScope, organization, application);
    pSettings->setIniCodec(utf8.toStdString().data());
  }
  return pSettings;
}

