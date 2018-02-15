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
#include <QAction>
#include <QActionGroup>
#include <QTextDocumentFragment>
#include <QTextStream>
#include <QRegExp>
#include <QPushButton>
#endif

//IAEX Headers
#include "graphcell.h"
#include "treeview.h"
#include "stylesheet.h"
#include "commandcompletion.h"
#include "omcinteractiveenvironment.h"
#include "indent.h"

//#include "evalthread.h"

using namespace OMPlot;

namespace IAEX {

  /*!
  * \class LineNumberArea
  * \author Henning Kiel
  * \date 2017-06-09
  *
  * \brief From Qt example code to have a line number area in QPlainTextEdit class
  */
  class LineNumberArea : public QWidget
  {
  public:
    LineNumberArea(MyTextEdit2a *editor) : QWidget(editor) {
      codeEditor = editor;
    }

    QSize sizeHint() const override {
      return QSize(codeEditor->lineNumberAreaWidth(), 0);
    }

  protected:
    void paintEvent(QPaintEvent *event) override {
      codeEditor->lineNumberAreaPaintEvent(event);
    }

  private:
    MyTextEdit2a *codeEditor;
  };

  /*!
  * \class MyTextEdit2a
  * \author Henning Kiel
  * \date 2017-06-09
  *
  * \brief Extends QPlainTextEdit to catch user clicks on the editor,
  * allow automatic indentation and show line numbers
  */
  MyTextEdit2a::MyTextEdit2a(QWidget *parent)
    : QPlainTextEdit(parent),
    inCommand(false),
    autoIndent(true)
  {
    lineNumberArea = new LineNumberArea(this);

    connect(this, SIGNAL(blockCountChanged(int)), this, SLOT(updateLineNumberAreaWidth(int)));
    connect(this, SIGNAL(updateRequest(QRect,int)), this, SLOT(updateLineNumberArea(QRect,int)));
    connect(this, SIGNAL(cursorPositionChanged()), this, SLOT(highlightCurrentLine()));

    updateLineNumberAreaWidth(0);
    highlightCurrentLine();
  }

  int MyTextEdit2a::lineNumberAreaWidth()
  {
    int digits = 1;
    int max = qMax(1, blockCount());
    // count digits
    while (max >= 10) {
        max /= 10;
        ++digits;
    }
    int space = 3 + fontMetrics().width(QLatin1Char('9')) * digits;

    return space;
  }

  void MyTextEdit2a::updateLineNumberAreaWidth(int /* newBlockCount */)
  {
    setViewportMargins(lineNumberAreaWidth(), 0, 0, 0);
  }

  void MyTextEdit2a::updateLineNumberArea(const QRect &rect, int dy)
  {
    if (dy) {
      lineNumberArea->scroll(0, dy);
    } else {
      lineNumberArea->update(0, rect.y(), lineNumberArea->width(), rect.height());
    }

    if (rect.contains(viewport()->rect())) {
      updateLineNumberAreaWidth(0);
    }
  }

  void MyTextEdit2a::resizeEvent(QResizeEvent *e)
  {
    QPlainTextEdit::resizeEvent(e);

    QRect cr = contentsRect();
    lineNumberArea->setGeometry(QRect(cr.left(), cr.top(), lineNumberAreaWidth(), cr.height()));
  }

  void MyTextEdit2a::highlightCurrentLine(bool highlight)
  {
    QList<QTextEdit::ExtraSelection> extraSelections;

    if (highlight && !isReadOnly() && blockCount() > 1) {
      QTextEdit::ExtraSelection selection;

      QColor lineColor = QColor(Qt::yellow).lighter(190);

      selection.format.setBackground(lineColor);
      selection.format.setProperty(QTextFormat::FullWidthSelection, true);
      selection.cursor = textCursor();
      selection.cursor.clearSelection();
      extraSelections.append(selection);
    }

    setExtraSelections(extraSelections);
  }

