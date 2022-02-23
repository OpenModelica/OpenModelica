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
 * \file inputcell.cpp
 * \author Ingemar Axelsson and Anders Fernström
 * \date 2005-10-27 (update)
 *
 * \brief Describes an inputcell.
 */

//STD Headers
#include <exception>
#include <stdexcept>
#include <sstream>

//QT Headers
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#else
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
#endif

//IAEX Headers
#include "inputcell.h"
#include "treeview.h"
#include "stylesheet.h"
#include "commandcompletion.h"
#include "omcinteractiveenvironment.h"

namespace IAEX
{
  /*!
   * \class MyTextEdit
   * \author Anders Ferström
   * \date 2005-11-01
   *
   * \brief Extends QTextEdit. Mostly so I can catch when a user
   * clicks on the editor
   */
  MyTextEdit::MyTextEdit(QWidget *parent)
    : QTextBrowser(parent),
    inCommand(false)
  {
  }

  MyTextEdit::~MyTextEdit()
  {
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
   * changing inputcells by clicking.
   */
  void MyTextEdit::mousePressEvent(QMouseEvent *event)
  {
    inCommand = false;
    QTextBrowser::mousePressEvent(event);

    if( event->modifiers() == Qt::ShiftModifier ||
      textCursor().hasSelection() )
    {
      return;
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
  void MyTextEdit::wheelEvent(QWheelEvent * event)
  {
    // ignore event and send it up in the event hierarchy
    event->ignore();
    emit wheelMove( event );
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
  void MyTextEdit::keyPressEvent(QKeyEvent *event )
  {

    // EVAL, key: SHIFT + RETURN || SHIFT + ENTER
    if( event->modifiers() == Qt::ShiftModifier &&

      (event->key() == Qt::Key_Return || event->key() == Qt::Key_Enter) )
    {
      inCommand = false;

      event->accept();
      emit eval();
    }
    // COMMAND COMPLETION, key: SHIFT + TAB (= BACKTAB) || CTRL + SPACE
    else if( (event->modifiers() == Qt::ShiftModifier && event->key() == Qt::Key_Backtab ) ||
      (event->modifiers() == Qt::ControlModifier && event->key() == Qt::Key_Space) )
    {

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

      event->accept();
      inCommand = false;
      emit nextField();
    }
    // BACKSPACE, DELETE
    else if( event->key() == Qt::Key_Backspace ||
      event->key() == Qt::Key_Delete )
    {
      inCommand = false;

      QTextBrowser::keyPressEvent( event );
    }
    // ALT+ENTER (ignore)
    else if( event->modifiers() == Qt::AltModifier &&
      ( event->key() == Qt::Key_Enter || event->key() == Qt::Key_Return ))
    {
      inCommand = false;

      event->ignore();
    }
    // PAGE UP (ignore)
    else if( event->key() == Qt::Key_PageUp )
    {
      inCommand = false;

      event->ignore();
    }
    // PAGE DOWN (ignore)
    else if( event->key() == Qt::Key_PageDown )
    {
      inCommand = false;

      event->ignore();
    }
    // CTRL+C
    else if( event->modifiers() == Qt::ControlModifier &&
      event->key() == Qt::Key_C )
    {
      inCommand = false;

      event->ignore();
      emit forwardAction( 1 );
    }
    // CTRL+X
    else if( event->modifiers() == Qt::ControlModifier &&
      event->key() == Qt::Key_X )
    {
      inCommand = false;

      event->ignore();
      emit forwardAction( 2 );
    }
    // CTRL+V
    else if( event->modifiers() == Qt::ControlModifier &&
      event->key() == Qt::Key_V )
    {
      inCommand = false;

      event->ignore();
      emit forwardAction( 3 );
    }

    // TAB
    else if( event->key() == Qt::Key_Tab )
    {
      inCommand = false;

            textCursor().insertText( "  " );
    }
    else
    {
      inCommand = false;

      QTextBrowser::keyPressEvent( event );
    }
  }

  /*!
   * \author Anders Fernström
   * \date 2006-01-23
   *
   * \brief If the mimedata that should be insertet contain text,
   * create a new mimedata object that only contains text, otherwise
   * text format is insertet also - don't want that for inputcells.
   */
  void MyTextEdit::insertFromMimeData(const QMimeData *source)
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
  }

  /*!
  * \class InputCell
  * \author Ingemar Axelsson and Anders Fernström
  *
  * \brief Describes how an inputcell works.
  *
  * Input cells is places where the user can do input. To evaluate
  * the content of an inputcell just press shift+enter. It will
  * throw an exception if it cant find OMC. Start OMC with
  * following commandline:
  *
  * # omc +d=interactiveCorba
  *
  *
  * \todo Make it possiblee to add and change syntax coloring of code.(Ingemar Axelsson)
  */

  int InputCell::numEvals_ = 1;

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
  InputCell::InputCell(Document *doc, QWidget *parent)
    : Cell(parent),
    evaluated_(false),
    closed_(true),
    delegate_(0),
    oldHeight_( 0 ),
    document_(doc)
  {
    QWidget *main = new QWidget(this);
    setMainWidget(main);

    layout_ = new QGridLayout(mainWidget());
    layout_->setMargin(0);
    layout_->setSpacing(0);

    setTreeWidget(new InputTreeView(this));

    //2005-10-07 AF, Porting, change from 'QWidget::' to 'Qt::'
    setFocusPolicy(Qt::NoFocus);

    createInputCell();
    createOutputCell();

    //setBackgroundColor(QColor(200,200,255));
  }

  /*!
   * \author Ingemar Axelsson and Anders Fernström
   *
   * \brief The class destructor
   */
  InputCell::~InputCell()
  {
    delete input_;
    delete output_;
  }

  /*!
   * \author Anders Fernström and Ingemar Axelsson
   * \date 2006-03-02 (update)
   *
   * \brief Creates the QTextEdit for the input part of the
   * inputcell
   *
   * 2005-10-27 AF, Large part of this function was changes due to
   * porting to QT4 (changes from Q3TextEdit to QTextEdit).
   * 2005-12-15 AF, Added more connections to the editor, mostly for
   * commandcompletion, but also for eval. invoking eval have moved
   * from the eventfilter on this cell to the reimplemented key event
   * handler in the editor
   * 2006-03-02 AF, Added call to createChapterCounter();
   */
  void InputCell::createInputCell()
  {
    input_ = new MyTextEdit( mainWidget() );
    mpModelicaTextHighlighter = new ModelicaTextHighlighter(input_->document());
    layout_->addWidget( input_, 1, 1 );

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
//    input_->setContextMenuPolicy( Qt::NoContextMenu );

    QPalette palette;
    palette.setColor(input_->backgroundRole(), QColor(200,200,255));
    input_->setPalette(palette);

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

    contentChanged();
  }

  /*!
   * \author Anders Fernström and Ingemar Axelsson
   * \date 2005-10-28 (update)
   *
   * \brief Creates the QTextEdit for the output part of the
   * inputcell
   *
   * Large part of this function was changes due to porting
   * to QT4 (changes from Q3TextEdit to QTextEdit).
   */
  void InputCell::createOutputCell()
  {
    output_ = new MyTextEdit( mainWidget() );
    layout_->addWidget( output_, 2, 1 );

    output_->setReadOnly( true );
    //output_->setFrameShape( QFrame::Panel );
    output_->setFrameShape( QFrame::Box );
    output_->setAutoFormatting( QTextEdit::AutoNone );

    output_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
    output_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
//    output_->setContextMenuPolicy( Qt::NoContextMenu );

    connect( output_, SIGNAL( textChanged() ),
      this, SLOT(contentChanged()));
    connect( output_, SIGNAL( clickOnCell() ),
      this, SLOT( clickEventOutput() ));
    connect( output_, SIGNAL( wheelMove(QWheelEvent*) ),
      this, SLOT( wheelEvent(QWheelEvent*) ));

    connect(output_, SIGNAL(forwardAction(int)), this, SIGNAL(forwardAction(int)));

    setOutputStyle();


    output_->hide();
  }

  /*!
   * \author Anders Fernström
   * \date 2006-04-21
   *
   * \brief Set the output style
   */
  void InputCell::setOutputStyle()
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
      QMessageBox::warning( 0, tr("Warning"), tr("No Output style defined, please define an Output style in stylesheet.xml"), "OK" );
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
  void InputCell::createChapterCounter()
  {
    chaptercounter_ = new MyTextEdit(this);
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
  QString InputCell::text()
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
  QString InputCell::textHtml()
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
  QString InputCell::textOutput()
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
  QString InputCell::textOutputHtml()
  {
    return output_->toHtml();
  }

  /*!
   * \author Anders Fernström
   * \date 2005-10-27
   *
   * \brief Return the text cursor to the QTextEdit that make up
   * the inputpart of the inputcell
   *
   * \return Text cursor to the cell
   */
  QTextCursor InputCell::textCursor()
  {
    return input_->textCursor();
  }

  /*!
   * \author Anders Fernström
   * \date 2006-01-05
   *
   * \brief Return the input texteditor
   *
   * \return Texteditor for the inputpart of the inputcell
   */
  QTextEdit *InputCell::textEdit()
  {
    return input_;
  }

  /*!
   * \author Anders Fernström
   * \date 2006-02-03
   *
   * \brief Return the output texteditor
   *
   * \return Texteditor for the output part of the inputcell
   */
  QTextEdit* InputCell::textEditOutput()
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
  void InputCell::setText(QString text)
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
//      input_->document()->setHtml( input_->toHtml() );
//      input_->document()->setPlainText( input_->toPlainText() );   // This causes a crash with Qt >= 4.2
    input_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );

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
  void InputCell::setTextHtml(QString html)
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
  void InputCell::setTextOutput(QString text)
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
  void InputCell::setTextOutputHtml(QString html)
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
   * IMPORTANT: User shouldn't be able to change style on inputcells
   * so this function always use "Input" as style.
   *
   * \param stylename The style name of the style that is to be applyed to the cell
   */
  void InputCell::setStyle(const QString &)
  {
    Cell::setStyle( "Input" );
  }

  /*!
   * \author Anders Fernström
   * \date 2005-10-27
   * \date 2006-03-02 (update)
   *
   * \brief Set cell style
   *
   * IMPORTANT: User shouldn't be able to change style on inputcells
   * so this function always use "Input" as style.
   *
   * 2005-11-03 AF, updated so the text is selected when the style
   * is changed, after the text is unselected.
   * 2006-03-02 AF, set chapter style
   *
   * \param style The cell style that is to be applyed to the cell
   */
  void InputCell::setStyle(CellStyle style)
  {
    if( style.name() == "Input" )
    {
      Cell::setStyle( style );

      // select all the text
      input_->selectAll();

      // set the new style settings
      input_->setAlignment( (Qt::AlignmentFlag)style_.alignment() );
      input_->mergeCurrentCharFormat( (*style_.textCharFormat()) );
      input_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );

      // unselect the text
      QTextCursor cursor(  input_->textCursor() );
      cursor.clearSelection();
      input_->setTextCursor( cursor );

      // 2006-03-02 AF, set chapter counter style
      chaptercounter_->selectAll();
      chaptercounter_->mergeCurrentCharFormat( (*style_.textCharFormat()) );

      QTextFrameFormat format = chaptercounter_->document()->rootFrame()->frameFormat();
      format.setMargin( style_.textFrameFormat()->margin() +
      style_.textFrameFormat()->border() +
      style_.textFrameFormat()->padding()  );
      chaptercounter_->document()->rootFrame()->setFrameFormat( format );

      chaptercounter_->setAlignment( (Qt::AlignmentFlag)Qt::AlignRight );

      cursor = chaptercounter_->textCursor();
      cursor.clearSelection();
      chaptercounter_->setTextCursor( cursor );
    }
    else
    {
      setStyle( "Input" );
    }
  }

  /*!
   * \author Anders Fernström
   * \date 2006-03-02
   *
   * \brief set the chapter counter
   */
  void InputCell::setChapterCounter( QString number )
  {
    chaptercounter_->selectAll();
    chaptercounter_->setPlainText( number );
    chaptercounter_->setAlignment( (Qt::AlignmentFlag)Qt::AlignRight );
    QTextFrameFormat format = chaptercounter_->document()->rootFrame()->frameFormat();
    format.setMargin( style_.textFrameFormat()->margin() +
      style_.textFrameFormat()->border() +
      style_.textFrameFormat()->padding()  );
    chaptercounter_->document()->rootFrame()->setFrameFormat( format );
  }

  /*!
   * \author Anders Fernström
   * \date 2006-03-02
   *
   * \brief return the value of the chapter counter, as plain text.
   * Returns null if the counter is empty
   */
  QString InputCell::ChapterCounter()
  {
    if( chaptercounter_->toPlainText().isEmpty() )
      return QString();

    return chaptercounter_->toPlainText();
  }

  /*!
   * \author Anders Fernström
   * \date 2006-03-03
   *
   * \brief return the value of the chapter counter, as html code.
   * Returns null if the counter is empty
   */
  QString InputCell::ChapterCounterHtml()
  {
    if( chaptercounter_->toPlainText().isEmpty() )
      return QString();

    return chaptercounter_->toHtml();
  }

  /*!
   * \author Anders Fernström
   * \date 2005-11-01
   * \date 2006-03-02 (update)
   *
   * \brief Set readonly value on the texteditor
   *
   * \param readonly The boolean value of readonly property
   *
   * 2006-03-02 AF, clear text selection in chapter counter
   */
  void InputCell::setReadOnly(const bool readonly)
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

  /*!
   * \author Anders Fernström
   * \date 2006-01-16
   *
   * \brief Set evaluated value on the texteditor
   *
   * \param evaluated The boolean value of evaluated property
   */
  void InputCell::setEvaluated(const bool evaluated)
  {
    evaluated_ = evaluated;
  }

  /*!
   * \author Ingemar Axelsson (and Anders Fernström)
   * \date 2005-11-01 (update)
   *
   * \brief Set if the output part of the cell shoud be
   * closed(hidden) or not.
   *
   * 2005-11-01 AF, Made some small changes to how the function
   * calculate the new height, to reflect the changes made when
   * porting from Q3TextEdit to QTextEdit.
   */
  void InputCell::setClosed(const bool closed, bool update)
  {
    if( closed )
      output_->hide();
    else
    {
      if( evaluated_ )
        output_->show();
    }

    closed_ = closed;
    contentChanged();
  }

  /*!
   * \author Ingemar Axelsson and Anders Fernström
   */
  void InputCell::setFocus(const bool focus)
  {
    if(focus)
      input_->setFocus();
  }

  /*!
   * \author Anders Fernström
   */
  void InputCell::setFocusOutput(const bool focus)
  {
    if(focus)
      output_->setFocus();
  }

  /*!
   * \author Ingemar Axelsson and Anders Fernström
   */
  void InputCell::clickEvent()
  {
    //if( input_->isReadOnly() )
      emit clicked(this);
  }

  /*!
   * \author Anders Fernström
   */
  void InputCell::clickEventOutput()
  {
    emit clickedOutput(this);
  }

  /*!
   * \author Anders Fernström and Ingemar Axelsson
   * \date 2006-04-10 (update)
   *
   * \brief Recalculates height.
   *
   * 2005-10-31 AF, Large part of this function was changes due to
   * porting to QT4 (changes from Q3TextBrowser to QTextBrowser).
   * 2006-04-10 AF, emits heightChanged if the height changes
   */
  void InputCell::contentChanged()
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
    setHeight( height + 3 );
    emit textChanged();

    if( oldHeight_ != (height + 3) )
      emit heightChanged();

    oldHeight_ = height + 3;
  }

  /*!
   * \author Anders Fernström
   * \date 2006-01-17
   *
   * \brief Returns true if inputcell is closed, otherwise the method
   * returns false.
   *
   * \return State of inputcell (closed or not)
   */
  bool InputCell::isClosed()
  {
    return closed_;
  }

  /*!
   * \author Anders Fernström
   * \date 2005-10-27
   *
   * \brief Function for telling if the user is allowed to change
   * the text settings for the text inside the cell. User isn't
   * allowed to change the text settings for inputcell so this
   * function always return false.
   *
   * \return False
   */
  bool InputCell::isEditable()
  {
    return false;
  }

  /*!
   * \author Anders Fernström
   * \date 2005-11-23
   *
   * \brief Returns true if inputcell is evaluated, returns false if
   * inputcell haven't been evaluated.
   *
   * \return State of inputcell (evaluated or not)
   */
  bool InputCell::isEvaluated()
  {
    return evaluated_;
  }

  /*!
   * \author Ingemar Axelsson and Anders Fernström
   * \date 2006-04-18 (update)
   *
   *\brief Sends the content of the inputcell to the evaluator.
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
  void InputCell::eval()
  {
    input_->blockSignals(true);
    output_->blockSignals(true);

    if( hasDelegate() )
    {
      // Only the text, no html tags. /AF
      QString expr = input_->toPlainText();
      //expr = expr.simplified();

      // 2006-02-17 AF,
      evaluated_ = true;
      setClosed(false);

      // 2006-02-17 AF, set text '{evaluation expression}" during
      // evaluation of expressiuon
      output_->selectAll();
      output_->textCursor().insertText( tr("{evaluating expression}") );
      setOutputStyle();
      output_->update();
      QCoreApplication::processEvents();
      delegate()->evalExpression(expr);

      // 2005-11-24 AF, added check to see if the user wants to quit
      if( 0 == expr.indexOf( "quit()", 0, Qt::CaseSensitive ))
      {
        qApp->closeAllWindows();
        input_->blockSignals(false);
        output_->blockSignals(false);
        return;
      }

      // get the result
      QString res = delegate()->getResult();
      QString error;
      error = delegate()->getError();

      {
        // check if resualt is empty
        if( res.isEmpty() && error.isEmpty() )
          res = "[done]";

        if( !error.isEmpty() )
          res += QString("\n") + error;

        output_->selectAll();
        output_->textCursor().insertText( res );
        //output_->setPlainText( res );
      }

      ++numEvals_;

      contentChanged();

      //Emit that the text have changed
      emit textChanged(true);
    }
    else
      cout << "Not delegate on inputcell" << endl;

    input_->blockSignals(false);
    output_->blockSignals(false);
  }

  /*!
   * \author Anders Fernström
   * \date 2005-12-15
   *
   *\brief Get/Insert the command that match the last word in the
   * input editor.
   */
  void InputCell::command()
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
  void InputCell::nextCommand()
  {
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
  void InputCell::nextField()
  {
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
   * \brief adds the input text editor to the highlighter thread
   * when text have changed.
   *
   * 2006-01-16 AF, don't add text editor if MyTextEdit says NO
   */
  void InputCell::addToHighlighter()
  {
    emit textChanged(true);
  }

  /*!
   * \author Anders Fernström
   * \date 2006-01-17
   *
   * \brief set the correct style if the charFormat is changed and the
   * cell is empty. This is done because otherwise the style is lost if
   * all text is removed inside a cell.
   */
  void InputCell::charFormatChanged(const QTextCharFormat &)
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
  void InputCell::setDelegate(InputCellDelegate *d)
  {
    delegate_ = d;
  }

  InputCellDelegate *InputCell::delegate()
  {
    if(!hasDelegate())
      throw runtime_error("No delegate.");

    return delegate_;
  }



  bool InputCell::hasDelegate()
  {
    return delegate_ != 0;
  }


  /*! \brief Do not use this member.
  *
  * This is an ugly part of the cell structure.
  */
  void InputCell::addCellWidgets()
  {
    layout_->addWidget(input_,0,0);

    if(evaluated_)
      layout_->addWidget(output_,1,0);
  }

  void InputCell::removeCellWidgets()
  {
    /*
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
  void InputCell::clear()
  {
    if(evaluated_)
    {
      output_->clear();
      evaluated_ = false;
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
  void InputCell::resizeEvent(QResizeEvent *event)
  {
    contentChanged();
    Cell::resizeEvent(event);
  }

  void InputCell::mouseDoubleClickEvent(QMouseEvent *)
  {
    if(treeView()->testAttribute(Qt::WA_UnderMouse))
    {
      setClosed(!closed_);
    }
  }

  void InputCell::accept(Visitor &v)
  {
    v.visitInputCellNodeBefore(this);

    if(hasChilds())
      child()->accept(v);

    v.visitInputCellNodeAfter(this);

    if(hasNext())
      next()->accept(v);
  }

}
