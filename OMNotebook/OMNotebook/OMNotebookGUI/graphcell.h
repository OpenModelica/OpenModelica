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

#ifndef GraphCell_H_
#define GraphCell_H_


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
#include "inputcelldelegate.h"
#include "document.h"
//#include <QToolBar>
#include "PlotWindow.h"
#include "ModelicaTextHighlighter.h"

class IndentationState;

namespace IAEX
{
  enum graphCellStates {Finished, Eval, Error, Modified};

  class MyTextEdit2;
  class MyTextEdit2a;
  class GraphCell : public Cell
  {
    Q_OBJECT

  public:
    GraphCell(Document *doc, QWidget *parent=0);  // Changed 2005-11-23 AF
    virtual ~GraphCell();

    QString text();
    QString textHtml();            // Added 2005-10-27 AF
    virtual QString textOutput();      // Added 2005-11-23 AF
    virtual QString textOutputHtml();    // Added 2005-11-23 AF
    virtual QTextCursor textCursor();    // Added 2005-10-27 AF
    virtual QTextEdit* textEdit();      // Added 2006-01-05 AF
    virtual QTextEdit* textEditOutput();  // Added 2006-02-03 AF
    virtual void viewExpression(const bool){}

    virtual void addCellWidgets();
    virtual void removeCellWidgets();

//    void setDelegate(GraphCellDelegate *d);
    void setDelegate(InputCellDelegate *d);
    virtual void accept(Visitor &v);
    virtual bool isClosed();              // Added 2006-01-17 AF
    virtual bool isEditable();
    virtual bool isEvaluated();              // Added 2005-11-23 AF

    static void PlotCallbackFunction(void *p, int externalWindow, const char* filename, const char* title, const char* grid,
                                     const char* plotType, const char* logX, const char* logY, const char* xLabel, const char* yLabel,
                                     const char* x1, const char* x2, const char* y1, const char* y2, const char* curveWidth,
                                     const char* curveStyle, const char* legendPosition, const char* footer, const char* autoScale,
                                     const char* variables);

  signals:
    void plotVariables(QStringList lst);
    void textChanged();
    void textChanged( bool );
    void clickedOutput( Cell* );          // Added 2006-02-03 AF
    void forwardAction( int );            // Added 2006-04-27 AF
    void updatePos(int, int);
    void newState(QString);
    void setStatusMenu(QList<QAction*>);

  public slots:
    void plotVariablesSlot(QStringList lst);
    void eval();
    void command();                  // Added 2005-12-15 AF
    void nextCommand();                // Added 2005-12-15 AF
    void nextField();                // Added 2005-12-15 AF
    void clickEvent();
    void clickEventOutput();            // Added 2006-02-03 AF
    void contentChanged();
    void setText(QString text);
    void setTextHtml(QString html);          // Added 2005-11-01 AF
    virtual void setTextOutput(QString output);    // Added 2005-11-23 AF
    virtual void setTextOutputHtml(QString html);  // Added 2005-11-23 AF
    void setStyle(const QString &stylename);    // Changed 2005-10-28 AF
    void setStyle(CellStyle style);          // Changed 2005-10-27 AF
    void setChapterCounter(QString number);      // Added 2006-03-02 AF
    QString ChapterCounter();            // Added 2006-03-02 AF
    QString ChapterCounterHtml();          // Added 2006-03-03 AF
    void setReadOnly(const bool readonly);      // Added 2005-11-01 AF
    void setEvaluated(const bool evaluated);    // Added 2006-01-16 AF
    void setClosed(const bool closed, bool update = true); //Changed 2006-08-24
    virtual void setFocus(const bool focus);
    virtual void setFocusOutput(const bool focus);  // Added 2006-02-03 AF
    void setExpr(QString);

    void delegateFinished(InputCellDelegate *delegate);
    void setState(int state);

  protected:
    void resizeEvent(QResizeEvent *event);    //AF
    void mouseDoubleClickEvent(QMouseEvent *);
    void clear();

    bool hasDelegate();
    InputCellDelegate *getDelegate();

  private slots:
    void addToHighlighter();              // Added 2005-12-29 AF