  void MyTextEdit2a::lineNumberAreaPaintEvent(QPaintEvent *event)
  {
    QPainter painter(lineNumberArea);
    painter.fillRect(event->rect(), Qt::lightGray);
    QTextBlock block = firstVisibleBlock();
    int blockNumber = block.blockNumber();
    int top = (int) blockBoundingGeometry(block).translated(contentOffset()).top();
    int bottom = top + (int) blockBoundingRect(block).height();
    while (block.isValid() && top <= event->rect().bottom()) {
      if (block.isVisible() && bottom >= event->rect().top()) {
        QString number = QString::number(blockNumber + 1);
        painter.setPen(Qt::black);
        painter.drawText(0, top, lineNumberArea->width(), fontMetrics().height(), Qt::AlignRight, number);
      }

      block = block.next();
      top = bottom;
      bottom = top + (int) blockBoundingRect(block).height();
      ++blockNumber;
    }
  }

  MyTextEdit2a::~MyTextEdit2a()
  {
    for(QMap<int, IndentationState*>::iterator i = indentationStates.begin(); i != indentationStates.end(); ++i) {
      delete i.value();
    }
  }

  void MyTextEdit2a::mousePressEvent(QMouseEvent *event)
  {
    inCommand = false;
    QPlainTextEdit::mousePressEvent(event);

    if( event->modifiers() == Qt::ShiftModifier ||
      textCursor().hasSelection() )
    {
      return;
    }

    emit clickOnCell();
    updatePosition();
    if(state != Error)
      emit setState(Modified);
    highlightCurrentLine();
  }

  void MyTextEdit2a::wheelEvent(QWheelEvent * event)
  {
    // ignore event and send it up in the event hierarchy
    event->ignore();
    emit wheelMove( event );
  }

  void MyTextEdit2a::focusInEvent(QFocusEvent* event)
  {
    emit undoAvailable(document()->isUndoAvailable());
    emit redoAvailable(document()->isRedoAvailable());
    setModified();
    highlightCurrentLine(true);
    QPlainTextEdit::focusInEvent(event);
  }

  void MyTextEdit2a::focusOutEvent(QFocusEvent* event)
  {
    emit undoAvailable(document()->isUndoAvailable());
    emit redoAvailable(document()->isRedoAvailable());
    setModified();
    highlightCurrentLine(false);
    QPlainTextEdit::focusOutEvent(event);
  }

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
    inCommand(false)
  {

  }
  MyTextEdit2::~MyTextEdit2()
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
  * changing GraphCells by clicking.
  */
  void MyTextEdit2::mousePressEvent(QMouseEvent *event)
  {
    inCommand = false;
    QTextBrowser::mousePressEvent(event);

    if( event->modifiers() == Qt::ShiftModifier ||
      textCursor().hasSelection() )
    {
      return;
    }

    emit clickOnCell();
    updatePosition();
    if(state != Error)
      emit setState(Modified);
  }

  void MyTextEdit2a::keyPressEvent(QKeyEvent *event )
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
    // COMMAND COMPLETION- NEXT FIELD, key: CTRL + TAB || SHIFT + SPACE
    else if( (event->modifiers() == Qt::ControlModifier && event->key() == Qt::Key_Tab ) ||
      (event->modifiers() == Qt::ShiftModifier && event->key() == Qt::Key_Space ) )
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

