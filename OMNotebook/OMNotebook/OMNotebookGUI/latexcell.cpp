#define QT_NO_DEBUG_OUTPUT
/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2015, Linköpings University,
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
* \file LatexCell.cpp
* \date 15-08-2015
*
* \brief Describes a LatexCell.
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
#include <QFile>
#include <QProcess>
#include <QDebug>
#include <QTemporaryFile>
#endif

//IAEX Headers
#include "latexcell.h"
#include "qdatetime.h"

#include "treeview.h"
#include "stylesheet.h"
#include "omcinteractiveenvironment.h"

namespace IAEX {
  /*!
  * \brief Extends QTextEdit. Mostly so I can catch when a user
  * clicks on the editor
  */
  MyTextEdit3::MyTextEdit3(QWidget *parent)
    : QTextBrowser(parent)
  {

  }

  MyTextEdit3::~MyTextEdit3()
  {
  }

  /*!
  * Needed a signal to be emited when the user click on the cell.
  *
  */
  void MyTextEdit3::mousePressEvent(QMouseEvent *event)
  {
    QTextBrowser::mousePressEvent(event);

    if( event->modifiers() == Qt::ShiftModifier ||
      textCursor().hasSelection() )
    {
      return;
    }

    emit clickOnCell();
    updatePosition();
    if(state != Error_l)
      emit setState(Modified_l);


  }

  /*!
  * \brief Handles mouse wheel events, ignore them and send the up
  * in the cell hierarchy
  */
  void MyTextEdit3::wheelEvent(QWheelEvent * event)
  {
    // ignore event and send it up in the event hierarchy
    event->ignore();
    emit wheelMove( event );
  }

  void MyTextEdit3::focusInEvent(QFocusEvent* event)
  {
    emit undoAvailable(document()->isUndoAvailable());
    emit redoAvailable(document()->isRedoAvailable());
    setModified();
    QTextBrowser::focusInEvent(event);
  }
  /*!
  * \brief Handles key event, check if command completion or eval,
  * otherwise send them to the textbrowser
  */
  void MyTextEdit3::keyPressEvent(QKeyEvent *event )
  {
    // EVAL, key: SHIFT + RETURN || SHIFT + ENTER
    if( event->modifiers() == Qt::ShiftModifier &&
      (event->key() == Qt::Key_Return || event->key() == Qt::Key_Enter) )
    {
      event->accept();
      emit eval();
    }
    // BACKSPACE, DELETE
    else if( event->key() == Qt::Key_Backspace ||
      event->key() == Qt::Key_Delete )
    {
      QTextBrowser::keyPressEvent( event );
    }
    // ALT+ENTER (ignore)
    else if( event->modifiers() == Qt::AltModifier &&
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
    else if(event->modifiers() == Qt::ControlModifier && event->key() == Qt::Key_K)
    {
      QTextCursor tc(textCursor());
      int i = toPlainText().indexOf(QRegExp("\\n|$"), tc.position());

      if(i -tc.position() > 0)
        tc.setPosition(i, QTextCursor::KeepAnchor);
      else
        tc.setPosition(i +1, QTextCursor::KeepAnchor);

      tc.insertText("");
      QTextBrowser::keyPressEvent( event );
    }
    // TAB
    else if( event->key() == Qt::Key_Tab )
    {
      textCursor().insertText( "  " );
    }
    else
    {
      QTextBrowser::keyPressEvent( event );
    }

    updatePosition();
  }

  void MyTextEdit3::setModified()
  {
    emit setState(Modified_l);
  }

  void MyTextEdit3::updatePosition()
  {
    int pos = textCursor().position();
    int row = toPlainText().left(pos).count("\n") +1;
    int col = pos - toPlainText().left(pos).lastIndexOf("\n");
    emit updatePos(row, col);
  }

  /*!
  * \brief If the mimedata that should be insertet contain text,
  * create a new mimedata object that only contains text
  */
  void MyTextEdit3::insertFromMimeData(const QMimeData *source)
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
    if(state != Error_l)
      emit setState(Modified_l);
  }

  void MyAction1::triggered2()
  {
    emit urlClicked(QUrl(text()));
  }

  MyAction1::MyAction1(const QString& text, QObject* parent): QAction(text, parent)
  {
  }


  LatexCell::LatexCell(Document *doc, QWidget *parent) :
   Cell(parent), evaluated_(false), closed_(true),
    oldHeight_( 0 ), document_(doc)
  {
    QWidget *main = new QWidget(this);
    setMainWidget(main);

    layout_ = new QGridLayout(mainWidget());
    layout_->setMargin(0);
    layout_->setSpacing(0);

    setTreeWidget(new InputTreeView(this));

    //2005-10-07 AF, Porting, change from 'QWidget::' to 'Qt::'
    setFocusPolicy(Qt::NoFocus);

    createLatexCell();
    createOutputCell();

    imageFile=0;
  }

