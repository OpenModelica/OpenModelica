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

#ifndef GRAPHCELL_H_
#define GRAPHCELL_H_

// Qt headers
#include <QtGlobal>
#include <QtWidgets>

// IAEX headers
#include "cell.h"
#include "indent.h"
#include "inputcelldelegate.h"
#include "document.h"
#include "PlotWindow.h"
#include "ModelicaTextHighlighter.h"

namespace IAEX {

// Enumerations
enum graphCellStates { Finished, Eval, Error, Modified };

// Forward declarations
class MyTextEdit2;
class MyTextEdit2a;

// GraphCell – the notebook cell that holds Modelica source code
class GraphCell : public Cell
{
    Q_OBJECT
public:
    explicit GraphCell(Document *doc, QWidget *parent = nullptr);

    /* ----- Cell‑interface (override virtuals from Cell) ----- */
    QString          text()               override;
    QString          textHtml()           override;
    QTextDocument*   document()           override;
    QTextCursor      textCursor()         override;
    void             cutText()            override;
    void             copyText()           override;
    void             pasteText()          override;
    bool             findText(const QString& exp,
                              QTextDocument::FindFlags options) override;
    void             clearSelection()     override;
    void             moveCursor(QTextCursor::MoveOperation operation) override;
    void             addCellWidgets()    override;
    void             removeCellWidgets() override;
    void             accept(Visitor &v)  override;
    bool             isClosed() const override;
    bool             isEditable() const override;
    bool             isEvaluated();              // not virtual in Cell

    /* ----- GraphCell‑specific members (non‑virtual) ----- */
    QString          textOutput();                    // plain‑text output
    QString          textOutputHtml();                // html output
    QTextEdit*       textEditOutput();                // raw pointer to output editor
    void             viewExpression(bool) override;

    void             setDelegate(InputCellDelegate *d);
    void             setText(QString text) override;
    void             setTextHtml(QString html) override;
    void             setTextOutput(QString output);
    void             setTextOutputHtml(QString html);
    void             setStyle(const QString &stylename) override; // old interface (kept for compatibility)
    void             setStyle(CellStyle style) override;   // preferred interface
    void             setChapterCounter(QString number);
    QString          ChapterCounter();
    QString          ChapterCounterHtml();
    void             setReadOnly(bool readonly) override;
    void             setEvaluated(bool evaluated);
    void             setClosed(bool closed, bool update = true) override;
    void             setFocus(bool focus)          override;
    void             setFocusOutput(bool focus);
    void             setExpr(QString expr);
    void             delegateFinished(InputCellDelegate *delegate);

public slots:
    void             plotVariablesSlot(QStringList lst);
    void             eval();
    void             command();
    void             nextCommand();
    void             nextField();
    void             clickEvent();
    void             clickEventOutput();
    void             contentChanged();
    void             addToHighlighter();
    void             setState(int state);

signals:
    void             plotVariables(QStringList lst);
    void             textChanged();
    void             textChanged(bool);
    void             clickedOutput(Cell *);
    void             forwardAction(int);
    void             updatePos(int, int);
    void             newState(QString);
    void             setStatusMenu(QList<QAction*>);

protected:
    void             resizeEvent(QResizeEvent *event) override;
    void             mouseDoubleClickEvent(QMouseEvent *) override;
    void             clear();
    bool             hasDelegate();
    InputCellDelegate* getDelegate();

private:
    /* ----- UI creation helpers ----- */
    void createGraphCell();
    void createOutputCell();
    void createPlotWindow();
    void createChapterCounter();
    void setOutputStyle();

    /* ----- Data members ----- */
    bool                     evaluated_   = false;
    bool                     closed_      = true;
    static int               numEvals_;
    int                      oldHeight_   = 0;

public:   // widgets – left public for historic reasons (kept unchanged)
    MyTextEdit2a*            input_                = nullptr;
    ModelicaTextHighlighter* mpModelicaTextHighlighter = nullptr;
    QTextBrowser*            output_               = nullptr;

private:
    QTextBrowser*            chaptercounter_ = nullptr;
    InputCellDelegate*       delegate_       = nullptr;
    QGridLayout*             layout_         = nullptr;
    Document*                document_       = nullptr;

public:
    OMPlot::PlotWindow*      mpPlotWindow    = nullptr;
    QPushButton*             variableButton  = nullptr;

    /* ----- Plot callback (static) ----- */
    static void PlotCallbackFunction(void *p,
                                     int externalWindow,
                                     const char *filename,
                                     const char *title,
                                     const char *grid,
                                     const char *plotType,
                                     const char *logX,
                                     const char *logY,
                                     const char *xLabel,
                                     const char *yLabel,
                                     const char *xRange1,
                                     const char *xRange2,
                                     const char *yRange1,
                                     const char *yRange2,
                                     const char *curveWidth,
                                     const char *curveStyle,
                                     const char *legendPosition,
                                     const char *footer,
                                     const char *autoScale,
                                     const char *variables);
};

/*======================================================================
 * MyTextEdit2 – a QTextBrowser used for the *output* part of a cell
 *====================================================================*/
class MyTextEdit2 : public QTextBrowser
{
    Q_OBJECT
public:
    explicit MyTextEdit2(QWidget *parent = nullptr);
    ~MyTextEdit2() override;

    int state = 0;

public slots:
    void updatePosition();
    void setModified();
    void setAutoIndent(bool);

signals:
    void clickOnCell();
    void wheelMove(QWheelEvent *);
    void eval();
    void forwardAction(int);
    void updatePos(int, int);
    void setState(int);

protected:
    void mousePressEvent(QMouseEvent *event) override;
    void wheelEvent(QWheelEvent *event) override;
    void keyPressEvent(QKeyEvent *event) override;
    void insertFromMimeData(const QMimeData *source) override;
    void focusInEvent(QFocusEvent *event) override;

private:
    bool inCommand = false;
};

// MyTextEdit2a – a QPlainTextEdit with line numbers and extra features
class MyTextEdit2a : public QPlainTextEdit
{
    Q_OBJECT
public:
    explicit MyTextEdit2a(QWidget *parent = nullptr);

    void lineNumberAreaPaintEvent(QPaintEvent *event);
    int  lineNumberAreaWidth();

    int state = 0;

public slots:
    void goToPos(const QUrl &);
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
    void clickOnCell();
    void wheelMove(QWheelEvent *);
    void command();
    void nextCommand();
    void nextField();
    void eval();
    void forwardAction(int);
    void updatePos(int, int);
    void setState(int);

protected:
    void mousePressEvent(QMouseEvent *event) override;
    void wheelEvent(QWheelEvent *event) override;
    void keyPressEvent(QKeyEvent *event) override;
    void insertFromMimeData(const QMimeData *source) override;
    void focusInEvent(QFocusEvent *event) override;
    void focusOutEvent(QFocusEvent *event) override;
    void resizeEvent(QResizeEvent *event) override;

private:
    bool                     inCommand      = false;
    bool                     autoIndent     = true;
    QMap<int, IndentationState> indentationStates;
    QWidget*                 lineNumberArea = nullptr;

    int indentationLevel(const QString &, bool = true);
};

// MyAction – thin wrapper that forwards a QAction click to a URL signal
class MyAction : public QAction
{
    Q_OBJECT
public:
    explicit MyAction(const QString &text, QObject *parent = nullptr);

public slots:
    void triggered2();

signals:
    void urlClicked(const QUrl &u);
};

} // namespace IAEX

#endif // GRAPHCELL_H_