      QPlainTextEdit::keyPressEvent( event );
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
    // CTRL+E: autoindent cell
    else if(event->modifiers() == Qt::ControlModifier && event->key() == Qt::Key_E)
    {
      inCommand = false;
      indentText();
    }
    // CTRL+K: kill text until EOL
    else if(event->modifiers() == Qt::ControlModifier && event->key() == Qt::Key_K)
    {
      inCommand = false;
      QTextCursor tc(textCursor());
      int i = toPlainText().indexOf(QRegExp("\\n|$"), tc.position());

      if(i -tc.position() > 0)
        tc.setPosition(i, QTextCursor::KeepAnchor);
      else
        tc.setPosition(i +1, QTextCursor::KeepAnchor);

      tc.insertText("");
      QPlainTextEdit::keyPressEvent( event );
    }
    // TAB
    else if( event->key() == Qt::Key_Tab )
    {
      inCommand = false;
      textCursor().insertText( "  " );
    }
    else if( event->key() == Qt::Key_Enter || event->key() == Qt::Key_Return )
    {
      if(autoIndent)
      {
        QTextCursor t(textCursor());
        QString tmp, tmp2;
        int k2 = t.blockNumber();
        QTextBlock b = t.block();
        int k = b.userState();
        int prevLevel = b.text().indexOf(QRegExp("\\S"));

        while(k2 >= 0 && !indentationStates.contains(k))
        {
          tmp = b.text() + "\n" + tmp;
          b = b.previous();
          --k2;
          k = b.userState();
        }
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
          i.next = s->next;
        }

        i.indentedText();

        if(prevLevel > 2*i.level())
        {
          t.setPosition(t.block().position());
          t.setPosition(t.block().position() + prevLevel-2*(i.level()),QTextCursor::KeepAnchor);
          if(!t.selection().toPlainText().trimmed().size())
            t.insertText("");
          t.setPosition(t.block().position() + t.block().length() -1);
        }

        QPlainTextEdit::keyPressEvent(event);
        t.insertText(QString(2*i.level(), ' '));
      }
      else
        QPlainTextEdit::keyPressEvent(event);
    }
    else
    {
      inCommand = false;
      QPlainTextEdit::keyPressEvent( event );
    }

    updatePosition();
  }

  void MyTextEdit2a::setAutoIndent(bool b)
  {
    autoIndent = b;
  }

  void MyTextEdit2a::setModified()
  {
    emit setState(Modified);
  }

  void MyTextEdit2a::updatePosition()
  {
    int pos = textCursor().position();
    int row = toPlainText().left(pos).count("\n") +1;
    int col = pos - toPlainText().left(pos).lastIndexOf("\n");
    emit updatePos(row, col);
  }

  bool MyTextEdit2a::lessIndented(QString s)
  {
    QRegExp l("\\b(equation|algorithm|public|protected|else|elseif)\\b");
    return s.indexOf(l) >= 0;
  }

  void MyTextEdit2a::indentText()
  {
    Indent a(toPlainText());
    setPlainText(a.indentedText(&indentationStates));

    int i = 1;
    for(QTextBlock b =this->document()->begin(); b != this->document()->end(); b = b.next())
    {
      b.setUserState(++i);
    }
    emit textChanged();
  }

  void MyTextEdit2a::insertFromMimeData(const QMimeData *source)
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

    updatePosition();
    if(state != Error)
      emit setState(Modified);
  }

  void MyTextEdit2a::goToPos(const QUrl& u)
  {
    QRegExp e("/|\\-|:");
    int r=u.path().section(e, 1,1).toInt();
    int c=u.path().section(e, 2,2).toInt();
    int r2=u.path().section(e, 3,3).toInt();
    int c2=u.path().section(e, 4,4).toInt();

    int p = 0;
    for(int i = 1; i < r; ++i)
      p = toPlainText().indexOf("\n", p)+1;
    p += (c-1);

    QTextCursor tc(textCursor());
    tc.setPosition(p);

    int p2 = 0;
    if(r2 > 0 && ((r!=r2) || (c!=c2)))
    {
      for(int i = 1; i < r2; ++i)
        p2 = toPlainText().indexOf("\n", p2)+1;
      p2 += c2;
      tc.setPosition(p2, QTextCursor::KeepAnchor);
    }
    setTextCursor(tc);
    updatePos(r, c);
    setFocus(Qt::MouseFocusReason);
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
    // EVAL, key: SHIFT + RETURN || SHIFT + ENTER
    if( event->modifiers() == Qt::ShiftModifier &&
      (event->key() == Qt::Key_Return || event->key() == Qt::Key_Enter) )
    {
      inCommand = false;

      event->accept();
      emit eval();
    }
    // CTRL+C
    else if( event->modifiers() == Qt::ControlModifier &&
      event->key() == Qt::Key_C )
    {
      inCommand = false;

      event->ignore();
      emit forwardAction( 1 );
    }
    else
    {
      inCommand = false;
      QTextBrowser::keyPressEvent( event );
    }

    updatePosition();
  }

  void MyTextEdit2::setAutoIndent(bool b)
  {
  }

  void MyTextEdit2::setModified()
  {
    emit setState(Modified);
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
    if(state != Error)
      emit setState(Modified);
  }
  void MyAction::triggered2()
  {
    emit urlClicked(QUrl(text()));
  }

  MyAction::MyAction(const QString& text, QObject* parent): QAction(text, parent)
  {
  }

  /*!
  * \class GraphCell
  * \author Ingemar Axelsson and Anders Fernström
  *
  * \brief Describes how an GraphCell works.
  *
  * Input cells is placed where the user can do input. To evaluate
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
  GraphCell::GraphCell(Document *doc, QWidget *parent) :
   Cell(parent), evaluated_(false), closed_(true), delegate_(0),
    oldHeight_( 0 ), document_(doc), mpPlotWindow(0)
  {
    QWidget *main = new QWidget(this);
    setMainWidget(main);

    layout_ = new QGridLayout(mainWidget());
    layout_->setMargin(0);
    layout_->setSpacing(0);

    setTreeWidget(new InputTreeView(this));

    //2005-10-07 AF, Porting, change from 'QWidget::' to 'Qt::'
    setFocusPolicy(Qt::NoFocus);

    createGraphCell();
    createOutputCell();
    createPlotWindow();

    connect(output_, SIGNAL(anchorClicked(const QUrl&)), input_, SLOT(goToPos(const QUrl&)));
    connect(this, SIGNAL(plotVariables(QStringList)), this, SLOT(plotVariablesSlot(QStringList)));

    imageFile=0;
  }

  /*!
  * \author Ingemar Axelsson and Anders Fernström
  *
  * \brief The class destructor
  */
  GraphCell::~GraphCell()
  {
    delete mpPlotWindow;
    delete input_;
    delete output_;
    if(imageFile)
      delete imageFile;
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
    input_ = new MyTextEdit2a( mainWidget() );
    Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
    CellStyle style = sheet->getStyle( "Input" );
    input_->setFont(style.textCharFormat()->font());

    mpModelicaTextHighlighter = new ModelicaTextHighlighter(input_->document());
    layout_->addWidget( input_, 1, 1 );
    createChapterCounter();

    input_->setReadOnly( true );
    input_->setUndoRedoEnabled( true );
    input_->setFrameShape( QFrame::Box );
//    input_->setAutoFormatting( QTextEdit::AutoNone );

    input_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
    input_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
    //    input_->setContextMenuPolicy( Qt::NoContextMenu );

    QPalette palette;
    palette.setColor(input_->backgroundRole(), QColor(200,200,255));
    input_->setPalette(palette);

    // is this needed, don't know /AF
    input_->installEventFilter(this);

    connect( input_, SIGNAL( textChanged() ), this, SLOT( contentChanged() ));
    connect( input_, SIGNAL( clickOnCell() ), this, SLOT( clickEvent() ));
    connect( input_, SIGNAL( wheelMove(QWheelEvent*) ), this, SLOT( wheelEvent(QWheelEvent*) ));
    // 2005-12-15 AF, new connections
    connect( input_, SIGNAL( eval() ), this, SLOT( eval() ));
    connect( input_, SIGNAL( command() ), this, SLOT( command() ));
    connect( input_, SIGNAL( nextCommand() ), this, SLOT( nextCommand() ));
    connect( input_, SIGNAL( nextField() ), this, SLOT( nextField() ));
    //2005-12-29 AF
    connect( input_, SIGNAL( textChanged() ), this, SLOT( addToHighlighter() ));
    // 2006-04-27 AF,
    connect( input_, SIGNAL( forwardAction(int) ), this, SIGNAL( forwardAction(int) ));

    connect( input_, SIGNAL(updatePos(int, int)), this, SIGNAL(updatePos(int, int)));
    contentChanged();

    connect(input_, SIGNAL(setState(int)), this, SLOT(setState(int)));
    connect(input_, SIGNAL(textChanged()), input_, SLOT(setModified()));
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
    output_->setFrameShape( QFrame::Box );
    output_->setAutoFormatting( QTextEdit::AutoNone );
    output_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
    output_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );

    connect( output_, SIGNAL( textChanged() ), this, SLOT(contentChanged()));
    connect( output_, SIGNAL( clickOnCell() ), this, SLOT( clickEventOutput() ));
    connect( output_, SIGNAL( wheelMove(QWheelEvent*) ), this, SLOT( wheelEvent(QWheelEvent*) ));

    connect(output_, SIGNAL(forwardAction(int)), this, SIGNAL(forwardAction(int)));

    setOutputStyle();

    output_->setTextInteractionFlags(
      Qt::TextSelectableByMouse|
      Qt::TextSelectableByKeyboard|
      Qt::LinksAccessibleByMouse|
      Qt::LinksAccessibleByKeyboard);
    output_->hide();
  }

  void GraphCell::createPlotWindow()
  {
      mpPlotWindow = new PlotWindow();
      mpPlotWindow->setMinimumHeight(400);
      layout_->addWidget( mpPlotWindow, 3, 1 /*, Qt::AlignHCenter*/);
      mpPlotWindow->hide();
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
      output_->setFont(style.textCharFormat()->font());
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

    connect( chaptercounter_, SIGNAL( clickOnCell() ), this, SLOT( clickEvent() ));

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
    Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
    CellStyle style = sheet->getStyle( "Input" );

    QTextEdit te;
    te.setPlainText(input_->toPlainText());
    te.selectAll();
    te.mergeCurrentCharFormat( (*style_.textCharFormat()) );
    te.document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );

    return te.toHtml();
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
    return (QTextEdit*)input_;
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
    bool state = input_->document()->blockSignals(true);

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
    input_->document()->blockSignals(state);
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
    input_->setPlainText( html );
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
//      input_->setAlignment( (Qt::AlignmentFlag)style_.alignment() );
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
  * \brief Set readonly value on the texteditor
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
      // qDebug() << "setReadOnly: crash" << endl;
    }
  }

  /*!
  * \author Anders Fernström
  * \date 2006-01-16
  *
  * \brief Set evaluated value on the texteditor
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
  * \brief Set if the output part of the cell shoud be
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
    }
    else
    {
      if( evaluated_ )
      {
        output_->show();
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
  * \brief Recalculates height.
  *
  * 2005-10-31 AF, Large part of this function was changes due to
  * porting to QT4 (changes from Q3TextBrowser to QTextBrowser).
  * 2006-04-10 AF, emits heightChanged if the height changes
  */
  void GraphCell::contentChanged()
  {
    int lineCount = input_->document()->lineCount() + 1;
    QFontMetrics fm(input_->font());
    int lineSpacing = fm.lineSpacing()+1;
    int height = lineCount * lineSpacing;

    input_->setMinimumHeight(height);

    if( evaluated_ && !closed_ )
    {
      int outHeight = output_->document()->documentLayout()->documentSize().toSize().height();

      if( outHeight < 0 ) outHeight = 30;

      output_->setMinimumHeight( outHeight );
      height += outHeight;
    }

    if(mpPlotWindow && mpPlotWindow->isVisible())
    {
      height += mpPlotWindow->height();
    }

    setHeight( height );
    emit textChanged();

    if( oldHeight_ != height )
      emit heightChanged();

    oldHeight_ = height;
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

  void GraphCell::setExpr(QString expr)
  {
    input_->setPlainText(expr);
  }

  void GraphCell::PlotCallbackFunction(void *p, int externalWindow, const char* filename, const char *title, const char *grid,
                                       const char *plotType, const char *logX, const char *logY, const char *xLabel, const char *yLabel,
                                       const char *x1, const char *x2, const char *y1, const char *y2, const char *curveWidth,
                                       const char *curveStyle, const char *legendPosition, const char *footer, const char *autoScale,
                                       const char *variables)
  {
    GraphCell *pGraphCell = (GraphCell*)p;
    if (pGraphCell) {
      QStringList lst;
      lst << ""; // yes the first one has to be empty.
      lst << filename;
      lst << title;
      lst << grid;
      lst << plotType;
      lst << logX;
      lst << logY;
      lst << xLabel;
      lst << yLabel;
      lst << x1;
      lst << x2;
      lst << y1;
      lst << y2;
      lst << curveWidth;
      lst << curveStyle;
      lst << legendPosition;
      lst << footer;
      lst << autoScale;
      lst << QString(variables).split(" ", QString::SkipEmptyParts);
      emit pGraphCell->plotVariables(lst);  // yes we need to use signal & slot since command is executed in different thread.
    }
  }

  void GraphCell::plotVariablesSlot(QStringList lst)
  {
    try
    {
      mpPlotWindow->show();
      // clear any curves if we have.
      foreach (PlotCurve *pPlotCurve, mpPlotWindow->getPlot()->getPlotCurvesList())
      {
        mpPlotWindow->getPlot()->removeCurve(pPlotCurve);
        pPlotCurve->detach();
      }
      mpPlotWindow->initializePlot(lst);
      /*! @note Calling the fitInView function removes the xRange/yRange set on the plotter by user.
          Fix for bug #2047.
      */
//      mpPlotWindow->fitInView();
      mpPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
    }
    catch (PlotException &e)
    {
      QMessageBox::warning( 0, tr("Error"), e.what(), "OK" );
    }
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
  QMutex* guard = new QMutex(QMutex::Recursive);

  void GraphCell::eval()
  {
    input_->blockSignals(true);
    output_->blockSignals(true);

    setState(Eval);

    if( hasDelegate() )
    {

      // Only the text, no html tags. /AF
      QString expr = input_->toPlainText();
      // Before evaluating any expression set the plot callback pointer and function.
      OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
      env->threadData_->plotClassPointer = this;
      env->threadData_->plotCB = GraphCell::PlotCallbackFunction;
      // Before evaluating any expression also hide the PlotWindow. If callback function is called it will show it.
      mpPlotWindow->hide();

      // 2006-02-17 AF,
      evaluated_ = true;
      setClosed(false);

      // 2006-02-17 AF, set text '{evaluation expression}" during
      // evaluation of expression
      output_->selectAll();
      output_->textCursor().insertText( "{evaluating expression}" );
      setOutputStyle();
      output_->update();
      QCoreApplication::processEvents();

      // 2005-11-24 AF, added check to see if the user wants to quit
      if( 0 == expr.indexOf( "quit()", 0, Qt::CaseSensitive ))
      {
        qApp->closeAllWindows();
        input_->blockSignals(false);
        output_->blockSignals(false);
        return;
      }

      {
        guard->lock();
        // adrpo:FIXME! WRONG! TODO! this is wrong!
        //       the commands should be sent to OMC in the same sequence
        //       they appear in the notebook, otherwise a simulate command
        //       might finish later than a plot!

        /*! @todo we can't use Qt threads with OpenModelica shared library. Use pthreads here.
         * for now just call it without threads.
         */
//        EvalThread* et = new EvalThread(getDelegate(), expr);
//        connect(et, SIGNAL(finished()), this, SLOT(delegateFinished()));
//        et->start();
        getDelegate()->evalExpression(expr);
        delegateFinished(getDelegate());
      }
    }
    input_->blockSignals(false);
    output_->blockSignals(false);
  }

  void GraphCell::delegateFinished(InputCellDelegate *delegate)
  {
    QString res   = delegate->getResult();
    QString error = delegate->getError();
    int errorLevel= delegate->getErrorLevel();

    //delete sender();
    guard->unlock();

    if( res.isEmpty() && (error.isEmpty() || error.size() == 0) ) {
      res = "[done]";
      setState(Finished);
    }

    if( !error.isEmpty() && error.size() != 0) {
      setState(Error);
      res += QString("\n") + error;
    }
    else
      setState(Finished);

    output_->selectAll();
    res = res.replace(QRegExp("\\[<interactive>:([\\d]+):([\\d]+)-([\\d]+):([\\d]+):.*\\](.*)"),"[\\1:\\2-\\3:\\4]\\5");
    output_->textCursor().insertText( res );

    QPalette pal = output_->palette(); // define palette for textEdit.
    if (errorLevel >= 2) {
      pal.setColor(QPalette::Base, QColor(0xff,0xe0,0xe0));
    } else if (errorLevel == 1) {
      pal.setColor(QPalette::Base, QColor(0xff,0xff,0xe0));
    } else {
      pal.setColor(QPalette::Base, Qt::white);
    }
    output_->setPalette(pal);

    QRegExp e("([\\d]+:[\\d]+-[\\d]+:[\\d]+)|([\\d]+:[\\d]+)");
    int cap = 1;
    int p=0;
    QList<QAction*> actions;
    while((p=res.indexOf(e, p)) > 0) {
      QTextCharFormat f;
      f.setAnchor(true);

      if(e.cap(2).size() > e.cap(1).size()) {
        cap = 2;
      }
      f.setAnchorHref("http://fake.url/"+e.cap(cap));
      QTextCursor c(output_->textCursor());
      c.setPosition(p);
      c.setPosition(p+=e.cap(cap).size(), QTextCursor::KeepAnchor);

      f.setFontUnderline(true);
      f.setUnderlineColor(QColor(0,0,255));
      c.mergeCharFormat(f);

      MyAction* a = new MyAction("_"+e.cap(cap), 0);
      connect(a, SIGNAL(triggered()), a, SLOT(triggered2()));
      connect(a, SIGNAL(urlClicked(const QUrl&)), output_, SIGNAL(anchorClicked(const QUrl&)));
      actions.push_back(a);
    }
    emit setStatusMenu(actions);

    ++numEvals_;
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
    case Modified:
      emit newState(tr("Ready"));
      break;
    case Eval:
      emit newState(tr("Evaluating..."));
      break;
    case Finished:
      emit newState(tr("Done"));
      break;
    case Error:
      emit newState(tr("Error"));
      break;
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

    if( commandcompletion->insertCommand( cursor )) {
      input_->setTextCursor( cursor );
      emit newState(commandcompletion->helpCommand().toLatin1().data());
    }
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
    //qDebug("Next Command");
    CommandCompletion *commandcompletion = CommandCompletion::instance( "commands.xml" );
    QTextCursor cursor = input_->textCursor();

    if( commandcompletion->nextCommand( cursor )) {
      input_->setTextCursor( cursor );
      emit newState(commandcompletion->helpCommand().toLatin1().data());
    }
  }

  /*!
  * \author Anders Fernström
  * \date 2005-12-15
  *
  *\brief Select the next field in the command, if any exists
  */
  void GraphCell::nextField()
  {
    //qDebug("Next Field");
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
  * 2006-01-16 AF, don't add text editor if MyTextEdit2 says NO
  */
  void GraphCell::addToHighlighter()
  {
    emit textChanged(true);
  }


  // ***************************************************************


  /*! \brief Sets the evaulator delegate.
  */
  void GraphCell::setDelegate(InputCellDelegate *d)
  {
    delegate_ = d;
  }

  InputCellDelegate *GraphCell::getDelegate()
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