  /*!
  *
  * \brief The class destructor
  */
  LatexCell::~LatexCell()
  {
    delete input_;
    delete output_;
    if(imageFile) {
      delete imageFile;
    }
  }

 void LatexCell::createLatexCell()
  {

    input_ = new MyTextEdit3( mainWidget() );
    layout_->addWidget( input_, 1, 1 );
    createChapterCounter();
    input_->setReadOnly( true );
    input_->setUndoRedoEnabled( true );
    input_->setFrameShape( QFrame::Box );
    input_->setAutoFormatting( QTextEdit::AutoNone );

    input_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
    input_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
    //    input_->setContextMenuPolicy( Qt::NoContextMenu );

    QPalette palette;

   // palette.setColor(input_->backgroundRole(), QColor(Qt::lightGray));
    palette.setColor(input_->backgroundRole(),QColor(247,247,247));
    input_->setPalette(palette);
    // is this needed, don't know /AF
    input_->installEventFilter(this);
    connect( input_, SIGNAL( textChanged() ), this, SLOT( contentChanged()));
    connect( input_, SIGNAL( clickOnCell() ), this, SLOT( clickEvent() ));
    connect( input_, SIGNAL( wheelMove(QWheelEvent*) ), this, SLOT( wheelEvent(QWheelEvent*) ));
    connect( input_, SIGNAL( eval() ), this, SLOT( eval() ));

    //connect( input_, SIGNAL( textChanged() ), this, SLOT( addToHighlighter() ));
    connect( input_, SIGNAL( currentCharFormatChanged(const QTextCharFormat &) ),
       this, SLOT( charFormatChanged(const QTextCharFormat &) ));
    connect( input_, SIGNAL( forwardAction(int) ), this, SIGNAL( forwardAction(int) ));

    connect( input_, SIGNAL(updatePos(int, int)), this, SIGNAL(updatePos(int, int)));
    contentChanged();

    connect(input_, SIGNAL(setState(int)), this, SLOT(setState(int)));
    connect(input_, SIGNAL(textChanged()), input_, SLOT(setModified()));
  }

  /*!
  * \brief Creates the QTextEdit for the output part of the
  * LatexCell
  *
  */
  void LatexCell::createOutputCell()
  {
    output_ = new MyTextEdit3( mainWidget() );
    layout_->addWidget( output_, 2, 1 );
    output_->setReadOnly( true );
    output_->setUndoRedoEnabled( true );
    output_->setOpenLinks(false);
    output_->setFrameShape( QFrame::Box );
    output_->setAutoFormatting( QTextEdit::AutoNone );
    output_->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
    output_->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
    connect( output_, SIGNAL( textChanged() ), this, SLOT(contentChanged()));
    connect( output_, SIGNAL( clickOnCell() ), this, SLOT( clickEventOutput() ));
    connect( output_, SIGNAL( wheelMove(QWheelEvent*) ), this, SLOT( wheelEvent(QWheelEvent*) ));
    connect(output_, SIGNAL(forwardAction(int)), this, SIGNAL(forwardAction(int)));
    connect(output_, SIGNAL(textChanged()), output_, SLOT(setModified()));

    setOutputStyle();

    output_->setTextInteractionFlags(
      Qt::TextSelectableByMouse|
      Qt::TextSelectableByKeyboard|
      Qt::LinksAccessibleByMouse|
      Qt::LinksAccessibleByKeyboard);
    output_->hide();
  }

  /*!
  * \author Anders Fernström
  * \date 2006-04-21
  *
  * \brief Set the output style
  */
  void LatexCell::setOutputStyle()
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
  void LatexCell::createChapterCounter()
  {
    chaptercounter_ = new MyTextEdit3(this);
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

  /* return The text, as plain text */

  QString LatexCell::text()
  {
    return input_->toPlainText();
  }

  /*!
  * \brief Return the text inside the cell as Html code
  *
  * \return Html code
  */
  QString LatexCell::textHtml()
  {
    return input_->toHtml();
  }

  /*!
  * \brief Return the text inside the output part of the cell
  * as plain text
  *
  * \return output text
  */
  QString LatexCell::textOutput()
  {
    return output_->toPlainText();
  }

  /*!
  * \brief Return the text and image inside the output part of the cell
  * as html code
  * \return html code
  */
  QString LatexCell::textOutputHtml()
  {
    return output_->toHtml();
  }

  /*!
  * \Return the text cursor to the QTextEdit that make up
  * the inputpart of the LatexCell
  *
  * \return Text cursor to the cell
  */
  QTextCursor LatexCell::textCursor()
  {
    return input_->textCursor();
  }

  /*!
  * \brief Return the input texteditor
  *
  * \return Texteditor for the inputpart of the LatexCell
  */
  QTextEdit *LatexCell::textEdit()
  {
    return input_;
  }

  /*!
  * \brief Return the output texteditor
  * \return Texteditor for the output part of the LatexCell
  */
  QTextEdit* LatexCell::textEditOutput()
  {
    return output_;
  }

  /*!
  * \brief Set text to the cell
  * \param text The text that should be placed inside the cell
  */
  void LatexCell::setText(QString text)
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
    contentChanged();
  }

