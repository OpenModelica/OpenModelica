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

#ifndef LatexCell_H_
#define LatexCell_H_


//QT Headers
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#else
#include <QtGui/QAction>
#include <QtGui/QWidget>
#include <QtGui/QTextBrowser>
#include <QtGui/QMouseEvent>
#include <QtGui/QGridLayout>
#include <QtGui/QResizeEvent>
#include <QtCore/QEvent>
#include <QPushButton>
#include <QTemporaryFile>
#endif

//IAEX Headers
#include "cell.h"
#include "document.h"

namespace IAEX
{
  enum latexCellStates {Finished_l, Eval_l, Error_l, Modified_l};

  class MyTextEdit3;
  class LatexCell : public Cell
  {
    Q_OBJECT

  public:
    LatexCell(Document *doc, QWidget *parent=0);
    virtual ~LatexCell();
    QString text();
    QString textHtml();
    virtual QString textOutput();
    virtual QString textOutputHtml();
    virtual QTextCursor textCursor();
    virtual QTextEdit* textEdit();
    virtual QTextEdit* textEditOutput();
    virtual void viewExpression(const bool){}

    virtual void addCellWidgets();
    virtual void removeCellWidgets();
    virtual void accept(Visitor &v);
    virtual bool isClosed();
    virtual bool isEditable();
    virtual bool isEvaluated();

  signals:
    void textChanged();
    void textChanged( bool );
    void clickedOutput( Cell* );
    void forwardAction( int );
    void updatePos(int, int);
    void newState(QString);
    void setStatusMenu(QList<QAction*>);

  public slots:
    void eval(bool silent=false);
    void clickEvent();
    void clickEventOutput();
    void contentChanged();
    void setText(QString text);
    void setTextHtml(QString html);
    virtual void setTextOutput(QString output);
    virtual void setTextOutputHtml(QString html);
    void setStyle(const QString &stylename);
    void setStyle(CellStyle style);
    void setChapterCounter(QString number);
    QString ChapterCounter();
    QString ChapterCounterHtml();
    void setReadOnly(const bool readonly);
    void setEvaluated(const bool evaluated);
    void setClosed(const bool closed, bool update = true);
    virtual void setFocus(const bool focus);
    virtual void setFocusOutput(const bool focus);
    void setExpr(QString);
    void setState(int state);

  protected:
    void resizeEvent(QResizeEvent *event);
    void mouseDoubleClickEvent(QMouseEvent *);
    void clear();

  private slots:
    void charFormatChanged(const QTextCharFormat &);

  private:
    void createLatexCell();
    void createOutputCell();
    void createChapterCounter();
    void setOutputStyle();

  private:
    bool evaluated_;
    bool closed_;
    int oldHeight_;

  public:
    MyTextEdit3* input_;
    MyTextEdit3* output_;
    //QTextBrowser *output_;
  private:
    QTextBrowser *chaptercounter_;
    //InputCellDelegate *delegate_;
    QGridLayout *layout_;
    Document *document_;

  public:
    //QPushButton* variableButton;
    //QPushButton* hideButton;
    //QPushButton* latexButton;
    QTemporaryFile* imageFile;
  };


  // QTextBrowser (browser better when working with images)
  class MyTextEdit3 : public QTextBrowser
  {
    Q_OBJECT

  public:
    MyTextEdit3(QWidget *parent=0);
    virtual ~MyTextEdit3();

    bool isStopingHighlighter();
    int state;

  public slots:
    void updatePosition();
    void setModified();

  signals:
    void clickOnCell();
    void wheelMove( QWheelEvent* );
    void eval();
    void forwardAction( int );
    void updatePos(int, int);
    void setState(int);
    //void showVariableButton(bool);

  protected:
    void mousePressEvent(QMouseEvent *event);
    void wheelEvent(QWheelEvent *event);
    void keyPressEvent(QKeyEvent *event );
    void insertFromMimeData(const QMimeData *source);
    void focusInEvent(QFocusEvent* event);

  private:
  };

  class MyAction1: public QAction
  {
    Q_OBJECT
  public:
    MyAction1(const QString& text, QObject* parent);
  public slots:
    void triggered2();
  signals:
    void urlClicked(const QUrl& u);

  };

}
#endif