  private:
    void createGraphCell();
    void createOutputCell();
    void createPlotWindow();

    void createChapterCounter();
    void setOutputStyle();                // Added 2006-04-21 AF

  private:
    bool evaluated_;
    bool closed_;
    static int numEvals_;
    int oldHeight_;                    // Added 2006-04-10 AF

  public:
    MyTextEdit2a* input_;
    ModelicaTextHighlighter *mpModelicaTextHighlighter;
    QTextBrowser *output_;
  private:
    QTextBrowser *chaptercounter_;
    InputCellDelegate *delegate_;
    QGridLayout *layout_;
    Document *document_;

  public:
    OMPlot::PlotWindow *mpPlotWindow;
    QPushButton* variableButton;
    QTemporaryFile* imageFile;
  };


  //***************************************************
  // 2005-12-13 AF, changed from QTextEdit to QTextBrowser (browser better when working with images)
  class MyTextEdit2 : public QTextBrowser
  {
    Q_OBJECT

  public:
    MyTextEdit2(QWidget *parent=0);
    virtual ~MyTextEdit2();

    int state;

  public slots:
    void updatePosition();
    void setModified();
    void setAutoIndent(bool);

  signals:
    void clickOnCell();          // Added 2005-11-01 AF
    void wheelMove( QWheelEvent* );    // Added 2005-11-28 AF
    void eval();            // Added 2005-12-15 AF
    void forwardAction( int );      // Added 2006-04-27 AF
    void updatePos(int, int);
    void setState(int);

  protected:
    void mousePressEvent(QMouseEvent *event);      // Added 2005-11-01 AF
    void wheelEvent(QWheelEvent *event);        // Added 2005-11-28 AF
    void keyPressEvent(QKeyEvent *event );        // Added 2005-12-15 AF
    void insertFromMimeData(const QMimeData *source);  // Added 2006-01-23 AF
    void focusInEvent(QFocusEvent* event);

  private:
    bool inCommand;            // Added 2005-12-15 AF

  };
  //***************************************************
  class MyTextEdit2a : public QPlainTextEdit
  {
    Q_OBJECT

  public:
    MyTextEdit2a(QWidget *parent=0);
    virtual ~MyTextEdit2a();
    void lineNumberAreaPaintEvent(QPaintEvent *event);
    int lineNumberAreaWidth();

    int state;

  public slots:
    void goToPos(const QUrl&);
    void updatePosition();
    void setModified();
    void indentText();
    bool lessIndented(QString);
    void setAutoIndent(bool);

  private slots:
    void updateLineNumberAreaWidth(int newBlockCount);
    void highlightCurrentLine(bool highlight = true);
    void updateLineNumberArea(const QRect &, int);

  signals:
    void clickOnCell();          // Added 2005-11-01 AF
    void wheelMove( QWheelEvent* );    // Added 2005-11-28 AF
    void command();            // Added 2005-12-15 AF
    void nextCommand();          // Added 2005-12-15 AF
    void nextField();          // Added 2005-12-15 AF
    void eval();            // Added 2005-12-15 AF
    void forwardAction( int );      // Added 2006-04-27 AF
    void updatePos(int, int);
    void setState(int);

  protected:
    void mousePressEvent(QMouseEvent *event);      // Added 2005-11-01 AF
    void wheelEvent(QWheelEvent *event);        // Added 2005-11-28 AF
    void keyPressEvent(QKeyEvent *event );        // Added 2005-12-15 AF
    void insertFromMimeData(const QMimeData *source);  // Added 2006-01-23 AF
    void focusInEvent(QFocusEvent* event);
    void focusOutEvent(QFocusEvent* event);
    void resizeEvent(QResizeEvent *event) override;

  private:
    bool inCommand;            // Added 2005-12-15 AF
    int indentationLevel(QString, bool b=true);
    bool autoIndent;
    QMap<int, IndentationState*> indentationStates;
    QWidget *lineNumberArea;

  };

  class MyAction: public QAction
  {
    Q_OBJECT
  public:
    MyAction(const QString& text, QObject* parent);
  public slots:
    void triggered2();
  signals:
    void urlClicked(const QUrl& u);

  };

}
#endif
