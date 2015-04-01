/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#ifndef BASEEDITOR_H
#define BASEEDITOR_H

#include <QtGui>
#include "BreakpointMarker.h"
#include "Utilities.h"

class ModelWidget;
class LineNumberArea;

class BaseEditor : public QPlainTextEdit
{
  Q_OBJECT
public:
  BaseEditor(MainWindow *pMainWindow);
  BaseEditor(ModelWidget *pModelWidget);
private:
  void initialize();
  void createActions();
public:
  int lineNumberAreaWidth();
  void lineNumberAreaPaintEvent(QPaintEvent *event);
  void lineNumberAreaMouseEvent(QMouseEvent *event);
  void goToLineNumber(int lineNumber);
  bool canHaveBreakpoints() {return mCanHaveBreakpoints;}
  void setCanHaveBreakpoints(bool canHaveBreakpoints);
  DocumentMarker* getDocumentMarker() {return mpDocumentMarker;}
  void toggleBreakpoint(const QString fileName, int lineNumber);
protected:
  ModelWidget *mpModelWidget;
  MainWindow *mpMainWindow;
  bool mCanHaveBreakpoints;
  LineNumberArea *mpLineNumberArea;
  QAction *mpFindReplaceAction;
  QAction *mpClearFindReplaceTextsAction;
  QAction *mpGotoLineNumberAction;
  QAction *mpToggleBreakpointAction;
  QAction *mpToggleCommentSelectionAction;
  DocumentMarker *mpDocumentMarker;

  virtual void resizeEvent(QResizeEvent *pEvent);
  virtual void keyPressEvent(QKeyEvent *pEvent);
  void addDefaultContextMenuActions(QMenu *pMenu);
private slots:
  virtual void showContextMenu(QPoint point) = 0;
public slots:
  void updateLineNumberAreaWidth(int newBlockCount);
  void updateLineNumberArea(const QRect &rect, int dy);
  void highlightCurrentLine();
  void updateCursorPosition();
  virtual void contentsHasChanged(int position, int charsRemoved, int charsAdded) = 0;
  void setLineWrapping();
  void showFindReplaceDialog();
  void clearFindReplaceTexts();
  void showGotoLineNumberDialog();
  void toggleBreakpoint();
  virtual void toggleCommentSelection() = 0;
  void indentOrUnindent(bool doIndent);
};

class LineNumberArea : public QWidget
{
public:
  LineNumberArea(BaseEditor *pEditor)
    : QWidget(pEditor)
  {
    mpEditor = pEditor;
  }
  QSize sizeHint() const
  {
    return QSize(mpEditor->lineNumberAreaWidth(), 0);
  }
protected:
  virtual void paintEvent(QPaintEvent *event)
  {
    mpEditor->lineNumberAreaPaintEvent(event);
  }
  virtual void mouseMoveEvent(QMouseEvent *event)
  {
    mpEditor->lineNumberAreaMouseEvent(event);
  }
  virtual void mousePressEvent(QMouseEvent *event)
  {
    mpEditor->lineNumberAreaMouseEvent(event);
  }
private:
  BaseEditor *mpEditor;
};

class GotoLineDialog : public QDialog
{
  Q_OBJECT
public:
  GotoLineDialog(BaseEditor *pBaseEditor);
private:
  BaseEditor *mpBaseEditor;
  Label *mpLineNumberLabel;
  QLineEdit *mpLineNumberTextBox;
  QPushButton *mpOkButton;
public slots:
  int exec();
private slots:
  void goToLineNumber();
};

#endif // BASEEDITOR_H