  /*!
  * \brief Sets the visible text using html code.
  *
  * Sets the text that should be visible using html code. Can change
  * the cellheight if the text is very long.
  * \param html Html code that should be visible as normal text inside the cell mainarea.
  */
  void LatexCell::setTextHtml(QString html)
  {
    input_->setHtml( html );
    setStyle( style_ );

    contentChanged();
  }

  /*!
  * \brief Set text to the output part of the cell
  * \param text The text that should be placed inside the output part
  */
  void LatexCell::setTextOutput(QString text)
  {
    if( !text.isNull() && !text.isEmpty() )
    {
      output_->setPlainText( text );
      evaluated_ = true;
      contentChanged();
    }
  }

  /*!
  * \brief Sets the output text and images using html code.
  * Sets the text that should be visible in the output part of the
  * cell using html code. Can change the cellheight if the text is
  * very long.
  * \param html Html code that should be visible as normal text inside the cell mainarea.
  */
  void LatexCell::setTextOutputHtml(QString html)
  {
    if( !html.isNull() && !html.isEmpty() )
    {
      output_->setHtml( html );
      evaluated_ = true;
      contentChanged();
    }
  }

  /*!
  * \brief Set cell style
  * \param stylename The style name of the style that is to be applyed to the cell
  */
  void LatexCell::setStyle(const QString &)
  {
    Cell::setStyle( "Latex" );
  }

  /*!
  * \brief Set cell style
  * \param style The cell style that is to be applyed to the cell
  */
  void LatexCell::setStyle(CellStyle style)
  {
    if( style.name() == "Latex" )
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
      setStyle( "Latex" );
    }
  }

  /*!
  * \brief set the chapter counter
  */
  void LatexCell::setChapterCounter( QString number )
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
  * \brief return the value of the chapter counter, as plain text.
  * Returns null if the counter is empty
  */
  QString LatexCell::ChapterCounter()
  {
    if( chaptercounter_->toPlainText().isEmpty() )
      return QString::null;

    return chaptercounter_->toPlainText();
  }

  /*!
  * \brief return the value of the chapter counter, as html code.
  * Returns null if the counter is empty
  */
  QString LatexCell::ChapterCounterHtml()
  {
    if( chaptercounter_->toPlainText().isEmpty() )
      return QString::null;

    return chaptercounter_->toHtml();
  }

  /*!
  * \brief Set readonly value on the texteditor
  *
  * \param readonly The boolean value of readonly property
     clear text selection in chapter counter
  */
  void LatexCell::setReadOnly(const bool readonly)
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
  * \brief Set evaluated value on the texteditor
  * \param evaluated The boolean value of evaluated property
  */
  void LatexCell::setEvaluated(const bool evaluated)
  {
    evaluated_ = evaluated;
  }

  /*!

  * \brief Set if the output part of the cell shoud be
  * closed(hidden) or not.
  */
  void LatexCell::setClosed(const bool closed, bool update)
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


  void LatexCell::setFocus(const bool focus)
  {
    if(focus)
      input_->setFocus();
  }


  void LatexCell::setFocusOutput(const bool focus)
  {
    if(focus)
      output_->setFocus();
  }


  void LatexCell::clickEvent()
  {
    emit clicked(this);
  }


  void LatexCell::clickEventOutput()
  {
    emit clickedOutput(this);
  }

  /*!
  * \brief Recalculates height.
  * \emits heightChanged if the height changes
  */
  void LatexCell::contentChanged()
  {
    int height = input_->document()->documentLayout()->documentSize().toSize().height();

    if( height < 0 ) height = 30;

    // add a little extra, just in case /AF
    input_->setMinimumHeight( height );

    if( evaluated_ && !closed_ )
    {
      int outHeight = output_->document()->documentLayout()->documentSize().toSize().height();

      if( outHeight < 0 ) outHeight = 30;

      output_->setMinimumHeight( outHeight );
      height += outHeight;
    }

    setHeight( height );
    emit textChanged();

    if( oldHeight_ != height )
      emit heightChanged();

    oldHeight_ = height;
  }

  /*!
  * \brief Returns true if LatexCell is closed, otherwise the method
  * returns false.
  *
  * \return State of LatexCell (closed or not)
  */
  bool LatexCell::isClosed()
  {
    return closed_;
  }

  /*!
  * \brief Function for telling if the user is allowed to change
  * the text settings for the text inside the cell. User isn't
  * allowed to change the text settings for LatexCell so this
  * function always return false.
  *
  * \return False
  */
  bool LatexCell::isEditable()
  {
    return false;
  }

  /*!
  * \brief Returns true if LatexCell is evaluated, returns false if
  * LatexCell haven't been evaluated.
  *
  * \return State of LatexCell (evaluated or not)
  */
  bool LatexCell::isEvaluated()
  {
    return evaluated_;
  }

  void LatexCell::setExpr(QString expr)
  {
    input_->setPlainText(expr);
  }


  /*!
  *
  *\brief Sends the content of the LatexCell to the QProcess evaluator.
  * Displays the result in a outputcell. If there is an error, the results
  * are displayed as text, if the result is success then the image document is
  * added to the ouptut to preserve the document format as equations gets
  * scrambled if converted to equation, If the document need only text this cell
  * should not be used , The users must use text cells, This cell must be used
  * only for advanced documentation when there is a need to write some equations
  * and formulas. Only one page document generation
  * per Latex cell is supported
  */


