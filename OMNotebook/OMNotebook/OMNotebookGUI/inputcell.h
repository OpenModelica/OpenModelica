/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*!
 * \file inputcell.h
 * \author Ingemar Axelsson and Anders Fernström
 * \date 2005-10-27 (update)
 *
 * \brief Describes a inputcell.
 */

#ifndef INPUTCELL_H_
#define INPUTCELL_H_


//QT Headers
#include <QtGlobal>
#include <QtWidgets>

//IAEX Headers
#include "cell.h"
#include "inputcelldelegate.h"
#include "document.h"
#include "ModelicaTextHighlighter.h"

namespace IAEX
{
  class InputCell : public Cell
  {
    Q_OBJECT

  public:
    InputCell(Document *doc, QWidget *parent=0);
    virtual ~InputCell() {};

    QString text() override;
    QString textHtml() override;
    QTextDocument* document() override;
    virtual QString textOutput();
    virtual QString textOutputHtml();
    virtual QTextCursor textCursor() override;
    virtual QTextEdit* textEdit() override;
    virtual QTextEdit* textEditOutput();
    void viewExpression(const bool) override;
    void cutText() override;
    void copyText() override;
    void pasteText() override;
    bool findText(const QString &exp, QTextDocument::FindFlags options) override;

    void clearSelection() override;
    void moveCursor(QTextCursor::MoveOperation operation) override;

    virtual void addCellWidgets() override;
    virtual void removeCellWidgets() override;

    void setDelegate(InputCellDelegate *d);
    virtual void accept(Visitor &v) override;
    virtual bool isClosed();
    virtual bool isEditable() override;
    virtual bool isEvaluated();

  signals:
    void textChanged();
    void textChanged( bool );
    void clickedOutput( Cell* );
    void forwardAction( int );

  public slots:
    void eval();
    void command();
    void nextCommand();
    void nextField();
    void clickEvent();
    void clickEventOutput();
    void contentChanged();
    void setText(QString text) override;
    void setTextHtml(QString html) override;
    virtual void setTextOutput(QString output);
    virtual void setTextOutputHtml(QString html);
    void setStyle(const QString &stylename) override;
    void setStyle(CellStyle style) override;
    void setChapterCounter(QString number);
    QString ChapterCounter();
    QString ChapterCounterHtml();
    void setReadOnly(const bool readonly) override;
    void setEvaluated(const bool evaluated);
    void setClosed(const bool closed, bool update = true) override;
    virtual void setFocus(const bool focus) override;
    virtual void setFocusOutput(const bool focus);



  protected:
    void resizeEvent(QResizeEvent *event) override;
    void mouseDoubleClickEvent(QMouseEvent *) override;
    void clear();

    bool hasDelegate();
    InputCellDelegate *delegate();

  private slots:
    void addToHighlighter();
    void charFormatChanged(const QTextCharFormat &);

  private:
    void createInputCell();
    void createOutputCell();
    void createChapterCounter();
    void setOutputStyle();

  private:
    bool evaluated_;
    bool closed_;
    static int numEvals_;
    int oldHeight_;

  public:
    QTextBrowser *input_;
    ModelicaTextHighlighter *mpModelicaTextHighlighter;
    QTextBrowser *output_;
  private:
    QTextBrowser *chaptercounter_;

    InputCellDelegate *delegate_;

    QGridLayout *layout_;
    Document *document_;
  };


  //***************************************************
  // 2005-12-13 AF, changed from QTextEdit to QTextBrowser (browser better when working with images)
  class MyTextEdit : public QTextBrowser
  {
    Q_OBJECT

  public:
    MyTextEdit(QWidget *parent=0);
    virtual ~MyTextEdit();

  signals:
    void clickOnCell();
    void wheelMove( QWheelEvent* );
    void command();
    void nextCommand();
    void nextField();
    void eval();
    void forwardAction( int );


  protected:
    void mousePressEvent(QMouseEvent *event);
    void wheelEvent(QWheelEvent *event);
    void keyPressEvent(QKeyEvent *event );
    void insertFromMimeData(const QMimeData *source);

  private:
    bool inCommand;
  };

}
#endif