void LatexCell::eval(bool silent)
{

    /*! Steps to generate the document output
       *  Create a tex script from the latex cell
       *  Start the QProcess
       *  1) Check for latex is installed in the system
       *  2) Generate the dvi file from Tex Script using the command line argument
       *     latex  -halt-on-Eroor filename.tex
       *  3) Generate the png file from dvi file using the command line argument
       *     dvipng filename.dvi -o filename.png
       *  4) Display the output as image to the output cell inorder to maintain the
       *     equations and formula structures
       */

    /*!
     * transfer the latex source to output cell and display the final output in
     * inputcell to have better view with hiding latex source and also maintain the
     * height of the final output to keep the Notebook precise.Any changes made to
     * latex source after first evaluation is done from outputcell.
     */

    QString expr;
    if(!evaluated_)
     {
       output_->setText(input_->toPlainText());
       QString latexexpr=output_->toPlainText();
       expr=latexexpr;
      }
    else
       {
        QString latexexpr=output_->toPlainText();
        expr=latexexpr;
    }
    //output_->setReadOnly(false);
    input_->blockSignals(true);
    output_->blockSignals(true);
    //output_->textCursor().insertText("");
    setState(Eval_l);
    input_->setReadOnly(true);
    bool setdvi=false;
    bool setpng=false;
    bool setpage=false;
    evaluated_ = true;
    QString tempdir=OmcInteractiveEnvironment::TmpPath();
    QTemporaryFile tfile;
    tfile.open();
    QString uniquefilename= tfile.fileName().section("/",-1,-1);
    tfile.close();
    //qDebug()<<"checktempdir"<<tempdir1;
    QString tempfname = tempdir + "/latexfile" + uniquefilename;

    QString Tex = tempfname + ".tex";
    QString Dvi = tempfname + ".dvi";
    QString Png = tempfname + ".png";
    QString log = tempfname + ".log";

    //QString expr = input_->toPlainText();
    if (!expr.isEmpty())
    {
        expr.replace("\\begin{document}","\\begin{document} \\thispagestyle{empty}");
        if (!expr.contains("\\begin{document}")) {
            expr.prepend("\\documentclass[12pt]{article}\\usepackage[utf8]{inputenc}\\usepackage{amsmath}\\usepackage{amsfonts}\\usepackage{amssymb}\\begin{document}\\thispagestyle{empty}");
            expr.append("\\end{document}");
        }
        QFile file(Tex);
        file.open(QIODevice::WriteOnly);
        QTextStream stream(&file);
        stream <<expr;
        file.close();

        QProcess *process = new QProcess(this);
        process->setWorkingDirectory(tempdir);
        process->setProcessChannelMode(QProcess::MergedChannels);
        //process->start("latex", QStringList() << Tex);
        process->start("latex", QStringList() << "-version");
        process->waitForFinished();
        QString Latexversion =process->readAllStandardOutput();

        //qDebug() << "Latex operation completed" << Latexversion;
        /* Check for latex is installed */
        if (Latexversion.isEmpty())
        {
          setState(Error_l);
          if (!silent)
            QMessageBox::warning( 0, tr("Error"), tr("Latex is not installed in your System. This cell cannot be evaluated."), "OK" );
        }
        /*Generate the DVI file from tex through latex */
        else
        {
            process->start("latex", QStringList() << "-halt-on-error" << Tex);
            process->waitForFinished();
            QFile logfile(log);
            logfile.open(QIODevice::ReadOnly);
            QStringList lines;
            while(!logfile.atEnd())
            {
                QString line=logfile.readLine();
                lines.append(line);
            }

            if(lines.last().contains("1 page"))
            {
                setpage=true;
            }

            QString texoutput=process->readAllStandardOutput();
            QFileInfo checkdvi(Dvi);
            if(!checkdvi.exists())
            {
                input_->clear();
                input_->textCursor().insertText(texoutput);
                setClosed(false);
                setState(Error_l);
            }
            else
            {
                setdvi=true;
                setClosed(true);
                setState(Finished_l);
            }

        }

        // Start PNG Generation through DVI file
        if (setdvi==true)
        {
            // check for number of pages tex script generates
            if(setpage==true)
            {
                process->start("dvipng",QStringList() << "-T" << "tight" << "-bg" << "transparent" << Dvi << "-o" << Png);
                process->waitForFinished();
                QFileInfo checkpng(Png);
                if(!checkpng.exists())
                {
                    input_->clear();
                    input_->textCursor().insertText("Error:Problem in finding dvipng executable");
                    setClosed(false);
                    setState(Error_l);
                }
                else
                {
                    input_->clear();
                    QFileInfo fi(Png);
                    QString res = fi.fileName();
                    QImage img(res, "PNG");
                    textEdit()->document()->addResource(QTextDocument::ImageResource, QUrl(res), img);
                    input_->textCursor().insertImage(res);
                    setClosed(true);
                }
            }
            else
            {
                QMessageBox::warning( 0, tr("Warning"), tr("Maximum of 1 page document generation is supported per Latexcell.\nThe script generates more than 1 page."), "OK" );
            }
        }
    }
    else
    {
        //qDebug()<< "Empty cells can't be evaluated";
        input_->clear();
        input_->textCursor().insertText(tr("Message: Empty Latex Cells cannot be evaluated."));
        setClosed(false);
        setState(Error_l);
    }
    input_->blockSignals(false);
    output_->blockSignals(false);
}


void LatexCell::setState(int state_)
  {
    input_->state = state_;
    switch(state_)
    {
    case Modified_l:
      emit newState(tr("Ready"));
      break;
    case Eval_l:
      emit newState(tr("Evaluating..."));
      break;
    case Finished_l:
      emit newState(tr("Done"));
      break;
    case Error_l:
      emit newState(tr("Error"));
      break;
    }
  }

  /*!
  * \brief set the correct style if the charFormat is changed and the
  * cell is empty. This is done because otherwise the style is lost if
  * all text is removed inside a cell.
  */
  void LatexCell::charFormatChanged(const QTextCharFormat &)
  {
    input_->blockSignals( true );
    input_->setAlignment( (Qt::AlignmentFlag)style_.alignment() );
    input_->mergeCurrentCharFormat( (*style_.textCharFormat()) );
    input_->document()->rootFrame()->setFrameFormat( (*style_.textFrameFormat()) );
    input_->blockSignals( false );
    contentChanged();

  }


  /*! \brief Do not use this member.
  *
  */
  void LatexCell::addCellWidgets()
  {
    layout_->addWidget(input_,0,0);

    if(evaluated_)
      layout_->addWidget(output_,1,0);
  }

  void LatexCell::removeCellWidgets()
  {

    layout_->removeWidget(input_);
    if(evaluated_)
      layout_->removeWidget(output_);
  }

  /*! \brief resets the input cell. Removes all output data and
  *  restores the initial state.
  */
  void LatexCell::clear()
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
  */
  void LatexCell::resizeEvent(QResizeEvent *event)
  {
    contentChanged();
    Cell::resizeEvent(event);
  }

  void LatexCell::mouseDoubleClickEvent(QMouseEvent *)
  {
    if(treeView()->testAttribute(Qt::WA_UnderMouse))
    {
      setClosed(!closed_);
    }
  }

  void LatexCell::accept(Visitor &v)
  {
    v.visitLatexCellNodeBefore(this);

    if(hasChilds())
      child()->accept(v);

    v.visitLatexCellNodeAfter(this);

    if(hasNext())
      next()->accept(v);
  }

}
